---
name: review-changes
description: "Review only the changes in the working tree — the staged and unstaged diff against HEAD. Read-only, with attribution so inherited debt doesn't block your own work. Use as the tight in-dev loop, or when the user says 'review my changes', 'review the diff', or invokes '/review-changes'."
category: "Code Review & Quality"
origin: Hackastak
---

Review **the changes**, not the codebase: the staged and unstaged diff against `HEAD`. This is the tight in-dev tier — run it after each committable block of work, before handing back for the commit.

This is **read-only inspection**: never modify files, never stage, never commit. Read and report.

**Which review skill is this?**

| Skill | Unit of review | Attribution | When |
|---|---|---|---|
| **`review-changes`** | **the working-tree / staged diff vs `HEAD`** | **yes** | **tight in-dev loop** |
| `code-review` | all code on the current branch | no | before push / before opening a PR |
| `review-github-pr` | an existing GitHub PR | yes | reviewing someone's PR |

## 1. Capture the diff

- `git status --short` — what's staged, what isn't, what's untracked.
- `git diff HEAD` — the full diff, staged and unstaged together. This is the review unit.
- `git diff --name-only HEAD` plus `git ls-files --others --exclude-standard` — the file list, including new untracked files.

**Untracked files are part of the change.** A new file that hasn't been `git add`ed still doesn't appear in `git diff` — read it in full and review it as entirely introduced code. Missing them is the most common way this review comes back clean on work that isn't.

If the diff is empty, say so and stop. Don't fall back to reviewing the branch — that's `code-review`.

When three lines of context aren't enough to judge a hunk, widen it: `git diff -U15 HEAD -- <path>`, or read the file at `HEAD` with `git show HEAD:<path>` to see what the change is changing.

## 2. Find the project's conventions

- `CLAUDE.md` at the root, and any nested `CLAUDE.md` near the changed files
- Linter and formatter configs (`.flake8`, `pyproject.toml`, `.eslintrc*`, `tsconfig.json`, `biome.json`, `package.json`, `.editorconfig`)
- `CONTRIBUTING.md`, `CODING_STANDARDS.md`
- `CONTEXT.md` — the domain glossary. New names should match it.
- `docs/adr/` — accepted decisions. A change contradicting an accepted ADR is **Major** at minimum: either the change is wrong or the ADR needs superseding, and this review's job is to force that choice into the open.

Treat what you find as authoritative for style and process.

## 3. Review across six dimensions

Surface findings tagged **Critical / Major / Minor / Nit**, each with a concrete `file:line` reference in the *post-change* file. **Never invent a path or a line number** — verify with `grep -n '<symbol>' <path>` before citing. Line numbers you read off the diff text are patch positions, not file lines; they must never appear in a citation.

