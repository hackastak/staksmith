---
name: audit-codebase
description: "Audit a whole codebase across every review dimension by fanning out the specialist reviewers and merging their findings into one ranked report — security, architecture, dead code, database, and language-idiomatic quality. Read-only, repo-scoped. Use to review an unfamiliar codebase end-to-end, or when the user says 'audit this repo', 'review the whole codebase', or invokes '/audit-codebase'."
category: "Code Review & Quality"
origin: Hackastak
---

Review a **whole codebase across every dimension at once** by orchestrating the specialist reviewers this plugin already ships, then merging their output into a **single deduped, severity-ranked report**. This is the front door for "review a new codebase": the other review skills each cover one axis or one unit of change; `audit-codebase` runs the full panel over the entire repo and hands back one prioritized list of what to fix first.

This is **read-only inspection**: never modify files, never commit, never push, never post anywhere. Every sub-agent it dispatches inherits the same constraint — findings are the deliverable, remediation is a separate, deliberately-reviewed step.

**Which review skill is this?**

| Skill | Unit | Dimensions | When |
|---|---|---|---|
| `review-changes` | working-tree diff | all, one context | tight in-dev loop |
| `code-review` | current branch | all six, one context | before push / PR |
| `review-github-pr` | a GitHub PR | all, one context | reviewing a PR |
| `security-scan` | whole repo | security only | security-auditing a repo |
| **`audit-codebase`** | **whole repo** | **all, fanned out to specialists** | **reviewing an unfamiliar codebase end-to-end** |

Reach for `audit-codebase` when the unit is the **whole repository** and you want **every dimension** covered with specialist depth — not the single-context breadth of `code-review` and not a single axis like `security-scan`. For one axis, call that axis's skill directly; this skill is the coordinator that runs them together and reconciles the results.

## 1. Scope

The default unit is **the entire repository**. Establish the surface before dispatching anything:

