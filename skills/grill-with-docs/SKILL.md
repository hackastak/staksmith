---
name: grill-with-docs
description: A relentless interview that also leaves a paper trail — the glossary and ADRs get written as the decisions crystallise. Use when the user wants to be grilled on a design and have the domain model captured at the same time.
category: "Workflow & Meta"
origin: Hackastak
disable-model-invocation: true
---

# Grill With Docs

Run the `grill-me` interview, and use `domain-modeling` to capture what it settles.

Two skills, one session:

- **`grill-me`** drives the conversation — one question at a time, recommended answer with each, facts looked up rather than asked, no acting until the user confirms shared understanding.
- **`domain-modeling`** captures the output as it happens — terms into the repo's `CONTEXT.md` the moment they're resolved, and an ADR into `docs/adr/` for any decision that passes both gates of the house standard (hard to reverse **and** a real trade-off).

## The rhythm

Capture as you go, not at the end. When a term gets sharpened mid-interview, write it to `CONTEXT.md` before asking the next question — a glossary written from memory at the end of a long session is a worse glossary.

Most questions settle nothing ADR-worthy, and that's normal. Offer an ADR only when a decision clears both gates; the full format and the supersede-don't-edit rule live in the `adr-standard` skill. Don't pause the interview to write one — note it, keep grilling, and write it at the next natural break.

When the interview contradicts something an existing ADR already settled, say so out loud. Reopening a settled decision is fine; editing the old ADR is not. If the user decides to change course, the result is a new ADR that supersedes the old one.

## When to use this instead of plain `grill-me`

Use `grill-with-docs` when the design being grilled is one the repo will have to live with — new domain concepts, a decision that will be expensive to unwind, an area where the vocabulary is still fuzzy. Use plain `grill-me` for a plan that only needs to survive the next hour.
