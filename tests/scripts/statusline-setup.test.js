/**
 * Tests for scripts/statusline-setup.js
 *
 * Exercises install/uninstall/status against temp settings files: idempotency, non-destructive
 * merge, foreign-config protection, and a CLI end-to-end in project scope (never touches the real
 * user settings.json).
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const {
  buildBlock,
  isOurs,
  readSettings,
  resolveSettingsPath,
  installStatusLine,
  uninstallStatusLine,
  statusStatusLine,
  runCli,
  getScriptPath,
} = require('../../scripts/statusline-setup.js');

const SCRIPT = getScriptPath();

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (err) {
    console.log(`  ✗ ${name}`);
    console.log(`    Error: ${err.message}`);
    failed++;
  }
}

function tmpFile() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'statusline-setup-'));
  return { dir, file: path.join(dir, 'settings.json') };
}
function cleanup(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
}

console.log('statusline-setup.js');

// --- buildBlock / isOurs ---
test('buildBlock produces a quoted command; isOurs recognizes it', () => {
  const block = buildBlock('/a b/scripts/statusline.js');
  assert.strictEqual(block.type, 'command');
  assert.strictEqual(block.command, 'node "/a b/scripts/statusline.js"');
  assert.ok(isOurs(block));
  assert.ok(!isOurs({ type: 'command', command: 'node other.js' }));
  assert.ok(!isOurs(undefined));
});

// --- install ---
test('install creates settings.json with our block', () => {
  const { dir, file } = tmpFile();
  try {
    const r = installStatusLine(file, SCRIPT);
    assert.strictEqual(r.action, 'installed');
    const settings = readSettings(file);
    assert.ok(isOurs(settings.statusLine));
  } finally {
    cleanup(dir);
  }
});

test('install is idempotent (second run is unchanged)', () => {
  const { dir, file } = tmpFile();
  try {
    installStatusLine(file, SCRIPT);
    const r = installStatusLine(file, SCRIPT);
    assert.strictEqual(r.action, 'unchanged');
  } finally {
    cleanup(dir);
  }
});

test('install preserves other settings keys', () => {
  const { dir, file } = tmpFile();
  try {
    fs.writeFileSync(file, JSON.stringify({ permissions: { allow: ['x'] }, env: { A: '1' } }));
    installStatusLine(file, SCRIPT);
    const settings = readSettings(file);
    assert.deepStrictEqual(settings.permissions, { allow: ['x'] });
    assert.deepStrictEqual(settings.env, { A: '1' });
    assert.ok(isOurs(settings.statusLine));
  } finally {
    cleanup(dir);
  }
});

test('install refreshes the path when ours but stale', () => {
  const { dir, file } = tmpFile();
  try {
    fs.writeFileSync(
      file,
      JSON.stringify({ statusLine: { type: 'command', command: 'node "/old/statusline.js"' } })
    );
    const r = installStatusLine(file, SCRIPT);
    assert.strictEqual(r.action, 'updated');
    assert.strictEqual(readSettings(file).statusLine.command, `node "${SCRIPT}"`);
  } finally {
    cleanup(dir);
  }
});

test('install refuses to clobber a foreign statusLine without force', () => {
  const { dir, file } = tmpFile();
  try {
    const foreign = { type: 'command', command: 'my-custom-statusline' };
    fs.writeFileSync(file, JSON.stringify({ statusLine: foreign }));
    const r = installStatusLine(file, SCRIPT);
    assert.strictEqual(r.action, 'conflict');
    // file untouched
    assert.deepStrictEqual(readSettings(file).statusLine, foreign);
  } finally {
    cleanup(dir);
  }
});

test('install --force overwrites a foreign statusLine', () => {
  const { dir, file } = tmpFile();
  try {
    fs.writeFileSync(
      file,
      JSON.stringify({ statusLine: { type: 'command', command: 'my-custom-statusline' } })
    );
    const r = installStatusLine(file, SCRIPT, { force: true });
    assert.strictEqual(r.action, 'installed');
    assert.ok(isOurs(readSettings(file).statusLine));
  } finally {
    cleanup(dir);
  }
});

// --- uninstall ---
test('uninstall removes our block but keeps other keys', () => {
  const { dir, file } = tmpFile();
  try {
    fs.writeFileSync(file, JSON.stringify({ env: { A: '1' } }));
    installStatusLine(file, SCRIPT);
    const r = uninstallStatusLine(file);
    assert.strictEqual(r.action, 'removed');
    const settings = readSettings(file);
    assert.strictEqual(settings.statusLine, undefined);
    assert.deepStrictEqual(settings.env, { A: '1' });
  } finally {
    cleanup(dir);
  }
});

test('uninstall leaves a foreign statusLine untouched', () => {
  const { dir, file } = tmpFile();
  try {
    const foreign = { type: 'command', command: 'my-custom-statusline' };
    fs.writeFileSync(file, JSON.stringify({ statusLine: foreign }));
    const r = uninstallStatusLine(file);
    assert.strictEqual(r.action, 'foreign');
    assert.deepStrictEqual(readSettings(file).statusLine, foreign);
  } finally {
    cleanup(dir);
  }
});

test('uninstall on a file without statusLine reports absent', () => {
  const { dir, file } = tmpFile();
  try {
    fs.writeFileSync(file, JSON.stringify({ env: {} }));
    assert.strictEqual(uninstallStatusLine(file).action, 'absent');
  } finally {
    cleanup(dir);
  }
});

// --- status / malformed handling ---
test('statusStatusLine reports ours / foreign / absent / malformed', () => {
  const { dir, file } = tmpFile();
  try {
    assert.strictEqual(statusStatusLine(file).action, 'absent'); // missing file
    installStatusLine(file, SCRIPT);
    assert.strictEqual(statusStatusLine(file).action, 'ours');
    fs.writeFileSync(
      file,
      JSON.stringify({ statusLine: { type: 'command', command: 'x' } })
    );
    assert.strictEqual(statusStatusLine(file).action, 'foreign');
    fs.writeFileSync(file, '{not json');
    assert.strictEqual(statusStatusLine(file).action, 'malformed');
  } finally {
    cleanup(dir);
  }
});

test('readSettings throws on malformed JSON (never clobbered blind)', () => {
  const { dir, file } = tmpFile();
  try {
    fs.writeFileSync(file, '{broken');
    assert.throws(() => readSettings(file));
  } finally {
    cleanup(dir);
  }
});

// --- resolveSettingsPath ---
test('resolveSettingsPath maps scope to the right file', () => {
  assert.ok(resolveSettingsPath('project', '/proj').endsWith(path.join('.claude', 'settings.json')));
  assert.ok(resolveSettingsPath('project', '/proj').startsWith('/proj'));
  assert.ok(resolveSettingsPath('global').endsWith(path.join('.claude', 'settings.json')));
});

// --- CLI end-to-end (project scope in a temp cwd; never touches real user settings) ---
test('CLI install/status/uninstall round-trip in project scope', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'statusline-cli-'));
  const prevCwd = process.cwd();
  const file = path.join(dir, '.claude', 'settings.json');
  try {
    process.chdir(dir);
    assert.strictEqual(runCli(['node', 'x', '--install', '--project']), 0);
    assert.ok(isOurs(readSettings(file).statusLine));
    assert.strictEqual(runCli(['node', 'x', '--status', '--project']), 0);
    assert.strictEqual(runCli(['node', 'x', '--uninstall', '--project']), 0);
    assert.strictEqual(readSettings(file).statusLine, undefined);
  } finally {
    process.chdir(prevCwd);
    cleanup(dir);
  }
});

test('CLI --help returns 0', () => {
  assert.strictEqual(runCli(['node', 'x', '--help']), 0);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
