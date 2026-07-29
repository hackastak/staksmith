---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker. Use when the user says "break this into tickets", "turn the spec into issues", or invokes /to-tickets.
origin: Hackastak
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it.

The tracker backend is configured per repo in `docs/agents/issue-tracker.md`. If that file is missing, the vault backend is the default — run `setup-hackastak` to make the choice explicit.

## Process

### 1. Gather context

Work from whatever is already in the conversation. If the user passes a reference (a spec path, a note name, an issue number or URL), fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so. Ticket titles and descriptions should use the project's `CONTEXT.md` glossary vocabulary and respect the ADRs in the area you're touching.

Look for opportunities to prefactor the code so the implementation gets easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring is done first

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A wide refactor is one mechanical change — rename a column, retype a shared symbol — whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**:

1. **Expand** — add the new form beside the old so nothing breaks.
2. **Migrate** — move call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand. CI stays green batch to batch because the old form still exists.
3. **Contract** — delete the old form once no caller remains, in a ticket blocked by every migrate batch.

When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket show:

- **Title** — short descriptive name
- **Blocked by** — which other tickets (if any) must complete first
- **What it delivers** — the end-to-end behaviour this ticket makes work

Then ask:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown. Nothing gets published before approval.

### 5. Publish to the configured tracker

The tickets are the same on every backend; only the shape of the blocking edges changes.

- **vault** (default) — one file per ticket at `1. Projects/<Project>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first), never a single combined file. "Blocked by" lists the numbers it depends on. Follow the draft → confirm → write gate and the wikilink conventions in `issue-tracker-vault.md`; wikilink each ticket back to its spec.
- **github** — one issue per ticket in dependency order so each ticket's blocking edges can reference real issue numbers. Use GitHub's native sub-issue and dependency relationships where they fit; otherwise write a "Blocked by" section. **Confirm before the remote write.**
- **local** — one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, same numbering rule.

Apply the `ready-for-agent` triage role unless instructed otherwise — these tickets are agent-grabbable by construction.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

Do NOT close or modify any parent issue or spec.

<file-ticket-template>

# <NN> — <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective — not a layer-by-layer implementation list.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None — can start immediately".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</file-ticket-template>

<issue-template>

## Parent

A reference to the parent issue on the tracker (omit if the source wasn't an existing issue).

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective — not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

A reference to each blocking ticket, or "None — can start immediately".

</issue-template>

In either form, avoid specific file paths and code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (a state machine, reducer, schema, or type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts.

## Related skills

- **`to-spec`** — the usual source document for these tickets.
- **`implement`** — picks a ticket off the frontier and builds it.
- **`wayfinder`** — for work too foggy to ticket yet; produces the map that eventually feeds this skill.
