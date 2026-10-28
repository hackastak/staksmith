/**
 * status-payload — normalize a provider-agnostic session snapshot into the JSON payload that
 * `scripts/statusline-stoplight/statusline.sh` reads on stdin.
 *
 * The status line is deliberately provider-agnostic: it renders a model name, a token count, and a
 * dollar figure without any concept of "Anthropic" vs "OpenAI" vs "xAI". This module is where the
 * per-provider knowledge lives — a `MODELS` registry (display name, context-window size, per-token
 * pricing) plus `buildStatusPayload()`, which maps one harness session into the exact schema pinned
 * in `scripts/statusline.schema.md`. A harness (e.g. the Pi agent harness) feeds a `StatusSession`,
 * gets back an object it can `JSON.stringify` and pipe into `statusline.sh`.
 *
 * Two segments — git branch and package manager — are NOT emitted here: the status line resolves
 * those itself from `workspace.current_dir` (git spawn / lockfile probe). Supply `cwd` and they
 * render for free.
 *
 * Guarantee: total and side-effect-free. Every field is treated as possibly-absent; a key is only
 * emitted when it carries real data, so a missing input simply drops that segment (mirroring how
 * the renderer guards each field) rather than rendering a wrong or zero value.
 *
 * PRICING NOTE — the `inMTok`/`outMTok` figures below are USD **per million tokens**, best-effort
 * defaults as of 2026-01. Model pricing drifts; verify against each provider's pricing page and
 * edit this one table. Cost accuracy is not required for the status line to function: an unknown
 * price yields no `cost.total_cost_usd` (the cost segment is simply omitted), and a harness that
 * already knows its spend can pass `costUsd` to bypass estimation entirely.
 */

'use strict';

/** Divisor for the per-million-token prices in MODELS. */
const PER_MILLION = 1_000_000;

/** Anthropic-style default: a cache read costs ~10% of the input rate when a model omits its own. */
const DEFAULT_CACHE_READ_FACTOR = 0.1;

/**
 * Model registry keyed by canonical model id. `window` is the default context-window size (a
 * session may override it, e.g. Claude extended context). `inMTok`/`outMTok` are USD per million
 * input/output tokens; `cacheReadMTok` is optional (falls back to `inMTok * 0.1`). Omit pricing to
 * mark a model whose cost we don't estimate.
 */
const MODELS = {
  // ── Anthropic · Claude ────────────────────────────────────────────────────────────────────
  'claude-opus-5-5': { provider: 'anthropic', display: 'Opus 5.5', window: 200_000, inMTok: 15, outMTok: 75 },
  'claude-opus-4-8': { provider: 'anthropic', display: 'Opus 4.8', window: 200_000, inMTok: 15, outMTok: 75 },
  'claude-sonnet-5': { provider: 'anthropic', display: 'Sonnet 5', window: 200_000, inMTok: 3, outMTok: 15 },
  'claude-haiku-4-5': { provider: 'anthropic', display: 'Haiku 4.5', window: 200_000, inMTok: 1, outMTok: 5 },
  'claude-fable-5-1': { provider: 'anthropic', display: 'Fable 5.1', window: 200_000, inMTok: 3, outMTok: 15 },

  // ── OpenAI · newest coding models ─────────────────────────────────────────────────────────
  'gpt-5.1-codex': { provider: 'openai', display: 'GPT-5.1 Codex', window: 400_000, inMTok: 1.25, outMTok: 10 },
  'gpt-5.1': { provider: 'openai', display: 'GPT-5.1', window: 400_000, inMTok: 1.25, outMTok: 10 },
  'gpt-5-codex': { provider: 'openai', display: 'GPT-5 Codex', window: 400_000, inMTok: 1.25, outMTok: 10 },
  'gpt-5': { provider: 'openai', display: 'GPT-5', window: 400_000, inMTok: 1.25, outMTok: 10 },
  'o4-mini': { provider: 'openai', display: 'o4-mini', window: 200_000, inMTok: 1.1, outMTok: 4.4 },

  // ── xAI · Grok ──────────────────────────────────────────────────────────────────────────────
  'grok-code-fast-1': { provider: 'xai', display: 'Grok Code Fast', window: 256_000, inMTok: 0.2, outMTok: 1.5 },
  'grok-4': { provider: 'xai', display: 'Grok 4', window: 256_000, inMTok: 3, outMTok: 15 },
  'grok-4-fast': { provider: 'xai', display: 'Grok 4 Fast', window: 256_000, inMTok: 0.2, outMTok: 0.5 },

  // ── Google · Gemini ───────────────────────────────────────────────────────────────────────
  'gemini-2.5-pro': { provider: 'google', display: 'Gemini 2.5 Pro', window: 1_048_576, inMTok: 1.25, outMTok: 10 },
  'gemini-2.0-flash': { provider: 'google', display: 'Gemini 2.0 Flash', window: 1_048_576, inMTok: 0.1, outMTok: 0.4 }
};

