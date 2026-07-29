---
name: to-spec
description: Turn the current conversation into a spec (a PRD) and publish it to the project's issue tracker — no interview, just synthesis of what has already been discussed. Use when the user says "turn this into a spec", "write the PRD", or invokes /to-spec.
origin: Hackastak
disable-model-invocation: true
---

# To Spec

Take the current conversation and codebase understanding and produce a spec — you may know this document as a PRD. **Do not interview the user.** Synthesise what you already know. If the conversation hasn't settled enough to write from, say so and point at `grill-me` or `grill-with-docs` rather than starting an interview here.

The tracker backend is configured per repo in `docs/agents/issue-tracker.md`. If that file is missing, the vault backend is the default — run `setup-hackastak` to make the choice explicit.

## Process

### 1. Explore the repo

If you haven't already, explore the repo to understand the current state of the code. Read `CONTEXT.md` if it exists and use the project's domain glossary vocabulary throughout the spec. Respect any ADRs in `docs/adr/` covering the area you're touching — if the spec would contradict one, surface that now, before writing.

### 2. Sketch the seams

Sketch the seams at which the feature will be tested. Existing seams beat new ones. Use the highest seam possible; if new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better — the ideal number is one. (See `codebase-design` for the vocabulary.)

Check with the user that these seams match their expectations before writing the spec. This is the one place the skill pauses.

### 3. Write and publish

Write the spec using the template below and publish it to the configured tracker:

- **vault** (default) — `1. Projects/<Project>/spec.md`, following the draft → confirm → write gate in `issue-tracker-vault.md`. Wikilink the spec to the project's other notes.
- **github** — a `gh` issue. Confirm with the user before the remote write.
- **local** — `.scratch/<feature-slug>/spec.md`.

Apply the `ready-for-agent` triage role — a spec you just synthesised needs no further triage.

<spec-template>

## Problem Statement

The problem the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories, each in the format:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see the balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

The decisions that were made. This can include:

- The modules that will be built or modified
- The interfaces of those modules that will change
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets — they go stale fast.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (a state machine, reducer, schema, or type shape), inline it in the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

- What makes a good test here (test external behaviour, never implementation details)
- Which modules will be tested, and at which seams
- Prior art for the tests — similar types of tests already in the codebase

## Out of Scope

What this spec deliberately does not cover.

## Further Notes

Anything else worth recording.

</spec-template>

## Related skills

- **`grill-me` / `grill-with-docs`** — for when the conversation isn't settled enough to synthesise from yet.
- **`to-tickets`** — the natural next step: break this spec into tracer-bullet tickets.
- **`codebase-design`** — seam and module vocabulary used in step 2.
