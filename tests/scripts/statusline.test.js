/**
 * Tests for scripts/statusline.js
 *
 * Covers every segment. Pure segments (which read the parsed payload, including the git-branch and
 * package-manager fields that main() injects) are tested directly; the resolvers that touch git and
 * the filesystem are tested against the repo and a fresh temp dir.
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const SCRIPT = path.join(__dirname, '..', '..', 'scripts', 'statusline.js');
const REPO_ROOT = path.join(__dirname, '..', '..');
const {
  render,
  parseInput,
  homeShorten,
  formatDuration,
  resolveGitBranch,
  resolvePackageManager,
  parseSegmentList,
  loadConfiguredOrder,
  resolveSegmentOrder,
  colorize,
  colorsEnabled,
  meter,
  meterColor,
  SEGMENT_COLORS,
  ACTIVITY_COLORS,
  DEFAULT_ORDER,
  directorySegment,
  branchSegment,
  pmSegment,
  modelSegment,
  contextSegment,
  usageSegment,
  costSegment,
  durationSegment,
  activitySegment
} = require('../../scripts/statusline.js');

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

/** Run the script as a real CLI with the given stdin, return trimmed stdout. */
// NO_COLOR keeps content assertions deterministic; color has its own dedicated tests.
function runCli(input) {
  return execFileSync('node', [SCRIPT], {
    input: typeof input === 'string' ? input : JSON.stringify(input),
    encoding: 'utf8',
    env: { ...process.env, NO_COLOR: '1' }
  }).replace(/\n$/, '');
}

console.log('statusline.js');

// --- render(): model + directory ---
test('renders directory then model, separated', () => {
  const line = render({
    workspace: { current_dir: '/tmp/proj' },
    model: { display_name: 'Opus', id: 'claude-opus-4-8' }
  });
  assert.strictEqual(line, '/tmp/proj  Opus');
});

test('prefers workspace.current_dir over top-level cwd', () => {
  const line = render({ workspace: { current_dir: '/a' }, cwd: '/b', model: { id: 'x' } });
  assert.strictEqual(line, '/a  x');
});

test('falls back to cwd when workspace.current_dir absent', () => {
  const line = render({ cwd: '/b', model: { display_name: 'Sonnet' } });
  assert.strictEqual(line, '/b  Sonnet');
});

test('prefers model.display_name over model.id', () => {
  assert.strictEqual(modelSegment({ model: { display_name: 'Opus', id: 'claude-opus-4-8' } }), 'Opus');
  assert.strictEqual(modelSegment({ model: { id: 'claude-opus-4-8' } }), 'claude-opus-4-8');
});

// --- resilience ---
test('empty payload renders an empty line, no throw', () => {
  assert.strictEqual(render({}), '');
});

test('non-object input is tolerated', () => {
  assert.strictEqual(render(null), '');
  assert.strictEqual(render(undefined), '');
  assert.strictEqual(render('nope'), '');
});

test('missing model omits the model segment (no "undefined")', () => {
  const line = render({ workspace: { current_dir: '/only/dir' } });
  assert.strictEqual(line, '/only/dir');
});

test('missing directory omits the directory segment', () => {
  assert.strictEqual(render({ model: { display_name: 'Opus' } }), 'Opus');
});

// --- meter() ---
test('meter fills proportionally and is always `width` cells wide', () => {
  assert.strictEqual(meter(0), '░'.repeat(10));
  assert.strictEqual(meter(100), '█'.repeat(10));
  assert.strictEqual(meter(30), '███░░░░░░░');
  assert.strictEqual(meter(6), '█░░░░░░░░░');
  assert.strictEqual(meter(50, 4), '██░░');
});

test('meter clamps out-of-range and non-numeric input', () => {
  assert.strictEqual(meter(-20), '░'.repeat(10));
  assert.strictEqual(meter(250), '█'.repeat(10));
  assert.strictEqual(meter(NaN), '░'.repeat(10));
});

// --- contextSegment() ---
test('uses pre-computed used_percentage with a meter', () => {
  assert.strictEqual(contextSegment({ context_window: { used_percentage: 6 } }), `ctx:6% ${meter(6)}`);
});

test('rounds the displayed percentage; meter uses the raw value', () => {
  assert.strictEqual(contextSegment({ context_window: { used_percentage: 23.5 } }), `ctx:24% ${meter(23.5)}`);
});

