---
description: Audit a whole codebase across every review dimension by fanning out the specialist reviewers and merging their findings into one ranked report — correctness, security, architecture, dead code, database, and language-idiomatic quality. Read-only, repo-scoped.
---

# Audit Codebase

Invoke the **`audit-codebase`** skill to review an unfamiliar codebase **end-to-end**: it orchestrates the specialist reviewers this plugin ships and merges their output into one deduped, severity-ranked report. This is the front door for "review a new codebase."

## What This Command Does

1. **Scope** the repo (languages, ecosystems, DB layer, high-risk surface).
2. **Build a shared context brief** — conventions, ADRs, scope, high-risk surface — to paste into every pass.
3. **Fan out the specialist passes in one message** so they run concurrently in clean contexts: `code-reviewer`, `security-reviewer`, `architect`, `refactor-cleaner`, `database-reviewer` (if a DB layer exists), the matching language reviewer(s), and a performance pass. Mutation-capable agents are briefed strictly read-only.
4. **Merge, dedupe, and verify** — one defect = one finding tagged with every dimension that surfaced it; spot-check every Critical/Major.
5. **Emit one severity-ranked report** with a per-pass coverage section.

## When to Use

- Reviewing a codebase you didn't write, before trusting or shipping it.
- You want **every dimension** with specialist depth over the **whole repo** — broader than `/security-scan` (one axis) and a bigger unit than `/code-review` (one branch).

## Usage

```text
/audit-codebase              # whole repo
/audit-codebase apps/api     # scope to a directory
```

## Output

A single inline report: verdict, findings tiered **Critical / Major / Minor / Nit** each anchored to `file:line · Dimension`, a **Coverage** section naming which passes ran / were skipped / lacked tooling, architectural notes, and genuine strengths. Read-only — never edits code.

## Related

- Skill: `skills/audit-codebase/SKILL.md`
- Single-axis / smaller unit: `/security-scan` · `/code-review` · `/review-changes`
- Deeper architecture pass: `skills/improve-codebase-architecture/`
