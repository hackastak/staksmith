/**
 * Contract for the Tier B sharpen / in-your-own-words graft.
 * Intent alignment lives on brainstorming, not as competing skills.
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

function section(content, start, end) {
  const from = content.search(start);
  assert.ok(from >= 0, `missing ${start}`);
  const to = end ? content.search(end) : content.length;
  assert.ok(to > from, `${start} must precede ${end}`);
  return content.slice(from, to);
}

console.log('\nintent-alignment port:');

test('does not add sharpen or in-your-own-words as skills or commands', () => {
  for (const name of ['sharpen', 'in-your-own-words']) {
    assert.strictEqual(fs.existsSync(path.join(repoRoot, 'skills', name)), false, name);
    assert.strictEqual(fs.existsSync(path.join(repoRoot, 'commands', `${name}.md`)), false, name);
    assert.strictEqual(
      fs.existsSync(path.join(repoRoot, '.opencode/commands', `${name}.md`)),
      false,
      name
    );
  }
});

test('brainstorming restates the goal before it classifies or designs', () => {
  const content = read('skills/brainstorming/SKILL.md');
  const align = section(content, /## Align on intent/, /## Three Paths/);
  const playback = section(align, /### In your own words/, /### Sharpen/);
  assert.match(content, /not skills/);
  assert.match(content, /Do not look for `sharpen` or `in-your-own-words`/);
  assert.match(playback, /before classification/i);
  assert.match(playback, /goals/);
  assert.match(playback, /problem they are trying to solve/);
  assert.match(playback, /Do not open with a question/);
  assert.match(playback, /Do not share your theory/);
  assert.match(playback, /misread costs one message/);
  assert.match(playback, /stop after the restatement/i);
  assert.match(playback, /Do not narrate/);
  assert.doesNotMatch(content, /poteto-mode|setup-pstack/);
});

test('sharpen aims the design and does not skip the approval gate', () => {
  const content = read('skills/brainstorming/SKILL.md');
  const align = section(content, /## Align on intent/, /## Three Paths/);
  const sharpen = section(align, /### Sharpen/, null);
  assert.match(sharpen, /top expert/);
  assert.match(sharpen, /raw sources/);
  assert.match(sharpen, /real methods/);
  assert.match(sharpen, /outside check/);
  assert.match(sharpen, /really after/);
  assert.match(sharpen, /over- or underspecified/);
  assert.match(sharpen, /Loosen a constraint that does not serve the goal/);
  assert.match(sharpen, /Leave choices that are the user's to make open/);
  assert.match(sharpen, /better, not bigger/);
  assert.match(sharpen, /Do not narrate/);
  assert.match(sharpen, /does not approve implementation/);
  assert.match(content, /<HARD-GATE>/);
  assert.match(content, /Aiming the task is not approval to implement/);
  const gate = content.search(/<HARD-GATE>/);
  const alignAt = content.search(/## Align on intent/);
  const paths = content.search(/## Three Paths/);
  assert.ok(gate < alignAt && alignAt < paths, 'gate, then align, then classify');
});

test('checklists and red flags keep the playback ahead of the design', () => {
  const content = read('skills/brainstorming/SKILL.md');
  const flags = section(content, /## Red Flags/, /## Checklists/);
  assert.match(flags, /skip the playback/);
  assert.match(flags, /named the method, so that is the goal/);
  assert.match(flags, /pick the open choice/);
  assert.match(flags, /Sharpen means start building/);
  assert.match(flags, /expert's whole method/);
  for (const heading of ['**Spike:**', '**Bounded:**', '**Architectural:**']) {
    const start = content.indexOf(heading);
    assert.ok(start >= 0, heading);
    const block = content.slice(start, start + 700);
    assert.match(block, /Restate goals and the problem/);
    assert.match(block, /Sharpen before/);
  }
});

test('commands and the router point at brainstorming, not new skills', () => {
  for (const rel of ['commands/brainstorming.md', '.opencode/commands/brainstorming.md']) {
    const content = read(rel);
    assert.match(content, /skills\/brainstorming\/SKILL\.md/);
    assert.match(content, /not new skills/);
    assert.match(content, /Do not look for `sharpen` or `in-your-own-words`/);
    assert.doesNotMatch(content, /poteto-mode|setup-pstack/);
    assert.doesNotMatch(content, /`\/sharpen`|`\/in-your-own-words`/);
  }
  const router = read('skills/ask-hackastak/SKILL.md');
  assert.match(router, /\/brainstorming` aligns intent/);
  assert.match(router, /not `sharpen` or `in-your-own-words`/);
  assert.match(read('skills/grill-me/SKILL.md'), /no plan yet, that is `brainstorming`/);
  assert.match(read('rules/common/development-workflow.md'), /Align on the goal before the plan/);
  assert.doesNotMatch(read('rules/common/development-workflow.md'), /poteto-mode|setup-pstack/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
