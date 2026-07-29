---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a visual Markdown report in the vault, then grill through whichever one you pick. Use when the user wants an architecture review, asks where the codebase is getting hard to change, or invokes /improve-codebase-architecture.
origin: Hackastak
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

This skill is *informed* by the project's domain model and built on a shared design vocabulary:

- **`codebase-design`** supplies the architecture vocabulary — **module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality** — and its principles: the deletion test, "the interface is the test surface", "one adapter means a hypothetical seam, two means a real one". Use these terms exactly in every suggestion. Don't drift into "component", "service", "API", or "boundary".
- **`CONTEXT.md`** gives names to good seams; the ADRs in `docs/adr/` record decisions this skill should not re-litigate.

## Process

### 1. Explore

**Scope before you scan — YAGNI.** Deepening a module pays off by making future changes to it easier, so weight the parts of the codebase that have recently changed. Decide *where* to look before you look:

- If the user named a direction — a module, a subsystem, a pain point — take it and skip the inference below.
- Otherwise walk back a good stretch of `git log --oneline` to find the codebase's hot spots, the files and areas that keep coming up, and let those paths pull your attention first. If the changes are scattered with no clear hot spot, widen the net.

Read `CONTEXT.md` and any ADRs in the area before you start.

Then use the Agent tool with `subagent_type=Explore` to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, while the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

Classify each candidate's dependencies using the four categories in `codebase-design`'s `DEEPENING.md` — in-process, local-substitutable, ports & adapters, mock — since the category determines how the deepened module gets tested.

### 2. Write the report to the vault

The report is a **Markdown note in the vault**, not a file in the repo and not a temp file. It's a durable, wikilinkable artifact — an architecture review is worth keeping and worth linking to from the project's other notes.

**Locate the project folder** by fuzzy-matching the repo name against the folders in `~/Developer/My_Notes/1. Projects/`, tolerating case, separators, and word order (`oms-athena` ↔ `OMS_Athena`). One clear match: use it. Ambiguous or no match: **ask** — never guess, never create a project folder silently.

Write to `1. Projects/<Project>/Architecture_Review_<YYYY-MM-DD>.md`. If a review already exists for today, suffix it rather than overwriting — old reviews are a record of what the codebase used to look like.

The format guide is [MD-REPORT.md](MD-REPORT.md): Mermaid for graph-shaped structure, ASCII depth-boxes for the mass/depth visual, badges as text, a before/after per candidate, and a Top recommendation at the end.

**Optional rich-visuals mode.** After writing the note, you may offer to publish the same report as a Claude Code **Artifact** — it renders Mermaid natively, is shareable by URL, and needs no CDN. Offer it; don't do it unprompted. The vault note stays the canonical artifact either way.

**Use `CONTEXT.md` vocabulary for the domain and `codebase-design` vocabulary for the architecture.** If `CONTEXT.md` defines "Order", talk about "the Order intake module" — not "the FooBarHandler", and not "the Order service".

**ADR conflicts.** If a candidate contradicts an accepted ADR, surface it *only* when the friction is real enough to warrant reopening the decision, and mark it clearly in the candidate's block. ADRs are immutable — reopening one means a new ADR that supersedes it, never an edit (see `adr-standard`). Don't list every theoretical refactor an ADR forbids.

Do **not** propose interfaces yet. Once the note is written, tell the user its path and ask: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, run **`grill-with-docs`** to walk the decision tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, which tests survive. One question at a time; don't act until they confirm shared understanding.

Side effects happen inline as decisions crystallise, via `domain-modeling`:

- **Naming a deepened module after a concept not in `CONTEXT.md`?** Add the term. Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term mid-conversation?** Update `CONTEXT.md` right there.
- **User rejects a candidate for a load-bearing reason?** Offer an ADR: *"Want me to record this so future architecture reviews don't re-suggest it?"* Only offer when the reason would actually be needed by a future explorer — skip ephemeral reasons ("not worth it right now") and self-evident ones. The reason must clear both gates of the house standard.
- **Want to explore alternative interfaces for the deepened module?** Use `codebase-design`'s `DESIGN-IT-TWICE.md` — fan parallel sub-agents out to design the interface several radically different ways, then compare on depth, locality, and seam placement.

This skill plans; it doesn't build. When the shape is agreed, hand off to `to-tickets` (for a wide refactor, the expand–contract sequence lives there) or straight to `implement` for a single deepening. **Never commit** — if any file was touched during the session, stage it and hand back.

## Related skills

- **`codebase-design`** — the vocabulary, the deletion test, `DEEPENING.md`, `DESIGN-IT-TWICE.md`.
- **`diagnosing-bugs`** — hands off here at Phase 6, when "what would have prevented this bug?" turns out to be architectural. That handoff arrives with specifics; use them as the scoping direction in step 1.
- **`domain-modeling` / `adr-standard`** — the glossary and ADR trail this skill maintains and respects.
- **`to-tickets` / `implement`** — where an agreed deepening goes to get built.
