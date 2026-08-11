---
name: sdd-workflow
description: Enforce spec-driven development — settle the requirements, write the spec, break it into tickets, build each one test-first, then gate on the implementation matching the spec. Use when the user says "let's do this spec-first", "spec-driven development", or invokes /sdd.
category: "Workflow & Meta"
origin: Hackastak
disable-model-invocation: true
---

# Spec-Driven Development Workflow

Where TDD makes a **failing test** the thing you write first, SDD makes an **approved spec** the thing you write first — and the spec, not a coverage number, is the gate you close at the end. Every line of implementation traces back to a user story or a decision in the spec; anything that doesn't is either out of scope or a spec change.

This skill is a **thin orchestrator**. It doesn't reimplement spec-writing, ticketing, or TDD — it sequences the skills that already do those and enforces the cadence between them, adding the one thing none of them own alone: the **spec-conformance gate**.

The SDD loop:

```
SPEC → SLICE → BUILD (test-first) → CONFORM → REPEAT

SPEC:    Write and get sign-off on the spec (the source of truth)
SLICE:   Break the spec into tracer-bullet tickets
BUILD:   Implement each ticket test-first
CONFORM: Verify the implementation satisfies the spec — the gate
REPEAT:  Next ticket on the frontier
```

## When to Activate

Use `/sdd` when:

- Building a feature big enough that the requirements deserve to be written down before code
- Multiple user stories or actors are involved
- The work will span more than one committable unit, or more than one session
- You want the finished work provably tied back to an agreed definition of done

For a single function or a quick bug fix, skip the ceremony — go straight to `/tdd`. SDD earns its keep when there's a *specification worth conforming to*.

## 1. SPEC — settle the requirements, then write it

The spec is the contract. It cannot be synthesised from a conversation that hasn't settled.

- **If the conversation is already settled** — run `to-spec` to synthesise the spec/PRD and publish it to the configured tracker (vault by default; see `docs/agents/issue-tracker.md`). `to-spec` pauses once to confirm the test seams — that pause is part of this step.
- **If it isn't settled** — stop and run `grill-me` (or `grill-with-docs` when there's reference material) first. Do not let SDD start an interview itself; that's `grill-me`'s job. Return here once the requirements hold together.

Respect any ADRs in `docs/adr/` covering the area. If the emerging spec would contradict one, surface that **now**, before writing — and if it warrants a new decision, record it per `adr-standard` before proceeding.

**Do not write code in this step.** The output is an approved spec, nothing more.

## 2. SLICE — break the spec into tickets

Run `to-tickets` against the approved spec. Each ticket is a tracer-bullet vertical slice — a narrow but complete path through every layer — declaring the tickets that block it. `to-tickets` quizzes the user on granularity and blocking edges and publishes nothing before approval.

Every ticket must trace to at least one user story in the spec. If a slice doesn't map to the spec, that's a signal: either the spec is missing a story (go back to step 1 and amend it) or the slice is out of scope (drop it).

## 3. BUILD — implement each ticket test-first

Work the **frontier**: any ticket whose blockers are all done. For each one, run `implement`, which:

- confirms the test seams (usually already named in the spec — confirm those, don't invent new ones),
- drives `tdd-workflow` red→green→refactor at those seams,
- keeps the verification cadence (typecheck per slice, focused tests in the tight loop, full suite once at the end),
- runs `review-changes` over the diff before stopping.

The spec is authoritative during the build. If implementing a ticket reveals the spec is wrong or incomplete, **stop and amend the spec** (step 1) rather than quietly diverging — a silent divergence is the one failure mode SDD exists to prevent.

## 4. CONFORM — gate on the spec, not just green tests

This is the step that makes it *spec*-driven and the SDD analog of TDD's coverage check. Green tests prove the code does what the tests say; the conformance gate proves the code does what the **spec** says.

Before handing a ticket (or the whole feature) back, verify conformance:

- **Walk the spec's user stories** — for each story the ticket claims to deliver, confirm the implemented behaviour actually satisfies it. Not "is there a test" — "does the described user actually get the described benefit."
- **Walk the ticket's acceptance criteria** — every checkbox demonstrably met.
- **Check the implementation decisions** — modules, interfaces, contracts, and schema changes match what the spec recorded, or the spec was amended to match reality.
- **Confirm nothing crept in** — behaviour not traceable to the spec is either an accidental scope creep (remove it) or an unrecorded decision (amend the spec).
- **Run `verification-loop`** for the mechanical gates (typecheck, lint, full test suite, build) as the floor beneath conformance.

State the conformance result explicitly — which stories/criteria are satisfied, and anything deliberately deferred and why. An unstated gate is a skipped gate.

## 5. REPEAT / hand back

**Do not commit** (that stays with `implement`'s hand-back rule). When a committable unit conforms, stage it, summarise what changed *and how it maps back to the spec*, and hand control to the user. Pick up the next frontier ticket only when they say to.

When every ticket is done and conforming, the feature is done — by definition, because "done" was written down in step 1.

## Guardrails

**DO:**
- ✅ Get the spec approved before slicing or building
- ✅ Trace every ticket and every behaviour back to the spec
- ✅ Amend the spec openly when reality diverges — the spec stays the source of truth
- ✅ Close the conformance gate explicitly, per ticket
- ✅ Let `to-spec` / `to-tickets` / `implement` do their own jobs — this skill only sequences them

**DON'T:**
- ❌ Start coding before the spec is signed off
- ❌ Interview the user inside this skill (that's `grill-me`)
- ❌ Let the implementation silently drift from the spec
- ❌ Treat green tests as sufficient — conformance is a separate gate
- ❌ Re-implement spec/ticket/TDD logic here — delegate

## Related skills

- **`grill-me` / `grill-with-docs`** — settle requirements before a spec exists (step 1).
- **`to-spec`** — writes and publishes the spec (step 1).
- **`to-tickets`** — breaks the spec into tracer-bullet tickets (step 2).
- **`implement`** — builds one ticket test-first (step 3).
- **`tdd-workflow`** — the red→green loop `implement` drives inside each ticket.
- **`verification-loop` / `review-changes`** — the mechanical gates beneath conformance (step 4).
- **`adr-standard`** — for decisions surfaced while writing the spec.
