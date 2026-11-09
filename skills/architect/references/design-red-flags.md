# Design red flags

Screen every candidate before synthesis. A red flag is a reason to revise or reject the shape. The words module, interface, depth, and seam mean what `codebase-design` says they mean.

## Shallow module

A shallow module exposes a large interface while hiding little complexity. Prefer a simple interface backed by substantial behavior.

Do not confuse a deep module with a deep call chain. A deep call chain scatters understanding. A deep module concentrates capability behind one interface.

Signs:

- Callers coordinate several methods to complete one operation.
- Public options expose internal stages or implementation choices.
- Learning the interface does not save the caller from learning the implementation.

## Information leakage

A representation, policy, or protocol detail appears in more than one module, so changing it requires coordinated edits.

Public re-exports of transport or wire types are leakage. Parse external data into domain types behind the interface. Keep storage schemas, framework objects, and protocol details private.

## Temporal decomposition

Modules organized by execution order (load, validate, transform, save) often repeat one representation and its invariants across several boundaries.

Group code around the knowledge it owns. Methods that run at different times can still belong to one module when they protect the same decisions.

## Pass-through method

A method that forwards the same arguments to another method with the same shape adds a layer without hiding complexity.

Remove it, or move the work to the module that can finish the operation. Keep a forwarding boundary only when it adds policy, adaptation, or a distinct abstraction.

## Split ownership

More than one module writes the same state or keeps its own copy. An edit to one writer cannot see the others, so their rules diverge.

Give each piece of state one owner. Other modules read it or ask the owner to change it.

## Two ways to do one task

The design supports more than one way to do the same task. The next edit copies whichever way it finds first, so every way keeps gaining callers.

Keep one way. Move callers off the others and delete them in the same change.

## Importable internals

A caller can import a module's internals, so the shortest path that compiles becomes part of the interface.

Make internals unreachable from outside the module, so an outside import fails the build.

## Hand-synced list

Two or more places list the same items, and adding an item means editing every list.

Keep one list and derive the others from it. If a list cannot be derived, make the build fail when the lists disagree.
