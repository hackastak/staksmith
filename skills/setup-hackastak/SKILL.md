---
name: setup-hackastak
description: Configure a target repo for the Hackastak engineering flow — write the issue-tracker backend, triage labels, and domain-model layout that the ticketing and design skills read. Use when a repo has no docs/agents/ config, when to-spec/to-tickets/triage/wayfinder report a missing tracker, or when the user says "set up this repo", "configure staksmith here", or invokes /setup-hackastak.
category: "Workflow & Meta"
origin: Hackastak
---

# Setup Hackastak

Scaffold the per-repo configuration that the engineering flow **reads**. The ticketing skills
(`to-spec`, `to-tickets`, `triage`, `wayfinder`) and the design skills (`domain-modeling`,
`vault-to-code-bridge`) look for their conventions in `docs/agents/`. Run once per repo to make
those conventions explicit; without it they fall back to defaults and prompt you to run this.

This skill writes **into the target repo**, not the vault. It scaffolds three things:

- **A** — `docs/agents/issue-tracker.md`: which backend holds specs and tickets, and how to
  publish/fetch/wayfind against it.
- **B** — `docs/agents/triage-labels.md`: the label strings for the triage state machine. Always
  written — triage is part of the flow on every backend.
- **C** — `docs/agents/domain.md`: where the domain glossary and ADRs live and the house standard
  they follow.

It is a configurator, not an installer. Installing the Staksmith skills themselves is a different
job; this points an already-equipped harness at *this* repo's choices.

## Scope

- Writes only under `docs/agents/` (plus the lazy `docs/adr/` note in Section C). It does **not**
  create `spec.md`, tickets, `CONTEXT.md`, or ADRs — those are written on demand by the skills that
  own them.
- Never overwrites an existing `docs/agents/*.md` without showing the diff and getting a yes. A
  repo that already ran this has made choices worth preserving.
- Idempotent: re-running it reconciles missing files and leaves configured ones alone unless asked.

## Before you write anything: the gate

Every file this skill writes goes through **draft → confirm → write**. Show the user the exact path
and the content you intend to write, get a yes, then write. Batch the three drafts into one review
where you can, so the user approves the whole config in one pass rather than three.

## Section A — Issue tracker backend

Pick the backend, then write `docs/agents/issue-tracker.md` from it.

### Choosing the backend

**Default to `vault`.** Only move off it on a clear signal:

- **vault** (default) — specs, tickets, and maps are markdown notes in the repo's PARA project
  folder under `~/Developer/My_Notes/1. Projects/<Project>/`. The right choice for personal and
  small projects where the notes belong beside the rest of the project's thinking.
- **github** — specs and tickets are `gh` issues, with native blocking, sub-issues, and external
  PRs as a request surface. Choose it when the repo has a public GitHub presence, takes issues or
  PRs from others, or wants AFK agents grabbing tickets autonomously.
- **local** — specs and tickets live in `.scratch/<feature>/` inside the repo. Choose it for a
  throwaway or offline repo with no vault project folder and no GitHub issues.

If the signal is ambiguous, state that you are defaulting to `vault` and let the user redirect —
do not silently pick `github` because a remote exists.

### Writing the config

- **vault** — copy this skill's `issue-tracker-vault.md` verbatim to `docs/agents/issue-tracker.md`,
  then confirm the project-folder match at the top: fuzzy-match the repo name against folders under
  `1. Projects/` (`oms-athena` ↔ `OMS_Athena`). One clear match, use it; ambiguous or none, ask —
  never create a project folder silently.
- **github** — write a config that names the backend, states that external PRs are (or are not) a
  triage surface, and records the label-creation step. Minimal shape:

  ```markdown
  # Issue tracker: GitHub

  Issues and specs for this repo are GitHub issues via `gh`, in `<owner>/<repo>`.

  ## Conventions
  - The spec is a pinned issue labelled `spec`, or a `docs/spec.md` linked from it.
  - Tickets are `gh` issues; blocking uses native "blocked by" / sub-issues.
  - Triage roles are GitHub labels — see `triage-labels.md`. Create them once with `gh label create`.
  - External PRs ARE a request surface: triage covers them as "an issue with attached code".

  ## Publishing
  Remote writes confirm before writing. `gh issue create` / `gh issue edit` for tickets.

  ## Wayfinding operations
  The map is a tracking issue; child tickets are issues it lists under "Blocked by".
  Frontier = open, unblocked, unassigned issues, lowest number first.
  ```

