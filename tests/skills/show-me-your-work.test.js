/**
 * Contract for the show-me-your-work port: a reviewable TSV decision trail
 * for long or unattended runs. It ships as its own skill. It does not depend
 * on poteto-mode or setup-pstack, and it is not /checkpoint.
 */

const assert = require('assert');
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const repoRoot = path.resolve(__dirname, '../..');
const logScript = path.join(repoRoot, 'skills', 'show-me-your-work', 'scripts', 'log.sh');

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

console.log('\nshow-me-your-work skill:');

test('declares name, category, and user-invoked frontmatter', () => {
  const content = read('skills/show-me-your-work/SKILL.md');
  const fm = content.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(fm, 'missing frontmatter');
  assert.match(fm[1], /^name:\s*show-me-your-work\s*$/m);
  assert.match(fm[1], /^category:\s*"Workflow & Meta"\s*$/m);
  assert.match(fm[1], /^origin:\s*community\s*$/m);
  assert.match(fm[1], /^disable-model-invocation:\s*true\s*$/m);
  assert.match(fm[1], /reviewable TSV decision trail/);
  assert.match(fm[1], /\/show-me-your-work/);
});

test('keeps one append-only TSV and distinguishes checkpoint', () => {
  const content = read('skills/show-me-your-work/SKILL.md');
  assert.match(content, /ts\s+phase\s+decision\s+why\s+evidence\s+result/);
  assert.match(content, /Append-only/);
  assert.match(content, /phase `start`/);
  assert.match(content, /decisions\.tsv/);
  assert.match(content, /\.audit\/<task-slug>\.tsv/);
  assert.match(content, /not `\/checkpoint`/);
  assert.match(content, /git snapshot/);
  assert.match(content, /references\/decision-log-template\.tsv/);
  const template = read('skills/show-me-your-work/references/decision-log-template.tsv');
  assert.strictEqual(template.trim(), 'ts\tphase\tdecision\twhy\tevidence\tresult');
});

test('inlines dependencies and does not require pstack', () => {
  const content = read('skills/show-me-your-work/SKILL.md');
  assert.match(content, /skills\/unslop\/SKILL\.md/);
  assert.match(content, /references\/model-panel\.md/);
  assert.match(content, /scripts\/log\.sh/);
  assert.match(content, /Do not look for `principle-encode-lessons-in-structure`/);
  assert.doesNotMatch(content, /poteto-mode/);
  assert.doesNotMatch(content, /setup-pstack/);
  const panel = read('skills/show-me-your-work/references/model-panel.md');
  assert.match(panel, /STAKSMITH_SHOW_ME_YOUR_WORK_REVIEWER/);
  assert.match(panel, /do not role-play/i);
  assert.doesNotMatch(panel, /poteto-mode/);
});

test('audits only this run and does not search other chats', () => {
  const content = read('skills/show-me-your-work/SKILL.md');
  assert.match(content, /~\/\.cursor\/projects\/\*/);
  assert.match(content, /unrelated private chats/);
  assert.match(content, /supersede/);
  assert.match(content, /never edits or removes a row/i);
  assert.match(content, /Attention/);
  assert.match(content, /reviewed by <model>/);
  assert.match(content, /this harness cannot spawn/);
});

test('is invocable from Claude Code and OpenCode', () => {
  const claude = read('commands/show-me-your-work.md');
  const opencode = read('.opencode/commands/show-me-your-work.md');
  const config = JSON.parse(read('.opencode/opencode.json'));
  assert.match(claude, /skills\/show-me-your-work\/SKILL\.md/);
  assert.match(opencode, /skills\/show-me-your-work\/SKILL\.md/);
  assert.ok(config.command && config.command['show-me-your-work'], 'missing command.show-me-your-work');
  assert.match(config.command['show-me-your-work'].template, /commands\/show-me-your-work\.md/);
});

test('catalog and router name the skill', () => {
  assert.match(read('SKILLS.md'), /`show-me-your-work`/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /\/show-me-your-work/);
  assert.match(read('skills/ask-hackastak/SKILL.md'), /not `\/checkpoint`/);
});

test('log.sh writes a safe append-only row', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'smyw-'));
  const logfile = path.join(dir, 'nested', 'decisions.tsv');
  const run = (args) => execFileSync('bash', [logScript, logfile, ...args], { encoding: 'utf8' });

  assert.throws(() => execFileSync('bash', [logScript], { encoding: 'utf8' }), /usage/);

  run(['frame', 'counted the work first', 'wanted the size', 'commit 3a9f1c2', 'found 5 things']);
  run(['widget', '=HYPERLINK("http://evil")', 'why', '+cmd', '@sheet']);

  const rows = fs.readFileSync(logfile, 'utf8').trim().split('\n');
  assert.strictEqual(rows.length, 3, `expected header plus two rows, got ${rows.length}`);
  assert.strictEqual(rows[0], 'ts\tphase\tdecision\twhy\tevidence\tresult');
  assert.match(rows[1], /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\tframe\t/);
  assert.match(rows[2], /\t'=HYPERLINK/);
  assert.match(rows[2], /\t'\+cmd\t/);
  assert.match(rows[2], /\t'@sheet$/);

  const seeded = path.join(dir, 'seeded.tsv');
  fs.writeFileSync(seeded, 'old\trow\tkeep\tthis\tevidence\topen\n');
  execFileSync('bash', [logScript, seeded, 'start', 'picked up the log', 'another run wrote since', 'agent this-run', 'open']);
  const seededText = fs.readFileSync(seeded, 'utf8');
  assert.match(seededText, /^old\trow\tkeep/);
  assert.doesNotMatch(seededText, /ts\tphase\tdecision/);

  const dirty = path.join(dir, 'dirty.tsv');
  execFileSync('bash', [logScript, dirty, 'phase', 'line1\nline2\tmore', 'why', 'evidence', '-reverted']);
  const dirtyRow = fs.readFileSync(dirty, 'utf8').trim().split('\n')[1];
  assert.strictEqual(dirtyRow.split('\t').length, 6);
  assert.match(dirtyRow, /line1 line2 more/);
  assert.match(dirtyRow, /\t'-reverted$/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
