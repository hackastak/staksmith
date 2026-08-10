---
name: implement
description: Implement a piece of work described by a spec, a set of tickets, a GitHub issue, or a task stated in the conversation. Use when the user says "implement this", "build ticket 03", or invokes /implement.
category: "Workflow & Meta"
origin: Hackastak
disable-model-invocation: true
---

# Implement

Build the work described by the user — a spec, a ticket off the frontier, a GitHub issue, or a task stated inline. This skill is a thin orchestrator: it sequences the skills that do the real work and enforces the cadence between them.

## 1. Pin down what you're building

Fetch the source if it's a reference (a ticket number, a note name, an issue URL) — the tracker backend is in `docs/agents/issue-tracker.md`, vault by default. If the task was only stated in conversation, restate it in one paragraph and make sure the user agrees before starting.

If the work is more than one ticket's worth, stop and use `to-tickets` first. This skill builds one committable unit at a time.

Read `CONTEXT.md` for the domain vocabulary and check `docs/adr/` for decisions covering the area you're about to touch.

## 2. Build it test-first

Use `tdd-workflow`, driving TDD **at pre-agreed seams** — write down the seams under test and confirm them with the user before writing a test. The spec or ticket usually names them already; if it does, confirm those rather than inventing new ones. (`codebase-design` has the seam vocabulary.)

## 3. Keep the verification cadence

- **Typecheck regularly** — after each slice, not at the end.
- **Run the single test files you're working in regularly** — the tight loop.
- **Run the full test suite once, at the end** — it's the expensive one; don't burn it on every cycle.

## 4. Review before you stop

Run `review-changes` over the diff once the unit is working. Fix what it turns up, or note explicitly what you're leaving and why.

## 5. Hand back for the commit

**Do not commit.** When a committable block of work is done, stage it, summarise what changed, and hand control back to the user to make the commit themselves. If the work spans several committable blocks, pause at each one rather than batching them into a single hand-back.

Then pick up the next ticket only if the user says to.

## Related skills

- **`to-tickets`** — produces the tickets this skill consumes.
- **`tdd-workflow`** — the how of step 2.
- **`review-changes`** — the diff review in step 4.
- **`draft-commit`** — drafts the message for the commit the user makes in step 5.
- **`diagnosing-bugs`** — when a test fails for reasons you can't explain, stop guessing and switch to that loop.
