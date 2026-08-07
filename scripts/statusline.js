#!/usr/bin/env node
/**
 * Staksmith status line
 *
 * A cross-platform, zero-dependency Claude Code `statusLine` command. Claude Code pipes a JSON
 * payload on stdin; this prints one line to stdout. Unlike the jq one-liner in
 * `examples/statusline.json`, this needs no `jq` and runs the same on Windows, macOS, and Linux.
 *
 * The stdin payload shape is pinned in `scripts/statusline.schema.md` (verified against CC 2.1.223).
 *
 * Segments: directory, git branch, package manager, model, context-usage, cost, duration, and
 * activity. Which segments render, and in what order, is configurable — precedence mirrors
 * package-manager detection: the `STAKSMITH_STATUSLINE_SEGMENTS` env var (comma/space-separated
 * names), then `<claudeDir>/statusline.json` (`{ "segments": [...] }`), then DEFAULT_ORDER.
 *
 * Guarantee: rendering never throws. A status line that crashes is worse than a sparse one, so
 * every field is treated as possibly-absent and the CLI degrades to an empty line on any error.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { detectFromPackageJson, detectFromLockFile } = require('./lib/package-manager');
const { getClaudeDir } = require('./lib/utils');

const MAX_STDIN = 1024 * 1024; // 1 MB cap — the payload is small; guard against a runaway pipe.
const SEP = '  ';

/**
 * Replace a leading home directory with `~`. Cross-platform: HOME on POSIX, USERPROFILE on Windows.
 * @param {string} dir
 * @returns {string}
 */
function homeShorten(dir) {
  const home = process.env.HOME || process.env.USERPROFILE || '';
  if (home && dir === home) return '~';
  if (home && dir.startsWith(home + '/')) return '~' + dir.slice(home.length);
  if (home && dir.startsWith(home + '\\')) return '~' + dir.slice(home.length);
  return dir;
}

/** The workspace directory a status line describes — `workspace.current_dir`, else top-level `cwd`. */
function workspaceDir(data) {
  const ws = data.workspace || {};
  const dir = ws.current_dir || data.cwd;
  return typeof dir === 'string' && dir ? dir : '';
}

/** Directory segment — prefers `workspace.current_dir`, falls back to top-level `cwd`. */
function directorySegment(data) {
  const dir = workspaceDir(data);
  return dir ? homeShorten(dir) : '';
}

/**
 * Git-branch segment. Reads `data.git_branch`, which `main()` resolves from the workspace via
 * `resolveGitBranch()`. Segments stay pure and deterministic — the git spawn lives at the impure
 * boundary in `main()`, so unit tests set `git_branch` directly instead of depending on git.
 */
function branchSegment(data) {
  return typeof data.git_branch === 'string' && data.git_branch ? data.git_branch : '';
}

/**
 * Package-manager segment. Reads `data.package_manager`, resolved by `main()` via
 * `resolvePackageManager()` (lock-file / package.json detection only — no process spawn).
 */
function pmSegment(data) {
  return typeof data.package_manager === 'string' && data.package_manager ? data.package_manager : '';
}

/** Model segment — prefers `model.display_name`, falls back to `model.id`. */
function modelSegment(data) {
  const model = data.model || {};
  const name = model.display_name || model.id;
  return typeof name === 'string' && name ? name : '';
}

/** A `width`-cell fill bar for a 0–100 percentage, e.g. `meter(30) → "███░░░░░░░"`. */
function meter(pct, width = 10) {
  const clamped = Math.max(0, Math.min(100, Number(pct) || 0));
  const filled = Math.round((clamped / 100) * width);
  return '█'.repeat(filled) + '░'.repeat(width - filled);
}

/** Gradient color for the context segment: green with room, amber from 35%, red from 50%. */
function meterColor(pct) {
  const p = Number(pct) || 0;
  if (p >= 50) return 167; // red
  if (p >= 35) return 179; // amber
  return 71; // green
}

