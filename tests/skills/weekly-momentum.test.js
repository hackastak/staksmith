/**
 * Tests for the weekly-momentum-report skill scripts
 * (skills/weekly-momentum-report/scripts/{discover-repos,scan-repos}.sh).
 *
 * Covers note-driven repo discovery, the note -> git-window scan, and two
 * historical regressions this skill has already had fixed:
 *   - git author casing: commits authored "hackastak" must count under an
 *     author_names entry of "Hackastak" (case-insensitive match).
 *   - week-format normalization: "2026-W37", "W37", and "37" must resolve to
 *     the same ISO week window.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { stageSkill, initRepo, writeFile, createRunner } = require('./lib/skill-test-utils');

const { test, done } = createRunner('Testing weekly-momentum-report scripts');

const WEEK = '2026-W37'; // Mon 2026-09-07 .. Sun 2026-09-13
const IN_WEEK = '2026-09-10T12:00:00';

/** Stage the skill with a fixture vault + repos and return the harness. */
function setup() {
  const dir = fs.mkdtempSync(path.join(require('os').tmpdir(), 'wm-fixture-'));
  const reposRoot = path.join(dir, 'repos');
  const vault = path.join(dir, 'vault');

  // Commit author is lowercase; config author is capitalized -> casing regression.
  initRepo(reposRoot, 'test-repo-alpha', [{ message: 'feat: parser', author: 'hackastak <h@example.com>', date: IN_WEEK }]);
  initRepo(reposRoot, 'staksmith', [{ message: 'chore: tidy', author: 'Hackastak <h@example.com>', date: IN_WEEK }]);

  writeFile(
    path.join(vault, '_Weekly', '2026', `${WEEK}.md`),
    [
      '## Daily Journal',
      '',
      '### Monday',
      '- [[test-repo-alpha]]: shipped the parser',
      '- Staksmith: wrote tests',
      '- Blog: published an article', // ignore_labels -> dropped
      '- [[ghost-repo]]: mentioned but no local checkout',
      ''
    ].join('\n')
  );

  const cacheDir = path.join(dir, 'cache');
  const skill = stageSkill('weekly-momentum-report', {
    search_roots: [reposRoot],
    vault_path: vault,
    author_names: ['Hackastak'],
    days_back: 3650,
    output_format: 'markdown',
    exclude_repos: [],
    ignore_labels: ['Blog'],
    repo_aliases: {},
    cache_path: cacheDir
  });
  skill.cacheDir = cacheDir;
  return skill;
}

test('discover-repos resolves note mentions to local repos and flags remotes', () => {
  const skill = setup();
  const res = skill.run('discover-repos.sh', ['--week', WEEK]);
  assert.strictEqual(res.status, 0, `exit 0 expected, stderr: ${res.stderr}`);

  const discovered = JSON.parse(res.stdout);
  const byToken = Object.fromEntries(discovered.map(d => [d.token.toLowerCase(), d]));

  assert.ok(byToken['test-repo-alpha']?.resolved, 'wikilink repo resolves locally');
  assert.strictEqual(byToken['test-repo-alpha'].repo_name, 'test-repo-alpha');
  assert.ok(byToken['staksmith']?.resolved, 'label "Staksmith:" resolves to repo staksmith');

  assert.ok(byToken['ghost-repo'], 'unresolved mention is retained');
  assert.strictEqual(byToken['ghost-repo'].resolved, false);
  assert.strictEqual(byToken['ghost-repo'].path, null);

  assert.ok(!('blog' in byToken), 'ignore_labels drops "Blog"');
});

test('discover-repos caches identical JSON to discovered-repos.json', () => {
  const skill = setup();
  const res = skill.run('discover-repos.sh', ['--week', WEEK]);
  const cached = fs.readFileSync(path.join(skill.cacheDir, 'discovered-repos.json'), 'utf8');
  assert.deepStrictEqual(JSON.parse(cached), JSON.parse(res.stdout));
});

test('scan-repos --from-notes counts commits despite author-name casing', () => {
  const skill = setup();
  const res = skill.run('scan-repos.sh', ['--week', WEEK, '--from-notes']);
  assert.strictEqual(res.status, 0, `exit 0 expected, stderr: ${res.stderr}`);

  const active = JSON.parse(res.stdout);
  const byName = Object.fromEntries(active.map(r => [r.name, r]));

  // The regression: author "hackastak" must be found by author_names ["Hackastak"].
  assert.ok(byName['test-repo-alpha'], 'lowercase-authored repo is active');
  assert.ok(byName['test-repo-alpha'].commit_count >= 1, 'commit counted across casing');
  assert.ok(byName['staksmith'], 'label-discovered repo is scanned too');
});

test('scan-repos --from-notes records mentioned-but-remote repos without inventing commits', () => {
  const skill = setup();
  skill.run('scan-repos.sh', ['--week', WEEK, '--from-notes']);
  const remote = JSON.parse(fs.readFileSync(path.join(skill.cacheDir, 'mentioned-remote.json'), 'utf8'));
  assert.deepStrictEqual(remote, [{ name: 'ghost-repo' }]);
});

test('scan-repos normalizes 2026-W37, W37, and 37 to the same 7-day window', () => {
  const skill = setup();
  const parse = arg => {
    const res = skill.run('scan-repos.sh', ['--week', arg]);
    assert.strictEqual(res.status, 0, `exit 0 for --week ${arg}, stderr: ${res.stderr}`);
    const m = res.stderr.match(/Week (\S+): (\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})/);
    assert.ok(m, `week window line present for --week ${arg}`);
    return { label: m[1], since: m[2], until: m[3] };
  };

  const full = parse('2026-W37');
  const short = parse('W37');
  const bare = parse('37');

  assert.deepStrictEqual(short, full, '"W37" matches "2026-W37"');
  assert.deepStrictEqual(bare, full, '"37" matches "2026-W37"');
  assert.strictEqual(full.label, WEEK);

  const days = (Date.parse(full.until) - Date.parse(full.since)) / 86400000;
  assert.strictEqual(days, 6, 'window spans Monday..Sunday (6 days apart)');
});

done();
