/**
 * Contract for the technical-writing port: a user-invoked standard for docs,
 * RFCs, READMEs, PR descriptions, and commit messages. It ships as its own
 * skill. It does not depend on poteto-mode or setup-pstack, and it does not
 * replace the blog-voice skills or the unslop catalog.
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

console.log('\ntechnical-writing skill:');

test('declares name, category, and user-invoked frontmatter', () => {
  const content = read('skills/technical-writing/SKILL.md');
  const fm = content.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(fm, 'missing frontmatter');
  assert.match(fm[1], /^name:\s*technical-writing\s*$/m);
  assert.match(fm[1], /^category:\s*"Writing & Content"\s*$/m);
  assert.match(fm[1], /^origin:\s*community\s*$/m);
  assert.match(fm[1], /^disable-model-invocation:\s*true\s*$/m);
  assert.match(fm[1], /Diátaxis structure/);
});

test('keeps the four layers and the compass', () => {
  const content = read('skills/technical-writing/SKILL.md');
  const body = content.replace(/^---\n[\s\S]*?\n---\n/, '');
  const diataxis = body.search(/Pick the mode first \(Diátaxis\)/);
  const google = body.search(/Write sentences to the reader \(Google developer style\)/);
  const ste = body.search(/Make statements load one at a time \(STE rules\)/);
  const globalEnglish = body.search(/Leave no sentence open to two readings \(Global English\)/);
  assert.ok(diataxis >= 0 && google > diataxis, 'Google style must follow Diátaxis');
  assert.ok(ste > google, 'STE must follow Google style');
  assert.ok(globalEnglish > ste, 'Global English must follow STE');
  assert.match(content, /Action and learning: \*\*tutorial\*\*/);
  assert.match(content, /Action and work: \*\*how-to\*\*/);
  assert.match(content, /Understanding and work: \*\*reference\*\*/);
  assert.match(content, /Understanding and learning: \*\*explanation\*\*/);
  assert.match(content, /Don't mix modes/);
  assert.match(content, /budget\.mjs --write/);
});

test('routes around the blog skills and does not edit unslop', () => {
  const content = read('skills/technical-writing/SKILL.md');
  assert.match(content, /not `article-writing`/);
  assert.match(content, /not `unslop`/);
  assert.match(content, /Do not edit that skill/);
  assert.match(content, /Apply the \*\*unslop\*\* skill/);
  assert.match(content, /PR descriptions and commit messages/);
  assert.doesNotMatch(content, /poteto-mode/);
  assert.doesNotMatch(content, /setup-pstack/);
});

test('is invocable from Claude Code and OpenCode', () => {
  const claude = read('commands/technical-writing.md');
  const opencode = read('.opencode/commands/technical-writing.md');
  const config = JSON.parse(read('.opencode/opencode.json'));
  assert.match(claude, /skills\/technical-writing\/SKILL\.md/);
  assert.match(opencode, /skills\/technical-writing\/SKILL\.md/);
  assert.ok(config.command && config.command['technical-writing'], 'missing command.technical-writing');
  assert.match(config.command['technical-writing'].template, /commands\/technical-writing\.md/);
});

test('catalog and router name the skill', () => {
  assert.match(read('SKILLS.md'), /`technical-writing`/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /\/technical-writing/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
