/**
 * Tests for the shared stoplight layout used by the Pi footer.
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  contextSegment,
  gaugeBar,
  gitPlace,
  joinSegments,
  readBranch,
  statusLine,
  turnsSegment,
  weekSegment,
  workHalf,
} = require('../../scripts/statusline-stoplight/layout');

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

test('gauge bar matches the bash half-up fill', () => {
  assert.strictEqual(gaugeBar(61), '▓▓▓▓▓░░░');
  assert.strictEqual(gaugeBar(41), '▓▓▓░░░░░');
  assert.strictEqual(gaugeBar(22), '▓▓░░░░░░');
  assert.strictEqual(gaugeBar(80), '▓▓▓▓▓▓░░');
});

test('context keeps its meter and nag bands', () => {
  assert.deepStrictEqual(contextSegment(22), { text: 'ctx ▓▓░░░░░░ 22%', tone: 'success' });
  assert.deepStrictEqual(contextSegment(62), { text: 'ctx ▓▓▓▓▓░░░ 62%', tone: 'warning' });
  assert.strictEqual(contextSegment(76).text, 'ctx ▓▓▓▓▓▓░░ 76%  ⚠ /compact approaching');
  assert.strictEqual(contextSegment(85).tone, 'error');
});

test('7-day gauge sits to the right of the model', () => {
  const line = statusLine({
    work: 'staksmith 🌿 main',
    claude: joinSegments([
      '✏️ ready',
      contextSegment(61).text,
      '🧠 Opus',
      weekSegment(41).text,
    ]),
  });
  assert.strictEqual(
    line,
    'staksmith 🌿 main  |  ✏️ ready  ctx ▓▓▓▓▓░░░ 61%  🧠 Opus  7d ▓▓▓░░░░░ 41%'
  );
  assert.strictEqual(weekSegment(80).tone, 'error');
  assert.strictEqual(turnsSegment(45).tone, 'error');
});

test('git place uses the worktree icon and strips the worktree suffix', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'stoplight-wt-'));
  const wt = path.join(root, '.claude', 'worktrees', 'feat');
  fs.mkdirSync(wt, { recursive: true });
  fs.writeFileSync(path.join(wt, '.git'), 'gitdir: /tmp/fake\n');
  try {
    assert.deepStrictEqual(gitPlace(wt), { name: path.basename(root), icon: '🪵' });
    assert.strictEqual(workHalf(wt, 'feat'), `${path.basename(root)} 🪵 feat`);
    assert.strictEqual(workHalf(path.join(root, 'missing')), '📁 no-repo');
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('readBranch follows a normal checkout HEAD', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'stoplight-git-'));
  fs.mkdirSync(path.join(root, '.git'));
  fs.writeFileSync(path.join(root, '.git', 'HEAD'), 'ref: refs/heads/main\n');
  try {
    assert.strictEqual(readBranch(root), 'main');
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
