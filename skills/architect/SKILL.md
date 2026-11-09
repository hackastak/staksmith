---
name: architect
description: "Sketch types, signatures, and module structure before code, then stay in the loop while implementation fills the sketch in. Use for /architect, architect this, design this, or non-trivial work where jumping to code would lock in the wrong shape."
category: "Workflow & Meta"
origin: community
disable-model-invocation: true
---

# Architect

Sketch types, function signatures, and module boundaries with `not implemented` bodies, then fill code in against the chosen sketch. This is the design procedure. It is not the `architect` agent. That agent is the read-only review pass `audit-codebase` fans out. Do not send this loop to that agent.

`how`, `why`, `arena`, `interrogate`, and `blast-radius` ship with this plugin. Read the skill you are about to use. You do not need another plugin. Model choice is in `references/model-panel.md`.

Open a todolist with one entry per phase before starting.

1. Ground
2. Sketch
3. Agree
4. Implement
5. Scrap

## Phase A: Ground

Build a real mental model of every system the new code touches. Run `how` over the relevant subsystems. Naming a file is not grounding. Produce the architectural explanation `how` prescribes. If the design redefines ownership or layering, also run `why` on the existing shape so the rationale is a constraint, not a guess.

Skip Phase A only when the work is genuinely greenfield and has no surrounding system to integrate.

## Phase B: Sketch

Design it twice. Require at least two structurally distinct candidates before synthesis, even when the first looks sufficient. Whole-shape alternatives, not point fixes inside one shape.

Run `arena` with the design-sketch task and the Phase A artifacts. Pass `references/runner-prompt.md` as each runner's prompt. Take runners from `references/model-panel.md`, not from arena's own runner line.

Each candidate writes usage first, then derives the type sketch from that usage. Bodies are `not implemented`. Tricky logic is pseudocode, not a guessed implementation. Screen every candidate against `references/design-red-flags.md` before synthesis. Compare viable candidates on interface depth: prefer the design that hides more complexity behind a smaller public surface. Vocabulary for that comparison is `codebase-design`.

Arena returns one synthesized design. Its synthesis decision fills the "Synthesis decision" section of `references/rationale-template.md`.

If this harness cannot spawn subagents, say the multi-model pass did not run. Do not role-play a second model. Still write two structurally distinct sketches yourself, in separate directories, labeled as same-model candidates, and compare them on interface depth. If you cannot produce a second distinct shape, stop. The design space was not exhausted.

## Phase C: Agree

Default: proceed to implementation with the synthesized design. No human checkpoint.

Stop and show the sketch only when the invoker asks: "/architect with checkpoint", "stop and show me before implementing", or similar.

The sketch may ship as its own commit, scaffold before features, per Design the Shape First in `rules/common/coding-style.md`. This skill does not create that commit. Hand the caller the files and the commit command.

For adversarial pressure before implementing, run `interrogate` on the synthesized sketch. Do this when the invoker asked for pressure, or when the decision would earn an ADR under `adr-standard`. Otherwise do not block on it.

If the human pushes back on the shape, in a checkpoint or after the fact, treat that as Phase A evidence. Re-ground and re-run Phase B before writing more code.

## Phase D: Implement against the sketch

Replace `not implemented` bodies with code, and pseudocode with logic. The synthesized sketch is the contract. A deviation is signal to surface, not friction to absorb. If a function needs a parameter the sketch did not anticipate, ask whether the sketch was wrong, the requirement was missed, or the implementation is overreaching. Say which, then either amend the sketch in the open or scrap it.

After the fill-in has a diff, run `blast-radius` on that diff before calling the shape done. A green build is not that proof.

## Phase E: Scrap

If implementation keeps producing friction the sketch cannot absorb, throw the sketch out. Do not bolt fixes onto a wrong design. That bar is Fix Root Causes in `rules/common/development-workflow.md`.

The same tells live in `codebase-design` (Scrap a wrong shape), so they apply when `/architect` is not the entry point. The signal is a pattern, not one instance. Tells:

- The same workaround shape appearing across unrelated code.
- Several unrelated edge cases that each need a special-case branch.
- Types that need escape hatches (`any`, casts, optional fields that are always set) to compile.
- A "we need a lock" reflex when the sketch said the state was not shared.
- Callers that must know the abstraction's internal rules to use it.
- Two or more independent Phase D deviations of the same shape.

A few edge cases do not condemn an architecture. Complexity in the data is not complexity in the design.

When you scrap:

1. Run `interrogate` on the sketch that failed, and `blast-radius` on the implementation that kept producing friction. Read those results before redesigning.
2. Run `how` over what has been built.
3. Redesign as if the new constraints had been day-one assumptions.
4. Subtract before adding. The new sketch should be smaller than the old one before it grows.
5. Return to Phase B and re-run arena, or the same-model fallback if this harness cannot spawn.

## Outputs

One rationale shaped per `references/rationale-template.md`, including the usage sketch and the synthesis decision. Small changes: one file of new types and signatures. Larger work: a module map plus type definitions. Patterns, the review checklist, and the ADR example live in `references/knowledge.md`. Write an ADR only when `adr-standard` says the decision earned one. Use that format, not a second template.

## Not this skill

- `brainstorming` settles intent before a design exists. This skill assumes the problem is aimed, then locks the shape.
- `grill-me` stress-tests a plan that already exists.
- `improve-codebase-architecture` deepens a codebase that is already hard to change. It does not sketch a new feature.
- `agents/architect.md` reviews. It does not run Ground through Scrap.
