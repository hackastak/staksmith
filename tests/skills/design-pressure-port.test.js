/**
 * Contract for the architect scrap and usage-first graft.
 * The pressure lives on codebase-design and improve-codebase-architecture
 * so it applies when /architect is not the entry point.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '../..');

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

console.log('\ndesign-pressure port:');

test('codebase-design writes usage first and compares on interface depth', () => {
  const content = read('skills/codebase-design/SKILL.md');
  assert.match(content, /## Usage first, then depth/);
  assert.match(content, /write the caller's usage first/);
  assert.match(content, /derive the type sketch from that usage/);
  assert.match(content, /structurally distinct/);
  assert.match(content, /interface depth/);
  assert.match(content, /smaller public surface/);
  assert.match(content, /when the entry point is this skill or `improve-codebase-architecture`/);
});

test('codebase-design carries the scrap tells without becoming the architect loop', () => {
  const content = read('skills/codebase-design/SKILL.md');
  assert.match(content, /## Scrap a wrong shape/);
  assert.match(content, /same workaround shape appearing across unrelated code/);
  assert.match(content, /special-case branch/);
  assert.match(content, /escape hatches/);
  assert.match(content, /we need a lock/);
  assert.match(content, /internal rules to use it/);
  assert.match(content, /independent deviations of the same shape/);
  assert.match(content, /Complexity in the data is not complexity in the design/);
  assert.match(content, /Subtract before adding/);
  assert.match(content, /Do not role-play `interrogate`, `blast-radius`, or `arena`/);
});

test('design-it-twice and the architecture scan use the same pressure', () => {
  const twice = read('skills/codebase-design/DESIGN-IT-TWICE.md');
  assert.match(twice, /structurally distinct/);
  assert.match(twice, /writes usage first/);
  assert.match(twice, /interface depth/);
  assert.match(twice, /Scrap a wrong shape/);
  const scan = read('skills/improve-codebase-architecture/SKILL.md');
  assert.match(scan, /usage-first sketching/);
  assert.match(scan, /scrap tells/);
  assert.match(scan, /structurally distinct/);
  assert.match(scan, /usage first, then derives the type sketch/);
  assert.match(scan, /smaller public surface/);
  assert.match(scan, /Do not role-play `interrogate`, `blast-radius`, or `arena`/);
  assert.match(scan, /even when `\/architect` is not the entry point/);
});

test('architect points at the shared tells instead of owning them alone', () => {
  const content = read('skills/architect/SKILL.md');
  assert.match(content, /codebase-design` \(Scrap a wrong shape\)/);
  assert.match(content, /when `\/architect` is not the entry point/);
});

console.log(`\nResults: Passed: ${passed}, Failed: ${failed}`);
if (failed > 0) process.exit(1);
