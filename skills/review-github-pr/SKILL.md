---
name: review-github-pr
description: "Review a GitHub pull request for the current branch by PR number. Performs read-only inspection across correctness, security, style, test coverage, architecture, and performance. Use when the user says things like 'review PR 186', 'review this pull request', or invokes '/review-github-pr <number>'."
category: "Code Review & Quality"
---

You are reviewing a GitHub pull request that targets the **current branch**. This is **read-only inspection**: never `git checkout` the PR branch, never modify files, never push, never post to GitHub. Use `gh` and direct file reads only.

## 1. Validate input

Require a PR number as an argument. Accept `186`, `#186`, or a full GitHub URL — extract the number from any of them.

If no argument was provided, ask the user:

> Which PR number should I review?

Wait for a number before proceeding. Do not guess.

## 2. Gather PR metadata

Run:

- `gh pr view <num> --json number,title,body,baseRefName,headRefName,baseRefOid,headRefOid,author,additions,deletions,changedFiles,url,isDraft,mergeable`

The review does **not** require the PR to be checked out locally — it works regardless of which branch the user is currently on. Capture `baseRefOid` and `headRefOid` (the base and PR head commit SHAs) for later use when widening the diff and reading file contents. If the PR is a draft, note it in the summary but proceed with the review.

## 3. Gather changes

Start with the default diff and the file list (run in parallel):

- `gh pr diff <num>` — unified diff with the default 3 lines of context per hunk. **Do not pass `-U<n>` or other `git diff` flags here:** `gh pr diff` does not forward unknown flags to `git diff` (it errors with `unknown shorthand flag: 'U'`). Use the widened-diff recipe below when you need more context.
- `gh pr view <num> --json files --jq '.files[].path'` — list of changed file paths

When the default 3 lines of context isn't enough (e.g., you need to see a helper called from a modified line, or you want to verify a file line number before citing it), bring the PR's commits into the local object database and use `git` directly:

- `git fetch origin pull/<num>/head` — read-only on the working tree; only updates `FETCH_HEAD` and the object database. Brings `headRefOid` (and its ancestors, which usually include `baseRefOid`) into the local repo.
- `git fetch origin <baseRefName>` — only needed if `baseRefOid` isn't already reachable (the first `git diff` below will fail with `fatal: bad object <sha>` if so).
- `git diff -U15 <baseRefOid> <headRefOid>` — widened diff (15 lines of context). Use `baseRefOid` and `headRefOid` from the step 2 metadata; both are concrete SHAs, so this works regardless of which local refs exist.
- `git show <headRefOid>:<path>` — pure stdout read of the file at the PR's head SHA. Use this when you need to see code that isn't in the diff at all.
- `git show <headRefOid>:<path> | grep -n '<symbol>'` — get the real file line number for a function, class, or field name before citing it.

**Do not** use the `Read` tool on the local working-tree copy — the user may be on a completely unrelated branch, and the working tree will not reflect the PR's content.

**Do not** use symbolic refs like `<baseRefName>...FETCH_HEAD` in the `git diff` range — the base branch may not exist as a local ref, and `FETCH_HEAD` is fragile across multiple fetches. Always use the concrete `baseRefOid` and `headRefOid` SHAs from step 2.

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

A hunk header's starting line is where the hunk *begins*, not where the statement you care about sits. Counting forward from it in your head is the most common source of an off-by-several citation. Run the `grep -n` and use what it returns.

## 4. Review across six dimensions

For each dimension, surface findings tagged **Critical / Major / Minor / Nit** with concrete `file:line` references drawn from the diff or files you read. Never invent paths or line numbers.

1. **Correctness & logic** — bugs, edge cases, off-by-one, race conditions, missing or wrong error handling, incorrect null/None handling, broken control flow, misuse of async/await, leaked resources, type mismatches.
2. **Security** — injection (SQL/command/template/HTML), unsafe deserialization, secrets or credentials in code, authn/authz gaps, SSRF, path traversal, insecure defaults, unvalidated user input crossing trust boundaries, risky dependency additions.
3. **Style & conventions** — adherence to the project conventions identified in step 3. Call out anything that would fail the project's configured linters/formatters, or that diverges from patterns established elsewhere in the same module. Apply the smell baseline below.
4. **Test coverage** — for each non-trivial code path the PR adds or changes, is there a corresponding test? Flag changed behavior with no new or updated tests. Flag tests that exist but assert weakly (e.g., only that a call did not throw).
5. **Architecture** — does the change respect existing module boundaries? Are new abstractions justified by current need rather than speculation? Are cross-cutting concerns (logging, tracing, error handling, auth) placed in the right layer? Does anything violate an invariant established elsewhere in the codebase? Apply the smell baseline below.
6. **Performance** — N+1 queries, unbounded loops or recursion, blocking I/O on async paths, missing pagination on potentially large result sets, hot-path allocations, missing caching where neighboring code caches similar work, retry storms, unnecessary serialization round-trips.