/**
 * Context-usage segment — e.g. `ctx:6% █░░░░░░░░░`.
 *
 * Reads `context_window` straight from the payload (CC 2.1.132+; see statusline.schema.md); no
 * transcript parsing. Prefers the pre-computed `used_percentage`, which can be `null` early in a
 * session or after `/compact` — in that case it derives the percentage from
 * `total_input_tokens / context_window_size` when both are present, and otherwise omits the
 * segment entirely. A fill-bar meter follows the percentage; when color is on the whole segment
 * (text and bar together) takes a green→amber→red gradient by fill level, so a filling context
 * reads at a glance. It self-colors, so `context` is intentionally absent from SEGMENT_COLORS.
 *
 * @param {object} data parsed payload
 * @param {{color?: boolean}} [opts] when `color`, the segment is wrapped in its gradient color.
 */
function contextSegment(data, opts = {}) {
  const cw = data.context_window || {};
  let pct = null;
  if (typeof cw.used_percentage === 'number' && isFinite(cw.used_percentage)) {
    pct = cw.used_percentage;
  } else if (typeof cw.total_input_tokens === 'number' && typeof cw.context_window_size === 'number' && cw.context_window_size > 0) {
    pct = (cw.total_input_tokens / cw.context_window_size) * 100;
  }
  if (pct === null) return '';
  const seg = `ctx:${Math.round(pct)}% ${meter(pct)}`;
  return opts.color ? colorize(seg, meterColor(pct)) : seg;
}

/**
 * Format a millisecond duration compactly for a status line: `45s`, `2m`, `1h`. Rounds to the
 * coarsest unit — a status line wants a glanceable magnitude, not stopwatch precision.
 */
function formatDuration(ms) {
  const s = Math.round(ms / 1000);
  if (s < 60) return `${s}s`;
  const m = Math.round(s / 60);
  if (m < 60) return `${m}m`;
  return `${Math.round(m / 60)}h`;
}

/** Cost segment — session USD from `cost.total_cost_usd` (resets on `/clear`). */
function costSegment(data) {
  const usd = (data.cost || {}).total_cost_usd;
  if (typeof usd !== 'number' || !isFinite(usd)) return '';
  if (usd === 0) return '$0.00';
  if (usd < 0.01) return '<$0.01';
  return `$${usd.toFixed(2)}`;
}

/**
 * 7-day usage segment — `7D:41% ████░░░░░░` from `rate_limits.seven_day.used_percentage`. Reflects
 * how much of the rolling 7-day account limit is spent. Absent before the first API response and for
 * non-subscription usage (the field simply isn't in the payload), in which case the segment is
 * omitted. A single flat color (blue, via SEGMENT_COLORS) covers the whole segment, so it does not
 * self-color.
 */
function usageSegment(data) {
  const week = (data.rate_limits || {}).seven_day || {};
  const pct = week.used_percentage;
  if (typeof pct !== 'number' || !isFinite(pct)) return '';
  return `7D:${Math.round(pct)}% ${meter(pct)}`;
}

/**
 * Duration segment — `wall/api`, e.g. `2m/3s`. Wall clock (`total_duration_ms`) is primary; the
 * API-wait time (`total_api_duration_ms`) is appended when present. Omitted if wall is absent.
 */
function durationSegment(data) {
  const cost = data.cost || {};
  const wall = cost.total_duration_ms;
  if (typeof wall !== 'number' || !isFinite(wall)) return '';
  let seg = formatDuration(wall);
  const api = cost.total_api_duration_ms;
  if (typeof api === 'number' && isFinite(api)) seg += `/${formatDuration(api)}`;
  return seg;
}

// Diff-stat colors for the activity segment: additions green, deletions red.
const ACTIVITY_COLORS = { added: 71, removed: 167 };

/**
 * Activity segment — `+added/-removed`, e.g. `+156/-23`. Omitted when both counts are absent or
 * both are zero (no edits yet), to keep an idle status line quiet. Self-colors like a diff stat
 * when color is on (additions green, deletions red), so it is absent from SEGMENT_COLORS.
 *
 * @param {object} data parsed payload
 * @param {{color?: boolean}} [opts] when `color`, additions/deletions take their diff-stat colors.
 */
