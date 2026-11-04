# Development Workflow

> This file extends [common/git-workflow.md](./git-workflow.md) with the full feature development process that happens before git operations.

The Feature Implementation Workflow describes the development pipeline: research, planning, TDD, code review, and then committing to git.

## Iron Law: Evidence Before Completion

**No completion claims without fresh verification evidence.** Violating the letter of this rule violates its spirit.

If you have not run the verifying command *in this message*, you cannot claim it passes. Before claiming any status — or expressing satisfaction ("Great!", "Perfect!", "Done!") — run the gate:

1. **Identify** the command that proves the claim.
2. **Run** it fresh and in full.
3. **Read** the full output — exit code, failure count.
4. **Verify** the output confirms the claim. If not, state the actual status with evidence.
5. **Only then** make the claim, stated *with* its evidence.

| Claim | Requires | Not sufficient |
|-------|----------|----------------|
| Tests pass | Test output: 0 failures | A previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passed, logs "look good" |
| Bug fixed | Original symptom retested: passes | Code changed, assumed fixed |
| Bug fixed at the cause | The first wrong decision was named, and the original symptom was retested | A guard, retry, clamp, or swallowed error at the symptom ([Fix Root Causes](#fix-root-causes)) |
| Premise still holds | The shared premise of two or more failed fixes was written down and tested | Another patch after stop / still / again ([Attack the Premise](#attack-the-premise)) |
| Regression test works | Red→green cycle verified (revert fix, confirm it fails, restore) | Test passes once |
| Agent completed | VCS diff shows the changes | Agent reports "success" |
| Requirements met | Line-by-line checklist against the spec | Tests passing |
| Feature works | The real artifact: the flow was run, the stored value was read, or the cited diff was opened | Build or tests green, "it compiles", a cached screenshot, an agent self-report |
| Citation is real | The cited `file:line` was opened in this turn | A plausible line number, or a caller that was not searched for |

**Red flags — STOP:** "should" / "probably" / "seems to"; satisfaction before verification; about to commit/push/PR unverified; trusting an agent's success report; relying on a partial check; "just this once"; tired and wanting it over. Confidence is not evidence. Run `/verify` (or the project's build/type/lint/test commands) and read the output before you say it works. A green toolchain run is not the feature check. That check is [Prove It Works](#prove-it-works).

This applies to exact phrases, paraphrases, synonyms, and any implication of success — before every commit, PR, task handoff, or move to the next task.

## Prove It Works

Fold of pstack `principle-prove-it-works`. It is a rule, not a skill. Do not look for `skills/principle-prove-it-works`.

The Iron Law above is the command check. This section is the artifact check. A green build, a passing suite, or "it compiles" does not prove the change works.

Wrong:

```
Fixed login. Tests pass. Redirect is src/auth.ts:42.
```

The suite was not re-run. Line 42 was not opened. The login flow was not exercised.

Right:

```
Ran `bun test src/auth.test.ts` — 12 passed, 0 failed.
Opened /login, submitted the form, and the browser landed on /dashboard.
The redirect is src/auth.ts:88 (`return redirect("/dashboard")`), opened in this turn.
```

Check the real thing, not a proxy:

- Run the feature the user will use, read the value the system stored, or inspect the diff. Do not infer from a proxy.
- These are not proof: file mtimes, output freshness, a cached screenshot, an agent self-report, "it compiles", a previous run.
- Check process liveness directly, not through derived state.
- Read the actual value, not a cached or derived representation.
- When a check fails, suspect the observation method before the system. Confirm you read the live value, and that the process you think is running is the one that is running.

Citations:

- A `file:line` is a line you opened. If you did not open it, do not cite it.
- A search that finds nothing is an answer. Say what you searched.
- Never invent a caller, an API, a test name, or a line number. An anchorless claim is correct. A fabricated citation is fatal.
- Review skills already treat a fabricated `file:line` as fatal. This rule is that bar for every completion claim, not only review findings.

Script the check when you will repeat it. The strongest proof is a deterministic script that re-runs the same comparison, not a one-time eyeball. Write the script, run it, and keep the output where a reviewer can re-run it. Commit that artifact only for large or complex work whose trail has to be auditable later, such as a big port or migration. `show-me-your-work` is not ported. Do not block on it.

Before you say it works, name the artifact, the command or observation, and the result. If you could not check the real artifact, say that. Do not upgrade a proxy into a pass.

A speedup, regression, throughput, latency, or eval score is a number, not a completion claim. Vet it with [Explain the Number](./performance.md#explain-the-number) before you report it or act on it.

## Fix Root Causes

Fold of pstack `principle-fix-root-causes`. It is a rule, not a skill. Do not look for `skills/principle-fix-root-causes`.

When debugging, fix the fault, not the place the symptom showed up. The symptom is where a wrong state became visible. The root cause is the first place the system did something it should not do, or failed to handle a state it should handle.

A symptom fix hides the evidence and leaves the fault free to surface somewhere else. The code then carries a workaround for a bug nobody named.

- Reproduce first. Do not change code from a guess.
- Ask why at each step until the answer is a wrong decision in the code, not a consequence of an earlier one.
- When stuck, instrument. Read the actual error and the actual state.
- Ask whether the state that triggered the symptom is legitimate. If the system may be in that state, handling it there is the fix. If the state should never exist, a check where it broke hides the bug. Find what produced the state. Guards, retries, swallowed errors, clamped values, and discarded state are the usual hides.
- When something fails only after a restart, suspect persisted state first: config, caches, lock files, serialized state.
- Fix the pattern, not only the instance. Find every place with the same fault.
- A workaround that needs a paragraph to justify is the wrong code. Fix the code, not the comment.
- If the deciding fact took a deep dig, propose the cheap always-on signal that would have shown it at first look.

`diagnosing-bugs` is the loop that builds the red signal. This section is the bar for what counts as the fix. [Prove It Works](#prove-it-works) still applies before you say the bug is gone.

## Attack the Premise

Fold of pstack `principle-attack-the-premise`. It is a rule, not a skill. Do not look for `skills/principle-attack-the-premise`.

When two or more fixes that share one premise have failed the same gate, suspect the premise, not the next fix. The tell is stop / still / again: the same failure after another patch that assumed the same cause.

Each failed fix is evidence against the belief it assumed. A third fix on that belief spends effort where the evidence already says the cause is not.

- Write the premise down. It is the one sentence every failed fix assumed.
- Test that premise before the next fix. Find an observation that would come out differently if the premise were false, and make it. Look at how the failures are distributed, not only how large they are. Make the check rerunnable. Do not block on an unported principle skill.
- Follow the evidence. If it contradicts the premise, the cause is elsewhere. Look for what the failures have in common that the premise did not predict. If it confirms the premise, ask the next why under [Fix Root Causes](#fix-root-causes). The earlier fixes treated a consequence.
- Remove the condition instead of compensating for it. If one part always lands on the losing side, change what puts it there. A cleanup that runs after it leaves the cause in place and adds work on every run.

Stop. Do not start the next fix until the premise is written down and tested.

This is not a redesign around a new requirement. It questions a fact the current fix loop assumes. It is also not [Prove It Works](#prove-it-works), which checks that a claimed fix is real. This checks that the next fix is aimed at the right fact.

## Feature Implementation Workflow

0. **Research & Reuse** _(mandatory before any new implementation)_
   - **GitHub code search first:** Run `gh search repos` and `gh search code` to find existing implementations, templates, and patterns before writing anything new.
   - **Library docs second:** Use Context7 or primary vendor docs to confirm API behavior, package usage, and version-specific details before implementing.
   - **Exa only when the first two are insufficient:** Use Exa for broader web research or discovery after GitHub search and primary docs.
   - **Check package registries:** Search npm, PyPI, crates.io, and other registries before writing utility code. Prefer battle-tested libraries over hand-rolled solutions.
   - **Search for adaptable implementations:** Look for open-source projects that solve 80%+ of the problem and can be forked, ported, or wrapped.
   - Prefer adopting or porting a proven approach over writing net-new code when it meets the requirement.

1. **Plan First**
   - Use **planner** agent to create implementation plan
   - Generate planning docs before coding: PRD, architecture, system_design, tech_doc, task_list
   - Identify dependencies and risks
   - Break down into phases

2. **TDD Approach**
   - Use **tdd-guide** agent
   - Write tests first (RED)
   - Implement to pass tests (GREEN)
   - Refactor (IMPROVE)
   - Verify 80%+ coverage

3. **Code Review**
   - Use **code-reviewer** agent immediately after writing code
   - Address CRITICAL and HIGH issues
   - Fix MEDIUM issues when possible

4. **Prove it works**
   - Follow [Prove It Works](#prove-it-works) on the real artifact before any done claim
   - Do not treat the build, the suite, or an agent self-report as that check

5. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format
   - See [git-workflow.md](./git-workflow.md) for commit message format and PR process
