---
name: interrogate
description: "Adversarial review of a diff by one readonly reviewer per model, then a lead verdict. Does not edit code. Use when the user says interrogate, adversarial review, multi-model review, stress-test this code, or tear this apart."
category: "Code Review & Quality"
origin: community
disable-model-invocation: true
---

# Interrogate

Spawn one reviewer per configured model to adversarially review code changes. The adversarial signal comes from model diversity, not assigned personas. The deliverable is a synthesized verdict. Do NOT auto-apply changes.

This is not `challenge` (that one pressure-tests a belief in the vault) and not `code-review` (one reviewer, the whole branch). Reach for this when you want independent models to try to break a diff.

The review references and the model-panel rules ship with this skill. You do not need another plugin's setup skill. If no reviewer list is configured, `references/model-panel.md` has the defaults.

## Step 1, Scope

Identify what to review from context:

- If the user points at specific files or a diff, use that.
- If on a feature branch, run `git diff main...HEAD` (or the appropriate base branch) for the full changeset.
- If the user's message references recent work, gather the relevant files.

Package the diff or file contents with any surrounding context files the reviewers need to understand the code.

**Done when:** you can name the files or the diff command, and you have the text the reviewers will see.

## Step 2, Intent

Before spawning reviewers, state the intent in one clear paragraph from the user's message, commit messages, the PR description if one exists, and the code. If you're unsure about the intent, ask the user before proceeding.

**Done when:** the intent is one paragraph, or you have asked and are waiting.

## Step 3, Spawn Reviewers

Read `references/model-panel.md` and follow it. Launch all reviewers in a single message, one per entry on the resolved `interrogate reviewers` line, labeled Reviewer A, B, and so on. If no config line exists, use the table defaults in that file.

Read `references/reviewer-prompt.md` and fill in the same template for every reviewer with the stated intent, the diff or file contents, the rubric from `references/rubric.md`, and the code-quality lens from `references/code-quality-review.md`.

**Done when:** every seat has either returned findings or been skipped with the reason from the model panel. A skipped seat is not a finding.

## Step 4, Synthesize

As results come back, build a unified picture. Parse every reviewer's findings. Merge findings that describe the same issue differently, and note which models raised each one. Findings two or more models raised independently are the highest signal. Read a lone model's finding, but weight it accordingly. Note disagreements. If one model flags something and another explicitly says the opposite, that is context for the verdict.

**Done when:** each raw finding is either merged with another or marked as a single-model finding, and disagreements are listed.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator. Read `references/lead-judgment.md` for the full framework. Put every finding in one of four buckets, with the model(s) that raised it and a one-line rationale.

- **Act on**. Real issues affecting correctness, security, or maintainability given the actual goals. They would block a real PR.
- **Consider**. Legitimate, but you're not sure they outweigh the cost of addressing them now. Worth the user's attention.
- **Noted**. Technically valid but not actionable. Context-dependent, premature optimization, or low-impact at this stage.
- **Dismissed**. Wrong, nitpicky, or missing context, with a brief reason.

**Done when:** every merged finding is in exactly one bucket, and you have not edited the code.

## Output Format

### Intent
> [The stated intent paragraph from Step 2]

### Reviewers
- Reviewer [label]: [model name], [N findings] (one bullet per reviewer, including skipped seats and why)

### Act On
[Each: description, which models raised it, why it matters.]

### Consider
[Each: description, which models raised it, the tradeoff.]

### Noted
[Brief list.]

### Dismissed
[Each with a brief rationale.]

### Agreement Map
[Where models agreed and diverged, and what that pattern tells us. If fewer than two distinct models actually ran, say the panel was not diverse.]
