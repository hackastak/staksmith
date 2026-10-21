---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Testing

> This file extends [common/testing.md](../common/testing.md) with TypeScript/JavaScript specific content.

## E2E Testing

Use **Playwright** as the E2E testing framework for critical user flows.

## What to run

- Do not mock what you can run. Prefer the framework's real test primitives, including leak and disposable checks
- Verify UI in a running build. Mock only what cannot run locally
- A branded type, type guard, or schema claim needs a compiler failure or a test that fails when the claim is wrong

## Agent Support

- **e2e-runner** - Playwright E2E testing specialist