If a dimension has nothing material to report, say so explicitly in the report — silence is not the same as a clean bill of health.

### The smell baseline

Under Style and Architecture, carry this fixed set of twelve code smells (Fowler, *Refactoring*, ch. 3) as a structural lens. It applies even when the repo documents no standards of its own. Three rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Report at Minor or Nit unless the smell is the *cause* of a correctness or security finding — then report that finding instead and name the smell as the underlying shape.
- **Skip anything tooling enforces.** If the linter catches it, the linter will say so.

Each reads *what it is* → *how to fix*; match against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → Rename it; if no honest name comes, the design is murky and that's the real finding.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → Extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → Move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together; a type wanting to be born. → Bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → Give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → Replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → Gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → Split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the PR doesn't have. → Delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → Hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → Cut it, call the real target directly.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → Drop the inheritance, use composition.

When a smell recurs across the PR, say so once at the architectural level rather than filing it a dozen times — that is the finding worth having. Smells are subject to §5 attribution like anything else: a smell identical at base is pre-existing, however loud.

## 5. Attribute every finding before assigning severity

You are reviewing **a diff**, not a codebase. A file appearing in the PR does not make everything in it this PR's responsibility. Before a finding gets a severity, establish which of three states it is in by checking the base:

- `git show <baseRefOid>:<path> | grep -n '<symbol>'` — does the problem already exist at base?
- `git diff <baseRefOid> <headRefOid> -- <path>` — did these specific lines actually change?

| Attribution | Meaning | Severity treatment |
|---|---|---|
| **introduced** | New code, or existing code this PR changed into a defect | Full severity ladder. These are the only findings that can be Critical or block a merge. |
| **improved-but-incomplete** | The PR makes this area better but leaves a gap (added partial auth, partial redaction, partial validation) | Cap at Minor. Frame as "the new guard doesn't cover X", never as "this PR leaks X". |
| **pre-existing** | Identical at base; the PR is merely adjacent | Never blocking, however severe the underlying issue. Move to a separate "Pre-existing — worth filing separately" section below the findings. |

A pre-existing critical vulnerability is still a real vulnerability worth surfacing — but it is not a reason to request changes on a PR that didn't cause it and doesn't worsen it. Blocking an author on debt they inherited is how a review loses credibility.

The most common failure mode is reading *files* instead of the *diff*, producing a competent audit of the wrong unit of work. Watch for it especially when the PR is large, when it merges other branches in, or when you are reading whole files at `<headRefOid>` for context.

**Attribution work is a gate, not report content.** Run the base checks on every finding, but keep the commands, the SHAs, the extraction method, and the counts-of-counts *out* of the report body — the attribution tag in the header is the whole visible result. The reader is deciding what to fix, not auditing how you decided. Two exceptions, both narrow: state the method once at the top when the diff is large enough that coverage itself is in question (§ Guardrails), and produce the full evidence chain if the author or user challenges a finding. Verification that leaks into finding bodies is the main way a review turns from a work order into a legal brief.

**When delegating any part of a review to subagents**, this section is the part that must be in their brief verbatim — along with the smell baseline from §4 pasted in full for the Style and Architecture agents, since a subagent has no other access to it. Require every returned finding to carry its attribution tag and the base-check command that established it. Then spot-check the attribution on each Critical and Major before promoting it into your report — the one verification you always owe, even when you otherwise commit to a delegation. An unattributed finding is not usable: send it back or verify it yourself.

## 6. Output

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

**Hard length budget: one paragraph, 2–4 sentences, per finding — Critical included.** Severity buys attention, not words; the most severe finding is the one that most needs to be read in full. If a finding will not compress to a paragraph, that is a signal it is really two findings with different anchors — split it. Specifically, do **not** spend body text on: the base-check commands or verification method (see §5), a defense of the severity you assigned, an inventory of every affected file when a count and the two or three worst examples carry the same weight, or a restatement of what the PR's own commit messages already say. A reader who wants the evidence will ask; a reader who wants the fix should not have to dig for it.

Always leave a blank line after every `####` header and a blank line after the comment body before the next `####`. Multiple file:line references for one logical finding can be combined in the header (e.g., `#### \`path/file.py:271, :280\``).

Findings in this section are **introduced** or **improved-but-incomplete** only (see §5). Append ` — improved-but-incomplete` to the header of the latter so the author can see the PR gets credit for the direction. Pre-existing findings never appear here; they go in their own section below.

### Findings with no file:line anchor

Some real findings have no code location because their subject is the pull request itself: a description that misstates what the diff does, commits that bundle unrelated work, a base branch chosen wrong, behavior changed with no test file to point at, a decision record the project's own conventions require and the PR omits. These are legitimate and sometimes blocking — a description that hides the largest change in the diff can be the single most important thing in a review.

Give them the same severity tiers, the same attribution tag, and the same 2–4 sentence budget as any other finding. The only difference is the header, which names the subject instead of a location:

