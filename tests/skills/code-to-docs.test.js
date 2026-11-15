/**
 * Tests for the code-to-docs-sync skill scripts
 * (skills/code-to-docs-sync/scripts/{detect-drift,analyze-drift,sync-docs}.sh).
 *
 * The three phases run in sequence: detect-drift writes drift-report.json,
 * analyze-drift turns it into drift-analysis.json with proposed fixes, and
 * sync-docs applies the auto-fixable ones. The tests exercise the real scripts
 * end to end and guard the bug classes this skill has a history with:
 *
 *   - set -e increment abort: `((count++))` returns status 1 when the counter
 *     is 0, which under `set -euo pipefail` killed the script on the first repo
 *     (detect-drift) or item (sync-docs) before it emitted its report. The
 *     scripts now use `count=$((count + 1))`; these tests fail if that regresses.
 *   - JSON escaping: analyze-drift embeds raw doc content via `jq -Rs .`, so a
 *     README with quotes, backslashes, `$VARS`, and backticks must still produce
 *     valid, round-trippable JSON.
 *   - no-code-file guard: detect-drift initializes latest_code_mtime=0 so a stale
 *     doc in a repo with no source files does not crash under `set -u`.
 *   - CI exit-code contract: detect-drift exits 1 when drift is found, 0 when clean.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { stageSkill, initRepo, writeFile, makeTempDir, createRunner } = require('./lib/skill-test-utils');

const { test, done } = createRunner('Testing code-to-docs-sync scripts');

/** Stage the skill with a fixture repos root + cache dir and return the harness. */
function stage(overrides = {}) {
  const fixture = makeTempDir('c2d-fixture-');
  const reposRoot = path.join(fixture, 'repos');
  const cacheDir = path.join(fixture, 'cache');
  fs.mkdirSync(reposRoot, { recursive: true });

  const skill = stageSkill('code-to-docs-sync', {
    repos_root: [reposRoot],
    watch_files: ['README.md', 'CLAUDE.md'],
    ignore_repos: [],
    auto_commit: false,
    staleness_threshold_days: 30,
    cache_path: cacheDir,
    ...overrides,
  });
  skill.reposRoot = reposRoot;
  skill.cacheDir = cacheDir;
  return skill;
}

/** Create a git repo with a package.json (and optional README/CLAUDE) on disk. */
function repoWith(skill, name, { pkg, readme, claude } = {}) {
  initRepo(skill.reposRoot, name, [{ message: 'init', file: '.keep', content: 'x' }]);
  const repo = path.join(skill.reposRoot, name);
  if (pkg) writeFile(path.join(repo, 'package.json'), JSON.stringify(pkg));
  if (readme !== undefined) writeFile(path.join(repo, 'README.md'), readme);
  if (claude !== undefined) writeFile(path.join(repo, 'CLAUDE.md'), claude);
  return repo;
}

test('detect-drift runs to completion on the first repo and flags a README tech-stack mismatch (exit 1)', () => {
  const skill = stage();
  repoWith(skill, 'alpha', {
    pkg: { dependencies: { fastify: '^4' } },
    readme: '# Alpha\n\nBuilt with Express.js for routing.\n',
  });

  const res = skill.run('detect-drift.sh');
  // The set -e increment bug made this exit 1 with EMPTY stdout. Now it must
  // exit 1 *with a valid report* (1 = drift found, the CI gate semantic).
  assert.strictEqual(res.status, 1, `drift present -> exit 1; stderr: ${res.stderr}`);

  const report = JSON.parse(res.stdout);
  assert.strictEqual(report.drift_detected, 1, 'exactly one drift item');
  const item = report.drift_items[0];
  assert.strictEqual(item.file, 'README.md');
  assert.strictEqual(item.drift_type, 'outdated');
  assert.strictEqual(item.auto_fixable, true);
  assert.match(item.details, /Express.*Fastify/);
  assert.ok(fs.existsSync(path.join(skill.cacheDir, 'drift-report.json')), 'report cached');
});

test('detect-drift reports no drift and exits 0 when docs match the code', () => {
  const skill = stage();
  repoWith(skill, 'beta', {
    pkg: { dependencies: { fastify: '^4' } },
    readme: '# Beta\n\nBuilt with Fastify.\n', // no Express mention -> no mismatch
  });

  const res = skill.run('detect-drift.sh');
  assert.strictEqual(res.status, 0, `clean repo -> exit 0; stderr: ${res.stderr}`);
  assert.strictEqual(JSON.parse(res.stdout).drift_detected, 0);
});

