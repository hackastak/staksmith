---
name: ask-hackastak
description: Route a situation to the right Hackastak skill — the map over everything you can invoke, with the engineering idea-to-ship flow as its spine. Use when you know there's a skill for this but not which one, when you want the lay of the land, or when the user invokes /ask-hackastak.
origin: Hackastak
disable-model-invocation: true
argument-hint: "What you're trying to do, or nothing to see the whole map"
---

# Ask Hackastak

The router over every skill you can invoke. When you know the work but not the tool — "there's probably a skill for this" — this is the map. It **points**; it does not do the work. Read the situation, name the one or two skills that fit, say why, and hand off to them.

If `$ARGUMENTS` names a situation, route straight to it. With no argument, show the map below and let the user pick.

## Keep the context in the sharp zone

Every skill below runs better in a clean context. A working session reasons sharpest well under the model's limit (rule of thumb: keep the live context in a healthy zone, roughly the first ~120k tokens, not crammed against the ceiling). So the router's first instinct at a **phase boundary** is to shed weight, not push through:

- Finished exploring and about to build? Compact the research context first (`strategic-compact` suggests when; `/compact` does it).
- Session ending with work unfinished? Write a `handoff` and resume fresh, rather than dragging a saturated context across the boundary.

A skill invoked in a bloated context gives worse results than the same skill invoked clean. Routing well includes routing *when*.

## The engineering flow: idea → ship

The spine. Most work is somewhere on this line; find where you are and take the next step.

1. **Research the ground** — `/source-research` investigates a question against high-trust primary sources (docs, source, specs) before you commit to a shape.
2. **Shape the design** — `codebase-design` gives the deep-module vocabulary to think in; `/prototype` builds a throwaway to answer one design question; `/domain-modeling` pins the domain language and records decisions as ADRs.
3. **Write the spec** — `/to-spec` turns the conversation into a PRD and publishes it to the tracker.
4. **Break it into tickets** — `/to-tickets` cuts the spec into tracer-bullet tickets with their blocking edges. By default these land in the vault at `1. Projects/<Project>/issues/NN-*.md` (github issues opt-in per repo, local `.scratch/` as the offline alternative).
5. **Stress-test before building** — `/grill-me` interviews you relentlessly until the plan holds; `/grill-with-docs` does the same and leaves the glossary and ADRs behind; `/batch-grill-me` asks a whole frontier of questions per round when you'd rather answer in batches.
6. **Build it** — `/implement` executes a planned unit (spec, tickets, or issue); `/tdd-workflow` drives it test-first when the change wants that discipline.
7. **When it fights back** — `/diagnosing-bugs` is the loop for hard bugs and performance regressions: build a red-capable feedback loop before hypothesizing.
8. **Review, in three tiers** — `/review-changes` is the tight in-dev loop over the working-tree diff (with introduced/pre-existing attribution); `/code-review` reads the whole branch broadly before you push; `/review-github-pr` reviews an actual PR by number.
9. **Ship** — `/draft-commit` stages the relevant changes and writes the one-line message; you run the commit.

### On-ramps — joining work mid-stream

Not everything starts from your own idea. When you're picking up existing work:

- `/triage` moves issues and external PRs through the triage state machine. On-ramp discipline: triage the requests you **didn't** create; don't triage your own in-flight tickets.
- `/wayfinder` plans a chunk too big for one session as a shared map of decision tickets and resolves them. It **maps and hands off**; it does not build.

### Crossing sessions

- `/handoff` writes a durable handoff document so a fresh session (or another agent) continues cleanly. Save-only — it never launches anything; you open the next session yourself.
- `strategic-compact` vs the built-in `/compact`: the skill tells you *when* a boundary is worth compacting at; `/compact` is the act.

### Codebase health — ongoing, not tied to one feature

- `/improve-codebase-architecture` scans for deepening opportunities, presents them as a report, and grills through which are worth doing.

### The vocabulary underneath

- `codebase-design` — deep modules, seams, adapters, leverage/locality (design-time language).
- `domain-modeling` + `adr-standard` — the domain glossary in `CONTEXT.md`, and the house standard every ADR follows.

## The rest, by family

One line each; open the skill for the detail.

### Setup / preconditions
- `/setup-hackastak` — configure a repo's issue-tracker backend, triage labels, and domain-model layout for the flow above.
- `/setup-ts-deep-modules` — wire dependency-cruiser so each TypeScript package is a deep module.
- `/setup-pre-commit` — Husky + lint-staged commit-time gate (format, typecheck, test).
- `/git-guardrails` — a hook that blocks dangerous git commands before they run.

### Git ops
- `/resolving-merge-conflicts` — resolve an in-progress merge or rebase by the intent behind each side.
- `/draft-commit` — stage the relevant changes and draft a tight conventional-commit message.
- `/review-github-pr` — read-only review of a GitHub PR by number.

### Writing
- `/writing-fragments` — explore: mine raw fragments for a piece before it has structure.
- `/writing-beats` and `/writing-shape` — exploit: assemble the material into a journey of beats, or shape it into an argued article.
- `/article-writing` — write long-form content in the house voice.
- `/polish` — audit and fix a draft against the HackaStak style guidelines.
- (`writing-grounding` is the shared reference the writing skills lean on, not invoked directly.)

### Personal / productivity
- `/design-workflow` — turn a recurring loop in your work into a delegable workflow spec.
- `/to-questionnaire` — package a decision you can't answer alone into questions for someone who can.
- `/teach` — learn a concept over multiple sessions in a stateful workspace.
- `/handoff` — durable cross-session handoff document (save-only).
- `strategic-compact` — suggests compacting at logical boundaries.

### Skill authoring
- `/skill-design` — the vocabulary and principles for writing a skill that behaves predictably. Read it first.
- `/skill-creator` scaffolds a new skill; `/skill-stocktake` audits skills for quality; `/skill-auto-extractor` mines git history and session logs for repeated workflows worth capturing.

## What this skill does not do

It routes; it does not execute. It never edits code, writes a spec, or runs a review itself — it names the skill that does and gets out of the way. If two skills both fit, say so and give the one-line difference that decides between them.
