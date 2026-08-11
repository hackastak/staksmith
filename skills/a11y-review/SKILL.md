---
name: a11y-review
description: "Review frontend code for accessibility — semantic structure, keyboard and focus, ARIA correctness, text alternatives, forms, color/contrast, and dynamic-content announcements — ranked by WCAG severity and real user impact. Read-only, scoped to frontend files. Use for a web/React/Vue/Svelte UI, or when the user says 'accessibility review', 'a11y', 'is this WCAG compliant', or invokes '/a11y-review'."
category: "Code Review & Quality"
origin: Hackastak
---

Review a frontend for **accessibility**: can someone using a keyboard, a screen reader, or high-contrast/zoom actually operate this UI? This is the accessibility axis of the review family — the dimension neither `code-review` nor the frontend-patterns skill audits. Scope it to the frontend, rank findings by WCAG severity and real user impact, and be honest about what static review can and can't see.

This is **read-only inspection**: read the markup/components, run read-only a11y tooling where available, and report. Never edit, never commit.

**Which review skill is this?**

| Skill | Axis | When |
|---|---|---|
| `code-review` | all six, one context | before push / PR |
| `perf-review` | performance | latency/scale review |
| **`a11y-review`** | **frontend accessibility** | **auditing a web UI for WCAG / keyboard / screen-reader support** |
| `audit-codebase` | every axis, fanned out | whole-repo review (dispatches this when a frontend is present) |

## 1. Scope

Only frontend code is in scope. Detect and target it:

- **Find the UI layer** — `.jsx`/`.tsx`, `.vue`, `.svelte`, `.astro`, `.html`, and template files (`.erb`/`.blade.php`/`.hbs`/Jinja). If the repo has no frontend, say so in one line and stop — this skill doesn't apply to a pure backend/CLI.
- Detect the framework and any existing a11y setup: `eslint-plugin-jsx-a11y`/`eslint-plugin-vuejs-accessibility` in the lint config, a component library (MUI, Radix, Chakra, shadcn) that ships accessible primitives, an existing axe/pa11y/Lighthouse setup.
- Prioritize the **interactive and high-traffic surface**: forms, modals/dialogs, menus, custom controls (anything that isn't a native element doing a native element's job), navigation, and data tables.
- Read-only git only.

## 2. What static review can and can't see (state this honestly)

You are reading source, not a rendered DOM. Be explicit about the split:

- **Static review catches** — non-semantic markup, missing labels/alt, `div`/`span` used as buttons, missing/incorrect ARIA, positive `tabindex`, `aria-hidden` on focusable elements, missing form labels, `<img>` without `alt`, missing `lang`, disabled zoom, click handlers with no keyboard equivalent.
- **Only a rendered DOM catches** — actual color-contrast ratios, computed accessible names, focus order as rendered, whether a live region actually announces, reflow at 400% zoom. For these, **run a tool or flag them as unverified** — never assert a contrast pass/fail from a hex value alone without doing the math, and never claim a screen-reader behavior you didn't observe.

