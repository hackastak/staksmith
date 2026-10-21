---
description: "TypeScript coding style extending common rules"
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"]
alwaysApply: false
---
# TypeScript/JavaScript Coding Style

> This file extends the common coding style rule with TypeScript/JavaScript specific content.

## Immutability

Use spread operator for immutable updates:

```typescript
// WRONG: Mutation
function updateUser(user, name) {
  user.name = name  // MUTATION!
  return user
}

// CORRECT: Immutability
function updateUser(user, name) {
  return {
    ...user,
    name
  }
}
```

## Error Handling

Use async/await with try-catch:

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('Detailed user-friendly message')
}
```

## Input Validation

Use Zod for schema-based validation:

```typescript
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

const validated = schema.parse(input)
```

## Type system discipline

On every `.ts` or `.tsx` edit, follow the `coding-standards` skill (`skills/coding-standards/SKILL.md` and `references/typescript-patterns.md`). Checklist:

- Discriminated unions, not optional-field bags
- Brand semantic primitives at the boundary. Never brand with `as`
- `unknown` until a schema parse. Infer the type from the schema
- No `as` except after validation. Prefer `satisfies`
- Exhaust switches with `const _exhaustive: never = value`
- Parse once at the boundary. Do not re-validate inside
- Derive from generated types before declaring a new interface

## Console.log

- No `console.log` statements in production code
- Use a structured logger with enough context to debug from an id
- See hooks for automatic detection
