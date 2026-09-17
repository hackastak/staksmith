/**
 * Shared harness for testing the custom second-brain skill shell scripts.
 *
 * The skills' scripts resolve their config as "$SCRIPT_DIR/../config.json" and
 * read real vault / repo / cache paths from it. To exercise the *real* scripts
 * hermetically, stageSkill() copies a skill's `scripts/` dir into a throwaway
 * temp dir and writes a fixture `config.json` one level up, so the same relative
 * lookup lands on our fixture instead of the user's live config. Nothing under
 * `skills/` is modified, and every path in the fixture config points inside the
 * temp dir, so runs never touch the real vault or ~/.claude cache.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync, execFileSync } = require('child_process');

const REPO_ROOT = path.resolve(__dirname, '..', '..', '..');
const tempDirs = [];

/** Create a self-cleaning temp dir (removed by cleanupAll / on the runner's done()). */
function makeTempDir(prefix = 'staksmith-skill-') {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
  tempDirs.push(dir);
  return dir;
}

function cleanupAll() {
  for (const dir of tempDirs.splice(0)) {
    try {
      fs.rmSync(dir, { recursive: true, force: true });
    } catch {
      /* best-effort cleanup */
    }
  }
}

/**
 * Copy a skill's scripts into a temp dir and write a fixture config beside them.
 * Returns { dir, scriptsDir, configPath, run } where run() invokes one of the
 * copied scripts with bash and captures status/stdout/stderr.
 */
function stageSkill(skillName, config) {
  const src = path.join(REPO_ROOT, 'skills', skillName, 'scripts');
  if (!fs.existsSync(src)) {
    throw new Error(`No scripts dir for skill "${skillName}" at ${src}`);
  }

  const dir = makeTempDir(`staksmith-${skillName}-`);
  const scriptsDir = path.join(dir, 'scripts');
  fs.cpSync(src, scriptsDir, { recursive: true });

  const configPath = path.join(dir, 'config.json');
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

  function run(scriptName, args = [], opts = {}) {
    const result = spawnSync('bash', [path.join(scriptsDir, scriptName), ...args], {
      cwd: dir,
      encoding: 'utf8',
      input: opts.input,
      timeout: opts.timeout || 30000,
      env: { ...process.env, ...(opts.env || {}) },
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return {
      status: result.status,
      stdout: result.stdout || '',
      stderr: result.stderr || '',
      error: result.error,
    };
  }

  return { dir, scriptsDir, configPath, run };
}

/**
 * Initialize a git repo under `root/name` with the given commits.
 * Each commit: { message, author?, date?, file?, content? }.
 * Identity is set locally (no dependency on the runner's global git config).
 */
function initRepo(root, name, commits = []) {
  const repo = path.join(root, name);
  fs.mkdirSync(repo, { recursive: true });

  const git = (args, env) =>
    execFileSync('git', ['-C', repo, ...args], {
      encoding: 'utf8',
      env: { ...process.env, ...env },
      stdio: ['pipe', 'pipe', 'pipe'],
    });

  git(['init', '-b', 'main']);
  git(['config', 'user.email', 'committer@example.com']);
  git(['config', 'user.name', 'Committer']);
  git(['config', 'commit.gpgsign', 'false']);

  for (const commit of commits) {
    const file = commit.file || 'README.md';
    const filePath = path.join(repo, file);
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.appendFileSync(filePath, `${commit.content || 'change'}\n`);
    git(['add', '-A']);

    const env = {};
    if (commit.date) {
      env.GIT_AUTHOR_DATE = commit.date;
      env.GIT_COMMITTER_DATE = commit.date;
    }
    const args = ['commit', '-m', commit.message];
    if (commit.author) args.push(`--author=${commit.author}`);
    git(args, env);
  }

  return repo;
}

/** Write a file, creating parent dirs. */
function writeFile(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content);
}

/**
 * Build a test runner matching the suite's output contract: it prints a
 * "Results: Passed: X, Failed: Y" line that tests/run-all.js parses, and exits
 * non-zero on any failure. done() cleans up temp dirs first.
 */
function createRunner(title) {
  console.log(`\n=== ${title} ===\n`);
  let passed = 0;
  let failed = 0;

  function test(name, fn) {
    try {
      fn();
      console.log(`  ✓ ${name}`);
      passed++;
    } catch (error) {
      console.log(`  ✗ ${name}`);
      console.log(`    Error: ${error.message}`);
      failed++;
    }
  }

  function done() {
    cleanupAll();
    console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
    process.exit(failed > 0 ? 1 : 0);
  }

  return { test, done };
}

module.exports = {
  REPO_ROOT,
  makeTempDir,
  cleanupAll,
  stageSkill,
  initRepo,
  writeFile,
  createRunner,
};
