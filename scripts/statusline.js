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

/**
 * Context-usage segment — e.g. `ctx:6%`.
 *
 * Reads `context_window` straight from the payload (CC 2.1.132+; see statusline.schema.md); no
 * transcript parsing. Prefers the pre-computed `used_percentage`, which can be `null` early in a
 * session or after `/compact` — in that case it derives the percentage from
 * `total_input_tokens / context_window_size` when both are present, and otherwise omits the
 * segment entirely. A trailing `!` marks `exceeds_200k_tokens` (a fixed 200k threshold that is
 * independent of the actual window size, which may be 1M on extended-context models).
 */
function contextSegment(data) {
  const cw = data.context_window || {};
  let pct = null;
  if (typeof cw.used_percentage === 'number' && isFinite(cw.used_percentage)) {
    pct = cw.used_percentage;
  } else if (typeof cw.total_input_tokens === 'number' && typeof cw.context_window_size === 'number' && cw.context_window_size > 0) {
    pct = (cw.total_input_tokens / cw.context_window_size) * 100;
  }
  if (pct === null) return '';
  let seg = `ctx:${Math.round(pct)}%`;
  if (data.exceeds_200k_tokens === true) seg += '!';
  return seg;
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

/**
 * Activity segment — `+added/-removed`, e.g. `+156/-23`. Omitted when both counts are absent or
 * both are zero (no edits yet), to keep an idle status line quiet.
 */
function activitySegment(data) {
  const cost = data.cost || {};
  const added = cost.total_lines_added;
  const removed = cost.total_lines_removed;
  const a = typeof added === 'number' && isFinite(added) ? added : null;
  const r = typeof removed === 'number' && isFinite(removed) ? removed : null;
  if (a === null && r === null) return '';
  if ((a || 0) === 0 && (r || 0) === 0) return '';
  return `+${a || 0}/-${r || 0}`;
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
  cost: costSegment,
  duration: durationSegment,
  activity: activitySegment
};

// Default order: location info (dir/branch/pm) leads, then session state.
const DEFAULT_ORDER = ['directory', 'branch', 'pm', 'model', 'context', 'cost', 'duration', 'activity'];

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
 * @returns {string} the single status line (no trailing newline)
 */
function render(data, order) {
  const safe = data && typeof data === 'object' ? data : {};
  const names = Array.isArray(order) && order.length ? order : DEFAULT_ORDER;
  const parts = [];
  for (const name of names) {
    const segment = SEGMENT_REGISTRY[name];
    if (!segment) continue;
    let value = '';
    try {
      value = segment(safe);
    } catch {
      value = '';
    }
    if (value) parts.push(value);
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
      line = render(data, order);
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
  DEFAULT_ORDER,
  SEGMENT_REGISTRY,
  directorySegment,
  branchSegment,
  pmSegment,
  modelSegment,
  contextSegment,
  costSegment,
  durationSegment,
  activitySegment
};
