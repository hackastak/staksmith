---
name: benchmark-checklist
description: "Vet a performance number before you report it or act on it: limiter, tuning, limits, errors, repeatability, relevance, and whether the work ran. Use when you run a benchmark, or report a speedup or regression you measured."
category: "Code Review & Quality"
origin: community
disable-model-invocation: true
---

# Benchmark checklist

Use this when you produce a performance number: a before and after, a regression claim, a harness comparison, or a library or config choice. Answer each question with evidence from a run, not a guess from reading the code.

This is not `perf-review`. That skill reads code and ranks likely cost. This is not `diagnosing-bugs`. That skill builds a feedback loop for a bug. This skill vets a number you already measured, including a bundle size, a bench result, or an `EXPLAIN QUERY PLAN` cost, before anyone trusts it. The rule behind it is [Explain the Number](../../rules/common/performance.md#explain-the-number). It is a rule, not a skill. Do not look for `skills/principle-explain-the-number`.

You do not need another plugin's setup skill to run this.

For a quick ballpark the user asked for, one run is enough. Still check questions 4 and 7, and say that it is one run. Skip the rest unless that run looks wrong. A choice between options is never a ballpark.

## Before you run anything

- Write down the claim you expect to ship, in the words you would ship. Example: "export is 30% faster at p50 on the 60k-row dataset." The questions test that sentence.
- Read the measurement script. Note what it times, what it counts, and what it ignores.
- Check load with `uptime` and core count with `nproc`, or `sysctl -n hw.ncpu` on macOS. If the machine is busy, find out what is running. If you cannot stop it, interleave the sides so both see the same noise, and say so.

## The questions

1. **Why not double?** Name the limiter. Profile in a run you do not report, because profilers slow the work down. Use CPU per process, a runtime profiler, I/O wait, and syscall counts, then map the hot spot to source. Watch the load generator too: if it saturates first, you measured the generator. If a change did not move the number, the limiter explains why. Find it before you call the change useless.
2. **Was it tuned?** Run every side the way production runs it: release builds, production flags and env, batching and transaction settings, pools, caches as warm or cold as production sees them, and the same versions and data. If one side runs on defaults, you compared configurations, not implementations. A limiter that is a setting (a commit per row, a debug build, a missing index) means that side is untuned. Tune it and measure again before you pick a winner. If you cannot tune it, do not pick a winner from that run. Do not pick a winner by narrowing the claim to today's settings. The user adopts the option, not the defaults it happened to have.
3. **Did it break limits?** Do the arithmetic. Compare bytes per second with disk and network bandwidth, operations per second times cost per operation with your cores, and the time saved with the time the changed piece took. Removing a piece that takes 10% of the run can make the run at most about 11% faster. A result past a limit measured something else: a cache, a no-op, or a bug.
4. **Did it error?** Count failures and non-success responses, and check that outputs are correct, not just present. Rejections are often fast. Timeouts and retries are slow. If the script does not count errors, add the count.
5. **Does it reproduce?** Run each side at least 5 times, alternating (A, B, A, B, and so on) so warmup, lazy init, caches, and drift favor neither. Report the median and range. A gap smaller than the run-to-run variation is no measurable difference. When the call is close, use a rank-sum test or the harness's own statistics.
6. **Does it matter?** Next to any micro result, measure the end-to-end path a user waits on, with realistic data sizes and concurrency, and report the micro result as a share of the whole. A helper that takes 1% of a request can make the request at most 1% faster, however fast the helper gets.
7. **Did it even happen?** Confirm the work ran inside the timed region: the request reached the server, the rows were written, the bytes were read, and the code used the result. Lazy code (a generator nobody iterates, a promise nobody awaits, a result the JIT can discard) and timeouts produce numbers for work that never happened.

## Report

- Lead with the verdict: faster, slower, no measurable difference, or inconclusive.
- Give the number with its unit, the run count, the range, and the limiter. Example: "p50 41 ms → 33 ms, median of 7 runs per side, range 32 to 35 ms after, bound by JSON parsing on one core."
- Call the verdict inconclusive when you claim a difference but cannot name the limiter, when a side ran untuned, or when you could not check questions 4 and 7. Name the gap.
- Keep a PR body to one primary number. Put the runs, range, and limiter evidence in a linked note or artifact.

When `diagnosing-bugs` is about a performance regression, vet the baseline with this checklist before the diagnosis plans from it. A `perf-review` finding is a reason to measure. It is not itself a measurement.
