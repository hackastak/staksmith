---
name: brainstorming
description: "Use BEFORE any creative work — creating features, building components, adding functionality, or modifying behavior. Explores intent, requirements, and design, and gets explicit approval before implementation. Fires when the user asks to build/add/change something without a settled design. Also the home for playing a goal back in your own words, or sharpening a task before it starts. Those are not separate skills."
category: "Workflow & Meta"
origin: community
---

# Brainstorming Ideas Into Designs

Turn an idea into a settled design through collaborative dialogue **before** touching code. Play the goal back, aim the task, then classify how much process the request needs and work your path: understand context, refine the idea, present a design, get approval.

This is the gate upstream of the rest of the workflow. `plan`, `to-spec`, and `implement` all assume a settled design — this skill produces one.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have told the user what you intend and they have approved it. This applies to EVERY task on EVERY path below — the ceremony scales with the task; the approval gate never does. Aiming the task is not approval to implement.
</HARD-GATE>

## Align on intent

Graft of pstack `sharpen` and `in-your-own-words`. They are not skills. Do not look for `sharpen` or `in-your-own-words`. This skill is the only surface. `grill-me` stress-tests a plan that already exists. This section stops the wrong plan from starting.

### In your own words

Before classification, questions, approaches, or a design, restate in your own words what you think the user's goals are and what problem they are trying to solve.

- The restatement is the first thing in the reply. Do not open with a question.
- Do not share your theory of the cause, the method, or the design until that restatement is on the page. A misread costs one message, not a revert.
- If the user asked only to play the goal back, stop after the restatement. No classification, no questions, no design, no code.
- Do not narrate that you are restating.

Say the path only after the restatement, and only when they also asked you to design or decide. The first reply still stops there. A correction to the reading comes before the first question.

### Sharpen

Once the reading holds, and before you present a design or a probe plan, aim the task. Do this in the work. Do not narrate the framing.

Ask yourself, and surface only what changes the aim:

1. How would a top expert approach this? Name their raw sources, their real methods, and one outside check that the result is right.
2. What is the user really after? The outcome, not the method they happened to name.
3. Is the task over- or underspecified?

Then:

- Loosen a constraint that does not serve the goal as readily as you add one that does.
- Leave choices that are the user's to make open. Do not decide them. Name the open choice.
- Fold in only what makes the work better, not bigger.
- Always keep one outside check that the result is right. Put it in the design, as how you will know, not in a preamble.

Sharpening does not approve implementation. pstack's sharpen continues into the work. Here the work of this skill is the aimed design. Code still waits on the hard gate.

If they asked only to sharpen the task, restate the goal, present the aimed task, and stop. Do not expand into a spec they did not ask for.

## Three Paths

The restatement comes first. Before your first question, and only after that playback, classify the request and say the classification out loud — "this looks bounded, so I'll present a short design here rather than write a spec" — so the user can override it:

- **Spike** — a feasibility question ("can we…", "is it possible…", "quick and dirty is fine") whose output is an answer, not code you keep. Present the question and what you'll try in 2-3 sentences, get a nod, then find out as cheaply as correctness allows. No spec. Report findings as a recommendation; label anything built as throwaway.
- **Bounded** — a well-scoped change to code that already exists in this repo: a new flag, a small endpoint, a one-file fix. Bounded means the flow you are changing is already here to read — understanding the *kind* of app is not enough. If there is no existing flow to change, it is not bounded. Ask the clarifying questions that matter, present a short design IN CHAT, and STOP. Implementation starts only after the user says yes.
- **Architectural** — new projects, new subsystems, changes that restructure how components fit together or alter interfaces others depend on. Follow the full process: questions, approaches, sectioned design, then hand off to `to-spec`.

When in doubt between two paths, take the heavier one. The ratchet is one-way: hidden complexity discovered mid-task upgrades the path — stop, say so, and step up. Nothing downgrades mid-task.

## Anti-Pattern: "Too Simple To Need Approval"

Every path ends with the user approving your intent before implementation. A todo list, a single-function utility, a config change — the design may be two sentences in chat, but you MUST present it and get approval. "Simple" tasks are where unexamined assumptions cause the most wasted work. What scales with simplicity is the artifact, never the approval.

## Red Flags

| Thought | Reality |
|---------|---------|
| "This is too simple to need a design" | Simple means a short design, not no design. Two sentences in chat, then approval. |
| "I'll call it bounded and skip the spec" | Reaching for a label to skip work IS the doubt — take the heavier path. |
| "It's bounded and the design is obvious — I'll start while they read it" | The gate is the approval, not the design's length. Present, then stop until you hear yes. |
| "I understand this kind of app, so it's bounded" | Bounded measures the repo, not your familiarity. A new project has no existing flow — it is architectural. |
| "The spike works, so I'll keep the code" | A spike's output is an answer. Keeping the code is a new request — classify it. |
| "It grew, but I'm almost done — no need to re-classify" | Hidden complexity upgrades the path mid-task. Stop and say so. |
| "They approved the spike, so the follow-up change is approved too" | Each task gets its own classification and its own approval. |
| "I know what they meant, so I'll skip the playback" | The playback is how a misread gets caught. First reply, own words, goals and problem. |
| "They named the method, so that is the goal" | Sharpen for the outcome. Loosen a constraint that does not serve it. |
| "I'll pick the open choice so we can move" | Leave their choice open. Name it. Do not decide it. |
| "Sharpen means start building" | Sharpen aims the design. The hard gate still blocks code. |
| "I'll add the expert's whole method" | Fold in only what makes the work better, not bigger. Keep one outside check. |

