---
name: setup-pre-commit
description: Set up Husky pre-commit hooks with lint-staged, type checking, and tests in the current repo. Use when the user wants to add pre-commit hooks, set up Husky, configure lint-staged, or add commit-time formatting/typechecking/testing.
category: "Build, Debug & Merge"
origin: Hackastak
---

# Setup Pre-Commit Hooks

Install a durable, in-repo **commit-time quality gate**: Husky runs lint-staged on the staged files, then typecheck, then tests. Unlike an agent-side hook, this one belongs to the repo and applies to every human and every tool that commits in it.

**Scope: Node / JS-TS repos.** Husky and lint-staged are npm-ecosystem tools. If the repo has no `package.json`, say so and stop rather than scaffolding one — the right gate for a Python or Rust repo is a different tool (`pre-commit`, `cargo-husky`), not this skill.

## What this sets up

- **Husky** pre-commit hook
- **lint-staged** running **the repo's existing formatter** on staged files
- **typecheck** and **test** scripts in the hook, where the repo has them

## Steps

### 1. Detect the package manager

Follow the Staksmith convention, in this precedence order: the `CLAUDE_PACKAGE_MANAGER` environment variable, then `.claude/package-manager.json`, then `package.json`'s `packageManager` field, then lock-file detection (`package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` → bun), then the user's global preference. Default to npm if nothing resolves.

Use the detected manager everywhere below — don't hardcode `npm`.

### 2. Detect the formatter — don't impose one

Look for what the repo already uses, in this order:

1. **Biome** — `biome.json` / `biome.jsonc`, or `@biomejs/biome` in `devDependencies`. Use `biome format --write` (add `biome check --write` instead if the repo also lints with Biome).
2. **Prettier** — `.prettierrc*`, `prettier.config.*`, or a `prettier` key in `package.json`. Use `prettier --ignore-unknown --write`.
3. **Neither** — then Prettier is the default choice, and only *then* do you create a config (step 6).

Forcing Prettier into a Biome repo will fight the existing config and reformat the whole codebase on the first commit. Detect first.

### 3. Install dependencies

Install as devDependencies: `husky lint-staged`, plus `prettier` **only** if step 2 landed on case 3.

### 4. Initialise Husky

```bash
npx husky init
```

This creates `.husky/` and adds `prepare: "husky"` to `package.json`.

### 5. Create `.husky/pre-commit`

No shebang needed for Husky v9+:

```
npx lint-staged
npm run typecheck
npm run test
```

**Adapt:** swap `npm` for the detected package manager. If the repo has no `typecheck` or `test` script, **omit that line and tell the user** — a hook that fails on a missing script blocks every commit in the repo, which is the worst possible outcome of a skill meant to help.

### 6. Create `.lintstagedrc`

Point it at the formatter from step 2:

```json
{
  "*": "biome format --write --no-errors-on-unmatched"
}
```

or

```json
{
  "*": "prettier --ignore-unknown --write"
}
```

### 7. Create `.prettierrc` — only if no formatter config existed

Skip this entirely in the Biome and existing-Prettier cases. Defaults for a greenfield repo:

```json
{
  "useTabs": false,
  "tabWidth": 2,
  "printWidth": 80,
  "singleQuote": false,
  "trailingComma": "es5",
  "semi": true,
  "arrowParens": "always"
}
```

### 8. Verify

- [ ] `.husky/pre-commit` exists and is executable
- [ ] `.lintstagedrc` exists and names the formatter the repo actually uses
- [ ] `prepare` script in `package.json` is `"husky"`
- [ ] A formatter config exists (found in step 2, or created in step 7)
- [ ] `npx lint-staged` runs clean

### 9. Stage, then hand back

The first commit through the new hook is a genuine smoke test — it's the only way to know the gate fires. But **do not make that commit yourself.** Stage everything you created or changed, then hand control back and tell the user:

- what's staged
- the message to use: `chore: add pre-commit hooks (husky + lint-staged)`
- that the commit will run the hook, and that a failure means the gate works and something needs fixing — not that the setup is broken

If the hook does reject their commit, the fix is in the code or the scripts, not in weakening the hook.

## Notes

- Husky v9+ doesn't need shebangs in hook files.
- `prettier --ignore-unknown` skips files Prettier can't parse (images, lockfiles).
- The order matters: lint-staged first because it's fast and staged-only, then the full typecheck and tests.
- Nothing here is a substitute for CI. A pre-commit hook is skippable with `--no-verify`; it catches mistakes early rather than enforcing policy.

## Related skills

- **`git-guardrails`** — the agent-side counterpart. This gate is in the repo and binds everyone; that hook is in the harness and binds the agent.
- **`setup-ts-deep-modules`** — the other repo-tooling setup, enforcing module boundaries via dependency-cruiser. They compose: add `depcruise` to the hook once both are installed.
- **`review-changes`** — what to run before committing when you want judgement, not just tooling.
