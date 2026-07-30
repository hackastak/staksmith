---
name: batch-grill-me
description: A relentless interview that asks every frontier question at once, round by round. Use when the user wants to answer a batch of design questions in one pass rather than one at a time, or invokes /batch-grill-me.
origin: Hackastak
disable-model-invocation: true
---

# Batch Grill Me

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask *now* without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Each round the user answers reshapes the tree — settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a *later* round, not this one.

**Facts are yours to find; decisions are the user's to make.** Finding facts is your job, never theirs. When a frontier question needs a fact from the environment — the filesystem, the codebase, a tool — dispatch a sub-agent to find it rather than asking for something you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report. Ask the rest of the frontier now.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. **Do not act on it until the user confirms you have reached a shared understanding.**

## Choosing between the two cadences

This skill and `grill-me` are two tools, not a right answer and a wrong one.

- **`grill-me`** asks one question at a time. Each answer reshapes the next question, so the conversation can follow a thread the user didn't know was there. Better when the space is unfamiliar and thinking out loud is the point.
- **`batch-grill-me`** asks the whole frontier per round. The user answers N questions in one message instead of sitting through N prompts. Better when the user knows the domain, when they're working AFK, or when the throughput matters more than the thread.

Pick by mood and by how much of the answer the user already carries. Switching mid-session is fine.

## Related skills

- **`grill-me`** — the one-at-a-time cadence.
- **`grill-with-docs`** — capture terms and ADRs as the interview settles them. Compose it with either cadence.
- **`to-spec` / `to-tickets`** — where a finished interview usually goes next.
