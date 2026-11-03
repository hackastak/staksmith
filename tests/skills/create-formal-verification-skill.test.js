/**
 * Contract for the create-formal-verification-skill port: a user-invoked
 * generator that writes a project-local formal-* skill. It does not depend
 * on poteto-mode or setup-pstack, and it does not replace
 * create-verification-skill, e2e-testing, or verification-loop.
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

console.log('\ncreate-formal-verification-skill:');

test('declares name, category, and user-invoked frontmatter', () => {
  const content = read('skills/create-formal-verification-skill/SKILL.md');
  const fm = content.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(fm, 'missing frontmatter');
  assert.match(fm[1], /^name:\s*create-formal-verification-skill\s*$/m);
  assert.match(fm[1], /^category:\s*"Testing & TDD"\s*$/m);
  assert.match(fm[1], /^origin:\s*community\s*$/m);
  assert.match(fm[1], /^disable-model-invocation:\s*true\s*$/m);
  assert.match(fm[1], /project-local skill/);
  assert.match(fm[1], /model-check this race/);
});

test('keeps target, tool, quality bar, generate, and prove in order', () => {
  const content = read('skills/create-formal-verification-skill/SKILL.md');
  const target = content.search(/Choose the target from the code/);
  const tool = content.search(/Let the question choose the tool/);
  const quality = content.search(/What makes it good/);
  const root = content.search(/Choose one write root/);
  const generate = content.search(/Generate the verify skill/);
  const prove = content.search(/Prove it before you hand off/);
  const handoff = content.search(/^## Hand off/m);
  assert.ok(target >= 0 && tool > target, 'tool choice must follow the target');
  assert.ok(quality > tool, 'the quality bar must follow tool choice');
  assert.ok(root > quality && generate > root, 'generation must follow the write root');
  assert.ok(prove > generate, 'proof must follow generation');
  assert.ok(handoff > prove, 'handoff must follow the proof');
  for (const mark of [
    'True to the code',
    'Able to fail',
    'Findings stay findings',
    'Honest about scope',
    'Readable without the tool',
    'Cheap to rerun',
    'Kept in step with the code',
  ]) {
    assert.match(content, new RegExp(`\\*\\*${mark}\\.\\*\\*`));
  }
  assert.match(content, /TLA\+ is the default/);
  assert.match(content, /formal-<area>/);
  assert.match(content, /Do not weaken the property/);
});

test('routes around the other verification skills and drops pstack deps', () => {
  const content = read('skills/create-formal-verification-skill/SKILL.md');
  assert.match(content, /not `create-verification-skill`/);
  assert.match(content, /not `e2e-testing`/);
  assert.match(content, /not `verification-loop`/);
  assert.match(content, /not `\/verify`/);
  assert.match(content, /no separate maintain command/);
  assert.match(content, /\.claude\/skills\//);
  assert.match(content, /\.cursor\/skills\//);
  assert.match(content, /\.agents\/skills\//);
  assert.match(content, /Do not invent `\.pi\/skills\/`/);
  assert.doesNotMatch(content, /poteto-mode/);
  assert.doesNotMatch(content, /setup-pstack/);
});

test('is invocable from Claude Code and OpenCode', () => {
  const claude = read('commands/create-formal-verification-skill.md');
  const opencode = read('.opencode/commands/create-formal-verification-skill.md');
  const config = JSON.parse(read('.opencode/opencode.json'));
  assert.match(claude, /skills\/create-formal-verification-skill\/SKILL\.md/);
  assert.match(opencode, /skills\/create-formal-verification-skill\/SKILL\.md/);
  assert.ok(
    config.command && config.command['create-formal-verification-skill'],
    'missing command.create-formal-verification-skill'
  );
  assert.match(
    config.command['create-formal-verification-skill'].template,
    /commands\/create-formal-verification-skill\.md/
  );
});

test('catalog and router name the skill', () => {
  assert.match(read('SKILLS.md'), /`create-formal-verification-skill`/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /\/create-formal-verification-skill/);
  assert.match(read('SKILLS.md'), /Testing & TDD \(14\)/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
