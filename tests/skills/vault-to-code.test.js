/**
 * Tests for the vault-to-code-bridge skill scripts
 * (skills/vault-to-code-bridge/scripts/{scan-vault-projects,generate-docs}.sh).
 *
 * scan-vault-projects maps each vault project folder to a code repo by name
 * similarity and writes project-mappings.json; generate-docs reads that mapping
 * and scaffolds CLAUDE.md, ARCHITECTURE.md, and append-only ADR files. The tests
 * run the real scripts and guard this skill's bug classes:
 *
 *   - set -e increment abort: `((common++))` inside the similarity loop and
 *     `((generated++))` in the project loop returned status 1 when the counter
 *     was 0, aborting the script under `set -euo pipefail`. Fixed to
 *     `count=$((count + 1))`; the no-match and generate paths exercise both.
 *   - JSON key safety: mapping keys are project names built with `jq --arg`, so a
 *     name containing quotes must still produce valid, correctly-keyed JSON (a
 *     regression this skill has had fixed before).
 *   - ADR base-10 guard: the next ADR number is `$((10#$highest + 1))`, so a
 *     seeded 0009 advances to 0010 instead of hitting bash's "value too great for
 *     base" octal error.
 *   - ADR immutability + dry-run safety: existing ADRs are never rewritten, and
 *     dry_run writes nothing to disk.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { stageSkill, initRepo, writeFile, makeTempDir, createRunner } = require('./lib/skill-test-utils');

const { test, done } = createRunner('Testing vault-to-code-bridge scripts');

/** Stage the skill with a fixture vault + repos root + cache and return the harness. */
function stage(overrides = {}) {
  const fixture = makeTempDir('v2c-fixture-');
  const vault = path.join(fixture, 'vault');
  const reposRoot = path.join(fixture, 'repos');
  const cacheDir = path.join(fixture, 'cache');
  fs.mkdirSync(vault, { recursive: true });
  fs.mkdirSync(reposRoot, { recursive: true });

  const skill = stageSkill('vault-to-code-bridge', {
    vault_path: vault,
    repos_root: [reposRoot],
    auto_match_threshold: 0.8,
    cache_path: cacheDir,
    manual_mappings: {},
    dry_run: false,
    templates_path: './templates/',
    ...overrides
  });
  skill.vault = vault;
  skill.reposRoot = reposRoot;
  skill.cacheDir = cacheDir;
  return skill;
}

/** Write a project-mappings.json straight into the cache so generate-docs can read it. */
function writeMapping(skill, projectName, vaultPath, repoPath) {
  writeFile(
    path.join(skill.cacheDir, 'project-mappings.json'),
    JSON.stringify({
      [projectName]: {
        vault_path: vaultPath,
        repo_path: repoPath,
        confidence: 1.0,
        match_method: 'manual',
        has_backlog: false,
        has_architecture: true
      }
    })
  );
}

test('scan-vault-projects maps a project to its same-named repo and records vault files', () => {
  const skill = stage();
  writeFile(path.join(skill.vault, 'Alpha', 'Backlog.md'), '- [ ] task\n');
  initRepo(skill.reposRoot, 'Alpha', [{ message: 'init' }]);

  const res = skill.run('scan-vault-projects.sh');
  assert.strictEqual(res.status, 0, `exit 0; stderr: ${res.stderr}`);

  const map = JSON.parse(res.stdout);
  assert.ok(map.Alpha, 'Alpha mapped');
  assert.strictEqual(map.Alpha.confidence, 1, 'exact name -> confidence 1.0');
  assert.strictEqual(map.Alpha.match_method, 'fuzzy_name');
  assert.strictEqual(map.Alpha.has_backlog, true);
  assert.strictEqual(map.Alpha.has_architecture, false);
  assert.ok(map.Alpha.repo_path.endsWith(`${path.sep}Alpha`));

  const cached = JSON.parse(fs.readFileSync(path.join(skill.cacheDir, 'project-mappings.json'), 'utf8'));
  assert.deepStrictEqual(cached, map, 'cache matches stdout');
});

test('scan-vault-projects excludes a project with no repo above the threshold (exercises the fixed similarity loop)', () => {
  const skill = stage();
  fs.mkdirSync(path.join(skill.vault, 'Zephyr'), { recursive: true });
  initRepo(skill.reposRoot, 'Alpha', [{ message: 'init' }]); // only a dissimilar repo exists

  const res = skill.run('scan-vault-projects.sh');
  // Zephyr vs Alpha drives the char-by-char `((common++))` path that used to abort.
  assert.strictEqual(res.status, 0, `exit 0; stderr: ${res.stderr}`);
  const map = JSON.parse(res.stdout);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(map, 'Zephyr'), false, 'below-threshold project dropped');
});

