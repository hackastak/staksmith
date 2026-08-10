---
name: prototype
description: Build a throwaway prototype to answer a design question. Use when the user wants to sanity-check whether a state model or logic feels right, or explore what a UI should look like.
category: "Workflow & Meta"
origin: Hackastak
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered — from the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [LOGIC.md](LOGIC.md). Build a tiny interactive terminal app that pushes the state machine through cases that are hard to reason about on paper.
- **"What should this look like?"** → [UI.md](UI.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar. This branch assumes a **web frontend** — a routed app with a component library (Next, React Router, Tailwind/shadcn/MUI). Backend and logic work routes to LOGIC regardless of how the question is phrased.

The two branches produce very different artifacts — getting this wrong wastes the whole prototype. If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Rules that apply to both

1. **Throwaway from day one, and clearly marked as such.** Locate the prototype code close to where it will actually be used (next to the module or page it's prototyping for) so context is obvious — but name it so a casual reader can see it's a prototype, not production. For throwaway UI routes, obey whatever routing convention the project already uses; don't invent a new top-level structure.
2. **One command to run.** Whatever the project's existing task runner supports — `pnpm <name>`, `python <path>`, `bun <path>`, etc. The user must be able to start it without thinking.
3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. If the question explicitly involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE — wipe me" name.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn something fast.
5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the user can see what changed.
6. **Capture it when done.** See below — the answer and the code go to two different places.

## Capture

A prototype produces two things worth keeping, and they don't live together.

**The answer → the vault.** The verdict and the question it settled go into the project note: `~/Developer/My_Notes/1. Projects/<Project>/`, fuzzy-matched from the repo name the same way the other vault skills do it (ask if it's ambiguous, never create a project folder silently). Append to the existing project note, or to the tracking ticket in `issues/` if the prototype was resolving one. If the repo uses the `github` tracker instead, the answer goes on the tracking issue.

Write the verdict as *"we asked X, we learned Y, so we're doing Z"* — a paragraph, not a transcript. This is the durable part; the code is disposable by design.

**The code → a throwaway branch off main.** Create the branch (`prototype/<slug>`), move the prototype code onto it, and **stage everything — then stop.** Do not commit and do not push; hand control back and tell the user the branch name and what's staged. Leave a context pointer to the branch in the vault note so it can be found again.

The main branch keeps only the validated decision, folded into the real code — and that fold is normal work, subject to the usual review and the usual manual commit.

If a snippet from the prototype encodes a decision more precisely than prose can — a state machine, a reducer, a schema, a type shape — inline the decision-rich part of it in the vault note or ticket. `to-spec` and `to-tickets` will carry it forward from there.

## Related skills

- **`codebase-design`** — the LOGIC branch's "pure portable module behind a small interface, thin throwaway shell over it" is exactly the module/interface/seam thinking from that skill.
- **`wayfinder`** — prototype tickets on a map resolve through this skill.
- **`to-spec` / `to-tickets`** — carry the verdict, and any decision-encoding snippet, into the build.
- **`grill-me`** — for a question that can be settled by conversation. Prototype when talking has stopped moving it.
