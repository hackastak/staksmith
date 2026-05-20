---
name: review-github-pr
description: "Review a GitHub pull request for the current branch by PR number. Performs read-only inspection across correctness, security, style, test coverage, architecture, and performance. Use when the user says things like 'review PR 186', 'review this pull request', or invokes '/review-github-pr <number>'."
---

You are reviewing a GitHub pull request that targets the **current branch**. This is **read-only inspection**: never `git checkout` the PR branch, never modify files, never push, never post to GitHub. Use `gh` and direct file reads only.

## 1. Validate input

Require a PR number as an argument. Accept `186`, `#186`, or a full GitHub URL — extract the number from any of them.

If no argument was provided, ask the user:

> Which PR number should I review?

Wait for a number before proceeding. Do not guess.

## 2. Gather PR metadata

Run:

- `gh pr view <num> --json number,title,body,baseRefName,headRefName,headRefOid,author,additions,deletions,changedFiles,url,isDraft,mergeable`

The review does **not** require the PR to be checked out locally — it works regardless of which branch the user is currently on. Capture `headRefOid` (the PR's head commit SHA) for later use when reading file contents. If the PR is a draft, note it in the summary but proceed with the review.

## 3. Gather changes

Run in parallel:

- `gh pr diff <num> -U15` — full unified diff with 15 lines of context per hunk. Wider context usually eliminates the need for full-file reads. (`gh pr diff` forwards extra flags to `git diff`, so `-U15` works.)
- `gh pr view <num> --json files --jq '.files[].path'` — list of changed file paths

When even the widened diff is not enough context (e.g., you need to see a helper function that's unchanged but called from a modified line), or when you need to verify a file line number before citing it, bring the PR's head commit into the local object database and read the file at that SHA:

- `git fetch origin pull/<num>/head` — read-only on the working tree; only updates `FETCH_HEAD` and the object database
- `git show <headRefOid>:<path>` — pure stdout read of the file at the PR's head SHA. Use `headRefOid` from the step 2 metadata, or `FETCH_HEAD` if you just fetched it.
- `git show <headRefOid>:<path> | grep -n '<symbol>'` — get the real file line number for a function, class, or field name before citing it.

**Do not** use the `Read` tool on the local working-tree copy — the user may be on a completely unrelated branch, and the working tree will not reflect the PR's content.

**Do not** construct a manual diff range like `git diff <baseRef>...FETCH_HEAD` or `git diff <baseRef>...<headRefOid>`. `gh pr diff <num> -U15` already returns the full PR diff against the correct merge base — re-running it as a `git diff` is redundant and routinely fails on refs that aren't fetched locally (the base branch may not exist as a local ref, and inventing one produces errors like `fatal: ambiguous argument '<ref>...FETCH_HEAD': unknown revision`). Reserve direct `git` calls for `git show <headRefOid>:<path>` file reads only.

Look for project conventions before reviewing style:

- `CLAUDE.md` at the repo root (and any nested `CLAUDE.md` near changed files)
- Linter / formatter configs (`.flake8`, `pyproject.toml`, `.eslintrc*`, `tsconfig.json`, `package.json`, `.editorconfig`)
- `CONTRIBUTING.md`, `.github/pull_request_template.md`

Treat what you find there as authoritative for the project's style and process expectations.

### Reading file line numbers from diff hunks

A diff hunk header looks like `@@ -331,205 +331,271 @@`. The `+331,271` half is the only one that matters for citing locations in the post-change file: **new content starts at file line 331** and spans 271 lines. To translate a position inside the hunk back to a file line number:

- The first `+` or context (space-prefixed) line of the hunk is file line 331.
- Each subsequent `+` or context line increments the file line counter by 1.
- `-` lines do **not** increment the new-file counter (they only exist in the pre-change file).

The line numbers `cat -n` or your viewer shows for the diff text itself are **patch line numbers** — positions within the diff blob. They are not file line numbers and must never appear in a `file:line` citation. If you're unsure, verify with `git show <headRefOid>:<path> | grep -n '<symbol>'` before writing the citation.

## 4. Review across six dimensions

For each dimension, surface findings tagged **Critical / Major / Minor / Nit** with concrete `file:line` references drawn from the diff or files you read. Never invent paths or line numbers.

1. **Correctness & logic** — bugs, edge cases, off-by-one, race conditions, missing or wrong error handling, incorrect null/None handling, broken control flow, misuse of async/await, leaked resources, type mismatches.
2. **Security** — injection (SQL/command/template/HTML), unsafe deserialization, secrets or credentials in code, authn/authz gaps, SSRF, path traversal, insecure defaults, unvalidated user input crossing trust boundaries, risky dependency additions.
3. **Style & conventions** — adherence to the project conventions identified in step 3. Call out anything that would fail the project's configured linters/formatters, or that diverges from patterns established elsewhere in the same module.
4. **Test coverage** — for each non-trivial code path the PR adds or changes, is there a corresponding test? Flag changed behavior with no new or updated tests. Flag tests that exist but assert weakly (e.g., only that a call did not throw).
5. **Architecture** — does the change respect existing module boundaries? Are new abstractions justified by current need rather than speculation? Are cross-cutting concerns (logging, tracing, error handling, auth) placed in the right layer? Does anything violate an invariant established elsewhere in the codebase?
6. **Performance** — N+1 queries, unbounded loops or recursion, blocking I/O on async paths, missing pagination on potentially large result sets, hot-path allocations, missing caching where neighboring code caches similar work, retry storms, unnecessary serialization round-trips.

If a dimension has nothing material to report, say so explicitly in the report — silence is not the same as a clean bill of health.

## 5. Output

Emit a single inline markdown report. **Do not** post comments to GitHub. **Do not** save the report to a file. Use this structure:

```
# Review: PR #<num> — <title>

**Branch:** <head> → <base>   **Author:** <login>   **Diff:** +<add>/-<del> across <n> files
**Link:** <url>

## Summary
**Verdict:** Approve | Request changes | Needs discussion

<The main review comment — the single most important thing the author needs to know about this PR. One short paragraph (1–3 sentences). Always explain the *why* behind the verdict:
- **Approve** — name what makes the PR ready (e.g., "Coverage is thorough, the refactor preserves behavior, and the new abstraction matches existing patterns in this module.").
- **Request changes** — name the specific blocker(s) that must be addressed before merge.
- **Needs discussion** — name the ambiguity or trade-off that should be resolved with the author or team before the PR can move forward.

Do not restate the findings list below — this is the headline, not a recap.>

## Findings

Each finding is its own `####` subsection — **never** a bullet list item. This is non-negotiable: bullet-list findings collapse together when rendered in a terminal, which is unreadable. Always use h4 headers so the renderer pads each finding with vertical space.

The `####` header is the file/line location (backtick-wrapped). The body is the review comment as natural prose covering what the issue is, why it matters, and the suggested fix — written the way you would write it directly to the author. Do not prefix the body with `**Comment:**` or split it into separate Issue/Why/Fix labels; the header already labels the finding.

Always leave a blank line after every `####` header and a blank line after the comment body before the next `####`. Multiple file:line references for one logical finding can be combined in the header (e.g., `#### \`path/file.py:271, :280\``).

### Critical

#### `path/file.py:42`

<Self-contained review comment covering issue, impact, and suggested fix in natural prose. Reference other code locations as `file:line` when helpful.>

#### `path/other.py:88`

<Next finding — note the blank lines above and below separating each h4 block.>

### Major

#### `path/foo.py:12`

<...>

#### `path/bar.py:34`

<...>

### Minor

#### `path/baz.py:56`

<...>

### Nits

#### `path/qux.py:78`

<...>

## What looks good
- <1–3 bullets — call out genuinely good choices, not filler.>

## Open questions
- <questions to raise with the author, if any.>
```

Omit any subsection (Critical / Major / Minor / Nits / What looks good / Open questions) that would be empty, rather than printing "(none)".

## Guardrails

- **Never** run any command that mutates the working tree, the index, or local branch refs: `git checkout`, `git switch`, `git reset`, `git restore`, `git clean`, `git merge`, `git rebase`, `gh pr checkout`. The user's currently-checked-out work must be untouched at the end of the review.
- Read-only git operations are fine: `git fetch origin pull/<num>/head` (writes only to the object database and `FETCH_HEAD`, not to the working tree or any local branch), `git show <ref>:<path>`, `git log`, `git diff <ref1>..<ref2>`, `git rev-parse`, `git cat-file`, `git ls-tree`.
- **Never** call `gh pr review`, `gh pr comment`, `gh pr merge`, `gh pr close`, `gh pr edit`, `gh pr ready`, or any other `gh` subcommand that writes to GitHub. Inspection only.
- **Never** invent file paths or line numbers. Every `file:line` reference must be a **file line number** (the line number in the post-change file), not a patch line number (a position within the diff text). Derive it from the `@@ -X,Y +N,M @@` hunk header per §3, or verify with `git show <headRefOid>:<path> | grep -n '<symbol>'` before citing. If you can't pin the exact line, cite the nearest symbol name with `~` (e.g., `path/file.py (near bad_debts)`) rather than guess a number.
- If the diff is too large to review thoroughly (rule of thumb: >2000 changed lines or >40 files), say so at the top of the report and review the highest-risk files first rather than skimming everything shallowly. Name the files you skipped so the user can ask for a follow-up pass.
- If `gh` is not authenticated or the PR number does not exist, surface the error verbatim and stop.
