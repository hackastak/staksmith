/**
 * Contract for the interrogate port: the skill, its review references, and the
 * inlined model-panel rules must ship together. The panel file replaces the
 * pstack dependency on poteto-mode and setup-pstack.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '../..');
const skillDir = path.join(repoRoot, 'skills', 'interrogate');
const skillMd = path.join(skillDir, 'SKILL.md');

const REQUIRED_REFERENCES = [
  'references/reviewer-prompt.md',
  'references/rubric.md',
  'references/lead-judgment.md',
  'references/code-quality-review.md',
  'references/model-panel.md',
];

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

function readSkill() {
  assert.ok(fs.existsSync(skillMd), 'skills/interrogate/SKILL.md is missing');
  return fs.readFileSync(skillMd, 'utf8');
}

console.log('\ninterrogate skill:');

test('declares name, category, and user-invoked frontmatter', () => {
  const content = readSkill();
  const fm = content.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(fm, 'missing frontmatter');
  assert.match(fm[1], /^name:\s*interrogate\s*$/m);
  assert.match(fm[1], /^category:\s*"Code Review & Quality"\s*$/m);
  assert.match(fm[1], /^origin:\s*community\s*$/m);
  assert.match(fm[1], /^disable-model-invocation:\s*true\s*$/m);
});

test('ships every review reference and points the procedure at them', () => {
  const content = readSkill();
  for (const rel of REQUIRED_REFERENCES) {
    const abs = path.join(skillDir, rel);
    assert.ok(fs.existsSync(abs), `missing ${rel}`);
    assert.ok(fs.statSync(abs).size > 0, `empty ${rel}`);
    assert.ok(content.includes(rel), `SKILL.md does not name ${rel}`);
  }
});

test('does not require poteto-mode or setup-pstack', () => {
  const content = readSkill();
  assert.doesNotMatch(content, /poteto-mode/);
  assert.doesNotMatch(content, /setup-pstack/);
  assert.match(content, /references\/model-panel\.md/);
});

test('model panel documents defaults and the harness honesty rule', () => {
  const panel = fs.readFileSync(path.join(skillDir, 'references/model-panel.md'), 'utf8');
  assert.match(panel, /interrogate reviewers:/);
  assert.match(panel, /claude-opus-5-5-xhigh/);
  assert.match(panel, /grok-4\.7-xhigh-fast/);
  assert.match(panel, /Do not role-play the missing reviewers/);
  assert.match(panel, /Do not invent a second model's findings/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
