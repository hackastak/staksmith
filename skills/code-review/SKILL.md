---
name: code-review
description: "Review all the code on the current branch — the whole state of what this branch has built, read broadly and architecturally. Read-only. Use before pushing or opening a PR, or when the user says 'review this branch', 'review my work', or invokes '/code-review'."
category: "Code Review & Quality"
origin: Hackastak
---

Review **the code on the current branch**: not a diff, but the state of the codebase this branch has produced. This is the broad, architectural tier of the review family — run it before you push, when the shape of the whole change matters more than any individual hunk.

This is **read-only inspection**: never modify files, never commit, never push, never post anywhere. Read and report.

**Which review skill is this?**

| Skill | Unit of review | Attribution | When |
|---|---|---|---|
| `review-changes` | the working-tree / staged diff vs `HEAD` | yes — introduced / incomplete / pre-existing | tight in-dev loop |
| **`code-review`** | **all code on the current branch** | **no** | **before push / before opening a PR** |
| `review-github-pr` | an existing GitHub PR | yes | reviewing someone's PR |

## 1. Scope the branch

Establish what this branch is and what it built:

- `git rev-parse --abbrev-ref HEAD` — the branch name.
- `git merge-base HEAD <base>` — where it diverged. Default `<base>` to `main` (or `master`); if the user named a base, use theirs. If the current branch *is* the base branch, ask what to review against before going further.
- `git log <base>..HEAD --oneline` — the commits, which tell you what the branch was trying to do.
- `git diff --name-only <base>...HEAD` — the files the branch touched. **This is the scoping list, not the review unit.**

Read those files **in full**, at their current state — plus their immediate neighbours (callers, the module they sit in, the tests that cover them). You are reviewing code as it now stands, so a problem is a problem regardless of which commit introduced it. There is no diff here and therefore **no attribution** — do not tag findings introduced/pre-existing, and do not soften a finding because an earlier commit on the branch caused it. The branch is one unit of work.

Also check for uncommitted work (`git status --short`). If the working tree is dirty, say so at the top of the report and state whether you included it — reviewing a branch while unreviewed edits sit uncommitted is a real gap in coverage.

## 2. Find the project's conventions

Look for what the repo says about itself before reviewing style:

- `CLAUDE.md` at the root, and any nested `CLAUDE.md` near the changed files
- Linter and formatter configs (`.flake8`, `pyproject.toml`, `.eslintrc*`, `tsconfig.json`, `biome.json`, `package.json`, `.editorconfig`)
- `CONTRIBUTING.md`, `CODING_STANDARDS.md`, `.github/pull_request_template.md`
- `CONTEXT.md` — the domain glossary. Names in the code should match it; a divergence between the glossary and the code is a legitimate finding.
- `docs/adr/` — accepted architectural decisions. Code that contradicts an accepted ADR is a **Major** finding at minimum: either the code is wrong or the ADR needs superseding, and the review's job is to force that choice into the open.

Treat what you find as authoritative for style and process.

## 3. Find the spec (optional axis)

If a spec source exists, add a **Spec** axis to the review: does the code faithfully implement what was asked for? Look in this order and stop at the first hit:

1. A path or issue reference the user passed as an argument.
2. Issue references in the branch's commit messages (`#123`, `Closes #45`) — fetch via `docs/agents/issue-tracker.md`.
3. `1. Projects/<Project>/spec.md` in the vault (the default tracker), or a spec under `docs/`, `specs/`, or `.scratch/` matching the branch name.

If nothing turns up, skip the axis and say so in one line. Do not ask the user to produce a spec — the review is still worth running without one.

The Spec axis reports three things: requirements that are **missing or partial**, behaviour in the code that **wasn't asked for** (scope creep), and requirements that look implemented but where the **implementation looks wrong**. Quote the spec line for each.

## 4. Review across six dimensions

Surface findings tagged **Critical / Major / Minor / Nit**, each with a concrete `file:line` reference. **Never invent a path or a line number** — verify with `grep -n '<symbol>' <path>` before citing. If you can't pin the exact line, cite the nearest symbol (`path/file.py (near bad_debts)`) rather than guessing.