test('scan-vault-projects produces valid JSON keyed verbatim for a multi-word project name', () => {
  // Real vault projects are multi-word (e.g. "SAP Business Network"). The key is
  // built with `jq --arg key`, so the name must round-trip verbatim into valid JSON.
  const skill = stage();
  const name = "Tom's Data Pipeline"; // space + apostrophe: realistic, portable
  fs.mkdirSync(path.join(skill.vault, name), { recursive: true });
  initRepo(skill.reposRoot, name, [{ message: 'init' }]);

  const res = skill.run('scan-vault-projects.sh');
  assert.strictEqual(res.status, 0, `exit 0; stderr: ${res.stderr}`);

  const map = JSON.parse(res.stdout); // throws if the key is not JSON-safe
  assert.ok(Object.prototype.hasOwnProperty.call(map, name), 'key preserved verbatim');
  assert.ok(map[name].repo_path.endsWith(`${path.sep}${name}`));
});

test('generate-docs scaffolds ADRs past 0009 (base-10 guard), fills the house sections, and is immutable on re-run', () => {
  const skill = stage();
  const vaultProj = path.join(skill.vault, 'Alpha');
  const repo = path.join(skill.reposRoot, 'Alpha');
  const adrDir = path.join(repo, 'docs', 'adr');
  fs.mkdirSync(adrDir, { recursive: true });

  writeFile(
    path.join(vaultProj, 'Architecture.md'),
    ['## System Overview', 'Overview text.', '', '## ADR: Use Postgres', 'We chose Postgres.', '', '## ADR: Event Sourcing', 'Because.', ''].join('\n')
  );
  writeFile(path.join(adrDir, '0009-legacy.md'), '# ADR-0009: Legacy\n'); // forces next = 0010
  writeMapping(skill, 'Alpha', vaultProj, repo);

  const res = skill.run('generate-docs.sh', ['--project', 'Alpha']);
  assert.strictEqual(res.status, 0, `exit 0; stderr: ${res.stderr}`);

  const postgresFile = path.join(adrDir, '0010-use-postgres.md');
  assert.ok(fs.existsSync(postgresFile), 'next number is 0010, not an octal error');
  assert.ok(fs.existsSync(path.join(adrDir, '0011-event-sourcing.md')), 'second ADR numbered 0011');

  const postgres = fs.readFileSync(postgresFile, 'utf8');
  assert.ok(postgres.includes('# ADR-0010: Use Postgres'), 'title carries the assigned number');
  assert.ok(postgres.includes('**Status:** Proposed'));
  assert.ok(postgres.includes('## Considered Options'));
  assert.ok(postgres.includes('## Decision'));
  assert.ok(postgres.includes('We chose Postgres.'), 'vault body carried into the ADR');

  assert.strictEqual(fs.readFileSync(path.join(adrDir, '0009-legacy.md'), 'utf8'), '# ADR-0009: Legacy\n', 'seed untouched');

  const before = fs.readdirSync(adrDir).sort();
  const res2 = skill.run('generate-docs.sh', ['--project', 'Alpha']);
  assert.strictEqual(res2.status, 0);
  assert.deepStrictEqual(fs.readdirSync(adrDir).sort(), before, 'no duplicate ADRs on re-run (immutability)');
});

test('generate-docs writes nothing when dry_run is true', () => {
  const skill = stage({ dry_run: true });
  const vaultProj = path.join(skill.vault, 'Alpha');
  const repo = path.join(skill.reposRoot, 'Alpha');
  fs.mkdirSync(repo, { recursive: true });
  writeFile(path.join(vaultProj, 'Architecture.md'), '## ADR: Use Redis\nCache layer.\n');
  writeMapping(skill, 'Alpha', vaultProj, repo);

  const res = skill.run('generate-docs.sh', ['--project', 'Alpha']);
  assert.strictEqual(res.status, 0, `exit 0; stderr: ${res.stderr}`);

  assert.ok(!fs.existsSync(path.join(repo, 'CLAUDE.md')), 'no CLAUDE.md in dry run');
  assert.ok(!fs.existsSync(path.join(repo, 'ARCHITECTURE.md')), 'no ARCHITECTURE.md in dry run');
  assert.ok(!fs.existsSync(path.join(repo, 'docs', 'adr')), 'no ADRs scaffolded in dry run');
  assert.strictEqual(JSON.parse(res.stdout).dry_run, true, 'summary still emitted');
});

done();
