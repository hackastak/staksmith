---
name: draft-commit
description: Stage the relevant changes and draft a tight, one-line commit message in the user's preferred conventional-commit format (e.g. "feat: add user auth integration using Supabase auth"). Never commits — staging and message drafting only. Use when the user says "draft a commit", "stage and write a commit message", or "/draft-commit".
category: "Build, Debug & Merge"
origin: Hackastak
---

# Draft Commit

Stage the relevant changes and draft a commit message. This skill **never commits**. Its only actions are staging files with `git add` and producing a one-line commit message for the user to review and run themselves.

## Scope (read this first)

- **Never** run `git commit` (or `commit --amend`, or any command that creates a commit), regardless of what the user says. If they ask you to commit, stage + draft the message and hand it back for them to run.
- **Never** push, pull, merge, rebase, or otherwise move history.
- **Never** modify file contents. Staging is the only write action.
- The two allowed write actions are `git add <paths>` to stage, and presenting the drafted message as text.

If the user wants the commit made, they run the final command themselves. Give them a copy-paste-ready line.

## When to Activate

- the user asks to "draft a commit", "stage and write a commit message", "prep a commit"
- the user invokes `/draft-commit`
- there are working-tree changes ready to be described and the user wants a message in house format

## Message Format

A **tight, one-line** message. No body, no wrapping paragraph, no trailers unless the user asks.

```
<type>: <imperative, lower-case summary>
```

- Starts with a **change type identifier** followed by `: `.
- The summary is imperative mood ("add", "fix", "remove" — not "added"/"adds"), lower-case first word, no trailing period.
- Concise but specific: name *what* changed and, when it clarifies, *how/where* (e.g. `using Supabase auth`, `in the checkout flow`).
- Keep the whole line short — aim for ≤ 72 characters; hard ceiling stays readable in `git log --oneline`.
- Avoid em dashes (use a comma plus a conjunction, a colon, or split the phrase) to match the user's writing preference.

**Example:** `feat: add user auth integration using Supabase auth`

### Change types

| Type       | Use for |
|------------|---------|
| `feat`     | a new feature or user-facing capability |
| `fix`      | a bug fix |
| `refactor` | code change that neither fixes a bug nor adds a feature |
| `docs`     | documentation only |
| `style`    | formatting, whitespace, no logic change |
| `test`     | adding or fixing tests |
| `chore`    | build, tooling, deps, config, housekeeping |
| `perf`     | a performance improvement |
| `ci`       | CI/CD pipeline changes |
| `build`    | build system or external dependency changes |

Optionally scope with `type(scope): summary` (e.g. `fix(api): handle null session token`) when the change is clearly confined to one area and the scope adds clarity. Omit the scope when it would just repeat the summary.

## Instructions

### Step 1: Inspect the working tree

```bash
git status --short
git diff --stat
git diff            # unstaged changes
git diff --staged   # anything already staged
```

Understand what actually changed before staging or writing anything. Read the diff, not just the filenames.

### Step 2: Decide what to stage

Stage only the changes **relevant to this commit**. If the working tree contains a single coherent change, stage it all. If it mixes unrelated changes, do not lump them together:

- Identify the logically coherent set of changes for one commit.
- Stage exactly those paths with `git add <paths>` (prefer explicit paths over `git add -A` so unrelated edits, secrets, or debug files are not swept in).
- If the changes span two or more unrelated concerns, tell the user and propose the split. Stage and draft for the first (or the set they pick); mention the others are left unstaged for a separate commit.

Never stage: files that look like secrets/credentials, local scratch/debug files, or anything the diff shows is unintended. Flag them instead.

### Step 3: Draft the message

From the staged diff, write one message in the format above:

1. Pick the change type from the dominant intent of the staged diff.
2. Write the imperative summary naming what changed.
3. Trim to a tight single line.

If the staged changes genuinely cover two intents that can't be separated, pick the primary type and mention the secondary aspect in the summary, but prefer suggesting a split (Step 2) over a vague message.

### Step 4: Present for review

Show the user:

```
Staged:
  <path>
  <path>

Proposed commit message:

  <type>: <summary>

Run it yourself when ready:
  git commit -m "<type>: <summary>"
```

Then stop. Do **not** run the commit. If the user wants changes to the message or the staged set, adjust and re-present.

## Notes

- The final `git commit` is always the user's to run. This skill hands over a ready line; it never pulls the trigger.
- One commit, one concern: a clean message comes from a clean staged set. When in doubt, propose a split.
- Read the diff before naming the type — a change in a test file might still be a `fix`, and a rename might be a `refactor`.
- No message body or footer unless the user explicitly asks for one.
