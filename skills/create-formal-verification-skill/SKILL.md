---
name: create-formal-verification-skill
description: "Generate a project-local skill that formally verifies the code where a bug costs the most and tests reach the least, in any language, with whichever verification tool fits. Use for /create-formal-verification-skill, 'model-check this race', 'prove this invariant', or when concurrency, retries, state machines, parsers, or unsafe code need more than tests."
category: "Testing & TDD"
origin: community
disable-model-invocation: true
---

# Create a formal verification skill

A test checks the cases that someone thought to write. Formal verification checks every case in a stated scope: every order of steps in a model, every input up to a bound, or every input. This skill finds the part of the repo where that matters most, verifies one property of it, and leaves a project-local skill that lets the next agent check a change against that property. Write that skill for an agent who reads it cold, mid-change, and has never seen your work. The user must be able to trust the result and act on it without learning the verification language.

This is not `create-verification-skill`. That skill drives the app the way a user does. This is not `e2e-testing`. That skill is Playwright suite patterns. This is not `verification-loop` and not `/verify`. Those run build, type, lint, and test gates. This skill checks one property past the cases those paths reach.

You do not need another plugin's setup skill to run this. There is no separate maintain command. Put the upkeep rules in the generated skill.

## When to use it

Use it when the user invokes `/create-formal-verification-skill`, asks to model-check a race, prove an invariant, or the code has concurrency, retries, a state machine, a parser, or unsafe code where a bug is costly and tests rarely reach the case that breaks it.

If a `formal-*` skill already covers that area, extend that one. Do not generate a second.

## 1. Choose the target from the code

Answer from the codebase, and ask the user only what you cannot observe. If the user named an area or a bug, start there.

A good target is a promise the code makes, where a break harms users and tests rarely reach the case that breaks it. Choose the strongest such target in the repo, not the one that is easiest to verify.

**Done when:** you can name the promise, the harm, the code it lives in, and why tests miss the breaking case.

## 2. Let the question choose the tool

Pick the tool that answers the question at the lowest cost: a model checker, a proof assistant, an SMT-backed verifier, or another tool.

- Whether events can happen in a bad order usually suits a model checker over a small model of the design. TLA+ is the default for that in any language.
- Whether the code itself behaves for every input, as with memory safety, overflow, or a data-structure invariant, usually suits a verifier that runs on the code.
- If no verifier runs on this language, say so, and test the real code with generated inputs, not a hand model of the function.
- A property that must hold at every size, where a bound is not enough, can need a proof.

Prefer a tool that the repo's developers can install and run. Tell the user why you chose it. Pin a reproducible tool version in the generated skill.

**Done when:** the tool, the version, and the reason are named, and you have seen the tool run in this environment or reported the exact install failure.

## 3. What makes it good

- **True to the code.** Every part of the model or proof points to code that a reviewer can open. What the verification treats as one indivisible step is one indivisible step in the code. Names come from this repo.
- **Able to fail.** A check that you have never seen fail proves nothing. Show each property failing on a broken variant of the code it guards, such as a removed check or a reordered step.
- **Findings stay findings.** When the current code breaks the property, report it with the counterexample in the code's terms. Do not weaken the property or the model until it passes, and do not change product code unless the user asks.
- **Honest about scope.** Say what is verified, under which bounds and assumptions, and what is left out. A pass covers the model or the bound, not the whole system.
- **Readable without the tool.** State the property and the harm in one plain sentence each. Tell a counterexample as a short sequence of steps in the code's words.
- **Cheap to rerun.** One command, a reproducible tool version, and a run short enough that the next agent will use it on every relevant change.
- **Kept in step with the code.** When verified code changes, something tells the next agent that the verification needs another look.

## 4. Choose one write root

Write one directory, `formal-<area>/`, into the project skill root the current harness already loads:

1. `.claude/skills/` when this session is Claude Code, or that directory already exists.
2. `.cursor/skills/` when this session is Cursor, or that directory already exists and `.claude/skills/` does not.
3. `.agents/skills/` when this session is Codex, or that directory already exists and the two above do not.
4. Otherwise `.claude/skills/`.

Do not write into this plugin's `skills/` catalog. Do not invent `.pi/skills/` or a second copy. Name the path in the reply. If the repo already loads skills from a second root, say so and ask before copying. `<area>` is a short noun from this repo, not a placeholder.

## 5. Generate the verify skill

Write `<root>/formal-<area>/SKILL.md` with YAML frontmatter (`name: formal-<area>` and a `description` that names the area, the property, and when to reach for it). Without frontmatter, the skill never registers. From the skill alone, the next agent must be able to tell whether a change touches the verified code, run the check, tell a real bug from a modeling error, and update the verification when a change is intended. Use this repo's real commands, paths, and nouns. Leave no placeholders.

Ground every section in what you verified:

- **Property:** one plain sentence. **Harm:** one plain sentence.
- **Tool:** the command, the pinned version, and why this tool fits this question.
- **Scope:** bounds, assumptions, and what a pass does not cover.
- **Map:** each model or proof step points at the code a reviewer can open.
- **Run:** one command. Say how long a clean run takes.
- **Read a failure:** a counterexample as a short sequence of steps in the code's words, and how to tell a real bug from a modeling error.
- **Upkeep:** when the verified code changes, re-read the touched code, rerun the check, and update the model or the proof. Do not weaken the property to make a failing check pass. Do not edit product code unless the user asks. A break in the current code is a finding, reported in the code's terms.

Ship any helper the skill needs as an executable script next to the skill, and show its invocation in the skill body. A helper the reader has to reverse-engineer is not a helper.

**Done when:** the file exists at the chosen root, frontmatter is valid, and no section still contains a placeholder.

## 6. Prove it before you hand off

Follow the generated skill once, as the next agent would, on a scratch change that breaks the property in the real code. It must catch the break. Then drop the scratch change and confirm that the check is back where it started: passing, or failing only on the findings you will report. A verify skill that was never run is a draft. If the skill misses the break or a step does not run, fix the skill or the verification, not the scratch change.

Keep the scratch change out of the commit. If you proved it in a stand-in for the real tool or a reduced bound, say which steps the stand-in skipped. Those steps stay unverified until a run on the real tool covers them.

**Done when:** you can name the scratch break, the command that caught it, and the state of the check after the scratch change was dropped.

## Hand off

Tell the user what you verified, which tool you used and why, the bounds, what the check found in plain words, how to run it, and what it does not cover. Name the skill path. Suggest a second target only if you found a close one. Do not claim the skill works without the proof in step 6.