Read-only tooling, if present (note as a coverage gap when absent, never fabricate): `eslint --plugin jsx-a11y`, `axe` / `@axe-core/cli`, `pa11y`, `lighthouse --only-categories=accessibility` against a running dev server (only if one is already up — don't start services). Treat tool output as leads to confirm in the source, not verdicts.

## 3. Walk the accessibility dimensions

Verify every `file:line` with `grep -n` before citing — **never invent a path or line number**. Cite the relevant WCAG success criterion where it clarifies (e.g. *2.1.1 Keyboard*, *4.1.2 Name/Role/Value*).

1. **Semantic structure** — `div`/`span` where a `button`/`a`/`nav`/`main`/`ul`/`heading` belongs; heading levels skipped or used for size; missing landmarks; tables without `<th>`/scope. Native elements first — they come with role, focus, and keyboard behavior for free.
2. **Keyboard & focus** *(2.1.1, 2.4.3, 2.4.7)* — interactive elements not reachable/operable by keyboard (click handler on a non-button with no `onKeyDown`/`role`/`tabIndex`), positive `tabindex`, focus not moved into/out of modals, focus not restored on close, keyboard traps, no visible focus indicator (`outline:none` with no replacement), missing skip-link.
3. **ARIA correctness** *(4.1.2)* — invalid role, required ARIA attributes missing (e.g. `aria-expanded` on a disclosure), redundant/conflicting ARIA on a native element, `aria-hidden="true"` on a focusable element, `role="button"` without keyboard handling, referencing a non-existent id in `aria-labelledby`/`aria-describedby`. The first rule of ARIA: don't use it if a native element would do.
4. **Names & text alternatives** *(1.1.1, 2.4.4, 2.4.6)* — `<img>`/icon without `alt` (or decorative image without `alt=""`), icon-only button/link with no accessible name (`aria-label`/visually-hidden text), form control with no associated `<label>`, ambiguous link text ("click here"), `<svg>` without `role`/title where it conveys meaning.
5. **Forms** *(1.3.1, 3.3.1, 3.3.2, 1.3.5)* — inputs not programmatically labeled (`htmlFor`/`id`, or wrapping label), missing `fieldset`/`legend` for radio/checkbox groups, errors conveyed by color only with no text/`aria-invalid`/`aria-describedby`, missing `autocomplete` on identity fields, placeholder used as the only label.
6. **Color & contrast** *(1.4.1, 1.4.3, 1.4.11)* — meaning conveyed by color alone (status by red/green with no icon/text), and text/UI contrast below threshold. **Do the math or run a tool** — compute the ratio from the actual foreground/background tokens (4.5:1 normal text, 3:1 large text/UI) or mark it unverified; don't eyeball it.
7. **Media & motion** *(1.2.x, 2.3.3, 1.4.2)* — video without captions/track, audio without transcript, animation/auto-scroll not gated behind `prefers-reduced-motion`, autoplaying media.
8. **Dynamic content & announcements** *(4.1.3, 2.4.3)* — async updates (toasts, validation, search results) with no `aria-live`/`role="status"`/`alert`, route changes in an SPA that don't move focus or announce the new view, modals without `role="dialog"`/`aria-modal` and focus management.
9. **Document & viewport** *(3.1.1, 1.4.4, 1.4.10)* — missing `<html lang>`, `<meta viewport>` disabling zoom (`user-scalable=no`/`maximum-scale=1`), fixed-px layouts that won't reflow at 400% zoom.

If a dimension has nothing material, say so — silence is not a clean bill of health.

## 4. Output

Emit a single inline markdown report. Do not save it to a file, and do not post it anywhere.

```
# Accessibility review: <repo or scope>

**Scope:** <n frontend files / dir> · **Framework:** <React/Vue/…> · **Verified:** <tooling that ran; note static-only / unverified areas>

## Summary
**Verdict:** Blocks users of assistive tech | Usable with real friction | Broadly accessible

<One short paragraph, 1–3 sentences: the single most important accessibility fact —
usually a control that can't be operated by keyboard or a screen reader.>

## Findings

### Critical

#### `src/Modal.tsx:24` — dialog traps nothing and never receives focus (2.4.3, 4.1.2)

<Who it blocks and how (keyboard-only user, screen-reader user), the WCAG criterion,
and the fix. One paragraph, 2–4 sentences.>

### Major

#### `src/IconButton.tsx:12` — icon-only button has no accessible name (4.1.2)

<...>

### Minor

#### `src/Card.tsx:8` — heading level skips h2→h4 (1.3.1)

<...>

### Nits

#### `src/Logo.tsx:3` — decorative image missing alt="" (1.1.1)

<...>

## Not statically verifiable
- <Contrast ratios / computed names / focus order / live-region behavior that need a
  rendered DOM or a tool run — list what a follow-up axe/pa11y pass should confirm.>

## What looks good
- <1–3 genuine strengths — native elements used well, a properly-managed dialog,
  an accessible component library. Not filler.>
```

**Formatting rules, non-negotiable:**

- Each finding is its own `####` subsection, **never** a bullet item. Blank line after every header and body. The header is the backtick-wrapped `file:line`, a short `—` label, and the WCAG SC in parentheses where it clarifies.
- **One paragraph, 2–4 sentences per finding, Critical included.** Say *who* it blocks — a11y findings land when they name the user.
- Severity tracks **user impact / conformance**: **Critical** = a control that can't be operated or perceived by an AT user (a Level A block); **Major** = significant friction or a Level AA failure on key content; **Minor/Nit** = small or low-traffic gaps.
- **Never invent a `file:line`** or assert a contrast/behavior you didn't verify. Anchor to the nearest element if you can't pin a line; put unverifiable claims in "Not statically verifiable."
- Omit any empty section rather than printing "(none)".

## Guardrails

- **Read-only.** Read-only lint/axe/pa11y/Lighthouse against an already-running server only — never start services, never edit, never `--fix`.
- **Findings are the deliverable; fixes are not.** Hand the report back; the user decides what to remediate.
- **Don't fake the runtime.** Contrast ratios, computed accessible names, focus order, and announcements need a rendered DOM. Compute what you can from the actual tokens, run a tool where you can, and put the rest under "Not statically verifiable" — a guessed contrast pass is worse than an honest "unverified."
- **Native over ARIA.** When recommending fixes, prefer swapping to a native element over layering ARIA onto a non-semantic one.

## Related skills

- **`frontend-patterns`** — component patterns to build the accessible fix a finding calls for.
- **`code-review`** — the broad review; `a11y-review` is the accessibility depth it doesn't carry.
- **`audit-codebase`** — dispatches this as a conditional pass when a frontend is detected.
- **`dataviz`** — accessible color/contrast guidance when the frontend is charts and dashboards.
