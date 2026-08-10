---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching a shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, mentions "grill me".
category: "Workflow & Meta"
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time. Asking several at once is bewildering — it forces me to hold every open branch in my head instead of settling one and letting it reshape the rest. (When you deliberately want the whole frontier in one round instead, that's the `batch-grill-me` skill.)

**Facts are yours to find; decisions are mine to make.** Finding facts is your job, never mine. If a question can be answered by exploring the codebase or the environment, explore it — dispatch a sub-agent if it's a long look — rather than asking me for something you could look up yourself. Don't block on it either: only the questions downstream of a running exploration wait for it. The decisions are mine — put each one to me and wait for my answer.

**Do not act until I confirm we have reached a shared understanding.** The session ends when every branch has been visited and nothing is left silently assumed — and then only on my say-so, not yours.