test('derives percentage from tokens when used_percentage is null', () => {
  const seg = contextSegment({
    context_window: { used_percentage: null, total_input_tokens: 50000, context_window_size: 200000 }
  });
  assert.strictEqual(seg, `ctx:25% ${meter(25)}`);
});

test('omits the segment when no usable context data is present', () => {
  assert.strictEqual(contextSegment({}), '');
  assert.strictEqual(contextSegment({ context_window: { used_percentage: null } }), '');
  assert.strictEqual(contextSegment({ context_window: { total_input_tokens: 1, context_window_size: 0 } }), '');
});

test('exceeds_200k_tokens no longer changes the output', () => {
  assert.strictEqual(contextSegment({ context_window: { used_percentage: 30 }, exceeds_200k_tokens: true }), `ctx:30% ${meter(30)}`);
});

test('meterColor grades green → amber (35%) → red (50%)', () => {
  assert.strictEqual(meterColor(10), 71); // green
  assert.strictEqual(meterColor(34), 71);
  assert.strictEqual(meterColor(35), 179); // amber
  assert.strictEqual(meterColor(49), 179);
  assert.strictEqual(meterColor(50), 167); // red
  assert.strictEqual(meterColor(100), 167);
});

test('context is plain by default; whole segment (text + bar) gradient-colored when color is on', () => {
  const data = { context_window: { used_percentage: 90 } };
  assert.strictEqual(contextSegment(data), `ctx:90% ${meter(90)}`);
  // The entire "ctx:90% <bar>" string carries one gradient color — not just the bar.
  assert.strictEqual(contextSegment(data, { color: true }), colorize(`ctx:90% ${meter(90)}`, meterColor(90)));
});

test('context appears after directory and model in the full line', () => {
  const line = render({
    workspace: { current_dir: '/tmp/x' },
    model: { display_name: 'Opus' },
    context_window: { used_percentage: 6 }
  });
  assert.strictEqual(line, `/tmp/x  Opus  ctx:6% ${meter(6)}`);
});

// --- usageSegment() (7-day rate limit) ---
test('usage renders 7D label, percentage, and meter', () => {
  assert.strictEqual(usageSegment({ rate_limits: { seven_day: { used_percentage: 41 } } }), `7D:41% ${meter(41)}`);
});

test('usage rounds the percentage', () => {
  assert.strictEqual(usageSegment({ rate_limits: { seven_day: { used_percentage: 41.6 } } }), `7D:42% ${meter(41.6)}`);
});

test('usage is omitted when the rate-limit data is absent', () => {
  assert.strictEqual(usageSegment({}), '');
  assert.strictEqual(usageSegment({ rate_limits: {} }), '');
  assert.strictEqual(usageSegment({ rate_limits: { seven_day: {} } }), '');
});

test('usage is a single flat blue via render (whole segment one color)', () => {
  const data = { rate_limits: { seven_day: { used_percentage: 41 } } };
  assert.strictEqual(render(data, ['usage']), `7D:41% ${meter(41)}`); // plain
  assert.strictEqual(render(data, ['usage'], { color: true }), colorize(`7D:41% ${meter(41)}`, SEGMENT_COLORS.usage));
});

// --- costSegment() ---
test('formats session USD to two decimals', () => {
  assert.strictEqual(costSegment({ cost: { total_cost_usd: 1.2345 } }), '$1.23');
});

test('shows $0.00 at zero and <$0.01 for sub-cent costs', () => {
  assert.strictEqual(costSegment({ cost: { total_cost_usd: 0 } }), '$0.00');
  assert.strictEqual(costSegment({ cost: { total_cost_usd: 0.003 } }), '<$0.01');
});

test('omits cost when absent or non-numeric', () => {
  assert.strictEqual(costSegment({}), '');
  assert.strictEqual(costSegment({ cost: { total_cost_usd: 'nope' } }), '');
});

// --- formatDuration() / durationSegment() ---
test('formatDuration picks the coarsest unit', () => {
  assert.strictEqual(formatDuration(45000), '45s');
  assert.strictEqual(formatDuration(120000), '2m');
  assert.strictEqual(formatDuration(3600000), '1h');
});

test('durationSegment renders wall then api', () => {
  assert.strictEqual(durationSegment({ cost: { total_duration_ms: 120000, total_api_duration_ms: 3000 } }), '2m/3s');
});

