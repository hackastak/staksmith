/**
 * Plain-text stoplight bar. The Claude Code renderer and the Pi footer both
 * speak this layout: repo and branch on the left, session gauges on the right,
 * 7-day limit last.
 */

'use strict';

const fs = require('fs');
const path = require('path');

const GAUGE_WIDTH = 8;
const CONTEXT_BUDGET_PCT = 80;
const WEEK_RED_PCT = 80;
const YELLOW_PCT = 60;

/**
 * 8-cell bar. Matches the bash renderer: round half up, cap at a full bar.
 * @param {number} pct
 * @returns {string}
 */
function gaugeBar(pct) {
  const display = Math.max(0, Math.min(100, Math.round(pct)));
  const filled = Math.min(GAUGE_WIDTH, Math.floor((display * GAUGE_WIDTH + 50) / 100));
  return '▓'.repeat(filled) + '░'.repeat(GAUGE_WIDTH - filled);
}

/**
 * @param {number} pct
 * @param {number} redAt
 * @returns {'success' | 'warning' | 'error'}
 */
function gaugeTone(pct, redAt) {
  if (pct >= redAt) return 'error';
  if (pct >= YELLOW_PCT) return 'warning';
  return 'success';
}

/**
 * @param {number} pct
 * @param {number} [budgetPct]
 * @returns {{ text: string, tone: 'success' | 'warning' | 'error' }}
 */
function contextSegment(pct, budgetPct = CONTEXT_BUDGET_PCT) {
  const rounded = Math.round(pct);
  const approachFloor = Math.max(YELLOW_PCT, budgetPct - 5);
  let nag = '';
  if (rounded >= budgetPct) nag = '  ⚠ /compact recommended';
  else if (rounded >= approachFloor) nag = '  ⚠ /compact approaching';
  return {
    text: `ctx ${gaugeBar(rounded)} ${rounded}%${nag}`,
    tone: gaugeTone(rounded, budgetPct),
  };
}

/**
 * @param {number} pct
 * @returns {{ text: string, tone: 'success' | 'warning' | 'error' }}
 */
function weekSegment(pct) {
  const rounded = Math.round(pct);
  return {
    text: `7d ${gaugeBar(rounded)} ${rounded}%`,
    tone: gaugeTone(rounded, WEEK_RED_PCT),
  };
}

/**
 * @param {number} turns
 * @returns {{ text: string, tone: 'success' | 'warning' | 'error' }}
 */
function turnsSegment(turns) {
  const tone = turns > 40 ? 'error' : turns >= 20 ? 'warning' : 'success';
  return { text: `↺ ${turns}`, tone };
}

/**
 * @param {string[]} segments
 * @returns {string}
 */
function joinSegments(segments) {
  return segments.filter(segment => segment.length > 0).join('  ');
}

/**
 * @param {{ work: string, claude: string }} halves
 * @returns {string}
 */
function statusLine(halves) {
  if (halves.work && halves.claude) return `${halves.work}  |  ${halves.claude}`;
  return `${halves.work}${halves.claude}`;
}

/**
 * @param {string} cwd
 * @returns {{ name: string, icon: string } | null}
 */
function gitPlace(cwd) {
  const gitPath = path.join(cwd, '.git');
  if (!fs.existsSync(gitPath)) return null;
  const icon = fs.statSync(gitPath).isDirectory() ? '🌿' : '🪵';
  let root = cwd;
  const worktree = root.match(/^(.*)(?:\.claude\/worktrees|\.worktrees)\/[^/]+$/);
  if (worktree && worktree[1]) root = worktree[1];
  const name = path.basename(root.replace(/\/$/, '')) || path.basename(cwd);
  return { name, icon };
}

/**
 * Repo label for a directory. Linked worktrees use 🪵; a normal checkout uses 🌿.
 * @param {string} cwd
 * @param {string} [branch]
 * @returns {string}
 */
function workHalf(cwd, branch) {
  const place = gitPlace(cwd);
  if (!place) return '📁 no-repo';
  return branch ? `${place.name} ${place.icon} ${branch}` : `${place.name} ${place.icon}`;
}

/**
 * Current branch from HEAD, without spawning git. Empty when detached-unknown or missing.
 * @param {string} cwd
 * @returns {string}
 */
function readBranch(cwd) {
  const gitPath = path.join(cwd, '.git');
  if (!fs.existsSync(gitPath)) return '';
  let headPath = path.join(gitPath, 'HEAD');
  if (!fs.statSync(gitPath).isDirectory()) {
    const line = fs.readFileSync(gitPath, 'utf8').split('\n')[0] || '';
    if (!line.startsWith('gitdir: ')) return '';
    const gitdir = line.slice('gitdir: '.length);
    headPath = path.join(path.isAbsolute(gitdir) ? gitdir : path.join(cwd, gitdir), 'HEAD');
  }
  if (!fs.existsSync(headPath)) return '';
  const head = (fs.readFileSync(headPath, 'utf8').split('\n')[0] || '').trim();
  if (head.startsWith('ref: refs/heads/')) return head.slice('ref: refs/heads/'.length);
  return head.slice(0, 7);
}

module.exports = {
  CONTEXT_BUDGET_PCT,
  gaugeBar,
  contextSegment,
  weekSegment,
  turnsSegment,
  joinSegments,
  statusLine,
  gitPlace,
  readBranch,
  workHalf,
};
