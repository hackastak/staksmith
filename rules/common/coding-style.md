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

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)
