# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```
// Pseudocode
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

Rationale: Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:
- Handle errors explicitly at every level
- Provide user-friendly error messages in UI-facing code
- Log detailed error context on the server side
- Never silently swallow errors

## Input Validation

ALWAYS validate at system boundaries:
- Validate all user input before processing
- Use schema-based validation where available
- Fail fast with clear error messages
- Never trust external data (API responses, user input, file content)
- Do not re-validate data that a boundary already parsed into a domain type
- Keep business logic in pure functions. Framework, CLI, and transport adapters stay a thin shell
- Do not re-export transport, storage, or framework types through the public surface

## Type System Discipline

In any statically typed language, make the compiler reject impossible states:
- Brand semantic primitives that share an underlying type but mean different things. Validate once at creation, then trust the type
- Treat external data as untyped until a boundary parse returns the domain type
- Derive types from the authoritative schema (protobuf, OpenAPI, GraphQL, migrations, design tokens) instead of hand-rolling a parallel definition
- Exhaust variants so adding a case fails compilation
- If the lesson can be a lint, a schema, or a type, encode it there. Extra prose is only for checks that need judgment

TypeScript syntax for these rules is in [typescript/coding-style.md](../typescript/coding-style.md) and the `coding-standards` skill.

## Design the Shape First

Fold of the remaining pstack design principles: `principle-model-the-domain`, `principle-foundational-thinking`, and `principle-separate-before-serializing-shared-state`. They are rules, not skills. Do not look for those skill directories. Boundary checks already live in [Input Validation](#input-validation). This block is the rest of that set, kept together so it is not ported à la carte.

The mapping: authorization and external payload parsing (an API body, a loan file, a ULAD document) stay at the boundary. Races between writers are a sharing problem, not a lock problem. A domain such as a loan is a structure, not a chain of conditionals.

### Model the Domain

Encode the domain in a structure instead of scattering it across conditionals. Choosing the structure at write time is cheap. Recovering it later reads as a refactor and gets deferred.

Reach for a state machine instead of scattered booleans, a typed model instead of repeated shape assumptions, a registry or discriminated union instead of branches spread across files, or a module that owns one body of domain knowledge instead of a load-validate-transform-save sequence. Execution order is not ownership.

Do not force an abstraction. Prefer boring code when the shape is already clear, local, and unlikely to grow. An abstraction that adds indirection without deleting branches, duplicated rules, invalid states, or lifecycle risk is the wrong one.

The tell you skipped this: a new feature grows an existing if/else by one branch, a second boolean that must stay in sync with the first, or phase-named modules that repeat the same domain rule. `domain-modeling` records the glossary and the ADRs. This section is the code shape.

### Foundational Thinking

Get the data shape right before writing logic. Define the core types, trace the access patterns, and pick structures that match the dominant paths. Downstream code should become obvious. If it does not, the shape is wrong.

Structural decisions protect option value. Code-level decisions protect simplicity. DRY the structure, not every line. Three similar statements still beat a premature abstraction.

If something helps every later phase, do it first. Shared types, the parse at the boundary, CI, and the test harness are scaffold. Features come after. Remove dead code before laying that foundation. Each increment lands one coherent abstraction or deepens one that exists. Do not spread a new capability across callers as special-case coordination.

Before sharing state between actors, ask what happens if another actor modifies it concurrently. If the answer is not "nothing", isolate. That check is [Separate Before Serializing Shared State](#separate-before-serializing-shared-state).

### Separate Before Serializing Shared State

When concurrent actors might write the same file, branch, key, or object, first ask whether they need the same mutable target. If not, eliminate the sharing. Give each actor its own file, key, branch, or directory, and merge only at the read boundary. Two workers writing different fields of one `state.json` is still shared mutation. Separate files are not.

Serialize only when one shared writer is a real invariant. Enforce that with a lockfile, a sequential phase, a single-writer actor, or an atomic compare-and-swap. An instruction to be careful is not concurrency control. Treat "we need a lock" as a smell to check, not the default.

This covers code and agents. Parallel workers get their own worktree or branch. See [agents.md](./agents.md).

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)
- [ ] Domain rules live in one structure, not a new branch on an existing chain ([Model the Domain](#model-the-domain))
- [ ] Concurrent writers do not share a mutable file, branch, or key ([Separate Before Serializing Shared State](#separate-before-serializing-shared-state))
- [ ] The change was checked against the real artifact, not a proxy ([Prove It Works](./development-workflow.md#prove-it-works))
- [ ] Every cited `file:line` was opened; none were fabricated
