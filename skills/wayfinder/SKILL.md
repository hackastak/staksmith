---
name: wayfinder
description: Plan a huge chunk of work — more than one agent session can hold — as a shared map of decision tickets, and resolve them one at a time until the way to the destination is clear. Use when an effort is too big and too foggy to spec yet, or when the user invokes /wayfinder.
category: "Workflow & Meta"
origin: Hackastak
disable-model-invocation: true
---

# Wayfinder

A loose idea has arrived — too big for one agent session, and wrapped in fog: the way from here to the **destination** isn't visible yet. Wayfinding is about finding that way, not charging at the destination. This skill charts the way as a **shared map**, then works its **decision tickets** — questions whose resolution is a decision, not slices of a build to execute — one at a time until the route is clear.

The destination varies per effort, and naming it is the first act of charting — it shapes every ticket. It might be a spec to hand off and iterate on, a decision to lock before planning starts, or a change made in place like a data-structure migration. The map is domain-agnostic: engineering work, course content, whatever fits the shape.

## Plan, don't do

Wayfinder is **planning** by default: each ticket resolves a decision, and the map is done when the way is clear — nothing left to decide before someone goes and does the thing. The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off. An effort can override this in its **Notes** — carrying execution into the map itself — but absent that, produce decisions, not deliverables.

Downstream, a finished map hands off to `to-spec` → `to-tickets` → `implement`. Wayfinder plans the fog away; those skills execute.

## Refer by name

Every map and ticket has a **name** — its title. In everything the human reads — narration, the map's Decisions-so-far — refer to it by that name, never by a bare id, number, or slug. A wall of `#42, #43, #44` is illegible; names read at a glance. The id and link don't vanish — a name wraps its link — but they ride *inside* the name, never stand in for it.

## The Map

The map is a single artifact — the canonical one — with its tickets hanging off it as children.

The map is an **index**, not a store. It lists the decisions made and points at the tickets that hold their detail; a decision lives in exactly one place — its ticket — so the map never restates it, only gists it and links.

**Where the map, its tickets, blocking, and the frontier physically live is backend-specific.** Read the "Wayfinding operations" section of `docs/agents/issue-tracker.md` for how *this* repo expresses them. If no tracker has been configured, the vault backend is the default — run `setup-hackastak` to make the choice explicit.

- **vault** (default) — the map is `1. Projects/<Project>/map.md`; each ticket is `issues/NN-<slug>.md`. `Type:` and `Status:` lines carry the type and claim; `Blocked by: NN, NN` carries the edges; the frontier is found by scanning `issues/` for notes that are open, unblocked, and unclaimed. Wikilink the map to its tickets and back.
- **github** — the map is an issue labelled `wayfinder:map` and tickets are its child issues, each labelled `wayfinder:<type>`. Use GitHub's **native** dependency relationship for blocking — this is the best mode, because it renders the frontier *visually* in GitHub's own UI, so the human sees what's takeable without opening the map. Claiming is assignment: an open, unassigned ticket is unclaimed.
- **local** — the same file shapes as vault, under `.scratch/<effort-slug>/`.

### The map body

The whole map at low resolution, loaded once per session. Open tickets are **not** listed — they are found by scanning or querying, so the map never goes stale against them.

```markdown
## Destination

<what reaching the end of this map looks like — the spec, decision, or change this
effort is finding its way to. One or two lines; every session orients to it before
choosing a ticket.>

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

<!-- the index — one line per resolved ticket: enough to judge relevance, then follow
     the link for the detail the ticket holds -->

- [[<resolved ticket name>]] — <one-line gist of the answer>

## Not yet specified

<!-- see "Fog of war": in-scope fog you can't ticket yet; graduates as the frontier advances -->

## Out of scope

<!-- see "Out of scope": work ruled beyond the destination; closed, never graduates -->
```

### Tickets