## Checklists

Work the items in order. The restatement comes before the path announcement.

**Spike:**
1. Restate goals and the problem — own words, before classification. Stop if playback was the whole ask.
2. Sharpen before the probe plan — outcome, not the named method; one outside check; their choices left open. Do not narrate it.
3. Explore project context — enough to frame the probe
4. Present question + probe plan — 2-3 sentences
5. Get approval — a nod is enough
6. Investigate — as cheaply as correctness allows
7. Report findings — a recommendation; label anything built as throwaway

**Bounded:**
1. Restate goals and the problem — own words, before classification. Stop if playback was the whole ask.
2. Sharpen before the short design — outcome, not the named method; one outside check; their choices left open. Do not narrate it.
3. Explore project context — files, docs, recent commits
4. Ask clarifying questions — one at a time, the ones that matter. Not in the restatement reply.
5. Present short design in chat — approach, files touched, testing
6. Get approval — STOP and wait for an explicit yes; presenting the design and starting in the same breath is skipping the gate
7. Implement — normal development workflow (`tdd-workflow` applies); no spec document

**Architectural:**
1. Restate goals and the problem — own words, before classification. Stop if playback was the whole ask.
2. Sharpen before the approaches — outcome, not the named method; one outside check; their choices left open. Do not narrate it.
3. Explore project context — files, docs, recent commits; read `CONTEXT.md` and respect existing ADRs in `docs/adr/`
4. Ask clarifying questions — one at a time; understand purpose, constraints, success criteria. Not in the restatement reply.
5. Propose 2-3 approaches — with trade-offs and your recommendation, lead with the one you recommend
6. Present the design — in sections scaled to complexity, get approval after each section
7. Hand off to `to-spec` — it synthesises the settled design into a PRD and publishes it to the project's issue tracker
8. Continue the flow — `to-tickets` to slice, then `implement` per ticket

**Terminal states are path-bound.** Architectural: the only skill you invoke next is `to-spec`. Bounded: after approval, implementation proceeds directly through the normal development workflow; no spec. Spike: the terminal state is a reported recommendation.

## The Process (bounded & architectural)

A spike stops at "present the probe, get a nod." Sections from **Exploring approaches** onward are architectural-path depth — for bounded work, context plus a few questions plus a short in-chat design is the whole process.

**Understanding the idea:**
- The restatement already happened, and they have had a chance to correct it. Do not reopen with your theory.
- Check the current project state first (files, docs, recent commits).
- Assess scope before detailed questions: if the request describes multiple independent subsystems ("a platform with chat, file storage, billing, and analytics"), flag it immediately. Don't refine details of a project that needs decomposing first.
- If the project is too large for one spec, help decompose into sub-projects: what are the independent pieces, how do they relate, what order to build? Then brainstorm the first sub-project. Each sub-project gets its own spec → tickets → implementation cycle.
- For appropriately-scoped work, ask questions one at a time. Prefer multiple choice, but open-ended is fine. One question per message. Focus on purpose, constraints, success criteria.

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs.
- Present conversationally with your recommendation and reasoning; lead with the recommended option and explain why.
- YAGNI ruthlessly — remove unnecessary features from every approach.

**Presenting the design:**
- Once you understand what you're building, present the design.
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced.
- Ask after each section whether it looks right so far.
- Cover: architecture, components, data flow, error handling, testing.

**Design for isolation and clarity:**
- Break the system into smaller units, each with one clear purpose, communicating through well-defined interfaces, understandable and testable independently. (See `codebase-design` for the deep-module vocabulary.)
- For each unit: what does it do, how do you use it, what does it depend on? Can someone understand it without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.

**Working in existing codebases:**
- Explore the current structure before proposing changes; follow existing patterns.
- Where existing code has problems that affect the work (a file grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design. Don't propose unrelated refactoring.

## Recording the Decision

If the design settles an architectural decision worth remembering — a technology choice, a boundary, a trade-off future work must respect — record it as an ADR per the house `adr-standard` (`docs/adr/`). Supersede, don't edit. This is separate from the spec: the spec says what to build, the ADR says why the shape is what it is.

## After the Design (architectural path)

Hand the settled design to `to-spec` rather than writing a bespoke spec file — Staksmith persists specs through the project's configured tracker backend (vault-default), not an ad-hoc `docs/` path. `to-spec` will pause once to confirm the test seams; that is expected. Do NOT invoke any other implementation skill. `to-spec` is the next step.
