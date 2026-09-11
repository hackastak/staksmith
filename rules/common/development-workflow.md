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
| Regression test works | Red→green cycle verified (revert fix, confirm it fails, restore) | Test passes once |
| Agent completed | VCS diff shows the changes | Agent reports "success" |
| Requirements met | Line-by-line checklist against the spec | Tests passing |

**Red flags — STOP:** "should" / "probably" / "seems to"; satisfaction before verification; about to commit/push/PR unverified; trusting an agent's success report; relying on a partial check; "just this once"; tired and wanting it over. Confidence is not evidence. Run `/verify` (or the project's build/type/lint/test commands) and read the output before you say it works.

This applies to exact phrases, paraphrases, synonyms, and any implication of success — before every commit, PR, task handoff, or move to the next task.

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

4. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format
   - See [git-workflow.md](./git-workflow.md) for commit message format and PR process
