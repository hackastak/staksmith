/**
 * Contract for the blast-radius port. The skill proves a diff by running code.
 * Its dependencies (why, how, arena, unslop) ship with it, including the
 * reference files those procedures read, so none of them need poteto-mode
 * or setup-pstack.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '../..');

const SKILLS = {
  'blast-radius': {
    category: 'Code Review & Quality',
    refs: [],
  },
  why: {
    category: 'Docs & Lookup',
    refs: [
      'references/epistemics.md',
      'references/investigator-prompt.md',
      'references/source-playbook.md',
      'references/synthesizer-prompt.md',
      'references/model-panel.md',
      'references/sources/code-archaeology.md',
      'references/sources/linear.md',
      'references/sources/notion.md',
      'references/sources/slack.md',
      'references/sources/datadog.md',
      'references/sources/sentry.md',
      'references/sources/databricks.md',
      'references/sources/incident-postmortem.md',
    ],
  },
  how: {
    category: 'Docs & Lookup',
    refs: [
      'references/explainer-prompt.md',
      'references/explorer-prompt.md',
      'references/model-panel.md',
    ],
  },
  arena: {
    category: 'Workflow & Meta',
    refs: ['references/model-panel.md', 'references/graft-rules.md'],
  },
  unslop: {
    category: 'Writing & Content',
    refs: [],
  },
};

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

function readSkill(name) {
  const skillMd = path.join(repoRoot, 'skills', name, 'SKILL.md');
  assert.ok(fs.existsSync(skillMd), `skills/${name}/SKILL.md is missing`);
  return fs.readFileSync(skillMd, 'utf8');
}

console.log('\nblast-radius port:');

test('each ported skill declares name, category, origin, and user-invoked frontmatter', () => {
  for (const [name, spec] of Object.entries(SKILLS)) {
    const content = readSkill(name);
    const fm = content.match(/^---\n([\s\S]*?)\n---/);
    assert.ok(fm, `${name} missing frontmatter`);
    assert.match(fm[1], new RegExp(`^name:\\s*${name}\\s*$`, 'm'));
    assert.match(fm[1], new RegExp(`^category:\\s*"${spec.category}"\\s*$`, 'm'));
    assert.match(fm[1], /^origin:\s*community\s*$/m);
    assert.match(fm[1], /^disable-model-invocation:\s*true\s*$/m);
  }
});

test('ships every dependency reference and points the procedure at it', () => {
  for (const [name, spec] of Object.entries(SKILLS)) {
    const content = readSkill(name);
    for (const rel of spec.refs) {
      const abs = path.join(repoRoot, 'skills', name, rel);
      assert.ok(fs.existsSync(abs), `${name} missing ${rel}`);
      assert.ok(fs.statSync(abs).size > 0, `${name} empty ${rel}`);
      assert.ok(content.includes(rel), `${name} SKILL.md does not name ${rel}`);
    }
  }
});

test('does not require poteto-mode or setup-pstack', () => {
  for (const name of Object.keys(SKILLS)) {
    const content = readSkill(name);
    assert.doesNotMatch(content, /poteto-mode/, name);
    assert.doesNotMatch(content, /setup-pstack/, name);
  }
});

test('blast-radius proves by running code and calls its sibling skills', () => {
  const content = readSkill('blast-radius');
  assert.match(content, /running real code|runs the real code/);
  assert.match(content, /unproven/);
  assert.match(content, /skills\/why\/SKILL\.md/);
  assert.match(content, /skills\/arena\/SKILL\.md/);
  assert.match(content, /skills\/unslop\/SKILL\.md/);
  assert.match(content, /`how`/);
  assert.match(content, /Do not role-play the missing models/);
});

test('why keeps the code-anchor step blast-radius calls', () => {
  const content = readSkill('why');
  assert.match(content, /Step 2\. Establish the Code Anchor/);
  assert.match(content, /gh pr view/);
  assert.match(content, /references\/epistemics\.md/);
  const panel = fs.readFileSync(path.join(repoRoot, 'skills/why/references/model-panel.md'), 'utf8');
  assert.match(panel, /why investigators:/);
  assert.match(panel, /why synthesizer:/);
  assert.match(panel, /readonly: false/);
  assert.match(panel, /Do not role-play the missing investigators/);
});

test('arena inlines isolation, graft, and proof rules and refuses a fake panel', () => {
  const content = readSkill('arena');
  assert.doesNotMatch(content, /principle-/);
  const rules = fs.readFileSync(path.join(repoRoot, 'skills/arena/references/graft-rules.md'), 'utf8');
  assert.match(rules, /## Separate/);
  assert.match(rules, /## Laziness/);
  assert.match(rules, /## Redesign/);
  assert.match(rules, /## Prove/);
  const panel = fs.readFileSync(path.join(repoRoot, 'skills/arena/references/model-panel.md'), 'utf8');
  assert.match(panel, /arena runners:/);
  assert.match(panel, /arena cross-judge pool:/);
  assert.match(panel, /Do not invent a second model's artifact/);
});

test('unslop keeps the stable rule ids other skills cite', () => {
  const content = readSkill('unslop');
  for (const id of ['3.', '7.', '13.', '26.', '27.', '33.']) {
    assert.ok(content.includes(id), `missing rule ${id}`);
  }
  assert.match(content, /Rule numbers are stable ids/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