function activitySegment(data, opts = {}) {
  const cost = data.cost || {};
  const added = cost.total_lines_added;
  const removed = cost.total_lines_removed;
  const a = typeof added === 'number' && isFinite(added) ? added : null;
  const r = typeof removed === 'number' && isFinite(removed) ? removed : null;
  if (a === null && r === null) return '';
  if ((a || 0) === 0 && (r || 0) === 0) return '';
  const plus = `+${a || 0}`;
  const minus = `-${r || 0}`;
  if (!opts.color) return `${plus}/${minus}`;
  return `${colorize(plus, ACTIVITY_COLORS.added)}/${colorize(minus, ACTIVITY_COLORS.removed)}`;
}

/**
 * Resolve the current git branch for `dir` by spawning git once. Total — returns '' outside a
 * repo, when git is missing, or on any error. Falls back to a short SHA when HEAD is detached.
 */
function resolveGitBranch(dir) {
  if (!dir) return '';
  try {
    const run = args => spawnSync('git', args, { cwd: dir, encoding: 'utf8', timeout: 1000 });
    const res = run(['rev-parse', '--abbrev-ref', 'HEAD']);
    if (res.status !== 0 || typeof res.stdout !== 'string') return '';
    const branch = res.stdout.trim();
    if (!branch) return '';
    if (branch === 'HEAD') {
      const sha = run(['rev-parse', '--short', 'HEAD']);
      return sha.status === 0 && sha.stdout ? sha.stdout.trim() : '';
    }
    return branch;
  } catch {
    return '';
  }
}

/**
 * Resolve the project's package manager for `dir` from the package.json `packageManager` field,
 * else a lock file. No process spawn (hot-path safe). Returns '' when nothing is detected.
 */
function resolvePackageManager(dir) {
  if (!dir) return '';
  try {
    return detectFromPackageJson(dir) || detectFromLockFile(dir) || '';
  } catch {
    return '';
  }
}

// Segment name → renderer. Config refers to segments by these names.
const SEGMENT_REGISTRY = {
  directory: directorySegment,
  branch: branchSegment,
  pm: pmSegment,
  model: modelSegment,
  context: contextSegment,
  usage: usageSegment,
  cost: costSegment,
  duration: durationSegment,
  activity: activitySegment
};

// Default order: location (dir/branch) leads, then session state. `pm`, `cost`, and `duration` are
// registered and available via config, but off by default to keep the line uncluttered.
const DEFAULT_ORDER = ['directory', 'branch', 'model', 'context', 'usage', 'activity'];

// Per-segment xterm-256 colors. Muted, distinct tones that read on a dark background: location in
// cool blues/greens, model dimmed as secondary, session state in warmer accents. `context` is
// deliberately absent — it self-colors with a green→amber→red fill gradient (see contextSegment).
const SEGMENT_COLORS = {
  directory: 75, // blue
  branch: 114, // green
  pm: 108, // teal
  model: 245, // gray (secondary)
  usage: 39, // blue (7-day usage)
  cost: 179, // gold
  duration: 244 // gray
  // `activity` self-colors like a diff stat (green/red) — see activitySegment.
};

/** Wrap text in an xterm-256 foreground color, resetting after. */
function colorize(text, code) {
  return `\x1b[38;5;${code}m${text}\x1b[0m`;
}

/**
 * Whether to emit ANSI color. Honors the NO_COLOR standard (any non-empty value disables) and a
 * Staksmith opt-out (`STAKSMITH_STATUSLINE_COLOR=0|false|off`).
 */
function colorsEnabled(env = process.env) {
  if (env.NO_COLOR) return false;
  const flag = env.STAKSMITH_STATUSLINE_COLOR;
  if (flag === '0' || flag === 'false' || flag === 'off') return false;
  return true;
}

const ENV_VAR = 'STAKSMITH_STATUSLINE_SEGMENTS';

/** Path to the optional status-line config: `<claudeDir>/statusline.json` (`{ "segments": [...] }`). */
function configPath() {
  return path.join(getClaudeDir(), 'statusline.json');
}

/**
 * Normalise a raw segment list (array, or comma/whitespace-separated string) into an ordered,
 * de-duplicated array of *known* segment names. Unknown names are dropped silently — a status line
 * must not error on a typo'd config.
 */
