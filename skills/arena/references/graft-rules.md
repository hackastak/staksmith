# Graft rules

These are the operating rules `arena` used to pull from separate principle notes. They live here so the procedure does not depend on another plugin.

## Separate

When candidates might write the same file, branch, or state object, do not share it.

1. Name the shared mutable target (a file both would write, a branch both would push, a key both would set).
2. Default: give each candidate its own directory or worktree. Merge only when you graft, in this session, after they have stopped writing.
3. Two candidates writing different fields of one shared file is still shared mutation. Do not do that.
4. A lock is not the default. Use one only when a single shared writer is a real invariant, and enforce it with a lockfile, a sequential phase, or one writer. An instruction to "be careful" is not concurrency control.

## Laziness

When two bases feel tied, pick the one with the cleaner boundary or the smaller API.

- Do not repeat the same choice in several places. Put it behind one source of truth.
- Prefer the smaller diff. Fewer lines beat a second abstraction.

## Redesign

When you graft a piece from a loser into the base, do not bolt it on.

- Read the base and the piece you are moving.
- Ask what the base would look like if that requirement had been there from the start.
- Fold the graft in so one mental model still covers the result. Do not paste a second design next to the first.
- Update the types, names, and rationale the graft touches. Leave the rest alone.

## Prove

Verify the synthesized artifact against the real thing before you call the arena done.

- Run the check, read the value, or inspect the diff. "It compiles", a self-report, or a file timestamp is not proof.
- When a check fails, suspect the observation method before you suspect the artifact.
- Prefer a script that fails loud if the claim is wrong, and paste the output. `blast-radius` step 5 is that script when the arena question is what a change breaks.
- Do not paper over a miss. If verification finds a problem the arena missed, re-frame (Phase A) or go back to the graft (Phase E).
