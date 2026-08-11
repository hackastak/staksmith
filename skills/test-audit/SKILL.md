---
name: test-audit
description: "Audit an existing test suite for coverage gaps and test quality — untested critical paths, weak assertions, tautological tests, and tests that mock internal collaborators instead of testing at a seam. Read-only, whole-repo or diff-scoped. Use to assess a codebase's tests, or when the user says 'audit the tests', 'are these tests any good', 'where are we under-tested', or invokes '/test-audit'."
category: "Testing & TDD"
origin: Hackastak
---

Audit an **existing** test suite: where is the code under-tested, and where are the tests that exist not actually testing anything? This is the read-only counterpart to the TDD family — those skills write tests first for new code; `test-audit` assesses the tests a repo already has. Coverage percentage is the start of the question, not the answer: a suite at 90% can still be worthless if the assertions are weak and the criticial paths are the uncovered 10%.

This is **read-only inspection**: read code and tests, run read-only coverage tooling, and report. Never edit tests, never commit, never run anything that mutates state.

**Which testing skill is this?**

| Skill | Unit | Direction | When |
|---|---|---|---|
| `tdd` / `go-test` / `python-testing` / `rust-test` / … | new code | write tests **first** | building a feature |
| `code-review` (test dimension) | a branch diff | assess changed code's tests | before push / PR |
| **`test-audit`** | **the whole existing suite** | **assess what's already there** | **judging or improving a repo's tests** |

Reach for `test-audit` when the tests already exist and the question is whether to trust them. For writing new tests, use the TDD skills; for the test coverage of a specific change, `code-review` already carries that dimension.

## 1. Scope

Default unit is the **whole repository**; honour a narrower scope, and take a diff's file list from `git diff --name-only <base>...HEAD` when the user wants only what changed.

- Detect the stack and **test framework** (`go test`, pytest, cargo test, jest/vitest, PHPUnit, JUnit, …) and how the project runs and measures tests (check `CLAUDE.md`, `CONTRIBUTING.md`, `Makefile`, CI config, `package.json` scripts).
- Map **test files to source**: which packages/modules have tests, which have none, and where the critical-path code lives (auth, money, data mutation, the core pipeline) versus where the tests actually cluster. A mismatch — heavy tests on trivial code, none on the risky code — is the finding that matters most.
- Read-only git only.

## 2. Measure coverage (then look past the number)

Run the project's coverage tooling if present; **skip cleanly and say so** when it's absent — never invent a number. All read-only.

| Stack | Read-only coverage command |
|---|---|
| Go | `go test -cover ./...` / `-coverprofile` + `go tool cover` |
| Python | `pytest --cov` (coverage.py) |
| Rust | `cargo llvm-cov` / `cargo tarpaulin` |
| JS/TS | `jest --coverage` / `vitest run --coverage` / `nyc` |
| PHP | `phpunit --coverage-text` |
| JVM | JaCoCo report if generated |

Coverage tells you what code *ran* during tests — not whether anything was *asserted* about it. Use it to find the untested critical paths, then judge quality directly by reading the tests. A high number with weak assertions is worse than an honest low one, because it buys false confidence.

## 3. Walk the two axes

Verify every `file:line` with `grep -n` before citing — **never invent a path or line number**.

### Coverage gaps (what isn't tested)
- **Untested critical paths** — auth/authz, payments, data writes/migrations, the core pipeline, error/failure handling — code where a bug is expensive, with no test behind it. Rank these first, by the cost of the code being wrong, not by coverage delta.
- **Packages/modules with zero tests** — especially ones other code depends on.
- **Happy-path-only** — the success case is tested but error paths, edge cases, boundaries, and empty/nil inputs are not.
- **Untested behaviour changes** — a public API with tests that only exercise one shape of input.

