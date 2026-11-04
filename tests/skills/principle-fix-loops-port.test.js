/**
 * Contract for the principle-fix-root-causes and principle-attack-the-premise fold.
 * The backlog says fold both into rules, not add competing skills.
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

console.log('\nprinciple-fix-loops port:');

test('does not add competing principle skills or commands', () => {
  for (const name of ['principle-fix-root-causes', 'principle-attack-the-premise']) {
    assert.strictEqual(fs.existsSync(path.join(repoRoot, 'skills', name)), false, name);
    assert.strictEqual(
      fs.existsSync(path.join(repoRoot, 'commands', `${name}.md`)),
      false,
      name
    );
  }
});

test('folds both principles into the development workflow rule', () => {
  const content = read('rules/common/development-workflow.md');
  assert.match(content, /## Fix Root Causes/);
  assert.match(content, /## Attack the Premise/);
  assert.match(content, /principle-fix-root-causes/);
  assert.match(content, /principle-attack-the-premise/);
  assert.match(content, /not a skill/);
  assert.match(content, /Reproduce first/);
  assert.match(content, /legitimate/);
  assert.match(content, /persisted state/);
  assert.match(content, /stop \/ still \/ again/);
  assert.match(content, /Write the premise down/);
  assert.match(content, /two or more/);
  assert.match(content, /development-workflow\.md#fix-root-causes|Fix Root Causes/);
  assert.doesNotMatch(content, /poteto-mode|setup-pstack/);
  assert.doesNotMatch(content, /principle-build-the-lever|principle-laziness-protocol|principle-redesign-from-first-principles/);
});

test('points the debug loop and repeated-fix stops at the fold', () => {
  const testing = read('rules/common/testing.md');
  assert.match(testing, /development-workflow\.md#fix-root-causes/);
  assert.match(testing, /development-workflow\.md#attack-the-premise/);
  const diagnose = read('skills/diagnosing-bugs/SKILL.md');
  assert.match(diagnose, /development-workflow\.md#fix-root-causes/);
  assert.match(diagnose, /development-workflow\.md#attack-the-premise/);
  assert.match(diagnose, /not a skill/);
  for (const agent of [
    'agents/build-error-resolver.md',
    'agents/cpp-build-resolver.md',
    'agents/go-build-resolver.md',
    'agents/rust-build-resolver.md'
  ]) {
    const body = read(agent);
    assert.match(body, /#fix-root-causes/, agent);
    assert.match(body, /#attack-the-premise/, agent);
  }
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
