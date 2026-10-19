/**
 * status-payload — normalize a provider-agnostic session snapshot into the JSON payload that
 * `scripts/statusline.js` reads on stdin. See the `.js` for behavior and the pricing note.
 */

/** Provider a model belongs to. */
export type ModelProvider = 'anthropic' | 'openai' | 'xai' | 'google';

/** A registry entry. Prices are USD per million tokens (see PRICING NOTE in the implementation). */
export interface ModelEntry {
  provider?: ModelProvider;
  /** Human-facing model name, e.g. "Opus 5.5". */
  display?: string;
  /** Default context-window size in tokens; a session may override via `contextWindowSize`. */
  window: number;
  /** USD per million input tokens. Omit to mark a model whose cost is not estimated. */
  inMTok?: number;
  /** USD per million output tokens. Omit to mark a model whose cost is not estimated. */
  outMTok?: number;
  /** USD per million cached-read input tokens. Defaults to `inMTok * 0.1` when absent. */
  cacheReadMTok?: number;
}

/** A resolved model — a registry entry plus the id it resolved to and whether it was known. */
export interface ResolvedModel extends Partial<ModelEntry> {
  window: number;
  /** The canonical id this resolved to (may differ from the input when a snapshot id was matched). */
  id: string;
  /** False when the id was not in the registry and fell back to defaults. */
  known: boolean;
}

/**
 * A provider-agnostic snapshot of the current agent session. Every field except `modelId` is
 * optional; a missing field simply drops the corresponding status-line segment.
 */
export interface StatusSession {
  /** Model id, e.g. "claude-opus-5-5", "gpt-5.1-codex", "grok-code-fast-1". */
  modelId: string;
  /** Working directory — also drives the git-branch and package-manager segments. */
  cwd?: string;
  /** Cumulative input tokens billed this session (for cost estimation). */
  inputTokens?: number;
  /** Cumulative output tokens billed this session (for cost estimation). */
  outputTokens?: number;
  /** Cached-read input tokens, billed at the cache rate; assumed separate from `inputTokens`. */
  cachedInputTokens?: number;
  /** Current context fill in tokens (the meter). Defaults to `inputTokens` when omitted. */
  contextTokens?: number;
  /** Override the model's default context-window size (e.g. Claude extended context at 1_000_000). */
  contextWindowSize?: number;
  /** Pre-computed context fill percentage (0–100). Wins over token-derived percentage. */
  usedPercentage?: number;
  /** Pre-computed session cost in USD. Wins over token × pricing estimation. */
  costUsd?: number;
  /** Wall-clock duration in ms (duration segment). */
  wallMs?: number;
  /** API-wait duration in ms (duration segment, appended). */
  apiMs?: number;
  /** Lines added this session (activity segment). */
  linesAdded?: number;
  /** Lines removed this session (activity segment). */
  linesRemoved?: number;
  /** 7-day rolling limit used, 0–100 (Claude subscription only; omit for other providers). */
  sevenDayPct?: number;
  /** Override the resolved display name. */
  displayName?: string;
}

/** The subset `estimateCostUsd` reads. */
export type StatusSessionLike = Pick<StatusSession, 'inputTokens' | 'outputTokens' | 'cachedInputTokens'>;

/** The statusline stdin payload this module emits (subset of the pinned schema that we populate). */
export interface StatusPayload {
  model?: { display_name?: string; id?: string };
  workspace?: { current_dir: string };
  cwd?: string;
  context_window?: {
    used_percentage?: number;
    total_input_tokens?: number;
    context_window_size?: number;
  };
  cost?: {
    total_cost_usd?: number;
    total_duration_ms?: number;
    total_api_duration_ms?: number;
    total_lines_added?: number;
    total_lines_removed?: number;
  };
  rate_limits?: { seven_day: { used_percentage: number } };
}

/** Divisor for the per-million-token prices in MODELS. */
export const PER_MILLION: number;

/** Anthropic-style default cache-read factor (0.1 × input rate). */
export const DEFAULT_CACHE_READ_FACTOR: number;

/** Model registry keyed by canonical model id. Editable — this is the per-provider knowledge. */
export const MODELS: Record<string, ModelEntry>;

/** Strip a trailing dated snapshot suffix (`-20251001` or `-2025-10-01`) from a model id. */
export function stripDateSuffix(id: string): string;

/**
 * Resolve a model id to a registry entry (exact → date-stripped → longest-prefix → default).
 * Never throws; unknown ids yield a nameless 200k-window entry with `known: false`.
 */
export function resolveModel(modelId: string, models?: Record<string, ModelEntry>): ResolvedModel;

/**
 * Estimate session cost in USD from token counts and a model's pricing. Returns null when the model
 * has no pricing, so the caller omits the cost segment rather than showing $0.00.
 */
export function estimateCostUsd(session: StatusSessionLike, model: Partial<ModelEntry>): number | null;

/**
 * Build the statusline stdin payload from a provider-agnostic session snapshot. Only emits keys
 * that carry real data, so absent inputs drop their segments.
 */
export function buildStatusPayload(session: StatusSession, opts?: { models?: Record<string, ModelEntry> }): StatusPayload;