### Test quality (whether the existing tests mean anything)
- **Weak assertions** — a test that only asserts a call didn't panic/throw, or asserts truthiness, without checking the actual result.
- **Tautological tests** — the expected value is computed the same way the code computes it, so the test passes by construction and can't catch a wrong formula. (Watch for the code's own function reused to build the expectation.)
- **Mock-the-internals** — tests that mock internal collaborators of the unit instead of testing at a real seam, so they assert *how* the code works, not *what* it does; they break on refactor and pass on real bugs. Prefer tests at the module's public interface (this is the `codebase-design` "the interface is the test surface" principle).
- **Assertion-free / disabled tests** — tests with no assertions at all; `t.Skip`/`it.skip`/`xit`/`@pytest.mark.skip`/`#[ignore]` left in without a reason.
- **Snapshot/golden tests that assert nothing meaningful** — auto-updated snapshots no one reads, or golden files regenerated on every failure.
- **Flaky-by-construction** — dependence on wall-clock, `sleep`, randomness without a seed, map/iteration order, or real network/filesystem where a seam should be injected.
- **Brittle coupling** — tests asserting on private state, log strings, or exact error messages that will churn without a behaviour change.
- **Coverage padding** — trivial getter/setter tests inflating the number while the logic goes untested.

## 4. Output

Emit a single inline markdown report. Do not save it to a file, and do not post it anywhere.

```
# Test audit: <repo or scope>

**Scope:** <n source / n test files> · **Framework:** <name> · **Coverage:** <n% from tooling, or "not measured — <why>">

## Summary
**Verdict:** Under-tested where it counts | Covered but low-signal | Solid suite

<One short paragraph, 1–3 sentences: the single most important thing about this suite —
usually either a critical path with no test, or a high number hiding weak assertions.>

## Findings

### Critical

#### `path/auth.go` — no test on the token-verification path

<Self-contained: what's untested or what the test fails to actually check, why it
matters (cost of the code being wrong / false confidence), the fix. One paragraph,
2–4 sentences.>

### Major

#### `path/calc_test.go:40` — tautological: expected recomputed via the code under test

<...>

### Minor

#### `path/util_test.go:12` — asserts no-throw only, never checks the result

<...>

### Nits

#### `path/getter_test.go:8` — trivial getter test, coverage padding

<...>

## Coverage map
- <A few lines: which critical modules are well-tested, which have gaps, where the
  tests cluster vs where the risk is. This is the section that turns a % into a decision.>

## Coverage gaps (tooling)
- <What couldn't be measured: coverage tool not installed, a package excluded, tests
  that don't run. Silent omission reads as "tested" when it isn't.>

## What looks good
- <1–3 genuinely strong tests or well-covered risky areas. Not filler.>
```

**Formatting rules, non-negotiable:**

- Each finding is its own `####` subsection, **never** a bullet item. Blank line after every header and body. The header is the backtick-wrapped location (a test `file:line`, or a source `path` for an untested module) plus a short `—` label.
- **One paragraph, 2–4 sentences per finding, Critical included.** Severity buys attention, not words.
- Severity is about **risk**, not category: **Critical** = a high-cost path with no real test; **Major** = a test that gives false confidence on important logic; **Minor/Nit** = low-risk gaps or padding.
- A gap with no single line gets a subject header (`#### auth package: no tests`). **Never invent a `file:line`** — anchor to the file or nearest symbol if you can't pin a line.
- Omit any empty section rather than printing "(none)".

## Guardrails

- **Read-only.** Run tests/coverage read-only; never write, update snapshots/golden files, or `--fix`. Read-only git only.
- **Findings are the deliverable; fixes are not.** Hand the report back; the user decides what to test. (Writing the missing tests is a TDD-skill job, done deliberately.)
- **Rank by risk, not by percentage.** 100% on a formatter is worth less than one real test on the auth path. Don't let a green coverage number close a finding — read the assertions.
- **Name what you couldn't measure.** A coverage tool that wasn't installed, tests that don't compile/run, an excluded package — all go in the coverage-gaps section. An unmeasured suite reported as clean is a false pass.

## Related skills

- **`tdd`** and the language test skills (`go-test`, `python-testing`, `rust-test`, `cpp-test`) — write the missing tests a finding calls for, tests-first.
- **`code-review`** — carries the test-coverage dimension for a branch diff; `test-audit` is the whole-repo, quality-first version.
- **`codebase-design`** — the "interface is the test surface" vocabulary behind the mock-the-internals finding.
- **`audit-codebase`** — dispatches this as its optional test-coverage pass.
