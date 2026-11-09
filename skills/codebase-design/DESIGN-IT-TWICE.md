# Design It Twice

When the user wants to explore alternative interfaces for a chosen deepening candidate, fan out parallel sub-agents and compare what comes back. Based on "Design It Twice" (Ousterhout) — your first idea is unlikely to be the best.

Uses the vocabulary in [SKILL.md](SKILL.md) — **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Before spawning sub-agents, write a user-facing explanation of the problem space for the chosen candidate:

- The constraints any new interface would need to satisfy
- The dependencies it would rely on, and which category they fall into (see [DEEPENING.md](DEEPENING.md))
- A rough illustrative code sketch to ground the constraints — not a proposal, just a way to make the constraints concrete

Show this to the user, then immediately proceed to Step 2. The user reads and thinks while the sub-agents work in parallel.

### 2. Fan out the designers

Spawn 3+ sub-agents with Claude Code's **Agent tool**, `subagent_type: "general-purpose"`. Issue every call **in a single message** so they actually run concurrently — sequential calls waste the whole point of the pattern. Each agent must produce a **structurally distinct** interface for the deepened module. Whole-shape alternatives, not point fixes inside one shape. If you cannot produce a second distinct shape, stop. The design space was not exhausted.

If the user has explicitly opted into multi-agent orchestration, the same fan-out can run as a `Workflow` `parallel()` stage instead. Default to the Agent tool.

Prompt each sub-agent with a separate technical brief (file paths, coupling details, dependency category from [DEEPENING.md](DEEPENING.md), what sits behind the seam). The brief is independent of the user-facing problem-space explanation in Step 1. Give each agent a different design constraint:

- Agent 1: "Minimize the interface — aim for 1–3 entry points max. Maximise leverage per entry point."
- Agent 2: "Maximise flexibility — support many use cases and extension."
- Agent 3: "Optimise for the most common caller — make the default case trivial."
- Agent 4 (if applicable): "Design around ports & adapters for cross-seam dependencies."

Include the [SKILL.md](SKILL.md) vocabulary in every brief, plus the project's `CONTEXT.md` glossary if one exists (see `domain-modeling`), so each sub-agent names things consistently with both the architecture language and the project's domain language. If there's no `CONTEXT.md`, skip it silently.

Each sub-agent writes usage first, then derives the interface from that usage. When they diverge, reconcile the sketch to the usage, not the reverse. Bodies stay `not implemented`.

Each sub-agent outputs:

1. Usage: the README-style call, plus two or three real call sites. Write this before the types.
2. Interface derived from that usage (types, methods, params — plus invariants, ordering, error modes)
3. What the implementation hides behind the seam
4. Dependency strategy and adapters (see [DEEPENING.md](DEEPENING.md))
5. Trade-offs — where leverage is high, where it's thin

Sub-agent reports are not shown to the user. Relay the designs yourself in Step 3.

### 3. Present and compare

Present designs sequentially so the user can absorb each one, then compare them in prose. Contrast by **interface depth** (prefer the design that hides more complexity behind a smaller public surface), **locality** (where change concentrates), and **seam placement**.

If a candidate hits the scrap tells in [SKILL.md](SKILL.md) (Scrap a wrong shape), throw it out. Do not bolt a fix onto a wrong shape and call it a hybrid.

After comparing, give your own recommendation: which design you think is strongest and why. If elements from different designs would combine well, propose a hybrid. Be opinionated — the user wants a strong read, not a menu.

If the chosen direction contradicts an accepted ADR in `docs/adr/`, say so explicitly and let the user decide whether the friction warrants a superseding ADR. Never edit an accepted ADR.