1. **Correctness & logic** — bugs, edge cases, off-by-one, race conditions, missing or wrong error handling, incorrect null handling, broken control flow, misuse of async/await, leaked resources, type mismatches.
2. **Security** — injection, unsafe deserialization, secrets in code, authn/authz gaps, SSRF, path traversal, insecure defaults, unvalidated input crossing a trust boundary, risky dependency additions.
3. **Style & conventions** — adherence to what step 2 turned up, and to the patterns of the surrounding module.
4. **Test coverage** — for each non-trivial path the diff adds or changes, is there a test? Flag changed behaviour with no test. Flag tests that assert weakly, that are tautological (expected value recomputed the way the code computes it), or that mock internal collaborators rather than testing at a seam.
5. **Architecture** — does the change respect module boundaries? Is the new code a **deep** module or a shallow pass-through? Is a new seam justified by something that actually varies across it? Apply the **smell baseline** (the twelve smells in the `code-review` skill's `SMELLS.md`) here and under Style: the repo's documented standards override it, every smell is a judgement call, and skip anything tooling already enforces.
6. **Performance** — N+1 queries, unbounded loops, blocking I/O on async paths, missing pagination, hot-path allocations, missing caching where neighbouring code caches, retry storms.

If a dimension has nothing material to report, say so explicitly.

## 4. Attribute every finding before assigning severity

You are reviewing **a diff**, not a codebase. A file appearing in the diff does not make everything in it this change's responsibility. Before a finding gets a severity, establish which of three states it's in by checking `HEAD`:

- `git show HEAD:<path> | grep -n '<symbol>'` — does the problem already exist at `HEAD`?
- `git diff HEAD -- <path>` — did these specific lines actually change?

| Attribution | Meaning | Severity treatment |
|---|---|---|
| **introduced** | New code, or existing code this change turned into a defect | Full severity ladder. Only these can be Critical. |
| **improved-but-incomplete** | The change makes this area better but leaves a gap — partial validation, partial redaction, a guard added to two of three handlers | Cap at Minor. Frame as "the new guard doesn't cover X", never "this change leaks X". |
| **pre-existing** | Identical at `HEAD`; the change is merely adjacent | Never blocking. Move to a separate "Pre-existing" section below the findings. |

A pre-existing critical vulnerability is still a real vulnerability worth surfacing — but it is not a reason to stop work that didn't cause it and doesn't worsen it. **This is the point of attribution in the in-dev loop: it keeps you from blocking yourself on debt you inherited.**

The most common failure mode is reading *files* instead of the *diff*, producing a competent audit of the wrong unit of work. Watch for it especially when you've been reading whole files for context.

**Attribution work is a gate, not report content.** Run the base checks on every finding, but keep the commands, the SHAs, and the method *out* of the report body — the attribution tag in the header is the whole visible result. The reader is deciding what to fix, not auditing how you decided. Produce the evidence chain only if a finding is challenged.

**Every citation must anchor to a line the change actually touched.** A correct file line number isn't sufficient — an `introduced` finding pointing at code byte-identical at `HEAD` reads as a false blocker even when the underlying defect is real. When a change breaks code it didn't touch (a key format changes and an untouched query stops matching), anchor to the **changed line that causes it** and describe the unchanged site in prose.

**When delegating to sub-agents**, this section goes in their brief verbatim, along with the smell baseline pasted in full. Require every returned finding to carry its attribution tag and the check that established it, and spot-check each Critical and Major yourself before promoting it.

## 5. Output

Emit a single inline markdown report. Do not save it to a file.

```
# Changes review: <n> files (+<add>/-<del>)

**Working tree:** <n staged> staged, <n unstaged> unstaged, <n untracked> untracked

## Summary
**Verdict:** Ready to commit | Needs work | Needs discussion

<One short paragraph, 1–3 sentences: the single most important thing to know, and the
*why* behind the verdict. Not a recap of the findings below.>

## Findings

### Critical

#### `path/file.py:42`

<Self-contained comment: what the issue is, why it matters, the suggested fix.
One paragraph, 2–4 sentences.>

### Major

#### `path/foo.py:12 — improved-but-incomplete`

<...>

### Minor

#### `path/baz.py:56`

<...>

### Nits

#### `path/qux.py:78`

<...>

## Pre-existing — worth filing separately
- <`file:line` — one line each. Real issues you hit while reading, identical at HEAD.
  Not this change's to fix; name them so they can become their own tickets.>

## What looks good
- <1–3 bullets. Genuinely good choices, not filler.>

## Open questions
- <Anything you'd want answered before this is committed.>
```

**Formatting rules, non-negotiable:**

- Each finding is its own `####` subsection, **never** a bullet-list item — bullet findings collapse together in a terminal and become unreadable. Blank line after every header and after every body.
- The `####` header is the backtick-wrapped `file:line`. Append ` — improved-but-incomplete` to the header of those findings so the change gets visible credit for the direction. Findings in the main list are **introduced** or **improved-but-incomplete** only; pre-existing ones go in their own section.
- The body is prose written to the author — no `**Comment:**` prefix, no separate Issue/Why/Fix labels.
- **Hard length budget: one paragraph, 2–4 sentences per finding, Critical included.** Severity buys attention, not words. If a finding won't compress to a paragraph, it's really two findings with different anchors — split it. Don't spend body text on the base-check commands, a defence of the severity you assigned, or a restatement of what the code obviously does.
- Multiple locations for one logical finding combine in the header: `#### \`path/file.py:271, :280\``.
- **Never invent a plausible-looking `file:line`.** If you can't pin the line, cite the nearest symbol (`path/file.py (near bad_debts)`).
- Omit any empty section rather than printing "(none)".

## Guardrails

- **Never** run a command that mutates the working tree, the index, or branch refs: `git add`, `git commit`, `git checkout`, `git switch`, `git reset`, `git restore`, `git clean`, `git stash`. The user's work must be exactly as they left it when the review ends. Read-only git only: `git status`, `git diff`, `git show`, `git log`, `git ls-files`.
- **Never** assign a severity without establishing attribution. A Critical that turns out to be identical at `HEAD` is a false blocker, and false blockers cost more credibility than missed nits. When in doubt, run the check — it's one `git show` away.
- Findings are the deliverable; fixes are not. Don't edit code as part of this skill. (`simplify` is the skill that applies quality fixes.)

## Related skills

- **`implement`** — calls this skill at step 4, before handing back for the commit.
- **`code-review`** — the whole-branch tier, no attribution.
- **`review-github-pr`** — the PR tier.
- **`draft-commit`** — the natural next step once the review comes back clean.
