# Changelog

## 1.0.3 - 2026-09-17

Every skill is now invocable as a slash command in both harnesses:

- **Skill→command parity**: generated a same-named command for all 142 skills in `commands/` (Claude Code) and `.opencode/commands/` + `.opencode/opencode.json` (OpenCode). In OpenCode a skill is otherwise only loaded as passive context, so a command is the portable way to invoke it on demand.
- **`generate-commands` script**: `scripts/ci/generate-commands.js` (`npm run generate:commands`) creates the matching command for any skill that lacks one, in either or both surfaces. It never overwrites hand-authored commands and is idempotent.
- **CI enforcement**: `npm test` now runs `generate-commands.js --check` and fails if any skill is missing its command, so parity stays true as skills are added.

## 1.0.2 - 2026-09-11

Ported two workflow-discipline skills from the superpowers plugin and added a verification gate:

- **brainstorming**: pre-implementation gate that explores intent, requirements, and design, and requires explicit approval before any code. Architectural path hands off to `to-spec`.
- **receiving-code-review**: technical rigor for inbound review feedback, the counterpart to the outbound review family.
- **development-workflow rule**: added an "Evidence Before Completion" Iron Law (no completion claims without fresh verification), surfaced in the `/verify` command.

## 1.0.1 - 2026-08-19

Skill fixes and refinements:

- **weekly-momentum-report**: discover scanned repos from the weekly note, so the
  report covers whatever projects the note references rather than a hardcoded list.
- **quick-note**: drop the redundant approval step; no project scope for vault-level notes.
- **draft-commit**: remove scope addition.
- Validate doc catalog counts only where documented.

## 1.0.0 - 2026-07-31

First stable release of Staksmith as a Claude Code plugin: a curated collection of
agents, skills, commands, hooks, and rules for agent-assisted software development.

Everything published before this release was a beta iteration. This is the baseline
the versioning going forward is measured against.
