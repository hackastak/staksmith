---
name: correct
description: "Find the mistakes agents keep repeating in this repo and make each one impossible. Try architecture first, then types, then a lint whose error names the fix, then a test, and write docs last. Prove each check fails on a real past mistake. Repeat this each time the operator corrects you. Use for /correct."
category: "Code Review & Quality"
origin: community
disable-model-invocation: true
---

# Correct

The operator keeps correcting agents in this repo for the same mistakes. Change the repo so the next agent cannot make them.

This is not `learn` and not `evolve`. Those extract a pattern worth reusing. This skill hardens a mistake so the next agent cannot repeat it. Reach for it when the same correction has already happened twice, or when the operator invokes `/correct`.

Assume every contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles. Design the repo so a change that looks right from one file is right for the whole repo.

You do not need another plugin's setup skill to run this.

## Step 1, Find the mistake classes

Read recent commits, reverts, review comments, agent instruction files, and comments that explain workarounds. Group the mistakes into classes. A class counts once it has happened twice. One-off slips are not a class.

**Done when:** each class has a name, at least two pieces of evidence, and a count.

## Step 2, Fix each class at the highest level that works

Stop at the first level that makes the mistake fail closed. Do not add a lower level "as well" unless the higher one cannot see the mistake.

1. **Eliminate it with architecture.** Give each piece of state one owner and each task one supported way. Hide internals so the wrong import fails. Replace hand-synced lists with one source of truth. Delete old ways and dead code an agent would copy.
2. **Enforce it with types so the bad state cannot be written.** If bad code still compiles, add a lint or CI check whose error names the file, type, or function to use instead. If the pattern is already common, fail only when a change adds more.
3. **Test the behavior.** Fix or delete any test that still passes when the behavior it checks breaks, or that fails when only the internals change.
4. **Write docs or agent rules last, only for judgment calls.** Nothing fails when an agent skips them.

**Done when:** every class has exactly one chosen level, and you can say why each higher level did not work.

## Step 3, Fix and prove

Fix the most frequent classes now, one commit each. Prove each new check fails on a real past mistake. Run the same command locally and in CI. Exceptions go on the offending line with a reason, an expiry date, and a human's approval.

**Done when:** the check fails on the recorded mistake and passes on the fixed code, with the command named.

## Step 4, Keep the rule table

Keep a table in the agent instruction file (`AGENTS.md`, or `CLAUDE.md` when that is the file agents actually read) that pairs each rule with what enforces it. When the operator corrects you, fix the mistake and add the rule. If the rule was already there and nothing enforces it, that is a repeat, so fix it at the highest level in the same change. Drop a rule once its mistake cannot happen.

**Done when:** the table lists every live rule and the check that enforces it, and dropped rules are gone.

## Reply

For each class, report the evidence, the level you picked, and why a higher level did not work. Name the command that proved the check.
