---
name: adr-standard
description: The house standard for Architecture Decision Records — when a decision earns an ADR, the mandatory sections, and the supersede-don't-edit rule. Use when writing, updating, or superseding an ADR, when deciding whether a decision is worth recording, or when another skill needs the ADR format.
category: "Workflow & Meta"
origin: Hackastak
---

# ADR Standard

The house standard for Architecture Decision Records. Every skill that writes an ADR conforms to this one: `domain-modeling`, `vault-to-code-bridge`, `improve-codebase-architecture`, and the `docs/agents/domain.md` seed written by `setup-hackastak`.

An ADR records **why** a decision was made, at the moment it was made, by people who no longer remember the alternatives a year later. The trail is the product. A record that only states what was chosen has thrown away the part that was worth keeping.

## When a decision earns an ADR

Two gates. **Both** must hold:

1. **Hard to reverse.** Undoing it later means migrating data, rewriting call sites across the codebase, or breaking a published contract. If you could change your mind next week with a small diff, it isn't an ADR.
2. **A real trade-off.** Something was genuinely given up. There were at least two defensible options and the losing one had a real case.

A decision that is hard to reverse but had no serious alternative is just a fact — put it in `CONTEXT.md` or the README. A decision with a real trade-off that's trivially reversible is a code comment or a commit message.

Do not add a third gate. "Surprising" in particular was considered and dropped: whether a decision surprises someone depends on who's reading, which makes it useless as a filter.

### What typically qualifies

Decisions of these shapes usually clear both gates. Still check them individually — the shape is a prompt, not a pass.

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library — just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." These stop the next engineer from "fixing" something that was deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it — otherwise someone will suggest GraphQL again in six months.

## Storage

`docs/adr/NNNN-slug.md` — one file per ADR, in the repo the decision governs.

- `NNNN` is a zero-padded sequential number starting at `0001`. Never reuse a number, even if an ADR is superseded or withdrawn.
- `slug` is kebab-case and names the decision, not the outcome: `0007-session-storage.md`, not `0007-use-redis.md`. The outcome may be superseded; the question it answered is stable.
- One decision per file. Resist bundling related decisions — they get superseded at different times.

One file per ADR is what makes immutability real. A regenerated document with an ADR section cannot be immutable, because regeneration rewrites it. If a skill maintains a generated architecture document, ADRs live outside it and the generated document links to them.

## Mandatory sections

Every ADR has all five, in this order. None is optional, and none is omitted because it "doesn't apply" — if Considered Options has nothing real in it, gate 2 failed and this isn't an ADR.

**Status** — one of `Proposed`, `Accepted`, `Deprecated`, or `Superseded by ADR-NNNN`. The only line that may ever change after acceptance.

**Problem Statement** — the forces in play at the time: what pressure prompted the decision, what constraints bound it, what was unknown. Written so a reader a year out understands the situation without needing the code in front of them. This is the section that decays if written lazily.

**Considered Options** — every option that had a real case, each with its own pros and cons. The option you rejected gets an honest hearing, including the pros that made it tempting. A list of straw men is worse than no list, because it hides the trade-off the ADR exists to record.

**Decision** — which option was chosen, stated plainly, and the reason it won over the specific runner-up.

**Consequences** — what follows, good and bad. Name the costs you accepted, the new constraints the codebase now carries, and anything this forecloses. An ADR with only positive consequences is incomplete.

Optional metadata: `Date` and `Deciders`, as frontmatter or a line under the title.

## Immutable — supersede, don't edit

An **Accepted** ADR is never edited. Not to fix reasoning, not to reflect what you'd say now, not to tidy the prose. The record is what was decided and why, at that time, and rewriting it destroys the trail.

The single exception is the **Status** line, which may change to `Deprecated` or `Superseded by ADR-NNNN`.

A `Proposed` ADR may still be edited freely — it isn't a record yet.

### Changing a decision

1. Write a new ADR at the next number. Its Problem Statement says what changed since the old one: new constraints, new information, or a cost that turned out higher than expected.
2. List the superseded decision as one of its Considered Options, with an honest account of why it was right then and isn't now.
3. Reference the old ADR by number in the new ADR's Decision section.
4. Edit **only** the old ADR's Status line to `Superseded by ADR-NNNN`.

`Deprecated` is for a decision no longer in force with nothing replacing it — the subsystem was deleted, or the constraint went away.

## Template

```markdown
# ADR-NNNN: <the decision, named as a question or topic>

**Status:** Proposed
**Date:** YYYY-MM-DD

## Problem Statement

<The forces at the time: the pressure, the constraints, what was unknown.>

## Considered Options

### Option A — <name>

**Pros:** <what made it tempting>
**Cons:** <what it cost>

### Option B — <name>

**Pros:** <...>
**Cons:** <...>

## Decision

<Which option, and why it beat the specific runner-up.>

## Consequences

<What follows, good and bad. The costs accepted. What this forecloses.>
```

## Working with existing ADRs

Before proposing a design, read `docs/adr/` if it exists. When a proposal contradicts an Accepted ADR, say so explicitly, name the ADR by number, and let the user decide whether the friction warrants a superseding ADR. Never quietly design around an accepted decision, and never edit one to make a conflict disappear.

If `docs/adr/` does not exist, proceed silently. `domain-modeling` creates it lazily when the first decision earns a record.