test('detect-drift honors ignore_repos', () => {
  const skill = stage({ ignore_repos: ['alpha'] });
  repoWith(skill, 'alpha', {
    pkg: { dependencies: { fastify: '^4' } },
    readme: '# Alpha\n\nBuilt with Express.js.\n', // would drift if not ignored
  });

  const res = skill.run('detect-drift.sh');
  assert.strictEqual(res.status, 0, 'ignored repo contributes no drift');
  assert.strictEqual(JSON.parse(res.stdout).drift_detected, 0);
});

test('detect-drift flags an npm script missing from CLAUDE.md', () => {
  const skill = stage();
  repoWith(skill, 'delta', {
    pkg: { scripts: { build: 'tsc' } },
    claude: '# Delta\n\nNo build docs here.\n', // lacks "npm run build"
  });

  const res = skill.run('detect-drift.sh');
  assert.strictEqual(res.status, 1);
  const item = JSON.parse(res.stdout).drift_items.find(d => d.file === 'CLAUDE.md');
  assert.ok(item, 'CLAUDE.md drift present');
  assert.strictEqual(item.drift_type, 'missing');
  assert.match(item.details, /npm run build/);
});

test('detect-drift survives a stale doc in a repo with no source files (no-code-file guard)', () => {
  const skill = stage();
  // README only, no .ts/.js/.go/.py -> latest_code_mtime stays 0.
  initRepo(skill.reposRoot, 'epsilon', [{ message: 'init', file: 'README.md', content: 'old' }]);
  const readme = path.join(skill.reposRoot, 'epsilon', 'README.md');
  const old = new Date(Date.now() - 60 * 86400000); // 60 days old -> past the 30-day threshold
  fs.utimesSync(readme, old, old);

  const res = skill.run('detect-drift.sh');
  assert.strictEqual(res.status, 0, `must not crash under set -u; stderr: ${res.stderr}`);
  assert.strictEqual(JSON.parse(res.stdout).drift_detected, 0);
});

test('analyze-drift escapes tricky doc content into valid JSON and proposes a swap', () => {
  const skill = stage();
  const tricky = [
    '# Gamma',
    '',
    'Uses "Express.js" with \\backslashes\\, $VARS, and `backticks`.',
    '',
  ].join('\n');
  repoWith(skill, 'gamma', { pkg: { dependencies: { fastify: '^4' } }, readme: tricky });

  skill.run('detect-drift.sh'); // writes drift-report.json (exit 1 is expected)
  const res = skill.run('analyze-drift.sh');
  assert.strictEqual(res.status, 0, `analyze exit 0; stderr: ${res.stderr}`);

  const analysis = JSON.parse(res.stdout); // throws if escaping is broken
  assert.strictEqual(analysis.length, 1);
  const current = analysis[0].current_content;
  assert.ok(current.includes('"Express.js"'), 'quotes round-trip');
  assert.ok(current.includes('\\backslashes\\'), 'backslashes round-trip');
  assert.ok(current.includes('$VARS'), 'dollar-vars are literal');
  assert.ok(current.includes('`backticks`'), 'backticks are literal');

  const proposed = analysis[0].proposed_content;
  assert.ok(proposed.includes('Fastify'), 'fix swaps in Fastify');
  assert.ok(!proposed.includes('Express'), 'fix removes Express');
  assert.ok(fs.existsSync(path.join(skill.cacheDir, 'drift-analysis.json')), 'analysis cached');
});

test('sync-docs applies an auto-fixable fix in place and counts it without committing', () => {
  const skill = stage(); // auto_commit false
  const repo = repoWith(skill, 'zeta', {
    pkg: { dependencies: { fastify: '^4' } },
    readme: '# Zeta\n\nBuilt with Express for serving.\n',
  });
  const readme = path.join(repo, 'README.md');

  skill.run('detect-drift.sh');
  skill.run('analyze-drift.sh');
  const res = skill.run('sync-docs.sh');
  assert.strictEqual(res.status, 0, `sync exit 0; stderr: ${res.stderr}`);

  const summary = JSON.parse(res.stdout);
  assert.strictEqual(summary.applied, 1, 'one fix applied (guards the sync-docs counter)');
  assert.strictEqual(summary.auto_committed, false);

  const after = fs.readFileSync(readme, 'utf8');
  assert.ok(after.includes('Fastify'), 'file rewritten to the Fastify version');
  assert.ok(!after.includes('Express'), 'Express removed from the file');
});

done();