/** Strip a trailing dated snapshot suffix: `-20251001` or `-2025-10-01`. */
function stripDateSuffix(id) {
  return id.replace(/-\d{4}-?\d{2}-?\d{2}$/, '');
}

/**
 * Resolve a model id to a registry entry. Tries, in order: exact match, the id with a trailing date
 * snapshot stripped, then the longest registry key the id starts with (so provider variants and
 * dated ids like `claude-haiku-4-5-20251001` or `gpt-5.1-codex-2026-01` still resolve). Unknown ids
 * degrade to a nameless entry with a 200k window and no pricing — never throws, never null.
 *
 * @param {string} modelId
 * @param {Record<string, object>} [models] registry override (defaults to MODELS; used by tests)
 * @returns {{provider?: string, display?: string, window: number, inMTok?: number, outMTok?: number, cacheReadMTok?: number, id: string, known: boolean}}
 */
function resolveModel(modelId, models = MODELS) {
  const id = typeof modelId === 'string' ? modelId.trim() : '';
  if (!id) return { window: 200_000, id: '', known: false };

  if (models[id]) return { ...models[id], id, known: true };

  const dateless = stripDateSuffix(id);
  if (dateless !== id && models[dateless]) return { ...models[dateless], id: dateless, known: true };

  // Longest-prefix match — prefer `gpt-5.1-codex` over `gpt-5` for `gpt-5.1-codex-foo`.
  let best = '';
  for (const key of Object.keys(models)) {
    if (id.startsWith(key) && key.length > best.length) best = key;
  }
  if (best) return { ...models[best], id: best, known: true };

  return { window: 200_000, id, known: false };
}

/** Finite non-negative number, else null. */
function num(value) {
  return typeof value === 'number' && isFinite(value) && value >= 0 ? value : null;
}

/**
 * Estimate session cost in USD from token counts and a resolved model's pricing. Returns null when
 * the model has no pricing (so the caller omits the cost segment rather than showing $0.00 for an
 * unpriced model). Cached input tokens, when supplied, are billed at `cacheReadMTok` (default: 10%
 * of the input rate) and are assumed NOT already counted in `inputTokens`.
 *
 * @param {StatusSessionLike} session
 * @param {{inMTok?: number, outMTok?: number, cacheReadMTok?: number}} model
 * @returns {number|null}
 */
function estimateCostUsd(session, model) {
  if (typeof model.inMTok !== 'number' || typeof model.outMTok !== 'number') return null;
  const inTok = num(session.inputTokens);
  const outTok = num(session.outputTokens);
  const cachedTok = num(session.cachedInputTokens);
  // No token counts at all → no activity to price; omit cost rather than assert a spurious $0.00.
  if (inTok === null && outTok === null && cachedTok === null) return null;
  const input = inTok || 0;
  const output = outTok || 0;
  const cached = cachedTok || 0;
  const cacheRate = typeof model.cacheReadMTok === 'number' ? model.cacheReadMTok : model.inMTok * DEFAULT_CACHE_READ_FACTOR;
  const usd = (input * model.inMTok + output * model.outMTok + cached * cacheRate) / PER_MILLION;
  return isFinite(usd) ? usd : null;
}

