---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or AI-navigable, or when another skill needs the deep-module vocabulary.
category: "Workflow & Meta"
origin: Hackastak
---

# Codebase Design

Design **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. Use this language and these principles wherever code is being designed or restructured. The aim is leverage for callers, locality for maintainers, and testability for everyone.

## Scope: this is a design-time vocabulary

These terms govern **design discussions** — greenfield design, deepening work, interface exploration, architecture reviews. They are how you and the user talk about shape while deciding it.

They are **not** a renaming mandate for existing code. Don't rename a React component to a "module", a NestJS service to something else, or a DDD bounded context to a "seam". Frameworks, existing codebases, and third-party APIs keep their own names. The bans below apply to the conversation, not the filesystem.

## Glossary

Use these terms exactly — don't substitute "component," "service," "API," or "boundary." Consistent language is the whole point.

**Module** — anything with an interface and an implementation. Deliberately scale-agnostic: a function, class, package, or tier-spanning slice. _Avoid_: unit, component, service.

**Interface** — everything a caller must know to use the module correctly: the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics. _Avoid_: API, signature (too narrow — they refer only to the type-level surface).

**Implementation** — what's inside a module, its body of code. Distinct from **Adapter**: a thing can be a small adapter with a large implementation (a Postgres repo) or a large adapter with a small implementation (an in-memory fake). Reach for "adapter" when the seam is the topic; "implementation" otherwise.

**Depth** — leverage at the interface: the amount of behaviour a caller (or test) can exercise per unit of interface they have to learn. A module is **deep** when a large amount of behaviour sits behind a small interface, **shallow** when the interface is nearly as complex as the implementation.

**Seam** _(Michael Feathers)_ — a place where you can alter behaviour without editing in that place; the *location* at which a module's interface lives. Where to put the seam is its own design decision, distinct from what goes behind it. _Avoid_: boundary (overloaded with DDD's bounded context).

**Adapter** — a concrete thing that satisfies an interface at a seam. Describes *role* (what slot it fills), not substance (what's inside).

**Leverage** — what callers get from depth: more capability per unit of interface they learn. One implementation pays back across N call sites and M tests.

**Locality** — what maintainers get from depth: change, bugs, knowledge, and verification concentrate in one place rather than spreading across callers. Fix once, fixed everywhere.

## Deep vs shallow

**Deep module** = small interface + lots of implementation:

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid):

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

When designing an interface, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally composed of small, mockable, swappable parts — they just aren't part of the interface. A module can have **internal seams** (private to its implementation, used by its own tests) as well as the **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a seam unless something actually varies across it.

## Designing for testability

Good interfaces make testing natural:

1. **Accept dependencies, don't create them.**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results, don't produce side effects.**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **Small surface area.** Fewer methods = fewer tests needed. Fewer params = simpler test setup.

## Relationships

- A **Module** has exactly one **Interface** (the surface it presents to callers and tests).
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** produces **Leverage** for callers and **Locality** for maintainers.

## Usage first, then depth

When sketching an interface, write the caller's usage first. Two or three real call sites, then derive the type sketch from that usage. Bodies stay `not implemented`. Tricky logic is pseudocode, not a guessed implementation. When usage and the sketch diverge, reconcile the sketch to the usage, not the reverse.

Require at least two structurally distinct candidates before picking one, even when the first looks sufficient. Whole-shape alternatives, not point fixes inside one shape. Compare them on interface depth: prefer the design that hides more complexity behind a smaller public surface. `/architect` runs this as Phase B. These rules still apply when the entry point is this skill or `improve-codebase-architecture`.

## Scrap a wrong shape

If a design keeps producing friction the sketch cannot absorb, throw it out. Do not bolt fixes onto a wrong design. That bar is Fix Root Causes in `rules/common/development-workflow.md`.

The signal is a pattern, not one instance. Tells:

- The same workaround shape appearing across unrelated code.
- Several unrelated edge cases that each need a special-case branch.
- Types that need escape hatches (`any`, casts, optional fields that are always set) to compile.
- A "we need a lock" reflex when the sketch said the state was not shared.
- Callers that must know the abstraction's internal rules to use it.
- Two or more independent deviations of the same shape.

A few edge cases do not condemn an architecture. Complexity in the data is not complexity in the design.

When you scrap, redesign as if the new constraints had been day-one assumptions. Subtract before adding. The new sketch should be smaller than the old one before it grows. Return to usage-first sketching and compare the new candidates on interface depth. This is not the `/architect` loop. Do not role-play `interrogate`, `blast-radius`, or `arena` from here. Those run when `/architect` is the entry point.

## Rejected framings

- **Depth as ratio of implementation-lines to interface-lines** (Ousterhout): rewards padding the implementation. We use depth-as-leverage instead.
- **"Interface" as the TypeScript `interface` keyword or a class's public methods**: too narrow — interface here includes every fact a caller must know.
- **"Boundary"**: overloaded with DDD's bounded context. Say **seam** or **interface**.

## Going deeper

- **Deepening a cluster given its dependencies** — see [DEEPENING.md](DEEPENING.md): dependency categories, seam discipline, and replace-don't-layer testing.
- **Exploring alternative interfaces** — see [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md): fan out parallel sub-agents to design the interface several structurally distinct ways. Each candidate writes usage first. Compare on interface depth, locality, and seam placement. Scrap a shape that hits the tells above.

## Related skills

- **`setup-ts-deep-modules`** — mechanically enforces these boundaries in a TypeScript package-structured repo via dependency-cruiser.
- **`improve-codebase-architecture`** — scans a codebase for deepening opportunities using this vocabulary.
- **`diagnosing-bugs`** — Phase 5/6 use *seam* and *deep module* to decide where a fix belongs.
- **`tdd-workflow`** — "TDD at pre-agreed seams" and boundary-only mocking come from this vocabulary.
