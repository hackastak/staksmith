/**
 * Tests for scripts/lib/status-payload.js
 *
 * Covers model resolution (exact / date-stripped / prefix / unknown), cost estimation across
 * providers, the "only emit populated keys" contract, session overrides, and the round-trip through
 * the real statusline.js CLI.
 */

const assert = require('assert');
const path = require('path');
const { execFileSync } = require('child_process');

const PAYLOAD_SCRIPT = path.join(__dirname, '..', '..', 'scripts', 'lib', 'status-payload.js');
const STATUSLINE_SCRIPT = path.join(__dirname, '..', '..', 'scripts', 'statusline.js');
const {
  MODELS,
  PER_MILLION,
  resolveModel,
  stripDateSuffix,
  estimateCostUsd,
  buildStatusPayload
} = require('../../scripts/lib/status-payload.js');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (err) {
    console.log(`  ✗ ${name}`);
    console.log(`    Error: ${err.message}`);
    failed++;
  }
}

/** Pipe `input` through a node script and return trimmed stdout. */
function pipe(script, input, env) {
  return execFileSync('node', [script], {
    input: typeof input === 'string' ? input : JSON.stringify(input),
    encoding: 'utf8',
    env: { ...process.env, ...(env || {}) }
  }).replace(/\n$/, '');
}

console.log('status-payload.js');

// ── registry coverage: every requested provider is present ────────────────────────────────────
test('registry includes Claude, OpenAI coding, Grok, and Gemini families', () => {
  assert.ok(MODELS['claude-opus-5-5'], 'claude-opus-5-5');
  assert.ok(MODELS['gpt-5.1-codex'], 'gpt-5.1-codex');
  assert.ok(MODELS['gpt-5-codex'], 'gpt-5-codex');
  assert.ok(MODELS['grok-code-fast-1'], 'grok-code-fast-1');
  assert.ok(MODELS['grok-4'], 'grok-4');
  assert.ok(MODELS['gemini-2.5-pro'], 'gemini-2.5-pro');
  const providers = new Set(Object.values(MODELS).map(m => m.provider));
  for (const p of ['anthropic', 'openai', 'xai', 'google']) {
    assert.ok(providers.has(p), `provider ${p} represented`);
  }
});

// ── stripDateSuffix ─────────────────────────────────────────────────────────────────────────
test('stripDateSuffix removes compact and dashed date snapshots', () => {
  assert.strictEqual(stripDateSuffix('claude-haiku-4-5-20251001'), 'claude-haiku-4-5');
  assert.strictEqual(stripDateSuffix('gpt-5-codex-2026-01-15'), 'gpt-5-codex');
  assert.strictEqual(stripDateSuffix('grok-4'), 'grok-4');
});

// ── resolveModel ────────────────────────────────────────────────────────────────────────────
test('resolveModel exact match', () => {
  const m = resolveModel('grok-code-fast-1');
  assert.strictEqual(m.display, 'Grok Code Fast');
  assert.strictEqual(m.known, true);
  assert.strictEqual(m.provider, 'xai');
});

test('resolveModel strips a dated snapshot id', () => {
  const m = resolveModel('claude-haiku-4-5-20251001');
  assert.strictEqual(m.display, 'Haiku 4.5');
  assert.strictEqual(m.id, 'claude-haiku-4-5');
  assert.strictEqual(m.known, true);
});

test('resolveModel prefers the longest prefix', () => {
  const m = resolveModel('gpt-5.1-codex-preview');
  assert.strictEqual(m.id, 'gpt-5.1-codex');
  assert.strictEqual(m.display, 'GPT-5.1 Codex');
});

test('resolveModel unknown id degrades to a nameless 200k default', () => {
  const m = resolveModel('some-future-model');
  assert.strictEqual(m.known, false);
  assert.strictEqual(m.window, 200_000);
  assert.strictEqual(m.display, undefined);
});

test('resolveModel handles empty / non-string ids without throwing', () => {
  assert.strictEqual(resolveModel('').known, false);
  assert.strictEqual(resolveModel(undefined).known, false);
  assert.strictEqual(resolveModel(null).window, 200_000);
});

// ── estimateCostUsd ─────────────────────────────────────────────────────────────────────────
test('estimateCostUsd computes tokens × per-million pricing', () => {
  // 1M input + 1M output on Opus 5.5 (15 / 75) = $90.
  const usd = estimateCostUsd({ inputTokens: PER_MILLION, outputTokens: PER_MILLION }, MODELS['claude-opus-5-5']);
  assert.strictEqual(usd, 90);
});

test('estimateCostUsd bills cached tokens at the default 10% cache rate', () => {
  // 1M cached-read tokens on Sonnet 5 (input 3/MTok) → 3 * 0.1 = $0.30.
  const usd = estimateCostUsd({ cachedInputTokens: PER_MILLION }, MODELS['claude-sonnet-5']);
  assert.ok(Math.abs(usd - 0.3) < 1e-9, `expected ~0.30, got ${usd}`);
});

test('estimateCostUsd returns null for an unpriced model', () => {
  assert.strictEqual(estimateCostUsd({ inputTokens: 1000 }, { window: 200_000 }), null);
});

