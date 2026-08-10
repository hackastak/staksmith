---
name: perf-review
description: "Review code for performance — latency, throughput, memory, scalability — across a whole repo or a diff. Flags N+1 queries, algorithmic complexity, blocking I/O on async paths, unbounded work, missing pagination/caching, retry storms, and bundle/render cost, ranked by real hot-path impact. Read-only. Use when the user says 'review performance', 'why is this slow', 'perf review', or invokes '/perf-review'."
category: "Code Review & Quality"
origin: Hackastak
---

Review code for **performance**: where it will be slow, allocate too much, block, or fail to scale. This is the performance axis of the review family — the dimension `code-review` only touches in passing. Run it over a whole repo or a single diff, and rank every finding by the impact it will actually have in *this* codebase.

This is **read-only inspection**: read code, run read-only build/measure tooling, and report. Never edit, never commit, never run anything that mutates the working tree, a database, or external state.

**Which review skill is this?**

| Skill | Axis | When |
|---|---|---|
| `code-review` | all six, one context | before push / PR |
| `security-scan` | security only | security-auditing a repo |
| **`perf-review`** | **performance only** | **latency/throughput/memory/scalability review** |
| `audit-codebase` | every axis, fanned out | reviewing an unfamiliar repo end-to-end |

For the full panel, use `audit-codebase` — it dispatches the `performance-reviewer` agent as one pass. Use `perf-review` when performance is the question you actually have.

## 1. Scope

Default unit is the **whole repository**; honour a narrower scope if the user names one, and take a diff's file list from `git diff --name-only <base>...HEAD` when they want only what changed.

- Detect the stack (languages, frameworks, DB engine, whether there's a frontend bundle) from manifests.
- **Find the hot paths** — request/RPC handlers, the pipeline the program spends its wall-clock in, loops over user-scale data, anything network- or disk-bound, anything the user waits on. This is where the review lives; cold startup/config code is out of scope unless egregious.
- Read-only git only: `git ls-files`, `git log`, `git diff`, `git show`, `git status`.

## 2. The one rule that matters

**Rank by real hot-path impact, not theoretical cost.** Before flagging anything, answer: how often does this run, over how much data, on a path the user waits on? An O(n²) loop over a 3-item config slice is a Nit; a serial network call inside the main ingest loop is Critical. A finding with no plausible cost answer is noise — cut it. Most real problems reduce to *how much data crosses a boundary how many times*: count the round-trips, the allocations, the bytes.

## 3. Walk the performance dimensions

Over the hot paths, check each. Verify every `file:line` with `grep -n` before citing — **never invent a path or line number**.

1. **Database & I/O** — N+1 queries (a query/call inside a loop), per-item writes instead of batched transactions, unbounded result sets (`SELECT *` / no `LIMIT` / no pagination), missing indexes and predicates that defeat them (`LOWER(col)`), full scans where an index/KNN path exists.
2. **Concurrency & blocking** — independent network-bound calls awaited serially when they could be bounded-concurrent; blocking I/O on an async/event-loop path; unbounded goroutine/promise fan-out; missing timeouts or uncancellable waits; retry storms without capped backoff+jitter.
3. **Memory & allocation** — hot-path allocations (string concat in loops, slice/map growth without preallocation when size is known, per-iteration buffers), slurping whole files/responses/result sets instead of streaming, accidental retention.
4. **Caching & redundant work** — recomputing an expensive pure result every call, re-fetching/re-processing unchanged data when a skip-unchanged path exists, an uncached path next to a cached neighbour.
5. **Frontend (when applicable)** — bundle size (whole-library imports, no code-splitting/lazy-loading), unnecessary re-renders (missing memoization, unstable keys/props), unoptimized assets.

Use read-only tooling where present, and **name it as a coverage gap when absent** rather than fabricating output: `EXPLAIN`/`EXPLAIN ANALYZE` on a flagged query, index definitions, `go test -bench`/`pprof` profiles or bundle-analyzer output if checked in, `prealloc`/complexity linters. Confirm what you can cheaply measure; reason about the rest; say which is which.

**Delegating.** For a large repo, dispatch the `performance-reviewer` agent (same dimensions, isolated context) instead of reviewing inline — brief it with the stack, the hot-path list, and the read-only + `file:line` requirements, then verify its Critical/Major findings against the code before promoting them.

## 4. Output

Emit a single inline markdown report. Do not save it to a file, and do not post it anywhere.

```
# Performance review: <repo or scope>

**Scope:** <n files / dir / "whole repo"> · **Stack:** <langs / DB / frontend> · **Measured:** <tooling that ran; note reasoned-only areas>

## Summary
**Verdict:** Hot-path bottlenecks to fix before scale | Meaningful wins available | Performance is sound

<One short paragraph, 1–3 sentences: the single biggest performance fact about this
code and the why behind the verdict.>

## Findings

### Critical

#### `path/file.go:42` — serial LLM calls in the ingest loop

<The hot path and how often it runs, the cost (round-trips / allocations / blocking
time / bytes) and why it matters here, then the fix. Say whether measured or reasoned.
One paragraph, 2–4 sentences.>

### Major

#### `path/db.go:88` — per-row insert in autocommit

<...>

### Minor

#### `path/util.ts:12` — recompute on every render

<...>

### Nits

#### `path/config.go:20` — O(n²) over a small fixed slice

<...>

## Coverage
- <What was measured vs reasoned; tooling not installed; a subsystem not reachable.
  Name it — a reasoned finding presented as measured is a false confidence.>

## What looks good
- <1–3 genuine performance strengths: batched writes, bounded concurrency, caching
  where it counts. Not filler.>
```

**Formatting rules, non-negotiable:**

- Each finding is its own `####` subsection, **never** a bullet item. Blank line after every header and body. The header is the backtick-wrapped `file:line` plus a short `—` label.
- **One paragraph, 2–4 sentences per finding, Critical included.** Severity buys attention, not words.
- Severity is impact on *this* codebase, not category: **Critical** for a hot-path cost that bites at real scale, **Major** for a clear meaningful slowdown, **Minor/Nit** for small or cold-path wins.
- Multiple locations for one logical finding combine in the header: `#### \`a.go:12, b.go:40\` — N+1 across callers`.
- **Never invent a `file:line`.** Anchor to the nearest symbol if you can't pin it. A finding with no location gets a subject header.
- Omit any empty section rather than printing "(none)".

## Guardrails

- **Read-only.** Read-only build/measure tooling and read-only git only. Never `EXPLAIN ANALYZE` a mutation, never run load tests that write, never edit.
- **Findings are the deliverable; fixes are not.** Hand the report back; the user decides what to optimize. Premature optimization of a cold path is its own waste.
- **Don't flag what won't matter.** Micro-optimizations on cold paths, and rewrites whose payoff you can't estimate, are noise. If you can't answer "how much does this cost here," don't report it.
- **Measure honestly.** Distinguish measured from reasoned findings, and name coverage gaps — a profiler that wasn't run is a gap, not a clean result.

## Related skills

- **`performance-reviewer`** (agent) — the same review delegated to an isolated subagent; `audit-codebase` dispatches it as its performance pass.
- **`code-review`** — the broad review whose Performance dimension is a lighter pass than this.
- **`database-reviewer`** / **`postgres-patterns`** — deeper when the bottlenecks are query- or schema-shaped.
- **`cost-aware-llm-pipeline`** — when the hot path is LLM API cost and latency.
