/**
 * Contract for the correct port: a user-invoked procedure that hardens a
 * repeated agent mistake at the highest level that works. It ships as its own
 * skill. It does not depend on poteto-mode or setup-pstack.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '../..');
const skillMd = path.join(repoRoot, 'skills', 'correct', 'SKILL.md');

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

console.log('\ncorrect skill:');

test('declares name, category, and user-invoked frontmatter', () => {
  const content = read('skills/correct/SKILL.md');
  const fm = content.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(fm, 'missing frontmatter');
  assert.match(fm[1], /^name:\s*correct\s*$/m);
  assert.match(fm[1], /^category:\s*"Code Review & Quality"\s*$/m);
  assert.match(fm[1], /^origin:\s*community\s*$/m);
  assert.match(fm[1], /^disable-model-invocation:\s*true\s*$/m);
  assert.match(fm[1], /make each one impossible/);
});

test('orders the enforcement ladder and requires proof on a past mistake', () => {
  const content = read('skills/correct/SKILL.md');
  const architecture = content.search(/Eliminate it with architecture/);
  const types = content.search(/Enforce it with types/);
  const lint = content.search(/error names the file, type, or function to use instead/);
  const behavior = content.search(/Test the behavior/);
  const docs = content.search(/docs or agent rules last/);
  assert.ok(architecture >= 0 && types > architecture, 'types must follow architecture');
  assert.ok(lint > types, 'lint must follow types');
  assert.ok(behavior > lint, 'tests must follow lint');
  assert.ok(docs > behavior, 'docs must be last');
  assert.match(content, /happened twice/);
  assert.match(content, /Prove each new check fails on a real past mistake/);
  assert.match(content, /one commit each/);
  assert.match(content, /expiry date/);
});

test('keeps a rule table and is not the pattern-extraction skills', () => {
  const content = read('skills/correct/SKILL.md');
  assert.match(content, /agent instruction file/);
  assert.match(content, /what enforces it/);
  assert.match(content, /not `learn`/);
  assert.match(content, /not `evolve`/);
  assert.doesNotMatch(content, /poteto-mode/);
  assert.doesNotMatch(content, /setup-pstack/);
});

test('is invocable from Claude Code and OpenCode', () => {
  const claude = read('commands/correct.md');
  const opencode = read('.opencode/commands/correct.md');
  const config = JSON.parse(read('.opencode/opencode.json'));
  assert.match(claude, /skills\/correct\/SKILL\.md/);
  assert.match(opencode, /skills\/correct\/SKILL\.md/);
  assert.ok(config.command && config.command.correct, 'missing command.correct');
  assert.match(config.command.correct.template, /commands\/correct\.md/);
});

test('catalog and router name the skill', () => {
  assert.match(read('SKILLS.md'), /`correct`/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /\/correct/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
