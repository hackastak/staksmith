/**
 * Contract for the Tier B benchmark-checklist port.
 * The checklist stands as a skill. principle-explain-the-number is a rule,
 * not a competing skill. Neither depends on poteto-mode or setup-pstack.
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

console.log('\nbenchmark-checklist:');

test('declares name, category, and user-invoked frontmatter', () => {
  const content = read('skills/benchmark-checklist/SKILL.md');
  const fm = content.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(fm, 'missing frontmatter');
  assert.match(fm[1], /^name:\s*benchmark-checklist\s*$/m);
  assert.match(fm[1], /^category:\s*"Code Review & Quality"\s*$/m);
  assert.match(fm[1], /^origin:\s*community\s*$/m);
  assert.match(fm[1], /^disable-model-invocation:\s*true\s*$/m);
  assert.match(fm[1], /benchmark/);
  assert.match(fm[1], /speedup|regression/);
});

test('keeps the claim, the seven questions, and the report in order', () => {
  const content = read('skills/benchmark-checklist/SKILL.md');
  const claim = content.search(/Write down the claim/);
  const questions = [
    'Why not double?',
    'Was it tuned?',
    'Did it break limits?',
    'Did it error?',
    'Does it reproduce?',
    'Does it matter?',
    'Did it even happen?',
  ].map(mark => content.search(mark));
  const report = content.search(/^## Report/m);
  assert.ok(claim >= 0, 'the claim must be written before the run');
  let previous = claim;
  for (const at of questions) {
    assert.ok(at > previous, 'questions must stay in checklist order');
    previous = at;
  }
  assert.ok(report > previous, 'the report must follow the questions');
  assert.match(content, /median and range/);
  assert.match(content, /alternating/);
  assert.match(content, /at least 5 times/);
  assert.match(content, /inconclusive/);
});

test('keeps the ballpark exception and refuses a choice from one run', () => {
  const content = read('skills/benchmark-checklist/SKILL.md');
  assert.match(content, /one run is enough/);
  assert.match(content, /questions 4 and 7/);
  assert.match(content, /never a ballpark/);
  assert.match(content, /Do not pick a winner/);
});

test('drops pstack setup and unported playbooks', () => {
  const content = read('skills/benchmark-checklist/SKILL.md');
  assert.doesNotMatch(content, /poteto-mode/);
  assert.doesNotMatch(content, /setup-pstack/);
  assert.doesNotMatch(content, /Perf issue/);
  assert.doesNotMatch(content, /Hillclimb/);
  assert.match(content, /not `perf-review`/);
  assert.match(content, /not `diagnosing-bugs`/);
  assert.match(content, /sysctl -n hw\.ncpu/);
  assert.match(content, /nproc/);
  assert.match(content, /EXPLAIN QUERY PLAN/);
  assert.match(content, /bundle size/);
});

test('does not add a competing principle-explain-the-number skill', () => {
  assert.strictEqual(
    fs.existsSync(path.join(repoRoot, 'skills/principle-explain-the-number')),
    false
  );
  assert.strictEqual(
    fs.existsSync(path.join(repoRoot, 'commands/principle-explain-the-number.md')),
    false
  );
});

test('folds explain-the-number into the performance rule', () => {
  const content = read('rules/common/performance.md');
  assert.match(content, /## Explain the Number/);
  assert.match(content, /principle-explain-the-number/);
  assert.match(content, /not a skill/);
  assert.match(content, /why not double/i);
  assert.match(content, /run count/);
  assert.match(content, /spread/);
  assert.match(content, /named limiter/);
  assert.match(content, /Prove It Works/);
  assert.match(content, /benchmark-checklist/);
  assert.match(content, /eval result/);
  assert.doesNotMatch(content, /poteto-mode|setup-pstack/);
  const workflow = read('rules/common/development-workflow.md');
  assert.match(workflow, /performance\.md#explain-the-number/);
});

test('points perf review at the checklist and the rule', () => {
  const review = read('skills/perf-review/SKILL.md');
  assert.match(review, /benchmark-checklist/);
  assert.match(review, /Explain the Number/);
  const agent = read('agents/performance-reviewer.md');
  assert.match(agent, /benchmark-checklist/);
  assert.match(agent, /rules\/common\/performance\.md/);
});

test('is invocable from Claude Code and OpenCode', () => {
  const claude = read('commands/benchmark-checklist.md');
  const opencode = read('.opencode/commands/benchmark-checklist.md');
  const config = JSON.parse(read('.opencode/opencode.json'));
  assert.match(claude, /skills\/benchmark-checklist\/SKILL\.md/);
  assert.match(opencode, /skills\/benchmark-checklist\/SKILL\.md/);
  assert.ok(config.command && config.command['benchmark-checklist'], 'missing command.benchmark-checklist');
  assert.match(config.command['benchmark-checklist'].template, /commands\/benchmark-checklist\.md/);
});

test('catalog and router name the skill, not the principle', () => {
  assert.match(read('SKILLS.md'), /`benchmark-checklist`/);
  assert.match(read('SKILLS.md'), /Code Review & Quality \(15\)/);
  assert.doesNotMatch(read('SKILLS.md'), /principle-explain-the-number/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /\/benchmark-checklist/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /not `\/perf-review`/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
