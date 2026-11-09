/**
 * Contract for the architect procedure port.
 * The skill runs Ground through Scrap. The agent only reviews.
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

console.log('\narchitect procedure:');

test('skill is the procedure and does not need another plugin', () => {
  const content = read('skills/architect/SKILL.md');
  assert.match(content, /name: architect/);
  assert.match(content, /disable-model-invocation: true/);
  assert.match(content, /do not need another plugin/i);
  assert.doesNotMatch(content, /poteto-mode|setup-pstack/);
  for (const phase of ['## Phase A: Ground', '## Phase B: Sketch', '## Phase C: Agree', '## Phase D: Implement against the sketch', '## Phase E: Scrap']) {
    assert.match(content, new RegExp(phase.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
  }
});

test('sketch writes usage first and requires two distinct candidates', () => {
  const content = read('skills/architect/SKILL.md');
  const sketch = content.slice(content.indexOf('## Phase B: Sketch'), content.indexOf('## Phase C: Agree'));
  assert.match(sketch, /usage first/i);
  assert.match(sketch, /two structurally distinct/);
  assert.match(sketch, /interface depth/);
  assert.match(sketch, /not implemented/);
  assert.match(sketch, /arena/);
  assert.match(sketch, /Do not role-play a second model/);
  assert.match(sketch, /same-model/);
});

test('agree defaults to proceed and scrap has the tells', () => {
  const content = read('skills/architect/SKILL.md');
  const agree = content.slice(content.indexOf('## Phase C: Agree'), content.indexOf('## Phase D'));
  assert.match(agree, /Default: proceed/);
  assert.match(agree, /checkpoint/);
  assert.match(agree, /interrogate/);
  assert.match(agree, /does not create that commit/);
  const scrap = content.slice(content.indexOf('## Phase E: Scrap'));
  assert.match(scrap, /we need a lock/);
  assert.match(scrap, /escape hatches/);
  assert.match(scrap, /blast-radius/);
  assert.match(scrap, /Subtract before adding/);
  assert.match(scrap, /Return to Phase B/);
});

test('agent reviews and does not implement', () => {
  const agent = read('agents/architect.md');
  assert.match(agent, /Read-only architecture review/);
  assert.match(agent, /tools: \["Read", "Grep", "Glob"\]/);
  assert.match(agent, /model: opus/);
  assert.match(agent, /do not design/i);
  assert.match(agent, /Do not run Ground, Sketch, Agree, Implement, or Scrap/);
  assert.doesNotMatch(agent, /You are a senior software architect/);
  const prompt = read('.opencode/prompts/agents/architect.txt');
  assert.match(prompt, /do not design a new system/i);
  assert.doesNotMatch(prompt, /You are a senior software architect/);
});

test('knowledge survived as references the procedure pulls in', () => {
  const knowledge = read('skills/architect/references/knowledge.md');
  assert.match(knowledge, /Big ball of mud/);
  assert.match(knowledge, /Repository/);
  assert.match(knowledge, /ADR illustration/);
  assert.match(knowledge, /adr-standard/);
  const flags = read('skills/architect/references/design-red-flags.md');
  assert.match(flags, /Shallow module/);
  assert.match(flags, /Hand-synced list/);
  const rationale = read('skills/architect/references/rationale-template.md');
  assert.match(rationale, /## Usage \(caller's view\)/);
  assert.match(rationale, /## Synthesis decision/);
  const panel = read('skills/architect/references/model-panel.md');
  assert.match(panel, /architect runners:/);
  assert.doesNotMatch(panel, /poteto-mode|setup-pstack/);
});

test('audit-codebase still fans out the agent, not the implement loop', () => {
  const content = read('skills/audit-codebase/SKILL.md');
  assert.match(content, /`architect` agent/);
  assert.match(content, /not the `\/architect` design skill/);
});

test('slash commands exist on both harnesses', () => {
  for (const rel of ['commands/architect.md', '.opencode/commands/architect.md']) {
    const content = read(rel);
    assert.match(content, /architect/);
  }
  const config = read('.opencode/opencode.json');
  assert.match(config, /"architect": \{[\s\S]*?"template": "\{file:commands\/architect\.md\}/);
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