Each ticket is a child of the map. Its body is the question, sized to fit one fresh agent session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each ticket carries a **type** — one of `research`, `prototype`, `grilling`, `task` (see [Ticket types](#ticket-types)).

A session **claims** a ticket **first**, before any work, so concurrent sessions skip it.

A ticket is **unblocked** when every ticket blocking it is resolved; the **frontier** is the open, unblocked, unclaimed tickets — the edge of the known.

The answer isn't part of the body — it's recorded on resolution (see [Work through the map](#work-through-the-map)). Assets created while resolving a ticket are linked from the ticket, not pasted into it.

## Ticket types

Every ticket is either **HITL** — human in the loop, worked *with* a human who speaks for themselves — or **AFK**, driven by the agent alone. A HITL ticket only resolves through that live exchange; the agent never stands in for the human's side of it. A grilling agent that answers its own questions has broken this.

- **Research** (AFK) — reading documentation, third-party APIs, or local resources to surface a fact a decision waits on. Resolved by a **`source-research` subagent**. Use when knowledge outside the current working directory is required.
- **Prototype** (HITL) — raise the fidelity of the discussion by making something cheap, rough, and concrete to react to: an outline, a rough take, a stub, or UI/logic code via the `prototype` skill. Links the prototype as an asset. Use when "how should it look" or "how should it behave" is the key question.
- **Grilling** (HITL) — conversation via `grill-with-docs` (the `grill-me` interview with `domain-modeling` capturing terms and ADRs), one question at a time. The default case.
- **Task** (HITL or AFK) — manual work that must happen before a *decision* can be made: nothing to decide, prototype, or research, but the discussion is blocked until it's done. Signing up for a service so its API can be judged, provisioning access, moving data so its shape can be seen. This is the one type that *does* rather than decides — and it earns its place by unblocking a decision, not by delivering the destination. The agent drives it alone where it can; otherwise it hands the human a precise checklist. Resolved when the work is done; the answer records what was done and any resulting facts (where credentials live, new URLs, row counts) that later tickets depend on.

## Fog of war

The map is *deliberately* incomplete: don't chart what you can't yet see. Beyond the live tickets lies the **fog of war** — the dim view of decisions and investigations you can tell are coming but can't yet pin down, because they hang on questions still open. Resolving a ticket clears the fog ahead of it, graduating whatever's now specifiable into fresh tickets — one at a time, until the way to the destination is clear and no tickets remain.

The map's **Not yet specified** section is where that dim view is written down: the suspected question, the area to revisit later. It's the undiscovered frontier *toward* the destination — everything here is in scope, just not sharp enough to ticket. Write as loosely or as fully as the view allows; it doubles as a signpost for collaborators reading where the effort is headed.

**Fog or ticket?** The test is whether you can state the question precisely now — *not* whether you can answer it now.

- **Ticket** when the question is already sharp, even if it's blocked and you can't act on it yet.
- **Not yet specified** when you can't yet phrase it that sharply. Don't pre-slice the fog into ticket-sized pieces: it's coarser than a ticket, and one patch may graduate into several tickets, or none, once the frontier reaches it.

**Not yet specified** excludes what's already decided, what's already a live ticket, and what's out of scope.

## Out of scope

Fog only ever gathers *toward* the destination. The destination fixes the scope, so work beyond it is **out of scope** — it isn't fog, and it doesn't belong in **Not yet specified**. It gets its own **Out of scope** section on the map: work you've consciously ruled out of *this* effort. Scope, not sharpness, lands it here.

Out-of-scope work never graduates — the frontier stops at the destination — so it returns only if the destination is redrawn, and then as a fresh effort, not a resumption.

Ruling something out of scope is a scoping act, not a step on the route. When a ticket that already exists turns out to sit past the destination — mis-scoped in while charting, or exposed by a resolution — **resolve it closed** (a closed ticket is unambiguously off the frontier) and leave one line in the **Out of scope** section: the gist plus why it's out, linking the closed ticket. It stays out of **Decisions so far**, which records the route actually walked; a scope boundary isn't a step on it.

## Invocation

Two modes. Either way, **never resolve more than one ticket per session** — with the exception of research tickets, which run in parallel subagents.

### Chart the map

The user invokes with a loose idea.

1. **Name the destination.** Run `grill-with-docs` to pin down what this map is finding its way to — the spec, decision, or change. The destination fixes the scope, so it's settled first.
2. **Map the frontier.** Grill again, **breadth-first** this time: fan out across the whole space rather than going deep on any one thread, surfacing the open decisions and the first steps takeable now. **If this surfaces no fog** — the way to the destination is already clear, the whole journey small enough for one session — you don't need a map. Stop and say so; `to-spec` is probably the right skill instead.
3. **Create the map** with Destination and Notes filled in, Decisions-so-far empty, and the fog sketched into **Not yet specified**.
4. **Create the tickets you can specify now**, then wire the blocking edges in a **second pass** — tickets need identities before they can reference each other. Wiring sorts them into the frontier and the blocked; everything you can't yet specify stays in the fog.
5. **Fire the research subagents.** For each `research` ticket you just created, spin up a `source-research` subagent to resolve it in parallel, and record a context pointer from the ticket to wherever its findings landed.
6. **Stop.** Charting is one session's work; it hand-resolves nothing.

Vault and remote writes follow the tracker's draft → confirm → write gate — show the map and the tickets before creating them.

### Work through the map

The user invokes with a map. A ticket is **optional** — without one, you pick the next decision, not the user.

1. Load the **map** — the low-res view, not every ticket body.
2. **Choose the ticket.** If the user named one, use it. Otherwise take the first frontier ticket in order. **Claim it before any work.**
3. **Resolve it — zoom as needed.** Fetch the full body of any related or resolved ticket on demand; invoke the skills the `## Notes` block names. If in doubt, use `grill-with-docs`.
4. **Record the resolution.** Post the answer on the ticket, mark it resolved, and **append a context pointer** — gist plus link — to the map's Decisions-so-far.
5. **Update the map.** Add newly-surfaced tickets (create, then wire). Graduate any fog the answer has made specifiable, clearing each graduated patch from **Not yet specified** so it lives only as its new ticket. If the answer reveals that a ticket — this one or another — sits beyond the destination, **rule it out of scope** rather than resolving it on the route. If the decision invalidates other parts of the map, update or delete those tickets.

The user may run unblocked tickets in parallel, so expect other sessions to be editing the map concurrently. Re-read before you write.

## Related skills

- **`grill-with-docs`** — the interview that charts the map and resolves grilling tickets.
- **`source-research`** — resolves research tickets as a background subagent.
- **`prototype`** — resolves prototype tickets.
- **`to-spec` → `to-tickets` → `implement`** — the handoff once the way is clear.
