/**
 * Tests for the inbox trio scripts
 * (skills/inbox-scan/scripts/scan.sh, skills/inbox-classify/scripts/classify.sh).
 *
 * Covers the inventory step (exclusions, metadata, JSON validity with awkward
 * filenames) and the placeholder classification heuristics (keyword and
 * wikilink routing), guarding the JSON-escaping class of bug these skills have
 * had fixed before.
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { stageSkill, writeFile, createRunner } = require('./lib/skill-test-utils');

const { test, done } = createRunner('Testing inbox scan + classify scripts');

test('scan.sh inventories inbox files, honoring exclude_folders', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'inbox-scan-'));
  const inbox = path.join(dir, 'inbox');
  writeFile(path.join(inbox, 'note-a.md'), '# A\n');
  writeFile(path.join(inbox, 'note with space.md'), '# spaced\n');
  writeFile(path.join(inbox, 'Graduates', 'old.md'), '# excluded\n');

  const skill = stageSkill('inbox-scan', {
    inbox_path: inbox,
    exclude_folders: ['Graduates'],
  });

  const res = skill.run('scan.sh');
  assert.strictEqual(res.status, 0, `exit 0 expected, stderr: ${res.stderr}`);

  const items = JSON.parse(res.stdout); // valid JSON even with a spaced filename
  const names = items.map(i => i.filename).sort();
  assert.deepStrictEqual(names, ['note with space.md', 'note-a.md']);
  assert.ok(!names.includes('old.md'), 'excluded folder omitted');

  const spaced = items.find(i => i.filename === 'note with space.md');
  assert.strictEqual(typeof spaced.mtime, 'number', 'mtime is numeric JSON');
  assert.strictEqual(typeof spaced.size_bytes, 'number', 'size is numeric JSON');
  assert.ok(spaced.path.endsWith('note with space.md'));
});

test('classify.sh routes by filename keyword', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'inbox-classify-'));
  const vault = path.join(dir, 'vault');
  fs.mkdirSync(path.join(vault, '1. Projects', 'RepoG'), { recursive: true });
  fs.mkdirSync(path.join(vault, '2. Areas'), { recursive: true });

  const notePath = path.join(dir, 'repog-notes.md');
  writeFile(notePath, '# RepoG notes\nsome content\n');

  const skill = stageSkill('inbox-classify', {
    vault_path: vault,
    confidence_threshold: 0.7,
    cache_path: path.join(dir, 'cache'),
  });

  const input = JSON.stringify([{ path: notePath, filename: 'repog-notes.md' }]);
  const res = skill.run('classify.sh', [], { input });
  assert.strictEqual(res.status, 0, `exit 0 expected, stderr: ${res.stderr}`);

  const results = JSON.parse(res.stdout);
  assert.strictEqual(results.length, 1);
  assert.strictEqual(results[0].category, 'Projects');
  assert.strictEqual(results[0].destination, '1. Projects/');
  assert.strictEqual(typeof results[0].confidence, 'number');
});

test('classify.sh routes by wikilink to a known project', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'inbox-classify-wl-'));
  const vault = path.join(dir, 'vault');
  fs.mkdirSync(path.join(vault, '1. Projects', 'RepoG'), { recursive: true });
  fs.mkdirSync(path.join(vault, '2. Areas'), { recursive: true });

  // Neutral filename (no keyword) but body links to a known project.
  const notePath = path.join(dir, 'meeting.md');
  writeFile(notePath, '# Meeting\nDiscussed [[RepoG]] roadmap.\n');

  const skill = stageSkill('inbox-classify', {
    vault_path: vault,
    confidence_threshold: 0.7,
    cache_path: path.join(dir, 'cache'),
  });

  const input = JSON.stringify([{ path: notePath, filename: 'meeting.md' }]);
  const res = skill.run('classify.sh', [], { input });
  assert.strictEqual(res.status, 0, `exit 0 expected, stderr: ${res.stderr}`);

  const results = JSON.parse(res.stdout);
  assert.strictEqual(results[0].category, 'Projects');
  assert.strictEqual(results[0].destination, '1. Projects/RepoG/');
  assert.ok(/RepoG/.test(results[0].reason), 'reason names the matched project');
});

done();
