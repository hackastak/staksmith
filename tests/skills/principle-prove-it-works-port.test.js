/**
 * Contract for the principle-prove-it-works fold.
 * The backlog says fold this into rules, not add a competing skill.
 * The canonical text lives in rules/common/development-workflow.md.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '../..');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (err) {
    console.log(`  ✗ ${name}`);
    console.log(`    ${err.message}`);
    failed++;
  }
}

function read(rel) {
  const abs = path.join(repoRoot, rel);
  assert.ok(fs.existsSync(abs), `missing ${rel}`);
  return fs.readFileSync(abs, 'utf8');
}

console.log('\nprinciple-prove-it-works port:');

test('does not add a competing principle-prove-it-works skill', () => {
  assert.strictEqual(
    fs.existsSync(path.join(repoRoot, 'skills/principle-prove-it-works')),
    false
  );
  assert.strictEqual(
    fs.existsSync(path.join(repoRoot, 'commands/principle-prove-it-works.md')),
    false
  );
});

test('folds the real-artifact and citation rules into the completion rule', () => {
  const content = read('rules/common/development-workflow.md');
  assert.match(content, /## Prove It Works/);
  assert.match(content, /principle-prove-it-works/);
  assert.match(content, /not a skill/);
  assert.match(content, /real thing, not a proxy/);
  assert.match(content, /it compiles/);
  assert.match(content, /suspect the observation method/);
  assert.match(content, /fabricated citation is fatal/);
  assert.match(content, /file:line/);
  assert.match(content, /Script the check when you will repeat it/);
  assert.match(content, /show-me-your-work` is not ported/);
  assert.doesNotMatch(content, /poteto-mode|setup-pstack/);
});

test('points the toolchain gate and checklists at the fold', () => {
  const verify = read('commands/verify.md');
  assert.match(verify, /Prove It Works/);
  assert.match(verify, /does not prove the user-facing change/);
  const testing = read('rules/common/testing.md');
  assert.match(testing, /development-workflow\.md#prove-it-works/);
  const style = read('rules/common/coding-style.md');
  assert.match(style, /real artifact, not a proxy/);
  const agents = read('AGENTS.md');
  assert.match(agents, /Prove it works/);
  assert.match(agents, /no `principle-prove-it-works` skill/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
