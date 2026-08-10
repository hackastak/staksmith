---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when the user wants to pin down domain terminology or a ubiquitous language, record an architectural decision, or when another skill needs to maintain the domain model.
category: "Workflow & Meta"
origin: Hackastak
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* `CONTEXT.md` for vocabulary is not this skill — that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

## Where the model lives

The domain model is **repo-native**. `CONTEXT.md` and `docs/adr/` sit in the repository they describe, not in the vault. The glossary has to evolve in the same commit as the code that renames a concept, and an ADR has to be readable by anyone who clones the repo. This is the deliberate exception to the vault-first habit of the other skills.

It complements `CLAUDE.md` rather than competing with it: `CLAUDE.md` tells an agent how to work in this repo, `CONTEXT.md` tells it what the words mean. Keep instructions out of the glossary and vocabulary out of the instructions.

## File structure

Most repos have a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `CONTEXT-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily — only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up — capture them as they happen. Use the format in [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md).

`CONTEXT.md` should be totally devoid of implementation details. Do not treat `CONTEXT.md` as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

### Offer ADRs sparingly

Only offer an ADR when the decision passes **both** gates of the house standard: it is hard to reverse, and it was a real trade-off. Most decisions in a session pass neither.

The full standard — the gates, the five mandatory sections, and the supersede-don't-edit rule — lives in the **`adr-standard`** skill. Follow it exactly; do not invent a lighter template for a decision that seems small. A decision too small for the full format is a decision that failed the gates.

When a session revisits a decision an existing ADR already settled, the move is a new superseding ADR, never an edit to the old one.

## Vocabulary style

`CONTEXT.md` uses the same shape as the `codebase-design` glossary: a tight definition, then an opinionated `_Avoid_` line listing the synonyms you are ruling out. The two are complementary halves of a project's language. `codebase-design` supplies the *architecture* vocabulary (module, interface, seam, adapter) and is the same in every repo; `CONTEXT.md` supplies the *domain* vocabulary and is different in every repo.
