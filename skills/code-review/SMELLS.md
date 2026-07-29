# The Smell Baseline

Twelve code smells from Fowler's *Refactoring* (ch. 3), used as a structural lens over code under review. This baseline applies even when a repo documents no standards of its own — it is the floor, not the ceiling.

Two rules bind it:

- **The repo overrides.** A documented repo standard always wins. Where the repo endorses something this baseline would flag, suppress the smell and say nothing.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Report them as Minor or Nit unless the smell is the *cause* of a correctness or security finding, in which case report that finding instead and mention the smell as the underlying shape.

And one exclusion: **skip anything tooling already enforces.** If the linter catches it, the linter will say so — a review that repeats the linter wastes the reader's attention on the findings only a human could have made.

Each smell reads *what it is* → *how to fix*.

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → Rename it; if no honest name comes, the design is murky and that's the real finding.
- **Duplicated Code** — the same logic shape appears in more than one place. → Extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → Move the method onto the data it envies.
- **Data Clumps** — the same few fields or parameters keep travelling together; a type wanting to be born. → Bundle them into one type and pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → Give the concept its own small type. (Check `CONTEXT.md` — a clump with a glossary entry is a type waiting to happen.)
- **Repeated Switches** — the same `switch` or `if`-cascade on the same type recurs in several places. → Replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files. → Gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → Split it so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs nothing actually has. → Delete it; inline back until a real need shows. (One adapter means a hypothetical seam; two means a real one.)
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → Hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → Cut it, call the real target directly. (This is the deletion test from `codebase-design`: if deleting it makes complexity vanish, it was a pass-through.)
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → Drop the inheritance, use composition.

## Relationship to the deep-module vocabulary

Several of these smells are the same observation `codebase-design` makes in different words. Middle Man is a shallow module. Shotgun Surgery is a failure of locality. Speculative Generality is a seam with only one adapter. When a smell recurs across a review, say so once at the architectural level rather than filing it a dozen times — that is the finding worth having.
