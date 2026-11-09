# Architect knowledge

Reference for the procedure and for the read-only `architect` agent. The procedure is `skills/architect/SKILL.md`. This file does not authorize implementation.

Candidate screening uses `design-red-flags.md`. An accepted decision that is hard to reverse and had a real trade-off is an ADR. Write it with `adr-standard`, not a private format. The sample below is an illustration of the consequences shape, not the house template.

## Review anti-patterns

- **Big ball of mud.** No clear structure.
- **Golden hammer.** The same solution for every problem.
- **Premature optimization.** Optimizing before a measured hot path.
- **Not invented here.** Rejecting an existing solution without a constraint that forces it.
- **Analysis paralysis.** Planning past the point a sketch could be tested.
- **Magic.** Behavior a reader cannot trace from the types.
- **Tight coupling.** A change in one module forces edits in unrelated callers.
- **God object.** One type owns unrelated decisions.

## Patterns worth reaching for

Use these as candidates, not as a default stack.

### Interface

- **Composition.** Build a complex surface from small modules with one job each.
- **Container and presenter.** Keep data loading off the rendering surface.
- **Repository.** Hide storage behind one owner. Callers do not see the query shape.
- **Service layer.** Business decisions in pure functions. The shell parses, calls, and serializes.
- **Event-driven.** Async work crosses a boundary as a fact, not as a shared mutable object.

### Data

- **Normalize the write model** when two writers would otherwise copy the same invariant.
- **Denormalize a read model** when the access pattern is a query, not a second writer.
- **Cache at the read boundary** after the owner has the answer, not inside every caller.
- **Eventual consistency** only when a stale read is an accepted tradeoff, named in the rationale.

## Review checklist

### Functional

- [ ] Call sites are written before the types
- [ ] API contracts are defined at the boundary, not as leaked wire types
- [ ] Data models name their owner
- [ ] Error modes are part of the interface

### Non-functional

- [ ] Latency or throughput targets are numbers, or explicitly unset
- [ ] Scaling assumption is named (one process, many readers, many writers)
- [ ] Authz and external payloads stay at the boundary
- [ ] Availability target is set, or explicitly unset

### Technical

- [ ] Module map names what each module hides
- [ ] Data flow is traceable from input to output through signatures alone
- [ ] Integration points are adapters, not shared internals
- [ ] Testing strategy goes through the interface, not the internals

### Operations

- [ ] Deploy and rollback are named when the change is hard to reverse
- [ ] The signal that would show a wrong sketch early is named

## ADR illustration

House format is `adr-standard`. This sample only shows a consequences block worth keeping:

```markdown
# ADR-001: Use Redis for vector storage

## Context
Need to query 1536-dimensional embeddings for semantic search.

## Decision
Use Redis Stack with vector search.

## Consequences

### Positive
- Vector similarity search stays under 10ms at the expected corpus
- One process to operate

### Negative
- In-memory storage costs more as the corpus grows
- Single node is a single failure domain without clustering

### Alternatives considered
- PostgreSQL pgvector: persistent, slower at this corpus size
- A managed vector service: less to operate, a vendor boundary

## Status
Accepted
```
