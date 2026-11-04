/**
 * Contract for the remaining Tier B design-principle fold.
 * boundary-discipline already lives in coding-standards.
 * The other three are one rule block, not competing skills.
 * The canonical text lives in rules/common/coding-style.md.
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

console.log('\nprinciple-design-shape port:');

test('does not add competing principle skills or commands', () => {
  for (const name of [
    'principle-model-the-domain',
    'principle-foundational-thinking',
    'principle-separate-before-serializing-shared-state',
    'principle-boundary-discipline'
  ]) {
    assert.strictEqual(fs.existsSync(path.join(repoRoot, 'skills', name)), false, name);
    assert.strictEqual(
      fs.existsSync(path.join(repoRoot, 'commands', `${name}.md`)),
      false,
      name
    );
  }
});

test('folds the three remaining principles into one coding-style block', () => {
  const content = read('rules/common/coding-style.md');
  assert.match(content, /## Design the Shape First/);
  assert.match(content, /### Model the Domain/);
  assert.match(content, /### Foundational Thinking/);
  assert.match(content, /### Separate Before Serializing Shared State/);
  assert.match(content, /principle-model-the-domain/);
  assert.match(content, /principle-foundational-thinking/);
  assert.match(content, /principle-separate-before-serializing-shared-state/);
  assert.match(content, /not skills/);
  assert.match(content, /ULAD/);
  assert.match(content, /state\.json/);
  assert.match(content, /not concurrency control/);
  assert.match(content, /scaffold/);
  assert.match(content, /#input-validation/);
  assert.doesNotMatch(content, /poteto-mode|setup-pstack/);
});

test('points the edit path and the domain skill at the fold', () => {
  const standards = read('skills/coding-standards/SKILL.md');
  assert.match(standards, /coding-style\.md#design-the-shape-first/);
  assert.match(standards, /principle-model-the-domain/);
  assert.match(standards, /not three skills/);
  assert.strictEqual(
    read('.agents/skills/coding-standards/SKILL.md'),
    standards
  );
  const domain = read('skills/domain-modeling/SKILL.md');
  assert.match(domain, /coding-style\.md#model-the-domain/);
  assert.match(domain, /not a skill/);
  const ts = read('rules/typescript/coding-style.md');
  assert.match(ts, /coding-style\.md#design-the-shape-first/);
});

test('points parallel work, planning, authz, and review at the fold', () => {
  assert.match(read('rules/common/agents.md'), /#separate-before-serializing-shared-state/);
  assert.match(read('rules/common/development-workflow.md'), /#foundational-thinking/);
  assert.match(read('rules/common/security.md'), /#input-validation/);
  assert.match(read('skills/interrogate/references/rubric.md'), /#model-the-domain/);
  assert.match(
    read('skills/arena/references/graft-rules.md'),
    /#separate-before-serializing-shared-state/
  );
  assert.match(read('AGENTS.md'), /Design the Shape First/);
  assert.doesNotMatch(read('skills/arena/references/graft-rules.md'), /poteto-mode|setup-pstack/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
