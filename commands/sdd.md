---
description: Enforce spec-driven development. Settle requirements, write the spec, slice it into tickets, build each test-first, then gate on the implementation matching the spec.
---

# SDD Command

This command invokes the **sdd-workflow** skill to run spec-driven development: the spec is written and approved first, and conformance to the spec — not a coverage number — is the gate that closes the work.

`/sdd` is a supervised orchestrator. It sequences the skills that already do the real work and stops for your approval at each step; it never runs spec → tickets → code unattended.

## What This Command Does

1. **SPEC** — Settle the requirements and write the spec (source of truth)
2. **SLICE** — Break the spec into tracer-bullet tickets
3. **BUILD** — Implement each ticket test-first
4. **CONFORM** — Verify the implementation satisfies the spec (the gate)
5. **REPEAT** — Next ticket on the frontier

## SDD Cycle

```
SPEC → SLICE → BUILD → CONFORM → REPEAT

SPEC:    Write and get sign-off on the spec
SLICE:   Break the spec into tickets with blocking edges
BUILD:   Implement each ticket test-first (red → green → refactor)
CONFORM: Prove each user story / acceptance criterion is met
REPEAT:  Pick up the next frontier ticket when told to
```

## When to Use

Use `/sdd` when:

- Building a feature big enough that requirements deserve to be written before code
- Multiple user stories or actors are involved
- The work spans more than one committable unit, or more than one session
- You want the finished work provably tied back to an agreed definition of done

Use `/tdd` instead for a single function or a quick bug fix — SDD earns its keep only when there's a specification worth conforming to.

## Where It Pauses for You

`/sdd` inherits every human-approval gate from the skills it delegates to:

- **SPEC** — `to-spec` confirms the test seams before writing; `grill-me` interviews you if requirements aren't settled; remote backends confirm before any write.
- **SLICE** — `to-tickets` quizzes you on granularity and blocking edges and publishes nothing before you approve.
- **BUILD** — `implement` confirms the seams before writing a test and never commits — it stages and hands back at each committable unit.
- **CONFORM** — the conformance result is stated explicitly for your review.
- **HAND BACK** — the next frontier ticket is picked up only when you say so.

## How It Differs from /tdd

TDD makes a **failing test** the thing you write first. SDD makes an **approved spec** the thing you write first — and gates on the implementation matching that spec, not just on green tests. Inside each ticket, SDD still runs the full TDD loop via `tdd-workflow`; the spec wraps around it as the definition of done.

## Integration with Other Commands

- Use `/sdd` to run the whole spec-first feature loop
- It delegates to `to-spec`, `to-tickets`, `implement`, and `tdd-workflow` internally
- Use `/build-fix` if build errors occur mid-ticket
- Use the `code-review` skill for a deeper review of a completed unit

## Related Skills

This command invokes the `sdd-workflow` skill provided by staksmith.

For manual installs, the source files live at:
- `skills/sdd-workflow/SKILL.md`
- `commands/sdd.md`
