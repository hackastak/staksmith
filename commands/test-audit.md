---
description: Audit an existing test suite for coverage gaps and test quality — untested critical paths, weak assertions, tautological tests, and tests that mock internal collaborators instead of testing at a seam. Read-only, whole-repo or diff-scoped.
---

# Test Audit

Invoke the **`test-audit`** skill to assess a codebase's **existing** tests: where the code is under-tested, and where the tests that exist don't actually test anything. The read-only counterpart to the TDD family — coverage percentage is the start of the question, not the answer.

## What This Command Does

1. **Scope** the repo (or a directory/diff), detect the test framework, and map test files to source — which modules have tests, which have none, where the risk lives vs. where the tests cluster.
2. **Measure coverage** with the project's tooling (`go test -cover`, `pytest --cov`, `cargo llvm-cov`, `jest --coverage`, …), then look past the number.
3. **Walk two axes**: coverage gaps (untested critical paths, zero-test packages, happy-path-only) and test quality (weak assertions, tautological tests, mock-the-internals, assertion-free/skipped tests, flaky-by-construction, brittle coupling, coverage padding).
4. **Emit a risk-ranked report** (Critical / Major / Minor / Nit) with a coverage map and an explicit coverage-gaps section.

## When to Use

- Judging whether to trust an unfamiliar repo's tests.
- A high coverage number you suspect is hollow.
- Deciding where to spend testing effort before a release or refactor.

## Usage

```text
/test-audit                  # whole repo
/test-audit internal/embed   # scope to a directory
/test-audit diff main        # only what the current branch changed vs main
```

## Output

A single inline report: verdict, findings tiered **Critical / Major / Minor / Nit** each anchored to a `file:line` (or an untested source path), a **Coverage map** turning the % into a decision, a coverage-gaps section, and genuine strengths. Read-only — never edits tests.

## Related

- Skill: `skills/test-audit/SKILL.md`
- Write the missing tests: `/tdd` · `/go-test` · `/python-testing` · `/rust-test`
- Broader / composes it: `/code-review` (diff test dimension) · `/audit-codebase` (dispatches it as a pass)