1. **Correctness & logic** — bugs, edge cases, off-by-one, race conditions, missing or wrong error handling, incorrect null handling, broken control flow, misuse of async/await, leaked resources, type mismatches.
2. **Security** — injection (SQL/command/template/HTML), unsafe deserialization, secrets in code, authn/authz gaps, SSRF, path traversal, insecure defaults, unvalidated input crossing a trust boundary, risky dependency additions.
3. **Style & conventions** — adherence to what step 2 turned up. Call out anything that would fail the configured linters, or that diverges from patterns established elsewhere in the same module.
4. **Test coverage** — for each non-trivial code path the branch adds or changes, is there a test? Flag changed behaviour with no test. Flag tests that assert weakly (only that a call didn't throw), that are tautological (the expected value recomputed the way the code computes it), or that mock internal collaborators rather than testing at a seam.
5. **Architecture** — this is where the whole-branch tier earns its keep. Does the change respect module boundaries? Are the modules **deep** — real behaviour behind a small interface — or shallow pass-throughs? Are new seams justified by something that actually varies across them? Are cross-cutting concerns in the right layer? Does anything contradict an ADR or an invariant established elsewhere? Apply the **[smell baseline](SMELLS.md)** here and under Style — the twelve smells, the repo-overrides rule, and the skip-what-tooling-enforces exclusion.
6. **Performance** — N+1 queries, unbounded loops or recursion, blocking I/O on async paths, missing pagination on large result sets, hot-path allocations, missing caching where neighbouring code caches similar work, retry storms.

If a dimension has nothing material to report, say so explicitly — silence is not a clean bill of health.

**Delegating.** For a large branch, fan the dimensions out to `general-purpose` sub-agents in a single message so their contexts stay clean, then aggregate. Every sub-agent brief must include the file list, the conventions found in step 2, and — for the Architecture and Style agents — the smell baseline pasted in full, since a sub-agent cannot read `SMELLS.md`. Require a `file:line` on every returned finding, and spot-check each Critical and Major yourself before promoting it into the report. An unverified Critical is worse than a missed one.

## 5. Output

Emit a single inline markdown report. Do not save it to a file, and do not post it anywhere.

```
# Branch review: <branch> (<n> commits since <base>)

**Scope:** <n> files · **Spec:** <path or "none found">

## Summary
**Verdict:** Ready to push | Needs work | Needs discussion

<One short paragraph, 1–3 sentences: the single most important thing to know about
this branch, and the *why* behind the verdict. Not a recap of the findings below.>

## Findings

### Critical

#### `path/file.py:42`

<Self-contained review comment: what the issue is, why it matters, the suggested fix.
One paragraph, 2–4 sentences.>

### Major

#### `path/foo.py:12`

<...>

### Minor

#### `path/baz.py:56`

<...>

### Nits

#### `path/qux.py:78`

<...>

## Spec
- <Missing / partial / unasked-for / wrong, each quoting the spec line. Omit this
  section entirely if no spec was found.>

## Architectural notes
- <1–3 observations about the shape of the branch as a whole — recurring smells,
  a module that wants deepening, a seam that isn't earning its keep. This is the
  section that distinguishes a branch review from a diff review; don't pad it,
  but don't skip it when there's something real to say.>

## What looks good
- <1–3 bullets. Genuinely good choices, not filler.>

## Open questions
- <Anything you'd want answered before this ships.>
```

**Formatting rules, non-negotiable:**

- Each finding is its own `####` subsection, **never** a bullet-list item — bullet findings collapse together in a terminal and become unreadable. Leave a blank line after every `####` header and after every body.
- The `####` header is the backtick-wrapped `file:line`. The body is prose written to the author — no `**Comment:**` prefix, no separate Issue/Why/Fix labels.
- **Hard length budget: one paragraph, 2–4 sentences per finding, Critical included.** Severity buys attention, not words. If a finding won't compress to a paragraph, it is really two findings with different anchors — split it. Don't spend body text defending the severity you assigned, inventorying every affected file when a count plus the two worst examples carries the same weight, or restating what the commit messages already say.
- Multiple locations for one logical finding combine in the header: `#### \`path/file.py:271, :280\``.
- Some real findings have no code location — a branch that bundles unrelated work, a decision the repo's conventions require recording and the branch omits, behaviour changed with no test file to point at. Give them the same tiers and the same budget, with a header naming the subject instead of a location (`#### Branch-level: <short subject>`). But **if it can be anchored, anchor it** — spanning many files is not the same as having no location; anchor to the worst example and give a count. **Never invent a plausible-looking `file:line`** to satisfy the template: an anchorless header is always correct, a fabricated citation is always fatal.
- Omit any empty section rather than printing "(none)".

## Guardrails

- **Never** run a command that mutates the working tree, the index, or branch refs: `git checkout`, `git switch`, `git reset`, `git restore`, `git clean`, `git merge`, `git rebase`, `git commit`, `git push`. Read-only git is fine: `git log`, `git diff`, `git show`, `git status`, `git rev-parse`, `git merge-base`.
- **Never** invent file paths or line numbers. Verify with `grep -n` before citing.
- **No attribution tags here.** If you find yourself wanting to write "pre-existing", you want `review-changes` instead — that skill reviews a diff, where the distinction is real.
- A branch too large to review thoroughly (rule of thumb: >2000 changed lines or >40 files) gets a note at the top of the report and a highest-risk-first pass. **Name the files you skipped** so the user can ask for a follow-up. Silent truncation reads as "I covered everything" when you didn't.
- Findings are the deliverable; fixes are not. Don't edit code as part of this skill — hand the report back and let the user decide. (`simplify` is the skill that applies quality fixes.)

## Related skills

- **`review-changes`** — the same ladder and format over a working-tree diff, with attribution.
- **`review-github-pr`** — the PR tier.
- **`codebase-design`** — deep-module vocabulary for the Architecture dimension.
- **`security-review`** — a deeper single-dimension pass when the Security findings warrant one.
- **`adr-standard`** — what to do when the code and an accepted ADR disagree.
