/**
 * Contract for the create-verification-skill port: a user-invoked generator
 * that writes a project-local verify-* skill. It does not depend on
 * poteto-mode, setup-pstack, or the unported maintain-verification-skill,
 * and it does not replace e2e-testing or verification-loop.
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

console.log('\ncreate-verification-skill:');

test('declares name, category, and user-invoked frontmatter', () => {
  const content = read('skills/create-verification-skill/SKILL.md');
  const fm = content.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(fm, 'missing frontmatter');
  assert.match(fm[1], /^name:\s*create-verification-skill\s*$/m);
  assert.match(fm[1], /^category:\s*"Testing & TDD"\s*$/m);
  assert.match(fm[1], /^origin:\s*community\s*$/m);
  assert.match(fm[1], /^disable-model-invocation:\s*true\s*$/m);
  assert.match(fm[1], /project-local skill/);
});

test('keeps the interview, generate, map, and prove loop', () => {
  const content = read('skills/create-verification-skill/SKILL.md');
  const interview = content.search(/Interview the repo, not the user/);
  const generate = content.search(/Generate the skill/);
  const map = content.search(/Seed the feature map/);
  const prove = content.search(/Prove the generated skill before handing it over/);
  assert.ok(interview >= 0 && generate > interview, 'generate must follow the interview');
  assert.ok(map > generate, 'the feature map must follow generation');
  assert.ok(prove > map, 'proof must follow the feature map');
  for (const section of ['Launch', 'Doctor', 'Drive', 'Evidence', 'Cleanup', 'Helpers']) {
    assert.match(content, new RegExp(`\\*\\*${section}:\\*\\*`));
  }
  assert.match(content, /Sub-features/);
  assert.match(content, /How to get to it \(user POV\)/);
  assert.match(content, /Gotchas/);
  assert.match(content, /references\/feature-map-example\//);
});

test('ships the worked feature-map example', () => {
  const readme = read('skills/create-verification-skill/references/feature-map-example/README.md');
  const create = read('skills/create-verification-skill/references/feature-map-example/create-note.md');
  const search = read('skills/create-verification-skill/references/feature-map-example/search.md');
  assert.match(readme, /## Features/);
  assert.match(create, /## Driving it with control-notes/);
  assert.match(search, /## Gotchas/);
});

test('routes around the other verification skills and drops pstack deps', () => {
  const content = read('skills/create-verification-skill/SKILL.md');
  assert.match(content, /not `e2e-testing`/);
  assert.match(content, /not `verification-loop`/);
  assert.match(content, /not `\/verify`/);
  assert.match(content, /maintain-verification-skill` is not shipped/);
  assert.match(content, /\.claude\/skills\//);
  assert.doesNotMatch(content, /poteto-mode/);
  assert.doesNotMatch(content, /setup-pstack/);
  assert.doesNotMatch(content, /Offer the maintenance loop/);
});

test('is invocable from Claude Code and OpenCode', () => {
  const claude = read('commands/create-verification-skill.md');
  const opencode = read('.opencode/commands/create-verification-skill.md');
  const config = JSON.parse(read('.opencode/opencode.json'));
  assert.match(claude, /skills\/create-verification-skill\/SKILL\.md/);
  assert.match(opencode, /skills\/create-verification-skill\/SKILL\.md/);
  assert.ok(
    config.command && config.command['create-verification-skill'],
    'missing command.create-verification-skill'
  );
  assert.match(
    config.command['create-verification-skill'].template,
    /commands\/create-verification-skill\.md/
  );
});

test('catalog and router name the skill', () => {
  assert.match(read('SKILLS.md'), /`create-verification-skill`/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /\/create-verification-skill/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
