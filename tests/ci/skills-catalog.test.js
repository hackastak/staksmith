/**
 * Tests for scripts/ci/skills-catalog.js
 *
 * Guards the generated SKILLS.md against drift and enforces the frontmatter
 * contract: every skill declares a known category, and the committed catalog
 * matches what the generator produces from current frontmatter.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '../..');
const script = path.join(repoRoot, 'scripts/ci/skills-catalog.js');
const { render, readSkills, CATEGORY_ORDER } = require('../../scripts/ci/skills-catalog.js');

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

console.log('\nskills-catalog.js:');

test('every skill declares a category', () => {
  const missing = readSkills().filter(s => !s.category).map(s => s.name);
  assert.strictEqual(missing.length, 0, `missing category: ${missing.join(', ')}`);
});

test('every skill category is a known category', () => {
  const unknown = readSkills()
    .filter(s => !CATEGORY_ORDER.includes(s.category))
    .map(s => `${s.name} → ${s.category}`);
  assert.strictEqual(unknown.length, 0, `unknown categories: ${unknown.join('; ')}`);
});

test('render() throws if any skill lacks a category (contract)', () => {
  // render() must fail loudly rather than emit a half-built catalog.
  assert.doesNotThrow(() => render());
});

test('committed SKILLS.md is up to date with frontmatter', () => {
  const out = execFileSync('node', [script, '--check'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  assert.ok(out.includes('up to date'), out);
});

test('SKILLS.md has no empty description cells', () => {
  const md = fs.readFileSync(path.join(repoRoot, 'SKILLS.md'), 'utf8');
  const blankRows = md.split('\n').filter(l => /^\| /.test(l) && /\|\s+\|/.test(l) && !l.startsWith('| ---'));
  assert.strictEqual(blankRows.length, 0, `blank cells:\n${blankRows.join('\n')}`);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
