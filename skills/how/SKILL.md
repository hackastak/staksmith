---
name: how
description: "Explain how code works and where it should live. Use for how does X work, code walkthroughs before a change, and placement or layering questions. Use why for motivation."
category: "Docs & Lookup"
origin: community
disable-model-invocation: true
---

# How

Explore the codebase to answer "how does X work?" questions. Produce architectural explanations at the level of a senior engineer onboarding onto a subsystem, enough to build a working mental model, not so much that it reads like annotated source code.

Model choice and harness spawn rules are in `references/model-panel.md`. Follow that file. The panel file replaces an external model rule.

Every spawn is a general-purpose subagent with `readonly: true`. Explorers use the `how explorer` line. The explainer uses the `how explainer` line.

`why` is the companion for motivation. `blast-radius` is the companion for what a change breaks somewhere else. Do not answer either of those questions here.

## 1. Assess complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

- **Simple** (a single module, a small utility, a narrow question such as "how does function X work"): no explorers. Spawn one explainer that explores and explains in one pass, built from `references/explainer-prompt.md` without the explorer-findings section. Go to step 4.
- **Complex** (a subsystem spanning multiple files or services, a cross-cutting feature, a full architectural overview): go to step 2.

When in doubt, take the simple path.

## 2. Explore (complex only)

Decompose the question into 2 to 4 angles, each a distinct slice of the subsystem. Spawn all explorers in a single message, each with `references/explorer-prompt.md` and its angle filled in.

If this harness cannot spawn subagents, take the simple path and say the multi-explorer pass did not run. Do not role-play explorers.

## 3. Synthesize (complex only)

Once all explorers have returned, spawn one explainer with `references/explainer-prompt.md` and every explorer's findings filled in.

## 4. Present

Present the explainer's output. Light edits for clarity or context from the conversation are fine. Do not substantially rewrite it.

## Output format

The explanation uses the sections defined in `references/explainer-prompt.md`, dropping any that do not apply: Overview, Key Concepts, How It Works, Where Things Live, Gotchas.
