/**
 * Contract for the typescript-best-practices graft.
 * The skill is not a second TypeScript standards skill. Its on-edit trigger
 * and rules live in coding-standards. Its principle dependencies are folded
 * into that skill and the path-scoped TypeScript rules.
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

console.log('\ntypescript-best-practices port:');

test('does not add a competing typescript-best-practices skill', () => {
  assert.strictEqual(
    fs.existsSync(path.join(repoRoot, 'skills/typescript-best-practices')),
    false
  );
});

test('coding-standards auto-triggers on TypeScript edits and keeps description invocation', () => {
  const content = read('skills/coding-standards/SKILL.md');
  const fm = content.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(fm, 'missing frontmatter');
  assert.match(fm[1], /^name:\s*coding-standards\s*$/m);
  assert.match(fm[1], /Auto-apply the TypeScript discipline section when reading or editing any \.ts or \.tsx file/);
  assert.match(fm[1], /"\*\*\/\*\.ts"/);
  assert.match(fm[1], /"\*\*\/\*\.tsx"/);
  assert.doesNotMatch(fm[1], /^disable-model-invocation:\s*true\s*$/m);
});

test('folds the rule table and its principle dependencies into the skill', () => {
  const content = read('skills/coding-standards/SKILL.md');
  for (const rule of [
    'Discriminated unions',
    'Branded types',
    'Constructive modeling',
    'Simplest total type',
    'unknown` over `any',
    'Schemas before guards',
    'No `as` casts',
    'Narrowing hierarchy',
    'Type guards',
    'Exhaustiveness',
    'satisfies` over `as',
    'Boundary validation',
    'Schema-derived types',
    'Object args',
    'Real tests',
    'Structured telemetry',
  ]) {
    assert.ok(content.includes(rule), `missing rule: ${rule}`);
  }
  assert.match(content, /Type-system discipline/);
  assert.match(content, /Boundary discipline/);
  assert.match(content, /encode it there/);
  assert.match(content, /references\/typescript-patterns\.md/);
  assert.doesNotMatch(content, /poteto-mode|setup-pstack/);
});

test('ships the pattern reference the procedure points at', () => {
  const patterns = read('skills/coding-standards/references/typescript-patterns.md');
  assert.ok(patterns.length > 500);
  assert.match(patterns, /__brand: "AgentId"/);
  assert.match(patterns, /const _exhaustive: never = s/);
  assert.doesNotMatch(patterns, /principle skill/i);
  assert.doesNotMatch(patterns, /poteto-mode|setup-pstack/);
});

test('Codex subset matches the grafted skill', () => {
  const canonical = read('skills/coding-standards/SKILL.md');
  const codex = read('.agents/skills/coding-standards/SKILL.md');
  assert.strictEqual(codex, canonical);
  assert.strictEqual(
    read('.agents/skills/coding-standards/references/typescript-patterns.md'),
    read('skills/coding-standards/references/typescript-patterns.md')
  );
});

test('path-scoped rules carry the folded principles', () => {
  const tsStyle = read('rules/typescript/coding-style.md');
  assert.match(tsStyle, /\*\*\/\*\.ts/);
  assert.match(tsStyle, /\*\*\/\*\.tsx/);
  assert.match(tsStyle, /discriminated unions/i);
  assert.match(tsStyle, /coding-standards/);
  const common = read('rules/common/coding-style.md');
  assert.match(common, /Type System Discipline/);
  assert.match(common, /Do not re-validate data that a boundary already parsed/);
  const testing = read('rules/typescript/testing.md');
  assert.match(testing, /Do not mock what you can run/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