- `#### PR description vs. the diff` — the body is inaccurate, incomplete, or points away from the real change
- `#### Commit \`<short-sha>\`` — when one commit is the subject (scope creep, a message that misdescribes its own diff, unrelated work bundled in)
- `#### PR-level: <short subject>` — anything else (base branch, missing decision record, no tests added for changed behavior)

Two rules keep this from becoming an escape hatch. **If it can be anchored, anchor it** — a finding is not location-free merely because it spans many files; anchor to the worst example and give a count (`#### \`path/worst.ts:14\`` … "and 251 others"). And **never invent a plausible-looking `file:line` to satisfy the template** — an anchorless header is always correct where a fabricated citation is always fatal.

### Critical

#### `path/file.py:42`

<Self-contained review comment covering issue, impact, and suggested fix — one paragraph, 2–4 sentences. Reference other code locations as `file:line` when helpful.>

#### `path/other.py:88`

<Next finding — note the blank lines above and below separating each h4 block.>

### Major

#### `path/foo.py:12`

<...>

#### PR description vs. the diff

<Anchorless finding — same severity tier, same attribution, same 2–4 sentences. Use only when the subject is the PR itself, not a location in it.>

#### `path/bar.py:34`

<...>

### Minor

#### `path/baz.py:56`

<...>

### Nits

#### `path/qux.py:78`

<...>

## Pre-existing — worth filing separately
- <`file:line` — one line each. Real issues you hit while reading, identical at base. Not this PR's to fix; name them so they can become their own issues.>

## What looks good
- <1–3 bullets — call out genuinely good choices, not filler.>

## Open questions
- <questions to raise with the author, if any.>
```

Omit any subsection (Critical / Major / Minor / Nits / Pre-existing / What looks good / Open questions) that would be empty, rather than printing "(none)".

## Guardrails

- **Never** run any command that mutates the working tree, the index, or local branch refs: `git checkout`, `git switch`, `git reset`, `git restore`, `git clean`, `git merge`, `git rebase`, `gh pr checkout`. The user's currently-checked-out work must be untouched at the end of the review.
- Read-only git operations are fine: `git fetch origin pull/<num>/head` (writes only to the object database and `FETCH_HEAD`, not to the working tree or any local branch), `git show <ref>:<path>`, `git log`, `git diff <ref1>..<ref2>`, `git rev-parse`, `git cat-file`, `git ls-tree`.
- **Never** call `gh pr review`, `gh pr comment`, `gh pr merge`, `gh pr close`, `gh pr edit`, `gh pr ready`, or any other `gh` subcommand that writes to GitHub. Inspection only.
- **Never** invent file paths or line numbers. Every `file:line` reference must be a **file line number** (the line number in the post-change file), not a patch line number (a position within the diff text). Derive it from the `@@ -X,Y +N,M @@` hunk header per §3, or verify with `git show <headRefOid>:<path> | grep -n '<symbol>'` before citing. If you can't pin the exact line, cite the nearest symbol name with `~` (e.g., `path/file.py (near bad_debts)`) rather than guess a number.
- **Every citation must anchor to a line the PR actually changed.** A correct file line number is not sufficient — an `introduced` finding pointing at code that is byte-identical at base reads as a false blocker even when the underlying defect is real. When a change breaks code it did not touch (a key format changes and an untouched query stops matching; a signature changes and an untouched caller goes stale), anchor to the **changed line that causes it** and describe the unchanged site in prose. Verify with `git diff <baseRefOid> <headRefOid> -- <path>` that your cited line appears as `+` before writing the citation. If a finding resists this — the defect is a genuine omission with no changed line to point at, like a guard added to two of three handlers — anchor to the lines that *were* added and name the gap.
- **Never** assign a severity without establishing attribution per §5. A Critical or Major that turns out to be identical at base is a false blocker, and false blockers cost more credibility than missed nits. When in doubt, run the base check — it is one `git show` away.
- If the diff is too large to review thoroughly (rule of thumb: >2000 changed lines or >40 files), say so at the top of the report and review the highest-risk files first rather than skimming everything shallowly. Name the files you skipped so the user can ask for a follow-up pass. If the PR merges other branches in, say which commits are genuinely new versus inherited (`git log --oneline <baseRefOid>..<headRefOid>`) — inherited commits are `pre-existing` for attribution purposes even though they appear in the diff.
- If `gh` is not authenticated or the PR number does not exist, surface the error verbatim and stop.

## Related skills

This is the PR tier of a three-tier review family, all sharing the severity ladder, the output format, and the smell baseline:

- **`review-changes`** — the working-tree / staged diff against `HEAD`, with the same attribution model. The tight in-dev loop.
- **`code-review`** — all the code on the current branch, read broadly and architecturally, no attribution. Run before opening the PR.
- **`security-review`** — a deeper single-dimension pass when the Security findings warrant one.
