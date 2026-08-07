#!/usr/bin/env node
/**
 * Staksmith status line — setup / teardown
 *
 * Wires (or unwires) the Staksmith status line into a Claude Code `settings.json`. The status line
 * itself is `scripts/statusline.js`; nothing runs it until a `statusLine` block in settings points
 * at it, and plugins don't touch settings.json on install — so this is the opt-in step.
 *
 * The command path is resolved from THIS file's location (`statusline.js` is its sibling), so it
 * points at wherever the script actually lives — the dev repo or the installed plugin cache alike.
 *
 * Idempotent and non-destructive: re-running install is a no-op once configured; a foreign
 * `statusLine` you set yourself is never clobbered without `--force`; uninstall only removes a
 * block that is ours. All other settings keys are preserved.
 *
 *   node scripts/statusline-setup.js --install   [--global|--project] [--force]
 *   node scripts/statusline-setup.js --uninstall [--global|--project]
 *   node scripts/statusline-setup.js --status    [--global|--project]
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { getClaudeDir, ensureDir } = require('./lib/utils');

// A statusLine block is "ours" when its command references the status-line script by name.
const MARKER = 'statusline.js';

/** Absolute path to the status-line script (sibling of this file). */
function getScriptPath() {
  return path.join(__dirname, 'statusline.js');
}

/** The settings.json for the given scope: 'project' → ./.claude, else user → ~/.claude. */
function resolveSettingsPath(scope, cwd = process.cwd()) {
  if (scope === 'project') return path.join(cwd, '.claude', 'settings.json');
  return path.join(getClaudeDir(), 'settings.json');
}

/** Build the statusLine block. The path is quoted so spaces in it survive the shell. */
function buildBlock(scriptPath) {
  return { type: 'command', command: `node "${scriptPath}"` };
}

function isOurs(block) {
  return Boolean(block && typeof block.command === 'string' && block.command.includes(MARKER));
}

/** Read settings.json → object. Missing/empty → {}. Malformed JSON throws (never clobbered blind). */
function readSettings(file) {
  if (!fs.existsSync(file)) return {};
  const raw = fs.readFileSync(file, 'utf8');
  if (!raw.trim()) return {};
  return JSON.parse(raw);
}

function writeSettings(file, settings) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, JSON.stringify(settings, null, 2) + '\n', 'utf8');
}

/**
 * Install/refresh the status line in `file`. Returns { action } where action is:
 *   'installed' (added) | 'updated' (ours, path refreshed) | 'unchanged' (already correct) |
 *   'conflict' (a foreign statusLine exists; pass force to overwrite).
 */
function installStatusLine(file, scriptPath, opts = {}) {
  const settings = readSettings(file);
  const existing = settings.statusLine;
  if (existing && !isOurs(existing) && !opts.force) {
    return { action: 'conflict', file, existing };
  }
  const block = buildBlock(scriptPath);
  const wasOurs = isOurs(existing);
  if (wasOurs && existing.command === block.command) {
    return { action: 'unchanged', file };
  }
  settings.statusLine = block;
  writeSettings(file, settings);
  return { action: wasOurs ? 'updated' : 'installed', file };
}

/**
 * Remove the status line from `file`. Returns { action }:
 *   'removed' (ours, deleted) | 'foreign' (a statusLine you set — left untouched) | 'absent'.
 */
function uninstallStatusLine(file) {
  const settings = readSettings(file);
  const existing = settings.statusLine;
  if (!existing) return { action: 'absent', file };
  if (!isOurs(existing)) return { action: 'foreign', file };
  delete settings.statusLine;
  writeSettings(file, settings);
  return { action: 'removed', file };
}

/** Report the current statusLine state in `file`. */
function statusStatusLine(file) {
  let existing;
  try {
    existing = readSettings(file).statusLine;
  } catch {
    return { action: 'malformed', file };
  }
  if (!existing) return { action: 'absent', file };
  return { action: isOurs(existing) ? 'ours' : 'foreign', file, existing };
}

// ---- CLI ----

function showHelp() {
  console.log(`Staksmith status line setup

Usage:
  node scripts/statusline-setup.js --install   [--global|--project] [--force]
  node scripts/statusline-setup.js --uninstall [--global|--project]
  node scripts/statusline-setup.js --status    [--global|--project]

Scope:
  --global   ~/.claude/settings.json (default — a status line is personal)
  --project  ./.claude/settings.json

Notes:
  - Re-running --install is a no-op once configured.
  - A statusLine you set yourself is never overwritten without --force.
  - After changes, the status line refreshes on the next activity, not instantly.`);
}

function scopeLabel(file) {
  return file;
}

function runCli(argv) {
  const args = argv.slice(2);
  if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
    showHelp();
    return 0;
  }

  const scope = args.includes('--project') ? 'project' : 'global';
  const force = args.includes('--force');
  const file = resolveSettingsPath(scope);
  const scriptPath = getScriptPath();

  try {
    if (args.includes('--uninstall')) {
      const r = uninstallStatusLine(file);
      const msg = {
        removed: `Removed the Staksmith status line from ${scopeLabel(file)}`,
        foreign: `Left a non-Staksmith statusLine untouched in ${scopeLabel(file)} — remove it manually if you meant to.`,
        absent: `No statusLine configured in ${scopeLabel(file)} — nothing to remove.`,
      }[r.action];
      console.log(msg);
      return 0;
    }

    if (args.includes('--status')) {
      const r = statusStatusLine(file);
      const msg = {
        ours: `Staksmith status line is active in ${scopeLabel(file)}`,
        foreign: `A non-Staksmith statusLine is configured in ${scopeLabel(file)}`,
        absent: `No statusLine configured in ${scopeLabel(file)}`,
        malformed: `Could not parse ${scopeLabel(file)} — it is not valid JSON.`,
      }[r.action];
      console.log(msg);
      return r.action === 'malformed' ? 1 : 0;
    }

    if (args.includes('--install')) {
      const r = installStatusLine(file, scriptPath, { force });
      if (r.action === 'conflict') {
        console.error(
          `A different statusLine already exists in ${scopeLabel(file)}.\n` +
            `Re-run with --force to replace it, or remove it yourself first.`
        );
        return 1;
      }
      const msg = {
        installed: `Installed the Staksmith status line into ${scopeLabel(file)}`,
        updated: `Updated the Staksmith status line path in ${scopeLabel(file)}`,
        unchanged: `Staksmith status line already configured in ${scopeLabel(file)} — no change.`,
      }[r.action];
      console.log(`${msg}\nIt refreshes on the next activity in your session.`);
      return 0;
    }

    showHelp();
    return 0;
  } catch (err) {
    console.error(`Error: ${err.message}`);
    return 1;
  }
}

if (require.main === module) {
  process.exit(runCli(process.argv));
}

module.exports = {
  MARKER,
  getScriptPath,
  resolveSettingsPath,
  buildBlock,
  isOurs,
  readSettings,
  writeSettings,
  installStatusLine,
  uninstallStatusLine,
  statusStatusLine,
  runCli,
};
