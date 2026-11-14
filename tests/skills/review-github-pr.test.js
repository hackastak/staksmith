/**
 * Contract test for the review-github-pr skill (skills/review-github-pr/SKILL.md).
 *
 * This is a markdown-only skill, so its SKILL.md is the contract. These tests pin
 * the invariants that make the review safe and useful, so a careless edit that
 * drops one is caught:
 *   - read-only: never checks out, modifies, pushes, or posts to GitHub
 *   - reviews across the six named dimensions with the Critical/Major/Minor/Nit ladder
 *   - the three-state attribution gate (introduced / improved-but-incomplete / pre-existing)
 *   - no fabricated citations, and the patch-line vs file-line distinction
 *   - output is one inline report (not posted, not saved), findings as h4 not bullets
 *   - the twelve-smell baseline and the three-tier review family
 * Plus the command surface on both harnesses.
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

const SKILL = 'skills/review-github-pr/SKILL.md';

console.log('\n=== Testing review-github-pr contract ===\n');

test('frontmatter identifies the skill, category, and read-only intent', () => {
  const content = read(SKILL);
  assert.match(content, /name: review-github-pr/);
  assert.match(content, /category: "Code Review & Quality"/);
  assert.match(content, /read-only/i);
});

test('it requires a PR number and stays read-only', () => {
  const content = read(SKILL);
  assert.match(content, /Require a PR number/);
  assert.match(content, /read-only inspection/i);
  assert.match(content, /never `git checkout`/);
  assert.match(content, /never modify files, never push, never post to GitHub/);
});

test('guardrails forbid every mutating git and gh write', () => {
  const guardrails = read(SKILL);
  const section = guardrails.slice(guardrails.indexOf('## Guardrails'));
  for (const cmd of ['git checkout', 'git switch', 'git reset', 'gh pr review', 'gh pr comment', 'gh pr merge']) {
    assert.ok(section.includes(cmd), `guardrails must forbid ${cmd}`);
  }
});

test('it reviews across the six named dimensions', () => {
  const content = read(SKILL);
  assert.match(content, /six dimensions/);
  const section = content.slice(content.indexOf('## 4.'), content.indexOf('## 5.'));
  for (const dim of ['Correctness', 'Security', 'Style', 'Test coverage', 'Architecture', 'Performance']) {
    assert.ok(section.includes(dim), `missing dimension: ${dim}`);
  }
  assert.match(content, /Critical \/ Major \/ Minor \/ Nit/);
});

test('the three-state attribution gate is intact', () => {
  const content = read(SKILL);
  const section = content.slice(content.indexOf('## 5.'), content.indexOf('## 6.'));
  assert.match(section, /\bintroduced\b/);
  assert.match(section, /improved-but-incomplete/);
  assert.match(section, /pre-existing/);
  assert.match(section, /Attribution work is a gate, not report content/);
});

test('citations may not be fabricated and keep the patch-vs-file-line distinction', () => {
  const content = read(SKILL);
  assert.match(content, /invent (file )?paths or line numbers/i);
  assert.match(content, /patch line number/);
  assert.match(content, /file line number/);
});

test('output is one inline report, not posted or saved, findings as h4 not bullets', () => {
  const content = read(SKILL);
  const section = content.slice(content.indexOf('## 6. Output'));
  assert.match(section, /single inline markdown report/);
  assert.match(section, /\*\*Do not\*\* post comments to GitHub/);
  assert.match(section, /\*\*Do not\*\* save the report to a file/);
  assert.match(section, /a bullet list item/);
  assert.match(section, /h4 headers/);
});

test('the twelve-smell baseline is carried', () => {
  const content = read(SKILL);
  assert.match(content, /smell baseline/i);
  assert.match(content, /twelve code smells/);
  for (const smell of ['Feature Envy', 'Primitive Obsession', 'Shotgun Surgery', 'Speculative Generality']) {
    assert.ok(content.includes(smell), `missing smell: ${smell}`);
  }
});

test('it names its place in the three-tier review family', () => {
  const content = read(SKILL);
  const section = content.slice(content.indexOf('## Related skills'));
  for (const sib of ['review-changes', 'code-review', 'security-review']) {
    assert.ok(section.includes(sib), `missing sibling: ${sib}`);
  }
});

test('the command exists on both harnesses', () => {
  assert.match(read('commands/review-github-pr.md'), /review/i);
  assert.match(read('.opencode/commands/review-github-pr.md'), /review/i);
  const config = read('.opencode/opencode.json');
  assert.match(config, /"review-github-pr": \{[\s\S]*?"template": "\{file:commands\/review-github-pr\.md\}/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
