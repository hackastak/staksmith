# Domain model layout

Where this repo keeps its domain model and architectural decisions, and the standard they follow.
The `domain-modeling`, `vault-to-code-bridge`, and `improve-codebase-architecture` skills read this
file to know where to write; anyone onboarding reads it to know where to look.

The domain model is **repo-native**. Unlike specs and tickets — which default to the vault — the
glossary and the decision record live in the repository they describe, so the vocabulary evolves
in the same commit as the code that renames a concept, and an ADR is readable by anyone who clones
the repo.

## Layout

Single-context repo (the default):

```
CONTEXT.md              ← the domain glossary
docs/adr/               ← one immutable file per decision, NNNN-slug.md
```

Multi-context repo (a monorepo with distinct bounded contexts) — one glossary and one ADR trail
per context, plus a root glossary for shared language:

```
CONTEXT.md              ← shared / cross-context vocabulary
contexts/
  ordering/
    CONTEXT.md
    docs/adr/           ← decisions local to this context
  billing/
    CONTEXT.md
    docs/adr/
```

Use the single-context layout unless this repo actually has separate bounded contexts. Do not
scaffold `contexts/` speculatively — it is created only when a second context genuinely appears.

## CONTEXT.md — the glossary

`CONTEXT.md` is a glossary and nothing else: a tight definition per term, then an `_Avoid_` line
naming the synonyms being ruled out. No implementation details, no instructions, no decisions —
those go to `CLAUDE.md` (how to work here) and `docs/adr/` (what was decided) respectively.

Create it lazily. There is no empty template to fill in; `domain-modeling` writes the first entry
the moment the first term is resolved.

## docs/adr/ — the decision record

Architectural decisions follow the **house ADR standard** (the `adr-standard` skill). In short:

- **One file per ADR** at `docs/adr/NNNN-slug.md`, zero-padded sequential numbering from `0001`,
  numbers never reused. The slug names the *question*, not the outcome (`0007-session-storage.md`,
  not `0007-use-redis.md`).
- **Mandatory sections, all five, in order:** Status · Problem Statement · Considered Options (each
  with real pros **and** cons) · Decision · Consequences.
- **Two gates, both must hold** for a decision to earn an ADR: it is hard to reverse **and** it
  involved a genuine trade-off. A hard-to-reverse decision with no real alternative is a fact for
  `CONTEXT.md` or the README; a reversible trade-off is a commit message.
- **Immutable — supersede, don't edit.** An accepted ADR is never rewritten. The only line that
  may change is `Status`, to `Deprecated` or `Superseded by ADR-NNNN`. To change a decision, write
  a new ADR at the next number that lists the old one as a considered option and references it.

`docs/adr/` is created lazily too — when the first decision earns a record, not before. Read the
full standard in the `adr-standard` skill before writing or superseding one.

## Coordination with generated docs

`vault-to-code-bridge` generates `CLAUDE.md` and `ARCHITECTURE.md` and links **out** to
`docs/adr/` by path — it never inlines ADR bodies, because a regenerated document cannot be
immutable. Keep ADRs outside any generated file so the immutability guarantee holds.
