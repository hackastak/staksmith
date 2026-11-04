/**
 * Contract for the Tier B ketchup / recall graft: in-chat catch-up and
 * cross-session reconstruction live on /resume-session, not as new skills.
 * /handoff stays the save-only document.
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

console.log('\nsession-catchup:');

test('does not add ketchup or recall as skills', () => {
  assert.strictEqual(fs.existsSync(path.join(repoRoot, 'skills/ketchup')), false);
  assert.strictEqual(fs.existsSync(path.join(repoRoot, 'skills/recall')), false);
  assert.strictEqual(fs.existsSync(path.join(repoRoot, 'commands/ketchup.md')), false);
  assert.strictEqual(fs.existsSync(path.join(repoRoot, 'commands/recall.md')), false);
});

test('resume-session routes catch-up before loading a file', () => {
  const content = read('commands/resume-session.md');
  const route = content.search(/## Route first/);
  const saved = content.search(/### Step 1: Find the session file/);
  const inChat = content.search(/## In-chat catch-up/);
  const across = content.search(/## Cross-session reconstruction/);
  assert.ok(route >= 0 && route < saved, 'route before the saved-file steps');
  assert.ok(inChat > saved && across > inChat, 'both catch-up contracts follow the saved-file steps');
  assert.match(content, /not new skills/);
  assert.match(content, /Do not look for `ketchup` or `recall`/);
  assert.match(content, /no saved session file was found/);
  const step1 = content.slice(content.search(/### Step 1: Find the session file/), content.search(/### Step 2: Read the entire session file/));
  assert.doesNotMatch(step1, /Then stop/);
});

test('in-chat catch-up is read-only and decidable from the reply', () => {
  const content = read('commands/resume-session.md');
  const section = content.slice(content.search(/## In-chat catch-up/), content.search(/## Cross-session reconstruction/));
  assert.match(section, /read-only/);
  assert.match(section, /reply alone must be enough to decide/);
  assert.match(section, /Never invent a call/);
  assert.match(section, /Never mark something done that still waits on the user/);
  assert.match(section, /never draw or generate a picture of a screen you did not capture/i);
  assert.match(section, /Do not start the work/);
});

test('cross-session reconstruction verifies live state and cites sources', () => {
  const content = read('commands/resume-session.md');
  const section = content.slice(content.search(/## Cross-session reconstruction/));
  assert.match(section, /~\/\.claude\/projects\/<slug>/);
  assert.match(section, /~\/\.pi\/agent\/sessions\/<slug>/);
  assert.match(section, /skills\/why\/SKILL\.md/);
  assert.match(section, /skills\/unslop\/SKILL\.md/);
  assert.match(section, /\[merged #N\]/);
  assert.match(section, /\[reverted #N\]/);
  assert.match(section, /Live state wins over the transcript/);
  assert.match(section, /single-agent/);
  assert.match(section, /Do not start work until the user says to continue/);
  assert.doesNotMatch(content, /poteto-mode/);
  assert.doesNotMatch(content, /setup-pstack/);
});

test('handoff routes catch-up away and stays save-only', () => {
  const skill = read('skills/handoff/SKILL.md');
  assert.match(skill, /Catch-up is not a handoff/);
  assert.match(skill, /commands\/resume-session\.md/);
  assert.match(skill, /do not write a document/i);
  assert.match(skill, /Never launch/);
  assert.match(read('commands/handoff.md'), /\/resume-session, not a handoff/);
  assert.match(read('.opencode/commands/handoff.md'), /\/resume-session, not a handoff/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /\/resume-session` catches the user up/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
