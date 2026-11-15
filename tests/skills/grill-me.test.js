/**
 * Contract test for the grill-me skill (skills/grill-me/SKILL.md).
 *
 * grill-me is a markdown-only skill: there is no script to run, so the contract
 * is its SKILL.md. These tests pin the load-bearing promises that make grill-me
 * what it is, so an edit that quietly drops one fails here:
 *   - it starts from an existing plan and hands pre-plan work to brainstorming
 *   - one question at a time
 *   - each question carries a recommended answer
 *   - facts are the agent's to find, decisions are the user's to make
 *   - it does not act until the user confirms a shared understanding
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

console.log('\n=== Testing grill-me contract ===\n');

test('frontmatter identifies the skill and its category', () => {
  const content = read('skills/grill-me/SKILL.md');
  assert.match(content, /name: grill-me/);
  assert.match(content, /category: "Workflow & Meta"/);
  assert.match(content, /description:.*grill/i);
});

test('it starts from an existing plan and routes pre-plan work to brainstorming', () => {
  const content = read('skills/grill-me/SKILL.md');
  assert.match(content, /no plan yet, that is `brainstorming`/);
  assert.match(content, /starts once a plan or design exists/);
});

test('questions go one at a time, each carrying a recommended answer', () => {
  const content = read('skills/grill-me/SKILL.md');
  assert.match(content, /Ask the questions one at a time/);
  assert.match(content, /provide your recommended answer/);
});

test('facts are the agent’s to find, decisions are the user’s to make', () => {
  const content = read('skills/grill-me/SKILL.md');
  assert.match(content, /Facts are yours to find; decisions are mine to make/);
  assert.match(content, /Finding facts is your job, never mine/);
  assert.match(content, /dispatch a sub-agent/);
});

test('it does not act until the user confirms a shared understanding', () => {
  const content = read('skills/grill-me/SKILL.md');
  assert.match(content, /Do not act until I confirm we have reached a shared understanding/);
  assert.match(content, /only on my say-so, not yours/);
});

test('the command exists on both harnesses', () => {
  assert.match(read('commands/grill-me.md'), /grill/i);
  assert.match(read('.opencode/commands/grill-me.md'), /grill/i);
  const config = read('.opencode/opencode.json');
  assert.match(config, /"grill-me": \{[\s\S]*?"template": "\{file:commands\/grill-me\.md\}/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
