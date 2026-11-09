/**
 * Contract for the pstack tdd decision-filter graft.
 * The filter lives on tdd-workflow. tdd is not a competing skill.
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

console.log('\ntdd decision-filter port:');

test('does not add a competing tdd skill or command', () => {
  assert.strictEqual(fs.existsSync(path.join(repoRoot, 'skills/tdd')), false);
  assert.strictEqual(fs.existsSync(path.join(repoRoot, 'commands/tdd.md')), true);
  assert.doesNotMatch(read('commands/tdd.md'), /skills\/tdd\/SKILL\.md/);
  assert.match(read('skills/tdd-workflow/SKILL.md'), /does not need poteto-mode or setup-pstack/);
});

test('tdd-workflow states the skip gate, the bad-test definition, and failing-before evidence', () => {
  const content = read('skills/tdd-workflow/SKILL.md');
  assert.match(content, /not a skill/);
  assert.match(content, /Do not look for `skills\/tdd`/);
  assert.match(content, /unclear, expensive, integration-heavy, or not requested/);
  assert.match(content, /Prefer no new test over a bad test/);
  assert.match(content, /mostly tests mocks/);
  assert.match(content, /encodes implementation details/);
  assert.match(content, /timing or unrelated global state/);
  assert.match(content, /deleted after proving the fix/);
  assert.match(content, /80% coverage is a judgment call, not a mandate/);
  assert.match(content, /name the check and the failure it produced/);
  assert.doesNotMatch(content, /ALWAYS write tests first/);
  assert.doesNotMatch(content, /Minimum 80% coverage/);
  assert.doesNotMatch(content, /Tests are not optional/);
});

test('the Codex copy and the commands carry the same gate', () => {
  const codex = read('.agents/skills/tdd-workflow/SKILL.md');
  assert.match(codex, /When to skip/);
  assert.match(codex, /Prefer no new test over a bad test/);
  assert.match(codex, /judgment call, not a mandate/);
  assert.doesNotMatch(codex, /ALWAYS write tests first/);
  assert.doesNotMatch(codex, /Tests are not optional/);
  for (const rel of ['commands/tdd-workflow.md', '.opencode/commands/tdd-workflow.md']) {
    const content = read(rel);
    assert.match(content, /skip gate/);
    assert.match(content, /`tdd` is not a skill/);
    assert.doesNotMatch(content, /Enforces test-driven development with 80%/);
  }
});

test('rules, the agent, and the router no longer mandate tests first', () => {
  const testing = read('rules/common/testing.md');
  assert.match(testing, /skip gate/);
  assert.match(testing, /`tdd` is not a skill/);
  assert.doesNotMatch(testing, /MANDATORY workflow/);
  const workflow = read('rules/common/development-workflow.md');
  assert.match(workflow, /skip gate/);
  assert.match(workflow, /not a mandate to add a bad test/);
  const agents = read('AGENTS.md');
  assert.match(agents, /There is no `tdd` skill/);
  assert.doesNotMatch(agents, /80%\+ coverage required/);
  assert.match(read('agents/tdd-guide.md'), /skip gate/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /There is no `tdd` skill/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
