# Changelog

## 1.0.5 - 2026-11-15

Continued the stocktake prune with Tier 4 — the domain-dependent skills that only earn their place if you do the work (138 → 125 skills):

- **Removed 13 skills** across three groups: fundraising (`investor-materials`, `investor-outreach`), the video/story channel (`story-ideas`, `story-pipeline`, `story-script`, `crosspost`, `content-engine`), and narrow stacks not shipped on (`clickhouse-io`, `foundation-models-on-device`, `liquid-glass-design`, `x-api`, `bun-runtime`, `nextjs-turbopack`). Each dropped its paired command and `.opencode/commands/` mirror; 12 `.agents/` + `.cursor/` mirror dirs were removed too.
- **Kept the vault→Gumroad monetization pipeline**: `product-ideas` → `package-product` → `product-pipeline`, plus the `money` revenue advisor. These were initially swept up in the Tier 4 cut, then kept once it was clear they form one load-bearing workflow rather than independent residue — cutting part of a find→make→sell trilogy orphans the rest.
- **Manifest cascade**: cutting `crosspost` + `x-api` emptied the `social-distribution` install module (`paths` requires `minItems: 1`), so the module, its `capability:social` component, and its references in the `research` + `full` profiles were removed; the one test exercising that dependency was retargeted to an equivalent still-valid pair.
- **Scrubbed every trailing reference** to the cut skills across all surfaces: install manifests, `opencode.json`, the generated and hand-maintained catalogs (`SKILLS.md`, `CUSTOM_SKILLS.md`, `skills/README.md`, `configure-staksmith`), the `.codex`/`.opencode` listings, ops scripts, and see-also bullets in kept skills.

## 1.0.4 - 2026-11-14

Pruned the skill set back to what the work actually uses, from a usage + provenance stocktake (157 → 138 skills):

- **Removed 19 skills**: unadopted community-port residue, redundant siblings, and a dead domain (Laravel — no PHP in any target repo). Cut `architect`, `batch-grill-me`, `benchmark-checklist`, `correct`, `create-verification-skill`, `create-formal-verification-skill`, `data-scraper-agent`, `exa-search`, `grill-with-docs`, `iterative-retrieval`, `laravel-patterns`, `laravel-security`, `laravel-tdd`, `laravel-verification`, `market-research`, `skill-auto-extractor`, `skill-builder`, `team-builder`, `technical-writing`.
- **Kept 5 candidates that turned out load-bearing**: `how`, `why`, `arena`, `continuous-learning` (v1), and `prompt-optimizer` are depended on by kept skills or hooks, so they stayed.
- **Scrubbed every trailing reference** to the cut skills across all surfaces: the `commands/`, `.opencode/`, `.cursor/`, `.codex/`, and `.agents/` mirrors, install manifests, generated and hand-maintained catalogs (`SKILLS.md`, `CUSTOM_SKILLS.md`, `configure-staksmith`), the `ask-hackastak` router, rules, agent prompts, and ops scripts. Repointed the surviving `architect` agent and `perf-review` at where the cut skills' content now lives.
- **Hook test fix**: `detect-project` hook test now runs in a non-login shell to match how `hooks.json` invokes `observe.sh`, removing a macOS-only spurious failure.

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