- **local** — write a config pointing at `.scratch/<feature>/` with the same three shapes
  (`spec.md`, `issues/NN-*.md`, `map.md`) and the draft → confirm → write gate, mirroring the vault
  seed's structure against the scratch directory instead of the project folder.

## Section B — Triage labels (always)

Copy this skill's `triage-labels.md` to `docs/agents/triage-labels.md`. This runs for **every**
backend, because triage is part of the flow everywhere — only *how* the role is recorded differs
(a `Status:` line on vault/local, a real label on github, both already documented in the seed).

Ask whether the repo's team already uses different words for any role (`feature` for
`enhancement`, say). Change only the label strings, never the canonical role names — the skills key
off the roles.

## Section C — Domain-model layout

Copy this skill's `domain.md` to `docs/agents/domain.md`. It records that `CONTEXT.md` and
`docs/adr/` are repo-native and follow the house ADR standard (the `adr-standard` skill).

- **Do not create `CONTEXT.md` or `docs/adr/` here.** They are created lazily — `domain-modeling`
  writes the first glossary entry and the first ADR when there is something real to record. Section
  C only writes the *layout doc* that says where they will go.
- **Multi-context only on a real signal.** Scaffold the multi-context layout (per-context
  `CONTEXT.md` + `docs/adr/`) only when the repo shows monorepo signals — a `packages/`, `apps/`,
  or `contexts/` tree with genuinely distinct bounded contexts. Otherwise write the single-context
  layout and leave it. Guessing wrong here scatters empty directories no one fills.

## Coordination with `vault-to-code-bridge`

Both this skill and `vault-to-code-bridge` touch the repo's docs, so keep them from fighting:

- `vault-to-code-bridge` **generates** `CLAUDE.md` and `ARCHITECTURE.md` and preserves manual edits
  inside marked regions. This skill does not write those files — if `CLAUDE.md` is missing, note
  that `vault-to-code-bridge` owns it rather than stubbing one here.
- Both point at `docs/adr/` but neither inlines ADR bodies: generated docs link out to ADR files by
  path so the immutability guarantee survives regeneration. The `domain.md` seed states this so the
  next writer honours it.

## Steps

1. **Confirm you're in the target repo.** `git rev-parse --show-toplevel` — this scaffolds config
   for *this* repo. Create `docs/agents/` if it doesn't exist.
2. **Check what's already there.** List `docs/agents/`. For each of the three files that already
   exists, plan to leave it alone unless the user wants it reconciled; only draft the missing ones.
3. **Section A** — choose the backend (default `vault`), resolve the project folder or target, and
   draft `docs/agents/issue-tracker.md`.
4. **Section B** — draft `docs/agents/triage-labels.md` (always), applying any string overrides the
   user asked for.
5. **Section C** — draft `docs/agents/domain.md`, single-context unless monorepo signals say
   otherwise.
6. **One confirmation.** Show all drafted files with their paths, get the yes, then write.
7. **Verify** (below), then stage and hand back — do not commit.

## Verify

- [ ] `docs/agents/issue-tracker.md` exists and names exactly one backend
- [ ] `docs/agents/triage-labels.md` exists (every backend)
- [ ] `docs/agents/domain.md` exists and points at the house ADR standard
- [ ] For the vault backend, the resolved project folder under `1. Projects/` is correct
- [ ] No pre-existing config was overwritten without an explicit yes
- [ ] `CONTEXT.md`, `docs/adr/`, `spec.md`, and tickets were **not** created — those stay lazy

## Related skills

- **`to-spec` / `to-tickets` / `triage` / `wayfinder`** — the ticketing flow that reads
  `docs/agents/issue-tracker.md` and `triage-labels.md`. They prompt you to run this skill when the
  config is missing.
- **`domain-modeling`** — writes `CONTEXT.md` and the ADRs into the layout Section C declares.
- **`adr-standard`** — the house ADR standard that `domain.md` points at.
- **`vault-to-code-bridge`** — generates `CLAUDE.md` / `ARCHITECTURE.md`; coordinate on `docs/adr/`
  as above.
- **`setup-pre-commit` / `setup-ts-deep-modules` / `git-guardrails`** — the other per-repo setup
  skills. This one configures conventions; those install tooling.