/**
 * Build the statusline stdin payload from a provider-agnostic session snapshot.
 *
 * @param {StatusSessionLike} session
 * @param {{models?: Record<string, object>}} [opts] `models` overrides the registry (for tests or a
 *   harness that ships its own price table).
 * @returns {object} an object ready to `JSON.stringify` and pipe into `statusline.sh`.
 */
function buildStatusPayload(session, opts = {}) {
  const s = session && typeof session === 'object' ? session : {};
  const model = resolveModel(s.modelId, opts.models || MODELS);
  const payload = {};

  // model — display_name preferred, id as fallback/disambiguation.
  const displayName = s.displayName || model.display || model.id;
  const modelSeg = {};
  if (displayName) modelSeg.display_name = displayName;
  if (model.id) modelSeg.id = model.id;
  if (Object.keys(modelSeg).length) payload.model = modelSeg;

  // workspace — supplying current_dir also gives the branch + pm segments for free.
  if (typeof s.cwd === 'string' && s.cwd) {
    payload.workspace = { current_dir: s.cwd };
    payload.cwd = s.cwd;
  }

  // context_window — prefer a pre-computed percentage; else hand over tokens + window size and let
  // the renderer derive the fill. A session may override the model's default window (e.g. Claude
  // extended context at 1M).
  const windowSize = num(s.contextWindowSize) || model.window;
  const contextTokens = num(s.contextTokens) !== null ? num(s.contextTokens) : num(s.inputTokens);
  const usedPct = num(s.usedPercentage);
  const cw = {};
  if (usedPct !== null) cw.used_percentage = usedPct;
  if (contextTokens !== null) {
    cw.total_input_tokens = contextTokens;
    if (windowSize) cw.context_window_size = windowSize;
  }
  if (Object.keys(cw).length) payload.context_window = cw;

  // cost — an explicit costUsd wins; otherwise estimate from tokens × model pricing. Durations and
  // line counts ride along here (statusline's duration + activity segments read cost.*).
  const cost = {};
  const explicitCost = num(s.costUsd);
  const cost_usd = explicitCost !== null ? explicitCost : estimateCostUsd(s, model);
  if (cost_usd !== null) cost.total_cost_usd = cost_usd;
  const wall = num(s.wallMs);
  if (wall !== null) cost.total_duration_ms = wall;
  const api = num(s.apiMs);
  if (api !== null) cost.total_api_duration_ms = api;
  const added = num(s.linesAdded);
  if (added !== null) cost.total_lines_added = added;
  const removed = num(s.linesRemoved);
  if (removed !== null) cost.total_lines_removed = removed;
  if (Object.keys(cost).length) payload.cost = cost;

  // rate_limits — the 7-day rolling limit is a Claude.ai-subscription concept. Omit for other
  // providers so the `7D:` segment silently drops rather than showing an invented number.
  const week = num(s.sevenDayPct);
  if (week !== null) payload.rate_limits = { seven_day: { used_percentage: week } };

  return payload;
}

/** Read a whole stream to a string (CLI helper). */
function readStream(stream) {
  return new Promise(resolve => {
    let raw = '';
    stream.setEncoding('utf8');
    stream.on('data', chunk => {
      raw += chunk;
    });
    stream.on('end', () => resolve(raw));
    stream.on('error', () => resolve(raw));
  });
}

/**
 * CLI: read a StatusSession JSON on stdin, write the statusline payload JSON on stdout. Lets a
 * harness chain the two scripts: `pi-session-json | node status-payload.js | statusline.sh`.
 */
async function main() {
  const raw = await readStream(process.stdin);
  let session = {};
  try {
    session = raw && raw.trim() ? JSON.parse(raw) : {};
  } catch {
    session = {};
  }
  process.stdout.write(JSON.stringify(buildStatusPayload(session)) + '\n');
}

if (require.main === module) {
  main();
}

module.exports = {
  MODELS,
  PER_MILLION,
  DEFAULT_CACHE_READ_FACTOR,
  resolveModel,
  stripDateSuffix,
  estimateCostUsd,
  buildStatusPayload
};
