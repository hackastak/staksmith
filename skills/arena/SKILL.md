---
name: arena
description: "Spawn parallel candidates at the same task, pick a base, and graft the strongest parts of the losers into it. Use when one attempt at a non-trivial artifact would lock in the wrong shape."
category: "Workflow & Meta"
origin: community
disable-model-invocation: true
---

# Arena

Open a todolist with one entry per phase (Frame, Fan out, Cross-judge, Pick, Graft, Verify) before launching anything.

Model choice and harness spawn rules are in `references/model-panel.md`. Isolation, grafting, tie-breaks, and verification rules are in `references/graft-rules.md`. Follow both. Those files replace an external model rule and the principle notes this procedure used to cite.

If this harness cannot spawn subagents, stop. Say this harness cannot run an arena. Do not role-play the missing candidates, and do not invent a second model's artifact. The caller, including `blast-radius`, continues without the panel and says the multi-model pass did not run.

## Phase A: Frame

Every candidate gets the same prompt, so the prompt is the contract.

1. State the artifact each candidate is producing.
2. Derive the rubric, 3-6 concrete gradeable criteria for what success looks like on *this* task. It is the picker's tool in Phase D. Candidates only see the task.
3. Pick the runners from `references/model-panel.md`. Spawn more runners when the arena covers multiple design directions. Use the same model N times when the work is generation-bound rather than judgment-sensitive.
4. Give each candidate its own output location (a git worktree where possible, otherwise a private directory such as `/tmp/arena-<slug>/candidate-<n>/`). Follow Separate in `references/graft-rules.md`. Candidates must not write the same file.

## Phase B: Fan out

Spawn all N subagents in one message, in the background when the tool allows it, each with the task, the path to the shared grounding, its own output path, and instructions to produce the artifact and a short rationale naming the alternatives it considered and what it rejected.

If a candidate produces no output, proceed with N-1 and note the dropout. If that leaves one candidate, there is no arena. Say so and do not pretend there was a comparison.

## Phase C: Cross-judge

After all Phase B candidates complete, choose one model from the cross-judge pool in `references/model-panel.md`. Prefer a different model family from the parent's. Spawn one readonly judge subagent on that model. It sees the rubric and the candidates by path label, scores each criterion, and recommends a base with rationale. It runs in parallel with your reading in Phase D. Don't spawn it while candidates are still writing.

## Phase D: Pick a base

Read every candidate end to end before picking. Score each against the rubric criterion by criterion, not on holistic feel, and compare with the cross-judge. Agreement on the base confirms the pick. Disagreement means one of you is biased or the rubric was ambiguous. Read both rationales before deciding.

Pick the base a future maintainer can extend most easily without breaking invariants. When two feel tied, follow Laziness in `references/graft-rules.md`: prefer the cleaner boundary or smaller API.

## Phase E: Graft

Walk each losing candidate once more for what is worth porting into the base, usually one or two things per candidate, not most of it. Fold each graft in by hand, following Redesign in `references/graft-rules.md`, so the result stays coherent under one mental model. Don't paste mechanically.

If the candidates converge on one shape, that is strong agreement. Note it and ship the consensus shape. No graft is needed. If they wildly diverge, Phase A was under-specified. Reframe and re-run rather than averaging the divergence.

## Phase F: Verify

Verify the synthesized artifact like any other output, following Prove in `references/graft-rules.md`. If verification finds a problem the arena missed, either Phase A was wrong (re-frame and re-run) or a candidate caught it and you missed the graft (go back to Phase E). Don't paper over it.

## Outputs

One synthesized artifact, with a short synthesis note alongside naming the base and why, the cross-judge's verdict, each graft with its source candidate, what was rejected and why, any convergence or dropouts, and the verification result.