test('durationSegment shows wall only when api absent, omits when wall absent', () => {
  assert.strictEqual(durationSegment({ cost: { total_duration_ms: 45000 } }), '45s');
  assert.strictEqual(durationSegment({ cost: { total_api_duration_ms: 3000 } }), '');
  assert.strictEqual(durationSegment({}), '');
});

// --- activitySegment() ---
test('renders +added/-removed', () => {
  assert.strictEqual(activitySegment({ cost: { total_lines_added: 156, total_lines_removed: 23 } }), '+156/-23');
});

test('activity treats a missing side as zero', () => {
  assert.strictEqual(activitySegment({ cost: { total_lines_added: 10 } }), '+10/-0');
});

test('activity is quiet when both counts are absent or zero', () => {
  assert.strictEqual(activitySegment({}), '');
  assert.strictEqual(activitySegment({ cost: { total_lines_added: 0, total_lines_removed: 0 } }), '');
});

test('activity colors additions green and deletions red when color is on', () => {
  const data = { cost: { total_lines_added: 156, total_lines_removed: 23 } };
  assert.strictEqual(activitySegment(data), '+156/-23'); // plain by default
  assert.strictEqual(activitySegment(data, { color: true }), `${colorize('+156', ACTIVITY_COLORS.added)}/${colorize('-23', ACTIVITY_COLORS.removed)}`);
});

test('default order composes the visible segments (pm/cost/duration off by default)', () => {
  const data = {
    workspace: { current_dir: '/tmp/x' },
    package_manager: 'npm',
    model: { display_name: 'Opus' },
    context_window: { used_percentage: 6 },
    rate_limits: { seven_day: { used_percentage: 41 } },
    cost: {
      total_cost_usd: 0.05,
      total_duration_ms: 120000,
      total_api_duration_ms: 3000,
      total_lines_added: 156,
      total_lines_removed: 23
    }
  };
  // pm, cost, and duration are registered but not in DEFAULT_ORDER, so they don't show by default.
  assert.strictEqual(render(data), `/tmp/x  Opus  ctx:6% ${meter(6)}  7D:41% ${meter(41)}  +156/-23`);
  // ...but they still render when explicitly configured.
  assert.strictEqual(render(data, ['pm', 'cost', 'duration']), 'npm  $0.05  2m/3s');
});

// --- branchSegment() / pmSegment() (pure — read main()-injected fields) ---
test('branch and pm segments read injected fields', () => {
  assert.strictEqual(branchSegment({ git_branch: 'main' }), 'main');
  assert.strictEqual(branchSegment({}), '');
  assert.strictEqual(branchSegment({ git_branch: '' }), '');
  assert.strictEqual(pmSegment({ package_manager: 'npm' }), 'npm');
  assert.strictEqual(pmSegment({}), '');
});

test('branch shows by default after directory; pm slots in when configured', () => {
  const data = {
    workspace: { current_dir: '/tmp/x' },
    git_branch: 'main',
    package_manager: 'npm',
    model: { display_name: 'Opus' }
  };
  // Default: branch after directory, pm hidden.
  assert.strictEqual(render(data), '/tmp/x  main  Opus');
  // Explicitly ordered: pm sits between branch and model.
  assert.strictEqual(render(data, ['directory', 'branch', 'pm', 'model']), '/tmp/x  main  npm  Opus');
});

// --- resolveGitBranch() / resolvePackageManager() (impure boundary) ---
test('resolveGitBranch returns the current branch inside the repo', () => {
  const branch = resolveGitBranch(REPO_ROOT);
  assert.ok(typeof branch === 'string' && branch.length > 0, `expected a branch, got "${branch}"`);
});