// ── buildStatusPayload: population contract ───────────────────────────────────────────────────
test('emits model, workspace, context, and cost from a full session', () => {
  const p = buildStatusPayload({
    modelId: 'gpt-5.1-codex',
    cwd: '/home/pi/projects/stethoscope',
    inputTokens: 40000,
    outputTokens: 8000,
    wallMs: 128000,
    apiMs: 31000,
    linesAdded: 156,
    linesRemoved: 23
  });
  assert.strictEqual(p.model.display_name, 'GPT-5.1 Codex');
  assert.strictEqual(p.model.id, 'gpt-5.1-codex');
  assert.strictEqual(p.workspace.current_dir, '/home/pi/projects/stethoscope');
  assert.strictEqual(p.context_window.total_input_tokens, 40000);
  assert.strictEqual(p.context_window.context_window_size, 400_000);
  assert.strictEqual(p.cost.total_duration_ms, 128000);
  assert.strictEqual(p.cost.total_lines_added, 156);
  assert.ok(typeof p.cost.total_cost_usd === 'number' && p.cost.total_cost_usd > 0);
});

test('minimal session emits only model (no empty keys)', () => {
  const p = buildStatusPayload({ modelId: 'claude-sonnet-5' });
  assert.deepStrictEqual(Object.keys(p), ['model']);
  assert.strictEqual(p.model.display_name, 'Sonnet 5');
});

test('usedPercentage wins over token-derived context', () => {
  const p = buildStatusPayload({ modelId: 'grok-4', usedPercentage: 42, inputTokens: 5000 });
  assert.strictEqual(p.context_window.used_percentage, 42);
  assert.strictEqual(p.context_window.total_input_tokens, 5000);
});

test('contextWindowSize override models extended context', () => {
  const p = buildStatusPayload({ modelId: 'claude-opus-5-5', inputTokens: 1000, contextWindowSize: 1_000_000 });
  assert.strictEqual(p.context_window.context_window_size, 1_000_000);
});

test('explicit costUsd wins over estimation', () => {
  const p = buildStatusPayload({ modelId: 'claude-opus-5-5', inputTokens: PER_MILLION, costUsd: 1.23 });
  assert.strictEqual(p.cost.total_cost_usd, 1.23);
});

test('sevenDayPct emitted only when present', () => {
  const withWeek = buildStatusPayload({ modelId: 'claude-sonnet-5', sevenDayPct: 41 });
  assert.strictEqual(withWeek.rate_limits.seven_day.used_percentage, 41);
  const withoutWeek = buildStatusPayload({ modelId: 'gpt-5.1-codex', inputTokens: 10 });
  assert.strictEqual(withoutWeek.rate_limits, undefined);
});

test('unpriced/unknown model omits cost.total_cost_usd but keeps other cost fields', () => {
  const p = buildStatusPayload({ modelId: 'mystery-model', inputTokens: 5000, linesAdded: 3 });
  assert.strictEqual(p.cost.total_cost_usd, undefined);
  assert.strictEqual(p.cost.total_lines_added, 3);
  assert.strictEqual(p.model.display_name, 'mystery-model');
});

test('displayName override wins', () => {
  const p = buildStatusPayload({ modelId: 'grok-4', displayName: 'Grok (custom)' });
  assert.strictEqual(p.model.display_name, 'Grok (custom)');
});

test('non-object session does not throw', () => {
  assert.deepStrictEqual(buildStatusPayload(null), {});
  assert.deepStrictEqual(buildStatusPayload(undefined), {});
});

test('models override registry is honored', () => {
  const p = buildStatusPayload({ modelId: 'x' }, { models: { x: { display: 'X-One', window: 999 } } });
  assert.strictEqual(p.model.display_name, 'X-One');
});

// ── CLI + round-trip through statusline.js ────────────────────────────────────────────────────
test('CLI reads a session on stdin and writes payload JSON', () => {
  const out = pipe(PAYLOAD_SCRIPT, { modelId: 'grok-code-fast-1', inputTokens: 1000, outputTokens: 500 });
  const parsed = JSON.parse(out);
  assert.strictEqual(parsed.model.display_name, 'Grok Code Fast');
});

test('CLI tolerates malformed stdin', () => {
  assert.deepStrictEqual(JSON.parse(pipe(PAYLOAD_SCRIPT, '{not json')), {});
});

test('payload round-trips into statusline.js rendering', () => {
  const payload = pipe(PAYLOAD_SCRIPT, {
    modelId: 'gpt-5.1-codex',
    cwd: '/tmp/proj',
    inputTokens: 44800,
    contextWindowSize: 400_000,
    linesAdded: 10,
    linesRemoved: 2
  });
  const line = pipe(STATUSLINE_SCRIPT, payload, { NO_COLOR: '1' });
  assert.ok(line.includes('/tmp/proj'), `dir in "${line}"`);
  assert.ok(line.includes('GPT-5.1 Codex'), `model in "${line}"`);
  assert.ok(line.includes('ctx:'), `context meter in "${line}"`);
  assert.ok(line.includes('+10/-2'), `activity in "${line}"`);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
