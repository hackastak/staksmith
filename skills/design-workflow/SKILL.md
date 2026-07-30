---
name: design-workflow
description: Grill the user about the recurring loops in their life and work, and turn each one worth delegating into a workflow spec. Use when the user wants to design an automation, says "help me spec a workflow", or invokes /design-workflow.
origin: Hackastak
disable-model-invocation: true
argument-hint: "A workflow to design, or nothing to go find one"
---

# Design Workflow

Run a stateful **`grill-me`** session whose only output is **workflow specs**. `grill-me` carries the whole interview discipline — relentless, one question at a time, a recommended answer attached to each, facts looked up rather than asked of the user, no acting until they confirm shared understanding — so follow it as written and aim it at the lens and vocabulary below. Create, edit, and delete specs as the interview resolves things.

This skill **designs** workflows; it doesn't run them. Execution belongs to `loop` (interval runner) and `schedule` (cron agents). A finished spec here is what those skills, or an implementer agent, go and build.

## The loop lens

A **loop** is a recurring pattern in the user's life: their career, their week, their morning, a single repeated activity. Picturing a life as loops within loops reveals how predictable its activities really are — which is what makes them worth **delegating**. Use the lens to find loops worth specifying, and propose ones the user hasn't noticed.

A **workflow** is the spec of one loop, made real. You run a workflow on a loop — the loop is its running instantiation.

## Vocabulary

A shared language, reached for only when a workflow calls for it — never a checklist. **Mandate nothing structural:** a workflow needs no AI, no checkpoint, and no schedule unless the grilling shows it does.

- **Trigger** — what fires each run: an **event** (a new email, a new issue) or a **schedule** (every morning). Event-triggering is usually the more efficient of the two.
- **Checkpoint** — a human-in-the-loop point where the user is asked to verify or decide. Some workflows have none and run autonomously; some use no AI at all.
- **Push right** — defer the checkpoint as far as it will go. Do maximal work before involving the human, so they are asked once, late, with everything prepared.
- **Brief** — what a checkpoint presents: a tight, decision-ready summary of what was produced and why, with a link down to the asset itself. Never the raw output. The user reads a brief, not a draft — speed of review is the imperative.

## Definition of done

A workflow spec is done when an implementer agent could build it **without asking a single question**. Grill until then; nothing is done while a question remains.

## The workspace

Specs live in the vault, in a single browsable catalog: **`~/Developer/My_Notes/2. Areas/Workflows/`**. Life loops are recurring responsibilities, which is what a PARA Area is — so they go in one place, not scattered across the Areas they touch, and not in a code repo.

- **`2. Areas/Workflows/<workflow>.md`** — one spec per workflow. Create the folder if it doesn't exist.
- **`2. Areas/Workflows/NOTES.md`** — raw notes on the user's world: the tools they use, the channels they process, and their own terminology for both. **When it's empty or thin, interview them about their world before specifying anything.** Sharpen fuzzy terms into canonical ones as they surface, and record them here.

Wikilink specs to each other and to the Areas they serve, so the catalog knits into the vault's graph. Match the frontmatter conventions of the surrounding notes rather than imposing a new scheme.

Follow the vault's draft → confirm → write gate: show the user the spec and the exact path before writing it.

## Related skills

- **`grill-me`** — the interview engine. `batch-grill-me` if the user would rather answer a whole round at once.
- **`loop` / `schedule`** — execution. A spec designed here is what they run.
- **`to-spec`** — the software-feature equivalent. Keep them separate: that one specs a product change, this one specs a life or work automation.
- **`wizard`** — for the half of a procedure that can't be automated and needs a human walked through it.
