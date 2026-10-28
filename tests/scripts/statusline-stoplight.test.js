/**
 * Tests for scripts/statusline-stoplight/statusline.sh
 *
 * Covers the 7-day gauge, and that it does not steal context's used_percentage.
 */

const assert = require('assert');
const path = require('path');
const { execFileSync } = require('child_process');

const SCRIPT = path.join(__dirname, '..', '..', 'scripts', 'statusline-stoplight', 'statusline.sh');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  \u2713 ${name}`);
    passed++;
  } catch (err) {
    console.log(`  \u2717 ${name}`);
    console.log(`    Error: ${err.message}`);
    failed++;
  }
}

function render(payload) {
  const out = execFileSync(SCRIPT, [], {
    input: JSON.stringify(payload),
    encoding: 'utf8',
  });
  return out.replace(/\x1b\[[0-9;]*m/g, '').trim();
}

test('7-day gauge uses the context bar style and does not steal context %', () => {
  const line = render({
    session_id: 'smoke',
    workspace: { current_dir: '/tmp', project_dir: '/tmp' },
    model: { display_name: 'Opus' },
    context_window: { used_percentage: 61, context_window_size: 200000 },
    rate_limits: { five_hour: { used_percentage: 12 }, seven_day: { used_percentage: 41 } },
  });
  assert.match(line, /ctx ▓▓▓▓▓░░░ 61%/);
  assert.match(line, /7d ▓▓▓░░░░░ 41%/);
  assert.match(line, /🧠 Opus  7d ▓▓▓░░░░░ 41%/);
  assert.doesNotMatch(line, /ctx ▓░░░░░░░ 12%/);
});

test('7-day gauge is omitted when the weekly limit is absent', () => {
  const line = render({
    session_id: 'smoke',
    workspace: { current_dir: '/tmp', project_dir: '/tmp' },
    context_window: { used_percentage: 22, context_window_size: 200000 },
  });
  assert.match(line, /ctx ▓▓░░░░░░ 22%/);
  assert.doesNotMatch(line, /7d /);
});

test('7-day gauge turns red at 80, matching the context budget band', () => {
  const line = render({
    session_id: 'smoke',
    workspace: { current_dir: '/tmp', project_dir: '/tmp' },
    rate_limits: { seven_day: { used_percentage: 80 } },
  });
  assert.match(line, /7d ▓▓▓▓▓▓░░ 80%/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