- `git ls-files | wc -l` and a top-level `ls` — size and shape of the tree.
- Detect languages and ecosystems from manifests (`package.json`, `pyproject.toml`/`requirements*.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `pom.xml`, `*.csproj`) and whether there's a database layer (migrations, ORM models, `.sql` files).
- Locate the high-risk surface: auth, API/route handlers, DB access, file uploads, payments, webhooks, deserialization, subprocess/shell calls, template rendering, secret reads.
- **Probe build health once, up front.** Run the project's compile/build check (`go build ./...`, `tsc --noEmit`, `cargo check`, `mvn -q compile`, `python -m py_compile`/import check, etc.) and note whether the tree compiles. A red build blocks every downstream static-analysis tool (`vet`, linters, type-checkers, `govulncheck`), so **every pass needs to know** — otherwise each one independently rediscovers the same breakage and burns tokens on it. Also run `git status --short` to record whether a break is committed or uncommitted work-in-progress (a WIP break is a working-tree problem, not a shipped defect — check HEAD builds via `git stash`/`git archive HEAD` before calling it Critical). Carry the result into the shared brief.

If the user named a narrower scope (a directory, a service), honour it and say so at the top of the report. To audit only what a branch changed, take the file list from `git diff --name-only <base>...HEAD` and pass it to every pass — but prefer `code-review` for a pure branch review; `audit-codebase` earns its cost on whole-repo breadth.

Read-only git only: `git ls-files`, `git log`, `git diff`, `git show`, `git status`.

## 2. Build the shared context brief

The sub-agents run in clean contexts and cannot see what you've read, so gather once what every one of them needs, and paste it into each brief:

- **Conventions:** `CLAUDE.md` (root and nested), linter/formatter configs, `CONTRIBUTING.md`/`CODING_STANDARDS.md`, `CONTEXT.md` (domain glossary), and accepted decisions in `docs/adr/`. Code that contradicts an accepted ADR is a Major finding at minimum — either the code is wrong or the ADR needs superseding.
- **Scope:** the file list / directories in scope, and the language + ecosystem findings from step 1.
- **The high-risk surface** from step 1, so each pass spends its attention there first.
- **Build health** from step 1: whether the tree compiles and, if not, the exact breakage and whether it's committed or uncommitted WIP. This tells every pass that static analysis may be partial, saves each from rediscovering the same break, and lets the correctness pass root-cause it once instead of six times.

## 3. Select and dispatch the specialist passes

Pick the passes that match the stack, then **dispatch them all in a single message** so their contexts stay clean and they run concurrently. Each pass is a sub-agent; the mapping:

| Dimension | Agent | Note |
|---|---|---|
| Correctness & general quality | `code-reviewer` | always |
| Security (incl. dependency CVEs, OWASP) | `security-reviewer` | always; **read-only brief required** |
| Architecture & module depth | `architect` | always |
| Dead code, duplication, cleanliness | `refactor-cleaner` | always; **read-only brief required** |
| Database (queries, schema, migrations) | `database-reviewer` | only if a DB layer was detected; **read-only brief required**; **engine-fit caveat required** (see below) |
| Language-idiomatic | `python-reviewer` / `go-reviewer` / `rust-reviewer` / `cpp-reviewer` | one per detected language |
| Performance | `performance-reviewer` | N+1, complexity, blocking I/O on async paths, unbounded work, missing pagination/caching, retry storms, bundle/render cost |
| Test coverage & quality | `general-purpose` (briefed with the `test-audit` dimensions) | optional — when the repo has a test suite worth assessing or the user asks; untested critical paths, weak/tautological tests, mock-the-internals |

**Every brief must contain**, pasted in full (sub-agents can't read your context or these files):

1. The shared context from step 2 (conventions, scope, high-risk surface).
2. The dimension this pass owns and the instruction to stay strictly within it — overlap is reconciled by you in step 4, not by the agent narrowing itself.
3. **READ-ONLY, non-negotiable:** report findings only; do not edit, write, or run any mutating command. This is essential for `security-reviewer`, `database-reviewer`, and `refactor-cleaner`, whose agents *can* modify files — the brief must forbid it explicitly.
   - **Database-pass engine-fit caveat (required).** The `database-reviewer` agent is PostgreSQL/Supabase-specialized. When the repo uses a different engine (SQLite, MySQL, Mongo, DynamoDB, …), the brief MUST name the actual engine and instruct the agent to apply general relational/SQL principles — parameterization, indexing, transaction correctness, migration safety, N+1, connection handling — while **ignoring Postgres/Supabase-only advice** (RLS, pg extensions, `pg_stat_*`, etc.), and to record the fit as a Coverage line. Without this, a non-Postgres repo gets Postgres-shaped noise and the pass reads as more authoritative than it is.
4. The output contract: every finding tagged **Critical / Major / Minor / Nit**, each with a verified `file:line` (verify with `grep -n` before citing — never invent a path or line) and a one-paragraph body with the fix. A finding with no location gets a subject header instead.

Cap the fan-out to the passes that apply. If the repo is large enough that a pass would be shallow, say so in that pass's brief and have it go highest-risk-first, naming what it skipped.

## 4. Merge, dedupe, and verify

The passes overlap by design — `security-reviewer` and `code-reviewer` will both flag the same injection; `architect` and `refactor-cleaner` will both notice the same god-module. Reconcile before reporting:

- **Dedupe by `file:line` + root cause.** One underlying defect = one finding, tagged with every dimension that surfaced it (`Security · Correctness`). Don't print the same issue three times.
- **Reconcile severity.** When two passes disagree, take the higher — then sanity-check it against exploitability/impact in *this* codebase, not the label.
- **Spot-check every Critical and Major yourself** before promoting it. Re-read the cited line. An unverified Critical is worse than a missed one; a fabricated `file:line` is fatal. Drop or downgrade anything you can't confirm.
- **Rank by real impact**, not by which pass shouted loudest — a Major auth gap on a public endpoint outranks a Critical-labelled CVE in an unreachable dev dependency.

## 5. Output

Emit a single inline markdown report. Do not save it to a file, and do not post it anywhere.

```
# Codebase audit: <repo or scope>

**Scope:** <n files / dir / "whole repo"> · **Passes:** <which reviewers ran; note any skipped and why>

## Summary
**Verdict:** Ship-blocking issues | Fix before relying on it | Solid — minor cleanup

<One short paragraph, 1–3 sentences: the single most important thing to know about
this codebase and the why behind the verdict. Not a recap of the findings below.>

## Findings

### Critical

#### `path/file.ts:42` · Security · Correctness

<Self-contained finding: what it is, why it matters, the fix. One paragraph, 2–4
sentences. The dimension tags after the location say which pass(es) surfaced it.>

### Major

#### `path/db.py:88` · Database

<...>

### Minor

#### `path/util.go:56` · Performance

<...>

### Nits

#### `path/foo.ts:12` · Style

<...>

## Coverage
- <One line per pass: ran clean / n findings / skipped (why) / tooling unavailable.
  Silent truncation reads as "all clear" when it isn't — name what was not covered.>

## Architectural notes
- <1–3 observations about the shape of the codebase as a whole — a module wanting
  deepening, a seam not earning its keep, a recurring smell. From the architect pass.>

## What looks good
- <1–3 genuine strengths across dimensions. Not filler.>
```

**Formatting rules, non-negotiable:**

- Each finding is its own `####` subsection, **never** a bullet-list item — bullet findings collapse together in a terminal. Blank line after every `####` header and after every body.
- The `####` header is the backtick-wrapped `file:line`, followed by ` · ` and the dimension tag(s) that surfaced it. The body is prose written to the author — no `**Comment:**` prefix, no Issue/Why/Fix labels; the fix goes inside the paragraph.
- **Hard length budget: one paragraph, 2–4 sentences per finding, Critical included.** Severity buys attention, not words. If a finding won't compress, it's two findings — split it.
- Multiple locations for one logical finding combine in the header: `#### \`path/file.ts:271, :280\` · Security`.
- Findings with no single location get a subject header (`#### App-level: no rate limiting on auth endpoints · Security`). But **if it can be anchored, anchor it** to the worst example with a count. **Never invent a plausible `file:line`** — an anchorless header is always correct, a fabricated citation is always fatal.
- Omit any empty section rather than printing "(none)".

## Guardrails

- **Read-only, end to end.** This skill and every sub-agent it dispatches only read, run read-only analysis tooling, and report. Never run anything that mutates the working tree, index, or refs. The `security-reviewer`, `database-reviewer`, and `refactor-cleaner` agents *can* edit — their briefs must forbid it, and you must not promote any change they made.
- **Findings are the deliverable; fixes are not.** Hand the report back and let the user decide what to remediate.
- **Never invent file paths, line numbers, CVE ids, or tool output.** Verify every citation and spot-check every Critical/Major yourself before it reaches the report.
- **Don't let breadth hide gaps.** If a pass was skipped, ran shallow, or its tooling wasn't installed, the Coverage section must say so. An audit that silently skipped the database layer is worse than one that flags "DB layer not reviewed."
- A repo too large to audit thoroughly gets a note at the top and a highest-risk-first pass; name what was skipped so the user can ask for a follow-up.

## Related skills

- **`code-review`** — the same dimensions in one context over a branch; use it for a branch, not a whole unfamiliar repo.
- **`security-scan`** — the security axis alone, run inline; `audit-codebase` dispatches the `security-reviewer` agent for the same coverage as one pass among many.
- **`improve-codebase-architecture`** — a deeper, interactive architecture pass than the `architect` sub-agent gives here.
- **`review-changes`** / **`review-github-pr`** — the diff and PR tiers of the review family.
- **`adr-standard`** — what to do when a finding collides with an accepted ADR.
