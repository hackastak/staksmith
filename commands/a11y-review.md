---
description: Review frontend code for accessibility — semantic structure, keyboard and focus, ARIA correctness, text alternatives, forms, color/contrast, and dynamic-content announcements — ranked by WCAG severity and real user impact. Read-only, scoped to frontend files.
---

# Accessibility Review

Invoke the **`a11y-review`** skill to review a web UI for accessibility — the axis neither `/code-review` nor the frontend-patterns skill carries. Read-only, scoped to frontend files, findings ranked by WCAG severity and who they actually block.

## What This Command Does

1. **Scope** to the frontend (`.jsx`/`.tsx`, `.vue`, `.svelte`, `.astro`, `.html`, templates); if there's no UI layer, it says so and stops.
2. **Split static from runtime** — reads source for structural issues, and is honest that contrast ratios, computed accessible names, and focus order need a rendered DOM (runs axe/pa11y/eslint-jsx-a11y when available, flags the rest as unverified).
3. **Walk the WCAG dimensions**: semantic structure, keyboard & focus, ARIA correctness, names & text alternatives, forms, color & contrast, media & motion, dynamic-content announcements, document/viewport.
4. **Emit a severity-ranked report** (Critical / Major / Minor / Nit) with `file:line` anchors, WCAG success-criterion references, and a "Not statically verifiable" section.

## When to Use

- Auditing a web/React/Vue/Svelte UI for keyboard and screen-reader support.
- Before shipping a user-facing frontend, or checking WCAG A/AA conformance.

## Usage

```text
/a11y-review                 # all frontend files
/a11y-review src/components   # scope to a directory
```

## Output

A single inline report: verdict, findings tiered **Critical / Major / Minor / Nit** each anchored to `file:line` with its WCAG criterion and *who it blocks*, a **Not statically verifiable** section for runtime-only checks, and genuine strengths. Read-only — never edits code.

## Related

- Skill: `skills/a11y-review/SKILL.md`
- Build the fix: `skills/frontend-patterns/` · Accessible chart color: `dataviz`
- Broader / composes it: `/code-review` · `/audit-codebase` (dispatches it when a frontend is present)
