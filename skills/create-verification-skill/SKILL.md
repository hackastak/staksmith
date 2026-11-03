---
name: create-verification-skill
description: "Generate a project-local skill that drives the app the way a user does and proves behavior with evidence. Use for /create-verification-skill, or when a project has no scripted way to prove UI, CLI, or service behavior."
category: "Testing & TDD"
origin: community
disable-model-invocation: true
---

# Create a verification skill

Every serious project needs a scripted way to drive the real app and prove behavior: launch it, exercise a feature the way a user would, and capture evidence. This skill generates that as a project-local skill tailored to the repo. You write the generator's output for the next agent, not for a human. It will be read cold, mid-task, by an agent that has never seen the app.

This is not `e2e-testing`. That skill is Playwright suite patterns. This is not `verification-loop` and not `/verify`. Those run build, type, lint, and test gates. This skill writes a harness that drives the product the way a user does, when those gates cannot see the behavior.

You do not need another plugin's setup skill to run this. `maintain-verification-skill` is not shipped here. Put the upkeep rules in the generated skill instead of pointing at a missing command.

## When to use it

Use it when the user invokes `/create-verification-skill`, asks for a control skill for this repo, or the project has no scripted way to prove UI, CLI, or service behavior.

If a `verify-*` skill already exists, extend that one. Do not generate a second.

## 1. Interview the repo, not the user

Answer these from the codebase. Ask the user only what you cannot observe:

- **Surface:** what does a user actually touch? A web UI, a CLI/TUI, a desktop app, an API, a mobile app, a library? A repo can have several. Pick the primary one and note the rest.
- **Run:** how does the app start locally? Prefer the repo's own documented dev command (package scripts, Makefile, README quickstart). Note ports, env vars, seed data, auth.
- **Drive:** how can an agent interact with it programmatically? Existing harnesses first: Playwright/Cypress specs, expect scripts, PTY helpers, curl-able endpoints, a debug port. Only then pick a generic recipe: browser/CDP for web and Electron, a tmux/PTY harness for CLI/TUI, plain HTTP for services.
- **Observe:** what evidence can be captured? Screenshots, terminal transcripts, response bodies, logs, exit codes, DB state.
- **Isolate:** can two instances run side by side (ports, data dirs, profiles)? If not, say so in the generated skill. Refusing to double-drive a shared instance beats corrupting the user's session.

If the checkout doesn't build or start as-is, fix that first, or report the failure precisely, before generating. A skill written against a broken base teaches wrong steps. When an irrelevant missing asset blocks startup (a static dir the API never serves, a sample config), the generated skill may create it, clearly marked as verification scaffolding, and remove it in cleanup.

**Done when:** each question has an observed answer, or one named question you had to ask.

## 2. Choose one write root

Write one directory, `verify-<app>/`, into the project skill root the current harness already loads:

1. `.claude/skills/` when this session is Claude Code, or that directory already exists.
2. `.cursor/skills/` when this session is Cursor, or that directory already exists and `.claude/skills/` does not.
3. `.agents/skills/` when this session is Codex, or that directory already exists and the two above do not.
4. Otherwise `.claude/skills/`.

Do not write into this plugin's `skills/` catalog. Do not invent `.pi/skills/` or a second copy. Name the path in the reply. If the repo already loads skills from a second root, say so and ask before copying.

## 3. Generate the skill

Write `<root>/verify-<app>/SKILL.md` with YAML frontmatter (`name: verify-<app>` and a `description` that names the app, the surface, and when to reach for it). Without frontmatter the skill never registers. Ground every section in what the interview found. Leave no placeholders:

- **Launch:** the exact command that starts the app for verification, and how to tell it's ready (a log line, a prompt). Launch must reach a usable state from an empty data dir, including any migrations and seed data. Ready means usable, not just that a process answers. A database health check can pass while its init scripts are still running. Include teardown. For a short-lived CLI or TUI there is no server to keep alive: launch means build the binary (or install deps) once, then start each drive in its own isolated PTY or tmux session.
- **Doctor:** one read-only check that answers "is this instance worth driving?" Process up, right version/build, port owned by us, auth valid. An agent runs this first whenever anything looks off.
- **Drive:** the harness recipe with real selectors and commands from this repo, not examples. Prefer stable handles (ARIA labels, data attributes, prompt strings, route paths) over coordinates and tab order.
- **Evidence:** what to capture for a proof and where it goes. State the proof standards: exercise the real user path, not internal setters or test-only endpoints; capture the action and the resulting state, not just the final screen; verify side effects (files written, rows inserted, messages sent) alongside what's visible; mocks only where a production boundary already isolates the external system. When the safe path is a dry-run or test mode, verify what it actually skips by observing files, network, and git refs rather than trusting its name. Some dry-runs still touch the network or open a browser.
- **Cleanup:** how to tear down instances the run created. Never kill by process name. Kill what you started. Cleanup removes instances and scratch state, never the evidence. Proof artifacts survive the teardown, in a location the skill names.
- **Helpers:** any script the skill ships is executable, and its invocation is shown in the skill body. A helper the reader has to reverse-engineer is not a helper.
- **Upkeep:** when the app changes, re-read the touched feature from source, re-drive it, and fix the map or the harness. Do not edit product code to make the map pass. A behavior the map describes that the app no longer does is either doc drift (fix the map) or a product regression (report it).

**Done when:** the file exists at the chosen root, frontmatter is valid, and no section still contains a placeholder.

## 4. Seed the feature map

Create `<root>/verify-<app>/features/README.md` plus one file per user-facing feature you can identify. Aim for the top 3–5 to start, from routes, commands, menus, or docs. Follow the shape in [`references/feature-map-example/`](references/feature-map-example/): a README index and one file per feature.

Each feature file answers, from the user's point of view: what the feature is, how to reach it, how to drive it with the harness, and what observable end state proves it works. The four H2s are `Sub-features`, `How to get to it (user POV)`, `Driving it with <harness>`, and `Gotchas`. If the seed data lacks a precondition that a journey needs, the journey reports a failure and the reason goes in that feature's `Gotchas`. Never weaken the journey to make it pass. The map is the repo's maintained verification source. A proof that drives one convenient entry point is incomplete when the map lists others.

**Done when:** the README links every feature file, and each file has those four H2s in that order.

## 5. Prove the generated skill before handing it over

Run its own instructions end to end once: launch, doctor, drive ONE mapped feature (one is enough; the map exists so later runs can cover the rest), capture evidence, clean up. After cleanup, confirm the evidence still exists at the named location. A cleanup that eats the proof fails this step. Fix what fails. Run the generated cleanup after every failed iteration too, so broken attempts don't strand processes and ports. A generated skill that was never executed is a draft, not a deliverable.

If you proved it in a stand-in for the real target (a container in place of a fresh VM, a local stack in place of a remote one), list every setup step the stand-in did that the target will not. Those steps stay unverified until a run on the real target covers them.

**Done when:** you can name the command, the feature, the evidence path, and that the evidence was still there after cleanup.

## Reply

Name the skill path, the feature files, the proof command, and the evidence path. If the proof failed, say what failed and what you cleaned up. Do not claim the skill works without that proof.