test('resolveGitBranch returns empty outside a git repo', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'statusline-nogit-'));
  try {
    assert.strictEqual(resolveGitBranch(tmp), '');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('resolveGitBranch tolerates a falsy dir', () => {
  assert.strictEqual(resolveGitBranch(''), '');
});

test('resolvePackageManager detects npm from the repo lockfile', () => {
  assert.strictEqual(resolvePackageManager(REPO_ROOT), 'npm');
});

test('resolvePackageManager returns empty when nothing is detectable', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'statusline-nopm-'));
  try {
    assert.strictEqual(resolvePackageManager(tmp), '');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

// --- configurable ordering / visibility ---
test('render honors an explicit subset and order', () => {
  const data = {
    workspace: { current_dir: '/tmp/x' },
    model: { display_name: 'Opus' },
    context_window: { used_percentage: 6 },
    git_branch: 'main'
  };
  assert.strictEqual(render(data, ['model', 'directory']), 'Opus  /tmp/x');
  assert.strictEqual(render(data, ['context']), `ctx:6% ${meter(6)}`);
  assert.strictEqual(render(data, ['branch', 'model']), 'main  Opus');
});

test('render falls back to the default order when order is empty or invalid', () => {
  const data = { workspace: { current_dir: '/tmp/x' }, model: { display_name: 'Opus' } };
  assert.strictEqual(render(data, []), '/tmp/x  Opus');
  assert.strictEqual(render(data, undefined), '/tmp/x  Opus');
});

test('render skips unknown segment names in an explicit order', () => {
  const data = { workspace: { current_dir: '/tmp/x' }, model: { display_name: 'Opus' } };
  assert.strictEqual(render(data, ['directory', 'bogus', 'model']), '/tmp/x  Opus');
});

test('parseSegmentList normalizes strings and arrays, dropping unknowns and dupes', () => {
  assert.deepStrictEqual(parseSegmentList('directory, model ,context'), ['directory', 'model', 'context']);
  assert.deepStrictEqual(parseSegmentList('model model directory'), ['model', 'directory']);
  assert.deepStrictEqual(parseSegmentList(['branch', 'nope', 'pm']), ['branch', 'pm']);
  assert.deepStrictEqual(parseSegmentList(''), []);
  assert.deepStrictEqual(parseSegmentList(undefined), []);
});

test('resolveSegmentOrder: env var wins over config and default', () => {
  const order = resolveSegmentOrder({ STAKSMITH_STATUSLINE_SEGMENTS: 'model,context' }, '/nonexistent/statusline.json');
  assert.deepStrictEqual(order, ['model', 'context']);
});

test('resolveSegmentOrder: config file used when no env var', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'statusline-cfg-'));
  const file = path.join(tmp, 'statusline.json');
  fs.writeFileSync(file, JSON.stringify({ segments: ['directory', 'branch'] }));
  try {
    assert.deepStrictEqual(resolveSegmentOrder({}, file), ['directory', 'branch']);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('resolveSegmentOrder: falls back to DEFAULT_ORDER with neither env nor config', () => {
  assert.deepStrictEqual(resolveSegmentOrder({}, '/nonexistent/statusline.json'), DEFAULT_ORDER);
});

test('loadConfiguredOrder returns [] for missing or malformed config', () => {
  assert.deepStrictEqual(loadConfiguredOrder('/nonexistent/statusline.json'), []);
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'statusline-badcfg-'));
  const file = path.join(tmp, 'statusline.json');
  fs.writeFileSync(file, '{not json');
  try {
    assert.deepStrictEqual(loadConfiguredOrder(file), []);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('CLI honors STAKSMITH_STATUSLINE_SEGMENTS env override', () => {
  const out = execFileSync('node', [SCRIPT], {
    input: JSON.stringify({ workspace: { current_dir: '/tmp/x' }, model: { display_name: 'Opus' } }),
    encoding: 'utf8',
    env: { ...process.env, NO_COLOR: '1', STAKSMITH_STATUSLINE_SEGMENTS: 'model,directory' }
  }).replace(/\n$/, '');
  assert.strictEqual(out, 'Opus  /tmp/x');
});

// --- color ---
test('colorize wraps text in an xterm-256 code and resets', () => {
  assert.strictEqual(colorize('main', 114), '\x1b[38;5;114mmain\x1b[0m');
});

test('render is plain by default and colored when asked', () => {
  const data = { workspace: { current_dir: '/tmp/x' }, model: { display_name: 'Opus' } };
  assert.strictEqual(render(data), '/tmp/x  Opus');
  const colored = render(data, undefined, { color: true });
  assert.ok(colored.includes('\x1b['), 'expected ANSI codes');
  assert.ok(colored.includes(colorize('Opus', SEGMENT_COLORS.model)), 'model should carry its color');
  // separator stays outside color codes
  assert.ok(colored.includes(`\x1b[0m${'  '}\x1b[38;5;`));
});

test('colorsEnabled honors NO_COLOR and the Staksmith opt-out', () => {
  assert.strictEqual(colorsEnabled({}), true);
  assert.strictEqual(colorsEnabled({ NO_COLOR: '1' }), false);
  assert.strictEqual(colorsEnabled({ STAKSMITH_STATUSLINE_COLOR: '0' }), false);
  assert.strictEqual(colorsEnabled({ STAKSMITH_STATUSLINE_COLOR: 'off' }), false);
  assert.strictEqual(colorsEnabled({ STAKSMITH_STATUSLINE_COLOR: '1' }), true);
});

test('CLI emits color by default and plain under NO_COLOR', () => {
  const payload = JSON.stringify({ workspace: { current_dir: '/tmp/x' }, model: { display_name: 'Opus' } });
  const colored = execFileSync('node', [SCRIPT], { input: payload, encoding: 'utf8' });
  assert.ok(colored.includes('\x1b['), `expected color by default, got ${JSON.stringify(colored)}`);
  const plain = execFileSync('node', [SCRIPT], {
    input: payload,
    encoding: 'utf8',
    env: { ...process.env, NO_COLOR: '1' }
  }).replace(/\n$/, '');
  assert.strictEqual(plain, '/tmp/x  Opus');
});

// --- parseInput() ---
test('parseInput tolerates empty and malformed JSON', () => {
  assert.deepStrictEqual(parseInput(''), {});
  assert.deepStrictEqual(parseInput('   '), {});
  assert.deepStrictEqual(parseInput('{not json'), {});
  assert.deepStrictEqual(parseInput('{"a":1}'), { a: 1 });
});

// --- homeShorten() ---
test('homeShorten collapses the home prefix to ~', () => {
  const prevHome = process.env.HOME;
  const prevProfile = process.env.USERPROFILE;
  process.env.HOME = '/Users/dev';
  delete process.env.USERPROFILE;
  try {
    assert.strictEqual(homeShorten('/Users/dev'), '~');
    assert.strictEqual(homeShorten('/Users/dev/proj'), '~/proj');
    assert.strictEqual(homeShorten('/other/proj'), '/other/proj');
    assert.strictEqual(homeShorten('/Users/developer/x'), '/Users/developer/x'); // no false prefix match
  } finally {
    if (prevHome === undefined) delete process.env.HOME;
    else process.env.HOME = prevHome;
    if (prevProfile !== undefined) process.env.USERPROFILE = prevProfile;
  }
});

test('directorySegment shortens home in the rendered path', () => {
  const prevHome = process.env.HOME;
  process.env.HOME = '/Users/dev';
  try {
    assert.strictEqual(directorySegment({ workspace: { current_dir: '/Users/dev/app' } }), '~/app');
  } finally {
    if (prevHome === undefined) delete process.env.HOME;
    else process.env.HOME = prevHome;
  }
});

// --- CLI end-to-end ---
test('CLI prints the rendered line for a realistic payload', () => {
  const out = runCli({
    workspace: { current_dir: '/tmp/x' },
    model: { display_name: 'Opus', id: 'claude-opus-4-8' },
    context_window: { used_percentage: 6 },
    rate_limits: { seven_day: { used_percentage: 41 } },
    cost: { total_cost_usd: 0.01 }
  });
  // cost is off by default; context and 7-day usage show.
  assert.strictEqual(out, `/tmp/x  Opus  ctx:6% ${meter(6)}  7D:41% ${meter(41)}`);
});

test('CLI prints an empty line for empty stdin, exit 0', () => {
  const out = runCli('');
  assert.strictEqual(out, '');
});

test('CLI does not crash on malformed stdin', () => {
  const out = runCli('{garbage');
  assert.strictEqual(out, '');
});

test('CLI injects live branch (default) and pm (when configured) from the repo', () => {
  const branch = resolveGitBranch(REPO_ROOT);
  // branch is in the default order; assert it's injected without any config.
  const def = runCli({ workspace: { current_dir: REPO_ROOT }, model: { display_name: 'Opus' } });
  assert.ok(def.includes(branch), `expected branch "${branch}" in "${def}"`);
  assert.ok(!def.includes(' npm'), `pm should be off by default, got "${def}"`);
  // pm still resolves and renders when the config asks for it.
  const withPm = execFileSync('node', [SCRIPT], {
    input: JSON.stringify({ workspace: { current_dir: REPO_ROOT }, model: { display_name: 'Opus' } }),
    encoding: 'utf8',
    env: { ...process.env, STAKSMITH_STATUSLINE_SEGMENTS: 'branch,pm,model' }
  }).replace(/\n$/, '');
  assert.ok(withPm.includes('npm'), `expected npm in "${withPm}"`);
  assert.ok(withPm.includes(branch), `expected branch "${branch}" in "${withPm}"`);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