function parseSegmentList(raw) {
  const items = Array.isArray(raw) ? raw : typeof raw === 'string' ? raw.split(/[,\s]+/) : [];
  const seen = new Set();
  const out = [];
  for (const item of items) {
    const name = String(item).trim();
    if (SEGMENT_REGISTRY[name] && !seen.has(name)) {
      seen.add(name);
      out.push(name);
    }
  }
  return out;
}

/** Read the configured order from the config file. Returns [] when absent, unreadable, or empty. */
function loadConfiguredOrder(file = configPath()) {
  try {
    const cfg = JSON.parse(fs.readFileSync(file, 'utf8'));
    return cfg && cfg.segments ? parseSegmentList(cfg.segments) : [];
  } catch {
    return [];
  }
}

/**
 * Resolve which segments to render, and in what order. Precedence mirrors package-manager
 * detection: env var → config file → built-in default.
 */
function resolveSegmentOrder(env = process.env, file = configPath()) {
  const fromEnv = parseSegmentList(env[ENV_VAR]);
  if (fromEnv.length) return fromEnv;
  const fromConfig = loadConfiguredOrder(file);
  if (fromConfig.length) return fromConfig;
  return DEFAULT_ORDER.slice();
}

/**
 * Render the status line from a parsed payload. Pure and total — never throws.
 * @param {object} data parsed stdin JSON (or {} when absent/invalid)
 * @param {string[]} [order] segment names to render, in order; defaults to DEFAULT_ORDER.
 *   Unknown names are skipped.
 * @param {{color?: boolean}} [opts] when `color` is true, each segment is wrapped in its
 *   xterm-256 color; default is plain text.
 * @returns {string} the single status line (no trailing newline)
 */
function render(data, order, opts = {}) {
  const safe = data && typeof data === 'object' ? data : {};
  const names = Array.isArray(order) && order.length ? order : DEFAULT_ORDER;
  const useColor = opts.color === true;
  const parts = [];
  for (const name of names) {
    const segment = SEGMENT_REGISTRY[name];
    if (!segment) continue;
    let value = '';
    try {
      value = segment(safe, { color: useColor });
    } catch {
      value = '';
    }
    if (!value) continue;
    parts.push(useColor && SEGMENT_COLORS[name] ? colorize(value, SEGMENT_COLORS[name]) : value);
  }
  return parts.join(SEP);
}

/** Parse stdin text into an object, tolerating empty or malformed input. */
function parseInput(raw) {
  try {
    return raw && raw.trim() ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function main() {
  let raw = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', chunk => {
    if (raw.length < MAX_STDIN) {
      raw += chunk.substring(0, MAX_STDIN - raw.length);
    }
  });
  process.stdin.on('end', () => {
    let line = '';
    try {
      const data = parseInput(raw);
      const order = resolveSegmentOrder();
      // Impure boundary: resolve live git/PM state only when those segments will render, so a
      // config that hides them also skips the git spawn / lockfile probe.
      const dir = workspaceDir(data);
      if (dir && order.includes('branch')) data.git_branch = resolveGitBranch(dir);
      if (dir && order.includes('pm')) data.package_manager = resolvePackageManager(dir);
      line = render(data, order, { color: colorsEnabled() });
    } catch {
      line = '';
    }
    process.stdout.write(line + '\n');
  });
}

if (require.main === module) {
  main();
}

module.exports = {
  render,
  parseInput,
  homeShorten,
  formatDuration,
  workspaceDir,
  resolveGitBranch,
  resolvePackageManager,
  parseSegmentList,
  loadConfiguredOrder,
  resolveSegmentOrder,
  configPath,
  colorize,
  colorsEnabled,
  meter,
  meterColor,
  DEFAULT_ORDER,
  SEGMENT_REGISTRY,
  SEGMENT_COLORS,
  ACTIVITY_COLORS,
  directorySegment,
  branchSegment,
  pmSegment,
  modelSegment,
  contextSegment,
  usageSegment,
  costSegment,
  durationSegment,
  activitySegment
};
