/**
 * Tests for the skill-auto-extractor scripts
 * (skills/skill-auto-extractor/scripts/{scan-history,detect-patterns}.sh).
 *
 * Guards the historical JSON-escaping fix: commit messages containing quotes
 * and backslashes must round-trip through the cached JSON intact and valid.
 * Also covers the two-phase contract (detect-patterns depends on scan-history's
 * cache) and pattern detection off real commit messages.
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { stageSkill, initRepo, createRunner } = require('./lib/skill-test-utils');

const { test, done } = createRunner('Testing skill-auto-extractor scripts');

const NASTY_MESSAGE = 'feat: add "auth" login \\ session handling';

function setup() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'sae-fixture-'));
  const reposRoot = path.join(dir, 'repos');

  initRepo(reposRoot, 'app-with-auth', [
    {
      message: NASTY_MESSAGE,
      author: 'hackastak <h@example.com>',
      file: 'src/auth.ts',
      content: 'export const login = () => {}',
    },
  ]);

  const cacheDir = path.join(dir, 'cache');
  const skill = stageSkill('skill-auto-extractor', {
    repos_root: [reposRoot],
    days_back: 3650,
    min_frequency: 1,
    confidence_threshold: 0.8,
    exclude_repos: [],
    author_name: 'hackastak',
    cache_path: cacheDir,
  });
  skill.cacheDir = cacheDir;
  return skill;
}

test('scan-history escapes quotes/backslashes into valid, lossless JSON', () => {
  const skill = setup();
  const res = skill.run('scan-history.sh');
  assert.strictEqual(res.status, 0, `exit 0 expected, stderr: ${res.stderr}`);

  // stdout summary must be parseable JSON (regression: broken escaping produced
  // invalid JSON here).
  const summary = JSON.parse(res.stdout);
  assert.ok(summary.commits_analyzed >= 1, 'at least one commit analyzed');

  const commits = JSON.parse(fs.readFileSync(path.join(skill.cacheDir, 'commits.json'), 'utf8'));
  assert.ok(Array.isArray(commits) && commits.length >= 1, 'commits cached');

  const nasty = commits.find(c => c.message === NASTY_MESSAGE);
  assert.ok(nasty, 'commit message with quotes + backslash round-trips exactly');
  assert.ok(Array.isArray(nasty.files) && nasty.files.includes('src/auth.ts'), 'files captured');
});

test('detect-patterns reads the scan cache and detects the auth pattern', () => {
  const skill = setup();
  const scan = skill.run('scan-history.sh');
  assert.strictEqual(scan.status, 0, `scan exit 0, stderr: ${scan.stderr}`);

  const res = skill.run('detect-patterns.sh');
  assert.strictEqual(res.status, 0, `exit 0 expected, stderr: ${res.stderr}`);

  const report = JSON.parse(res.stdout);
  const ids = report.patterns.map(p => p.pattern_id);
  assert.ok(ids.includes('api-authentication'), `auth pattern detected, got: ${ids.join(', ')}`);
  assert.strictEqual(report.patterns_detected, report.patterns.length, 'count matches array');
});

test('detect-patterns fails clearly when run before scan-history', () => {
  const skill = setup(); // fresh cache, no scan run
  const res = skill.run('detect-patterns.sh');
  assert.notStrictEqual(res.status, 0, 'non-zero exit without scan cache');
  assert.ok(/Run scan-history\.sh first/.test(res.stderr), 'points user at the missing prerequisite');
});

done();
