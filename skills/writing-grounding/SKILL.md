---
name: writing-grounding
description: The grounding system shared by the writing skills — every concept is either a prerequisite the reader brings or is introduced by an earlier move.
disable-model-invocation: true
origin: Hackastak
---

The shared reference for **grounding**, used by `writing-beats`, `writing-shape`, and `article-writing`. It lives in one place so the rule reads the same whichever skill you came from.

Each of those skills has its own word for a unit of the draft — a **beat** in `writing-beats`, a **block** in `writing-shape`, a section or paragraph in `article-writing`. This reference calls them all **moves**. Keep your skill's own word while you work; the rule is the same one.

## The rule

Every **concept** has to be **grounded** before a move can lean on it: the reader either walked in knowing it or met it in an earlier move. A move that reaches for an ungrounded concept loses the reader. That is the one move a piece can't make.

The unit is the concept, not the word for it. A move can lean on an idea the reader lacks with no jargon in sight — plain language doesn't ground anything by itself. Where a concept has a name, a **term**, grounding it means landing the idea and the term together.

## The two ways a concept gets grounded

- **Prerequisite** — grounded before the first move. The reader brings it. Fixed at the start.
- **Introduced** — a move establishes it, and from then on it's grounded for every later move.

So each move does two jobs: it **requires** concepts that are already grounded, and it **grounds** new ones. Keep a running list of what's grounded so far and update it each time a move lands. That list is the state of the piece.

## The lever

The big decision is what you make a **prerequisite** versus what you ground inside the piece. Demand too much up front and you shut out readers who don't have it. Ground too much inside and the opening drowns in definitions.

Settle this with the user when you establish prerequisites, before drafting anything. Then revisit it whenever a tempting move turns out to require a concept nothing has grounded yet. The fix is one of two things: a grounding move before it, or promoting the concept to a prerequisite.

## Grounding is a dependency graph

Requires-and-grounds makes the piece a directed graph: each concept depends on the moves that ground it, and every move depends on the concepts it requires. Ordering the piece means respecting that graph.

This is why an ungrounded concept is never just a wording problem. When you ask "what does the reader need next?" and the honest answer names something nothing has grounded, that concept **is** the answer — ground it first, here or earlier, or you can't make the move.

## Applying it in each mode

**Journey of beats** (`writing-beats`) — the graph is what drives the choose-your-own-adventure. A candidate beat is only reachable if everything it requires is already grounded, and picking a beat that grounds concept X unlocks every beat that was waiting on X. When you offer next beats, they must all be reachable from the current grounded set, and you say what each one grounds so the user can see which paths it opens.

**Argued structure** (`writing-shape`) — the graph decides order. After the opening lands, "what does the reader need to hear next?" is answered against the grounded set. This is gap-naming one level down from the pile: there the raw material is missing something, here the article is missing a foundation.

**Editing an existing article** (`article-writing`) — the article already has an order, and that order may not respect the graph. Before editing, walk the piece and confirm a dependency-respecting section plan with the user. A section that leans on a concept a later section introduces is the defect to look for.

## Out of scope

Grounding governs what the reader can follow. It says nothing about voice, brand, SEO, or formatting — those belong to `article-writing` and `polish`. A perfectly grounded piece can still be badly written.
