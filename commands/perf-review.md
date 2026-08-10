---
description: Review code for performance — latency, throughput, memory, scalability — across a whole repo or a diff. Flags N+1 queries, algorithmic complexity, blocking I/O on async paths, unbounded work, missing pagination/caching, retry storms, and bundle/render cost, ranked by real hot-path impact. Read-only.
---

# Performance Review

Invoke the **`perf-review`** skill to review code for performance — the axis `/code-review` only touches in passing. Read-only, whole-repo or diff-scoped, findings ranked by the impact they'll actually have in *this* codebase.

## What This Command Does

1. **Scope** the repo (or a directory/diff) and find the **hot paths** — handlers, the pipeline the program spends its wall-clock in, loops over user-scale data, network/disk-bound work.
2. **Walk the performance dimensions**: database & I/O (N+1, per-item writes, unbounded queries, missing indexes), concurrency & blocking (serial network calls, blocking I/O on async paths, unbounded fan-out, retry storms), memory & allocation, caching & redundant work, and frontend bundle/render cost.
3. **Rank by real impact** — how often it runs, over how much data, on a path the user waits on — not by theoretical category.
4. **Emit a severity-ranked report** (Critical / Major / Minor / Nit) with `file:line` anchors, distinguishing measured from reasoned findings and naming coverage gaps.

## When to Use

- "Why is this slow?" / before a launch or a scale event.
- A focused performance pass deeper than `/code-review`'s Performance dimension.
- Reviewing a data pipeline, an API under load, or an LLM-calling hot path.

## Usage

```text
/perf-review                 # whole repo
/perf-review internal/embed  # scope to a directory
/perf-review diff main       # only what the current branch changed vs main
```

## Output

A single inline report: verdict, findings tiered **Critical / Major / Minor / Nit** each anchored to `file:line`, a **Coverage** section (measured vs reasoned, tooling gaps), and genuine strengths. Read-only — never edits code.

## Related

- Skill: `skills/perf-review/SKILL.md`
- Agent (isolated / dispatched by `/audit-codebase`): `agents/performance-reviewer.md`
- Broader / adjacent: `/code-review` · `database-reviewer` · `skills/cost-aware-llm-pipeline/`
