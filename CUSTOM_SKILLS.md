# Custom Skills

Deep reference for the **69 skills built for Staksmith** (`origin: Hackastak`), the ones marked ⭐ in [`SKILLS.md`](SKILLS.md). It exists so these skills stay usable **without the Obsidian vault** many of them were designed around.

**How this differs from [`SKILLS.md`](SKILLS.md).** That catalog is auto-generated and indexes *every* skill with a one-line description and location. This document is hand-authored and goes deeper, on the custom skills only: how each one works, what it takes as input, what it produces, and exactly which vault structure it assumes. Use `SKILLS.md` to find a skill; come here to understand how to run it.

## Shared vault configuration

Many of these skills read from and write to an Obsidian vault that follows the [PARA](https://fortelabs.com/blog/para/) convention. Unless a skill's entry says otherwise, it assumes this layout:

```
VAULT_PATH=~/Developer/My_Notes
  0. Inbox/        capture, unsorted
  1. Projects/     active projects, one folder each (Backlog.md, Dev_Notes.md, ...)
  2. Areas/        ongoing responsibilities
  3. Resources/    reference material
  4. Archive/      inactive
```

Script-backed skills expose the vault path (and other paths) as `config.json` keys, so you can point them at a differently structured vault without editing code. Skills without a `config.json` currently assume the layout above.

**Shared dependencies** for the script-backed skills: `jq` and `git`, with `gh` (GitHub CLI) and `rg` (ripgrep) as optional enhancements. Individual entries call out anything extra.

## Skills by category

Each entry follows the same shape: **Purpose**, **When to use**, **How it works**, **Inputs**, **Outputs**, **Vault dependencies**, and **Related**. Skills that touch only code report "None" under vault dependencies.

## Second Brain & Vault

### `backlinks`

**Purpose.** Wires the vault graph so it stays traversable: finds orphans, missing connections, and isolated clusters, scores candidate links, then adds `[[links]]` or link-only stub notes. It connects notes without generating content, so an empty hub gets flagged for you to write rather than filled.
**When to use.** When the graph feels disconnected or orphan-heavy, when you want related notes wired without new prose, when bridging isolated clusters across PARA folders, or when triaging unresolved `[[links]]` into stubs.
**How it works.** Seven phases: structural inventory (graph-only, no content reads), priority context (reads 5-7 recent weeklies, master task list, active backlogs to build a scoring filter), orphan rescue scan, cluster bridge analysis, unresolved link triage, score and recommend (Conceptual x Structural x Priority + PARA bonus), then present a tiered report and execute the approved connections.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`. Optional argument: a cluster name (e.g. `OMS_Athena`) to skip the full scan and focus on that cluster and its neighbors. Reads `1. Projects/`, `2. Areas/`, `3. Resources/`, `_Weekly/`, and `0.1 Tasks_List/Master_Task_List.md`; excludes `.obsidian/`, `.claude/`, `_templates/`, and media.
**Outputs.** A `BACKLINKS REPORT` with tiered connection cards, and on approval it edits notes to add wikilinks in-section and creates link-only stub notes (title plus a Related list, no synthesized content). Empty hubs are reported as flags only.
**Vault dependencies.** Assumes the PARA structure (`1. Projects/`, `2. Areas/`, `3. Resources/`, `4. Archive/`), `_Weekly/<year>/`, and `0.1 Tasks_List/Master_Task_List.md`. Scoring weights lean on PARA categories.
**Related.** `inbox` (process inbox notes before wiring them in place), `connect`, `trace`.

### `challenge`

**Purpose.** Pressure-tests a belief, position, or decision by mining your own notes for contradictions, hidden assumptions, weak reasoning, and missing perspectives. The goal is to strengthen thinking before a big decision, not to attack it.
**When to use.** Before a decision you want stress-tested, when auditing a belief for internal consistency, when hunting for blind spots and counterarguments, or when checking whether your stated views actually cohere.
**How it works.** A ten-step sequence: parse what to challenge, gather all relevant notes, map the belief system, find internal contradictions, surface hidden assumptions, test the reasoning for fallacies, find missing perspectives, check against reality, output a structured challenge report, then offer to go deeper.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`. Required argument: the topic or belief to challenge. Searches `2. Areas/`, `3. Resources/`, `1. Projects/`, `_Weekly/`, and `0. Inbox/`.
**Outputs.** A `Belief Stress Test` report (current position, contradictions, hidden assumptions, weak points, missing perspectives, questions to sit with, overall assessment). Read-only, writes nothing to the vault.
**Vault dependencies.** Assumes PARA folders plus `_Weekly/` and `0. Inbox/`, but only reads them. Degrades gracefully if a folder is thin.
**Related.** `ghost` (answer in your voice), `trace` (how a belief evolved), `connect`.

### `connect`

**Purpose.** Finds how two topics relate through the vault's wikilink graph, or, given no topics, audits the whole vault for related-but-unlinked notes. Surfaces bridge notes and non-obvious cross-pollination between domains.
**When to use.** When you want to see how two topics connect through your notes, when looking for bridge notes between domains, or when auditing the entire vault for missing links.
**How it works.** Detects mode from input. Connection Discovery (two topics): parse topics, build the link graph, find notes mentioning each, trace direct/one-hop/two-hop/shared-reference paths, analyze patterns, output. Vault-Wide Analysis (no topics): build the full graph, identify isolated clusters, run semantic-similarity search, find potential bridges, output.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`. Optional argument: two topics separated by `and`, `to`, `with`, or a comma; empty triggers whole-vault mode. Scans all `*.md`, excluding `.obsidian/`, `.claude/`, and images.
**Outputs.** A connection-analysis report: direct connections, link paths, bridge notes, patterns, and suggested new links. Read-only; suggests links but does not add them.
**Vault dependencies.** Uses PARA categories as a signal but has no hard structural requirement beyond a wikilinked vault. Effectively "operates on the vault graph."
**Related.** `backlinks` (actually wires suggested links), `trace`, `challenge`.

### `ghost`

**Purpose.** Answers a question the way you would, drawn from your stated beliefs and writing style in the vault. Use it to externalize your likely take or to draft authentic responses and blog copy in your own voice.
**When to use.** When you want an answer drafted in your voice, to externalize your likely take before writing, to draft a response grounded in stated beliefs, or to continue a piece consistently with your other writing.
**How it works.** Eight steps: understand the question, find relevant notes, analyze writing style (tone, argument style, values), extract relevant beliefs with sources, synthesize the answer in your voice, weave in note references, output the response with sources and voice notes, then offer refinement.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes` and `BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog` (referenced as `$VAULT_PATH/$BLOG_PATH`). Required argument: the question. Prioritizes `2. Areas/`, `3. Resources/`, `1. Projects/`, `0. Inbox/`, `_Weekly/`.
**Outputs.** A ghostwritten answer with a Sources Used and Voice Notes section. For blog drafts it matches existing articles under `$BLOG_PATH`. No em dashes in drafted prose. Read-only unless you ask it to save.
**Vault dependencies.** Assumes PARA folders plus `_Weekly/`, and the shared blog path `2. Areas/Hackastak_Brand/Medium_Blog`.
**Related.** `ideas` (writing opportunities feed from the same voice patterns), `challenge`, `blog-draft`.

### `graduate`

**Purpose.** Extracts undeveloped ideas buried in weekly notes and promotes each into a standalone seedling note in `0. Inbox/Graduates/`, capturing half-formed thoughts before they are lost.
**When to use.** When weeklies are accumulating half-formed ideas worth saving, when you want to capture recurring thoughts before they vanish, or during a periodic review of recent weeks for promising threads.
**How it works.** Nine steps: find weekly notes in scope, read each for idea indicators (excluding tasks, changelogs, template content), evaluate each idea, check for an existing home, create the `Graduates` directory, create standalone seedling notes, optionally mark the source weekly, output a summary, and confirm before creating anything.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`. Optional argument: number of weeks to scan (default 4) or `all`. Reads `_Weekly/` (filenames `YYYY-WXX.md`).
**Outputs.** New seedling notes at `0. Inbox/Graduates/<Core_Concept_Name>.md` (Status: Seedling, with source backlink, core claim, context, original excerpt, connections, questions, next steps), plus a graduation summary. Creation is gated on confirmation.
**Vault dependencies.** Assumes `_Weekly/` with `YYYY-WXX.md` files using the Obsidian Tasks plugin, and writes into `0. Inbox/Graduates/`.
**Related.** `inbox` (processes the graduated seedlings later), `ideas`, `weekly-momentum-report`.

### `ideas`

**Purpose.** Scans the vault for emerging patterns and generates a grounded ideas report across four lanes: tools to build, people to reach out to, topics to investigate, and things to write.
**When to use.** When seeking inspiration rooted in your actual interests, when looking for tools to build or people to contact, or when turning recent activity into a prioritized action list.
**How it works.** Eight steps: scan patterns across recent activity (last 30 days), weeklies, projects, areas, resources, and inbox; identify emerging themes; find people mentioned; identify tool opportunities; find investigation-worthy topics; surface writing opportunities; generate the report; offer follow-up.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes` and `BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog`. No required argument. Reads `1. Projects/`, `2. Areas/`, `3. Resources/`, `0. Inbox/`, `_Weekly/`, and the blog path; excludes `.obsidian/`, `.claude/`.
**Outputs.** An Ideas Report grouped into Tools to Build, People to Reach Out To, Topics to Investigate, Things to Write, plus pattern insights and recommended next actions. Read-only; can spin a follow-up into a project note if asked.
**Vault dependencies.** Assumes PARA folders, `_Weekly/`, and the blog path `2. Areas/Hackastak_Brand/Medium_Blog`.
**Related.** `ghost`, `graduate`, `blog-ideas`, `what-next`.

### `inbox`

**Purpose.** Processes notes in `0. Inbox/` and files them into the right PARA directory with per-file confirmation. Multi-relevance notes land in Resources and get linked from each relevant Project or Area.
**When to use.** When the inbox has accumulated unsorted notes, when processing Readwise/Matter imports into Resources, or for periodic inbox cleanup with confirmation.
**How it works.** Inventory the inbox (including Readwise, Matter, Books subfolders), map existing PARA structure, analyze each note (content type, relevance scoring, multi-relevance detection), apply a destination decision tree, confirm each file individually, execute the confirmed move (or move-plus-link), then output a summary. This is the AI-driven counterpart to the scan/classify/organize script pipeline.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`. No required argument. Reads `0. Inbox/` (and its `Readwise/`, `Matter/`, `Books/` subfolders) and maps `1. Projects/`, `2. Areas/`, `3. Resources/`, `4. Archive/`.
**Outputs.** Files moved into PARA folders, wikilinks or brief index notes created for multi-relevance items, and a processing summary. Every move is gated on explicit per-file approval.
**Vault dependencies.** Assumes the full PARA structure and inbox subfolders `Readwise/`, `Matter/`, `Books/`.
**Related.** `inbox-scan`, `inbox-classify`, `inbox-organize` (the scripted pipeline), `graduate`, `backlinks`.

### `inbox-classify`

**Purpose.** Takes an inbox inventory (from `inbox-scan`) and classifies each file into a PARA category with a destination folder, confidence, and reason. The middle stage of the scripted inbox pipeline.
**When to use.** After `inbox-scan` produces an inventory, when you have inbox items needing sorting, and before running `inbox-organize`.
**How it works.** `scan.sh -> classify.sh -> organize.sh`. `scripts/classify.sh` reads a scan JSON from stdin, gathers available PARA destinations from the vault for context, and emits a classification JSON array. Note: the shipped script uses placeholder classification logic; full AI classification comes from the `/inbox` command or a Claude API integration.
**Inputs.** `config.json` keys: `vault_path`, `confidence_threshold`, `cache_path`. Input is a JSON array of file paths on stdin (or a cached inventory file). Reads `1. Projects/` and `2. Areas/` under `~/Developer/My_Notes/` for destination context.
**Outputs.** A JSON array of `{path, filename, category, destination, confidence, reason}` objects, consumed by `inbox-organize`.
**Vault dependencies.** Assumes PARA folders under `~/Developer/My_Notes/`; classification targets `1. Projects/`, `2. Areas/`, `3. Resources/`, `4. Archive/`.
**Related.** `inbox-scan` (input), `inbox-organize` (output), `inbox`.

### `inbox-organize`

**Purpose.** Takes classification decisions and moves inbox files to their designated PARA folders, moving only items above the confidence threshold and tagging uncertain ones for manual review. The final stage of the scripted inbox pipeline.
**When to use.** After `inbox-classify` returns satisfactory results, when you have a classification JSON ready to execute, or as the last step of inbox processing.
**How it works.** `scan.sh -> classify.sh -> organize.sh`. `scripts/organize.sh` reads a classification JSON from stdin, and for each item moves files above the threshold, skips low-confidence ones, and optionally tags them with a review tag. Dry-run by default; will not overwrite an existing destination file; logs an audit trail to cache.
**Inputs.** `config.json` keys: `confidence_threshold`, `dry_run`, `tag_uncertain`, `uncertain_tag`, `cache_path`. Input is a JSON array of classifications on stdin (or a cached file).
**Outputs.** Files moved into PARA folders (when `dry_run` is false), a `#needs-review` tag added to uncertain items, and a summary counting Moved/Skipped/Tagged. In dry-run mode it previews only.
**Vault dependencies.** Moves into PARA destinations named in the classification input (e.g. `1. Projects/OMS_Athena/`); assumes the PARA structure exists.
**Related.** `inbox-scan`, `inbox-classify` (input), `inbox`.

### `inbox-scan`

**Purpose.** Inventories markdown files in the vault inbox and emits a JSON array of basic metadata per file. The lightweight first stage of the scripted inbox pipeline: paths and stats only, no content parsing.
**When to use.** Before running `inbox-classify` to get a fresh inventory, to audit what is in the inbox, or as input to any inbox workflow.
**How it works.** `scan.sh -> classify.sh -> organize.sh`. `scripts/scan.sh` reads `config.json`, finds `*.md` under the inbox path, filters excluded subfolders, and prints a JSON array; each element is `{path, filename, mtime, size_bytes}`. Pipes cleanly to `jq` or downstream skills.
**Inputs.** `config.json` keys: `inbox_path` (`~/Developer/My_Notes/0. Inbox/`) and `exclude_folders` (`Graduates`, `Matter`, `Excalidraw`). No stdin.
**Outputs.** A JSON array of file metadata to stdout (progress messages go to stderr); commonly saved to `~/.claude/cache/inbox-inventory.json` or piped into `inbox-classify`.
**Vault dependencies.** Assumes `0. Inbox/` exists in the vault; skips the configured subfolders.
**Related.** `inbox-classify`, `inbox-organize` (downstream), `inbox`.

### `quick-note`

**Purpose.** Distills the current chat's work into a single tight reference line and appends it to the current week's weekly note, under today, in the correct section (Hackastak or SAP Business Network) with a project label. These are scannable breadcrumbs, not detailed notes.
**When to use.** When session work is complete and worth a one-line record, when the user invokes `/quick-note`, or as the final logging step of `/handoff`.
**How it works.** Five steps: distill the work to one line (two only if it genuinely split), infer the section and project label from the cwd/repo then let an argument override, format the bullet to match surrounding entries, place it as the last bullet under today's day line, then write the edit directly and report what landed.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`. Optional argument (`argument-hint`): a section/project hint. Computes the target from `date` (`_Weekly/<ISO year>/<ISO year>-W<ISO week>.md`) and today's day name.
**Outputs.** One (rarely two) appended bullet under today's day line inside the chosen section's `#### Daily Journal`. If the weekly note is missing it stops and asks rather than scaffolding. No em dashes; edits only the current weekly note.
**Vault dependencies.** Assumes `_Weekly/<year>/<year>-WXX.md` with top-level sections `# Hackastak` and `# SAP Business Network`, each holding a `#### Daily Journal` and plain day-name lines.
**Related.** `handoff` (chains this as its final step), `weekly-momentum-report` (narrates the week from these entries), `backlog-review`.

### `sync`

**Purpose.** Loads full vault context into Claude Code at the start of a work session, reading recent weeklies, active projects, the master task list, recent inbox items, and everything modified in the last 7 days, then outputs a structured state summary.
**When to use.** When starting a work session and wanting full context loaded, when you need a snapshot of active projects and focus, when returning after time away, or before planning what to work on next.
**How it works.** Eight steps: load recent weekly notes (last 7 days), load active projects, read the master task list, check recent inbox items, scan all notes modified in the last 7 days, look for priority/focus markers, output a context summary, then offer next steps.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`. No required argument. Reads `_Weekly/`, `1. Projects/`, `2. Areas/`, `0. Inbox/`, and `0.1 Tasks_List/Master_Task_List.md`; excludes `.obsidian/`, `.claude/`, and images.
**Outputs.** A `Current Context Sync` summary (active projects, current focus, open tasks by priority, recent activity, areas of attention, inbox items, priorities). Read-only.
**Vault dependencies.** Assumes PARA folders, `_Weekly/<year>/` with `YYYY-WXX.md` files, and `0.1 Tasks_List/Master_Task_List.md`.
**Related.** `what-next`, `weekly-momentum-report`, `ideas`.

### `trace`

**Purpose.** Tracks how a single idea has evolved across the vault over time: finds every mention, follows wikilinks, and builds a chronological timeline with connections so you can see a concept's lineage.
**When to use.** When you want to see when and where an idea first appeared, when tracing how your thinking on a topic changed, when finding every note connected to a concept before writing or deciding, or when auditing a project's or belief's lineage.
**How it works.** Five steps: find all mentions (case-insensitive), gather file metadata (creation and modified dates via `stat`, surrounding context), extract connections (outgoing wikilinks, co-mentions, tags), build the chronological timeline, then provide insight on how understanding deepened and where gaps remain.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`. Required argument: the topic to trace. Searches the whole vault; notes `_Weekly/`, `1. Projects/`, and `4. Archive/` as signals; excludes `.obsidian/` and images.
**Outputs.** An `Idea Timeline` (first appearance, evolution, current state, connection map) plus a short analysis. Read-only.
**Vault dependencies.** Assumes PARA folders and `_Weekly/`, but only reads them; works on any wikilinked vault.
**Related.** `connect`, `challenge`, `graduate`.

### `vault-to-code-bridge`

**Purpose.** Converts Obsidian project notes into repo documentation: generates `CLAUDE.md`, a regenerable `ARCHITECTURE.md`, README feature sections, and append-only ADR files. Transforms loose vault notes into developer-facing docs.
**When to use.** On new project setup, when initializing docs for the first time, during a major refactor that needs architecture synced to the repo, or when preparing onboarding/handoff docs from tribal knowledge.
**How it works.** Two-phase workflow with backing scripts: `scan-vault-projects.sh` maps vault projects to code repos via fuzzy name matching, then `generate-docs.sh` transforms note content into repo docs (accepts `--project <name>`). ADRs are strictly append-only: each decision becomes `docs/adr/NNNN-slug.md`, existing files are never rewritten, numbers are never reused, and `ARCHITECTURE.md` carries only an ADR index.
**Inputs.** `config.json` keys: `vault_path`, `repos_root`, `templates_path`, `auto_match_threshold`, `dry_run`, `manual_mappings`, `sync_sections`, `cache_path`, `preserve_manual_edits`. Reads project notes under `<vault>/1. Projects/` and repos under the configured roots. Templates live in `templates/CLAUDE.template.md` and `templates/ARCHITECTURE.template.md`.
**Outputs.** Per matched repo: `CLAUDE.md`, `ARCHITECTURE.md` (regenerated each run), `docs/adr/NNNN-slug.md` files (scaffolded as `Status: Proposed`, append-only), and an updated `README.md`. A project-to-repo mapping cache is written under `~/.claude/homunculus/vault-to-code-bridge/project-mappings.json`. Dry-run by default.
**Vault dependencies.** Assumes `1. Projects/<Project>/` notes with recognizable headers (Tech Stack, Build, Architecture) and a PARA-structured vault; output lands in the code repos, not the vault.
**Related.** `adr-standard` (the ADR format it writes against), `domain-modeling` (shapes scaffolded ADRs), `code-to-docs-sync`, `weekly-momentum-report`, `sync`.

### `weekly-momentum-report`

**Purpose.** Builds a comprehensive weekly review by aggregating git activity, vault tasks, and note-driven context into a narrative report, then merges it into the weekly note's `# Weekly Momentum Report` section in place.
**When to use.** Friday EOD or Sunday planning, monthly roll-ups, standup prep, or building a historical record for performance reviews.
**How it works.** Three-phase workflow: `discover-repos.sh` reads the weekly note's Daily Journal to find the repos you actually mentioned (wikilinks and leading labels), `scan-repos.sh --from-notes <week>` inventories git activity across just those repos (multi-author, week-scoped), `scan-vault-tasks.sh` parses completed/pending tasks, and `generate-report.sh` plus `merge-report.py` merge a marked per-repo changelog block into the note while Claude fills the narrative sections. Legacy full-sweep mode scans every repo under the search roots.
**Inputs.** `config.json` keys: `search_roots`, `vault_path`, `author_names`, `days_back`, `output_format`, `exclude_repos`, `ignore_labels`, `repo_aliases`, `include_uncommitted`, `include_branches`, `cache_path`. Reads the weekly note, `1. Projects/*/Backlog.md`, and `1. Projects/*/Tasks.md`; scans git repos under the search roots.
**Outputs.** Rewrites only the `# Weekly Momentum Report` section of `~/Developer/My_Notes/_Weekly/<year>/<year>-WXX.md` (Highlights, Summary, Learning, Blockers, Metrics, Changelog), leaving the Daily Journal untouched. Intermediate scan data caches under `~/.claude/homunculus/weekly-momentum-report/`.
**Vault dependencies.** Assumes `_Weekly/<year>/<year>-WXX.md` (must already exist from the weekly template) with a Daily Journal, plus `1. Projects/*/Backlog.md` and `Tasks.md` using Obsidian Tasks format.
**Related.** `quick-note` (feeds the daily entries this narrates), `sync`, `vault-to-code-bridge`, `code-to-docs-sync`.

### `what-next`

**Purpose.** Answers one question for one project: what to work on next. It indexes every open todo scattered across a project's notes, ranks them against a fixed model, and hands back a top 3 with concrete first moves.
**When to use.** When a project's open todos are scattered and out of priority order and you want a ranked shortlist to start today. Model invocation is disabled, so it runs on explicit `/what-next` (with a project name or none to infer from the cwd).
**How it works.** Seven steps: resolve the project (from the argument or inferred from the cwd), index every open `- [ ]` across backlogs/todos/task notes and the master task list, gather read-only priority signal (in-note markers, dependencies, git momentum, dates), build a four-band priority map (Now/Next/Later/Icebox), present it and get approval, optionally rewrite a note into priority order only if asked and approved, then deliver the top 3.
**Inputs.** No config.json. `VAULT_PATH=~/Developer/My_Notes`, `PROJECTS_DIR=1. Projects`, `CODE_REPOS_ROOT=~/Developer`. Optional argument: a project name. Reads `Backlog.md`, `*_Todos.md`, `*Backlog*.md` variants, `TaskLists/` folders, todo sections inside other notes, and `0.1 Tasks_List/Master_Task_List.md`; reads code repos only as momentum evidence.
**Outputs.** A banded priority map and a `Top 3` (each with why-now, a concrete first move, and file:line). Read-only by default; the single possible write is an opt-in, approval-gated reorder of a note that preserves every item verbatim.
**Vault dependencies.** Assumes `1. Projects/<Project>/` with varied todo conventions and `0.1 Tasks_List/Master_Task_List.md`; falls back to `2. Areas/`, `3. Resources/`, `4. Archive/`, `0. Inbox/` when resolving a name.
**Related.** `backlog-review` (reconcile shipped items first, then rank), `sync`, `ideas`.

## Workflow & Meta

### `adr-standard`

**Purpose.** The house standard for Architecture Decision Records: it fixes when a decision earns an ADR, the five mandatory sections, and the supersede-don't-edit rule so every ADR-writing skill produces the same shape. An ADR records why a decision was made at the time it was made, because the trail is the product.
**When to use.** When writing, updating, or superseding an ADR, when deciding whether a decision is worth recording, or when another skill (`domain-modeling`, `vault-to-code-bridge`, `improve-codebase-architecture`, `setup-hackastak`) needs the ADR format.
**How it works.** A decision earns an ADR only when both gates hold: it is hard to reverse and it involved a real trade-off. Each ADR is one immutable file with five ordered sections; to change a decision you write a new ADR at the next number, list the old one as a considered option, and edit only the old file's Status line.
**Inputs.** No config.json. Reads `docs/adr/` in the governed repo if it exists; otherwise proceeds silently. Ships an `agents/` subdir with a supporting agent definition.
**Outputs.** ADR files at `docs/adr/NNNN-slug.md`, one decision per file, with sections Status, Problem Statement, Considered Options, Decision, Consequences (optional `Date`/`Deciders` metadata). Slugs name the question, not the outcome.
**Vault dependencies.** None. Operates on the code repo; the domain model and ADRs are deliberately repo-native, not vault-native.
**Related.** `domain-modeling`, `grill-with-docs`, `vault-to-code-bridge`, `improve-codebase-architecture`, `setup-hackastak`, `sdd-workflow`.

### `ask-hackastak`

**Purpose.** The router over every Staksmith skill: a map with the engineering idea-to-ship flow as its spine. It points to the one or two skills that fit a situation and hands off; it never does the work itself.
**When to use.** When you know there is a skill for the task but not which one, when you want the lay of the land, or when the user invokes `/ask-hackastak`. Model invocation is disabled, so it runs only on explicit request.
**How it works.** If `$ARGUMENTS` names a situation it routes straight to the fitting skill with a one-line reason; with no argument it prints the whole map. It first flags context hygiene at phase boundaries (compact or hand off before invoking the next skill), then walks the idea-to-ship spine, on-ramps, cross-session moves, and the rest of the skills grouped by family.
**Inputs.** `$ARGUMENTS` (a situation to route, or empty). No config.json. Ships an `agents/` subdir.
**Outputs.** Advisory routing prose only: named skills, why each fits, and the deciding difference when two compete. Writes and executes nothing.
**Vault dependencies.** None directly. Operates as a pointer; the skills it routes to carry their own vault assumptions.
**Related.** Effectively every skill, since it is the index. Spine anchors include `source-research`, `codebase-design`, `prototype`, `domain-modeling`, `grill-me`, `implement`, `tdd-workflow`, and the review tier `review-changes` / `code-review` / `review-github-pr`.

### `batch-grill-me`

**Purpose.** A relentless design interview that asks every frontier question at once, round by round, so the user answers a batch per message instead of one prompt at a time. It reaches a shared understanding before any building begins.
**When to use.** When the user wants to answer a batch of design questions in one pass, when they know the domain, are working AFK, or care about throughput, or when they invoke `/batch-grill-me`. Model invocation is disabled.
**How it works.** It models the design as a tree and works it in rounds. Each round it asks the whole frontier (every decision whose prerequisites are settled), numbered with a recommended answer each, then waits. Answers reshape the tree and the frontier is recomputed; facts are dispatched to sub-agents rather than asked of the user. Done when the frontier is empty, and it does not act until the user confirms.
**Inputs.** No config.json; no explicit arguments beyond the conversation. Ships an `agents/` subdir. Reads the environment/codebase via sub-agents to settle fact-based questions.
**Outputs.** A settled shared understanding in the conversation. It captures nothing durable itself; that is `grill-with-docs`'s job or the downstream spec skills.
**Vault dependencies.** None. Operates on the conversation and, via sub-agents, the working tree.
**Related.** `grill-me` (the one-at-a-time cadence), `grill-with-docs` (compose to capture terms/ADRs), `to-spec` / `to-tickets` (where a finished interview goes next).

### `codebase-design`

**Purpose.** A shared design-time vocabulary for building deep modules: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. The aim is leverage for callers, locality for maintainers, and testability for everyone.
**When to use.** When designing or improving a module's interface, finding deepening opportunities, deciding where a seam goes, making code more testable or AI-navigable, or when another skill needs the deep-module vocabulary.
**How it works.** It supplies an exact glossary (module, interface, implementation, depth, seam, adapter, leverage, locality), the deep-vs-shallow test, and testability principles (accept dependencies, return results, keep the surface small). Two reference files go deeper: `DEEPENING.md` classifies dependencies into four categories and sets replace-don't-layer testing and seam discipline; `DESIGN-IT-TWICE.md` fans out 3+ parallel sub-agents to design an interface several radical ways and compares them on depth, locality, and seam placement.
**Inputs.** No config.json. `DESIGN-IT-TWICE.md` reads the project's `CONTEXT.md` glossary if present (skipped silently otherwise) and checks `docs/adr/` for conflicting accepted ADRs. Ships an `agents/` subdir.
**Outputs.** Design vocabulary and analysis in-conversation; when design-it-twice runs, several compared interface proposals with a recommendation. It restructures code only as part of the calling design work, not on its own.
**Vault dependencies.** None. Operates on the code repo and its `CONTEXT.md` / `docs/adr/`.
**Related.** `setup-ts-deep-modules`, `improve-codebase-architecture`, `diagnosing-bugs`, `tdd-workflow`, `domain-modeling`.

### `design-workflow`

**Purpose.** Runs a stateful `grill-me` session whose only output is workflow specs: it grills the user about the recurring loops in their life and work and turns each one worth delegating into a spec an implementer could build without further questions. It designs workflows; it does not run them.
**When to use.** When the user wants to design an automation, says "help me spec a workflow", or invokes `/design-workflow`. Model invocation is disabled; `$ARGUMENTS` may name a workflow or be empty to go find one.
**How it works.** It applies the `grill-me` interview discipline through a loop lens (life as loops within loops) and a small vocabulary (trigger, checkpoint, push right, brief), mandating no structure the grilling does not justify. Specs are created, edited, and deleted as the interview resolves things, following the vault draft-confirm-write gate. A spec is done only when an implementer could build it without asking a question.
**Inputs.** `$ARGUMENTS` (a workflow to design, or empty). No config.json. Reads `<vault>/2. Areas/Workflows/NOTES.md` for the user's tools/channels/terminology; interviews the user first when it is thin. Ships an `agents/` subdir.
**Outputs.** One spec per workflow at `<vault>/2. Areas/Workflows/<workflow>.md`, wikilinked to each other and the Areas they serve, plus the shared `NOTES.md` sharpened with canonical terms.
**Vault dependencies.** Assumes `<vault>/2. Areas/Workflows/` (PARA Areas), creating the folder if absent, and matches surrounding note frontmatter conventions.
**Related.** `grill-me` (the interview engine), `batch-grill-me`, `loop` / `schedule` (execution), `to-spec` (the software-feature equivalent), `wizard`.

### `domain-modeling`

**Purpose.** The active discipline of building and sharpening a project's domain model: challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. Merely reading `CONTEXT.md` is not this skill; this is for when you are changing the model.
**When to use.** When the user wants to pin down domain terminology or a ubiquitous language, record an architectural decision, or when another skill needs to maintain the domain model.
**How it works.** During a session it challenges terms against the existing glossary, sharpens fuzzy language into canonical terms, stress-tests relationships with concrete scenarios, cross-references claims against the code, and updates `CONTEXT.md` inline as terms resolve. It offers ADRs sparingly, only when both `adr-standard` gates hold, and supersedes rather than edits when revisiting a settled decision. The `CONTEXT.md` format lives in `CONTEXT-FORMAT.md` (tight definition plus an opinionated `_Avoid_` line, no implementation detail).
**Inputs.** No config.json. Reads and writes the repo-native `CONTEXT.md` (or per-context `CONTEXT.md` plus a root `CONTEXT-MAP.md` in multi-context repos) and `docs/adr/`, all created lazily. Ships an `agents/` subdir.
**Outputs.** An evolving `CONTEXT.md` glossary (glossary only, no specs or implementation notes), a `CONTEXT-MAP.md` when multiple contexts exist, and ADRs in `docs/adr/` per the house standard.
**Vault dependencies.** None. The domain model is deliberately repo-native (the exception to the vault-first habit) so the glossary evolves in the same commit as the code.
**Related.** `adr-standard`, `codebase-design` (the complementary architecture vocabulary), `grill-with-docs`, `setup-hackastak`.

### `grill-with-docs`

**Purpose.** A relentless `grill-me` interview that also leaves a paper trail: the glossary and ADRs get written as decisions crystallise, via `domain-modeling`. Two skills in one session, so the design that is settled is also captured.
**When to use.** When the user wants to be grilled on a design and have the domain model captured at the same time, especially a design the repo will have to live with (new domain concepts, costly-to-unwind decisions, fuzzy vocabulary). Use plain `grill-me` for a plan that only needs to survive the next hour. Model invocation is disabled.
**How it works.** `grill-me` drives the conversation (one question at a time, recommended answer each, facts looked up, no acting until confirmed) while `domain-modeling` captures output as it happens: terms into `CONTEXT.md` the moment they resolve, and an ADR into `docs/adr/` for any decision clearing both gates. Capture happens mid-interview, not batched at the end; ADRs are noted and written at the next natural break. Contradictions with existing ADRs are surfaced and superseded, never edited.
**Inputs.** No config.json. Reads and writes the repo's `CONTEXT.md` and `docs/adr/` through `domain-modeling`. Ships an `agents/` subdir.
**Outputs.** A settled design plus a written paper trail: updated `CONTEXT.md` glossary entries and any qualifying ADRs in `docs/adr/`.
**Vault dependencies.** None. Captures to the repo-native `CONTEXT.md` and `docs/adr/`.
**Related.** `grill-me`, `batch-grill-me`, `domain-modeling`, `adr-standard`, `to-spec` / `to-tickets`.

### `handoff`

**Purpose.** Writes a durable, self-contained handoff document so a fresh agent, or the user in a new session, can pick up exactly where this one left off. Save-only: it produces one artifact and stops, never launching anything.
**When to use.** At a session boundary, before `/clear` or `/compact`, when the session nears its context limit, when handing the thread to another agent or AFK run, or when the user invokes `/handoff`. Model invocation is disabled; `$ARGUMENTS` may name a focus for the next session.
**How it works.** It captures the goal, state of play (done/in-flight/not-started, branch, last commit, tree cleanliness), ordered next moves, suggested skills, and watch-outs, referencing durable artifacts by path/URL rather than restating them and redacting all secrets. It follows the vault draft-confirm-write gate, reports the path, states plainly that nothing was launched, then silently chains `quick-note` to drop a one-line breadcrumb into the current weekly note.
**Inputs.** `$ARGUMENTS` (focus for next session, or empty). No config.json. Ships an `agents/` subdir. Reads the conversation state and git state.
**Outputs.** One handoff document, at `<vault>/1. Projects/<Project>/Handoff_<slug>.md` when the work fuzzy-matches a project folder, the session scratchpad (`Handoff_<slug>.md`) when nothing matches, or the cwd (`handoff-<slug>.md`) when bound to a specific repo. Plus a weekly-note breadcrumb via `quick-note`.
**Vault dependencies.** Prefers `<vault>/1. Projects/<Project>/` via fuzzy project-name matching (asks when ambiguous, never creates a folder silently); the breadcrumb assumes the weekly-note structure `quick-note` uses.
**Related.** `strategic-compact` (the in-place counterpart), `quick-note`, `weekly-momentum-report`, `what-next`.

### `implement`

**Purpose.** A thin orchestrator that builds one committable unit of work described by a spec, a ticket, a GitHub issue, or an inline task. It sequences the skills that do the real work and enforces the cadence between them.
**When to use.** When the user says "implement this", "build ticket 03", references an issue, or invokes `/implement`. Model invocation is disabled.
**How it works.** Five steps: pin down what is being built (fetch the reference or restate an inline task and get agreement; split with `to-tickets` if it is more than one ticket, and read `CONTEXT.md` plus `docs/adr/`); build test-first via `tdd-workflow` at pre-agreed, confirmed seams; keep the verification cadence (typecheck per slice, focused tests in the tight loop, full suite once at the end); run `review-changes` over the diff; then stage, summarise, and hand back for the user's own commit, pausing at each committable block.
**Inputs.** No config.json. Reads the tracker backend named in `docs/agents/issue-tracker.md` (vault by default) to fetch a referenced ticket/issue, plus `CONTEXT.md` and `docs/adr/`. Ships an `agents/` subdir.
**Outputs.** Implemented, tested, reviewed code staged (never committed) with a change summary handed back to the user.
**Vault dependencies.** Indirect: the default issue-tracker backend is the vault, per `docs/agents/issue-tracker.md`, so referenced tickets may resolve to vault issues.
**Related.** `to-tickets`, `tdd-workflow`, `review-changes`, `draft-commit`, `diagnosing-bugs`, `sdd-workflow`.

### `prototype`

**Purpose.** Builds throwaway code that answers a single design question, where the question decides the shape. It sanity-checks whether a state model or logic feels right, or explores what a UI should look like, then captures the verdict and disposes of the code.
**When to use.** When the user wants to check whether a state model or logic feels right, or explore a UI, and talking has stopped moving the question forward.
**How it works.** It picks a branch by question. `LOGIC.md`: a tiny interactive terminal app (a pure reducer/state machine/function set behind a small interface, plus a throwaway TUI shell that clears and re-renders each frame) to drive the state model by hand. `UI.md`: several radically different UI variants on one route switched by a `?variant=` param and a floating bottom bar, preferring to host them inside an existing populated page. Both obey shared rules: throwaway and clearly marked, one command to run, no persistence, no polish, surface the state, capture when done.
**Inputs.** No config.json. Reads the user's prompt and surrounding code to choose a branch and match tooling conventions. Ships `LOGIC.md`, `UI.md`, and an `agents/` subdir.
**Outputs.** Two things that live apart: the verdict (asked X, learned Y, doing Z) appended to the vault project note or its tracking ticket/issue, and the prototype code staged on a throwaway branch `prototype/<slug>` (staged then handed back, never committed or pushed), with a context pointer left in the vault note. Decision-encoding snippets may be inlined into the note.
**Vault dependencies.** Writes the verdict to `<vault>/1. Projects/<Project>/` (or its `issues/` ticket) by fuzzy repo-name matching, asking when ambiguous and never creating a project folder silently; falls back to the GitHub tracking issue when the repo uses the `github` tracker.
**Related.** `codebase-design`, `wayfinder`, `to-spec` / `to-tickets`, `grill-me`.

### `sdd-workflow`

**Purpose.** Enforces spec-driven development: an approved spec (not a coverage number) is written first and is the gate closed at the end, so every line of implementation traces back to a story or decision in the spec. A thin orchestrator that sequences existing skills and adds the spec-conformance gate none of them own.
**When to use.** When building a feature big enough to write requirements down first, spanning multiple stories/actors, more than one committable unit, or more than one session, or when the user says "spec-first" / "spec-driven development" / invokes `/sdd`. For a single function or quick fix, use `/tdd` instead. Model invocation is disabled.
**How it works.** The loop is SPEC to SLICE to BUILD to CONFORM to REPEAT. SPEC runs `to-spec` on a settled conversation (or `grill-me` / `grill-with-docs` first if not settled), respecting ADRs. SLICE runs `to-tickets` into tracer-bullet slices each tracing to a story. BUILD works the frontier via `implement` (which drives `tdd-workflow` at confirmed seams). CONFORM is the distinguishing gate: walk the spec's user stories and the ticket's acceptance criteria, check implementation decisions, confirm no untraceable behaviour crept in, and run `verification-loop` for the mechanical floor. Then stage, summarise the spec mapping, and hand back for a manual commit.
**Inputs.** No config.json. Reads the tracker backend in `docs/agents/issue-tracker.md` (vault by default) via `to-spec` / `to-tickets`, and `docs/adr/` for constraining decisions. Ships an `agents/` subdir.
**Outputs.** An approved spec published to the tracker, tracer-bullet tickets, test-first implementation staged (never committed), and an explicit per-ticket conformance result stating which stories/criteria are satisfied and what was deferred.
**Vault dependencies.** Indirect: `to-spec` / `to-tickets` publish to the configured tracker, the vault by default, per `docs/agents/issue-tracker.md`.
**Related.** `grill-me` / `grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `tdd-workflow`, `verification-loop` / `review-changes`, `adr-standard`.

### `setup-hackastak`

**Purpose.** Scaffolds the per-repo configuration that the Hackastak engineering flow reads: the issue-tracker backend, triage labels, and domain-model layout. It is a configurator, not an installer, pointing an already-equipped harness at this repo's choices.
**When to use.** When a repo has no `docs/agents/` config, when to-spec/to-tickets/triage/wayfinder report a missing tracker, or when the user says "set up this repo", "configure staksmith here", or invokes `/setup-hackastak`.
**How it works.** Confirms the repo root, checks existing `docs/agents/` files, then drafts three files through a single draft to confirm to write gate: Section A picks the backend (default `vault`, else `github` or `local`) and writes `issue-tracker.md`, Section B always writes `triage-labels.md`, Section C writes `domain.md`. It never creates `CONTEXT.md`, `docs/adr/`, `spec.md`, or tickets (those stay lazy), and stages without committing.
**Inputs.** No config.json. Reads seed files it ships (`issue-tracker-vault.md`, `triage-labels.md`, `domain.md`), the repo name (fuzzy-matched against `<vault>/1. Projects/` folders for the vault backend), and existing `docs/agents/*.md`. Honors user overrides of label strings and monorepo signals (`packages/`, `apps/`, `contexts/`).
**Outputs.** `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, and `docs/agents/domain.md` in the target repo, staged not committed.
**Vault dependencies.** For the vault backend it assumes a PARA project folder under `<vault>/1. Projects/<Project>/`; the github and local backends need no vault.
**Related.** `to-spec`, `to-tickets`, `triage`, `wayfinder` (read its output), `domain-modeling`, `adr-standard`, `vault-to-code-bridge`, `setup-pre-commit`, `git-guardrails`.

### `skill-auto-extractor`

**Purpose.** Mines git history and session logs across repositories to detect repeated workflows and auto-generate reusable SKILL.md definitions for review before promotion.
**When to use.** On a monthly review, after a sprint, before a team member transition, when the same workflow is detected 3+ times, or as part of the continuous-learning (homunculus) evolution system.
**How it works.** A 3-phase pipeline run via shell scripts: `scripts/scan-history.sh` extracts patterns from git logs and session transcripts, `scripts/detect-patterns.sh` identifies reusable workflows, and `scripts/generate-skill.sh` writes SKILL.md files. Generated skills follow the `skill-design` vocabulary and should be checked against the sprawl and no-op failure modes. Depends on `jq`, `git`, `bc`, and Claude AI access.
**Inputs.** `config.json` keys: `repos_root`, `days_back`, `min_frequency`, `confidence_threshold`, `output_path`, `session_logs_path`, `exclude_repos`, `author_name`, `pattern_types`, `cache_path`. It reads git repos under `repos_root` and optional session logs at `session_logs_path`.
**Outputs.** A pattern report at `~/.claude/homunculus/evolved/patterns-report.json` and generated skills under `~/.claude/homunculus/evolved/skills/{pattern-id}/` (SKILL.md, metadata.json, examples/), pending review before promotion to `~/.claude/skills/` or the Staksmith skills dir.
**Vault dependencies.** None. Operates on code repos and the `~/.claude/homunculus/` workspace.
**Related.** `skill-design`, `skill-creator`, `skill-stocktake`, `continuous-learning-v2`, `weekly-momentum-report`, `vault-to-code-bridge`, `code-to-docs-sync`.

### `skill-design`

**Purpose.** The reference layer for writing and editing skills well: the vocabulary and principles (predictability, invocation, information hierarchy, leading words, failure modes) that make a skill predictable. It does no task itself.
**When to use.** When authoring, auditing, or refactoring a skill, or when another skill needs the shared skill-design vocabulary. User-invoked only (`disable-model-invocation: true`).
**How it works.** All reference, no steps. `SKILL.md` covers invocation tradeoffs (model- vs user-invoked), description writing, the information-hierarchy ladder (in-skill step, in-skill reference, external reference), progressive disclosure, when to split, pruning, leading words, and named failure modes (premature completion, duplication, sediment, sprawl, no-op, negation). Full term definitions are disclosed to `GLOSSARY.md`.
**Inputs.** No config.json or arguments. Reads its sibling `GLOSSARY.md` for bolded term definitions.
**Outputs.** None. It is a knowledge reference consulted while working on other skills.
**Vault dependencies.** None. Pure reference, no filesystem writes.
**Related.** `skill-creator` (authors a new skill), `skill-stocktake` (audits skills), `skill-auto-extractor` (mines patterns), `writing-fragments` (shares the leading-word concept).

### `teach`

**Purpose.** Teaches the user a new skill or concept over multiple sessions, building a stateful, vault-based learning workspace of missions, interactive HTML lessons, references, and learning records grounded in the user's real-world mission.
**When to use.** When the user wants to learn something over time, or invokes `/teach`. User-invoked only (`disable-model-invocation: true`); takes a topic as an argument.
**How it works.** On first use it creates the topic workspace; on return it reads existing state before teaching to gauge the zone of proximal development. It grounds teaching in `MISSION.md`, gathers trusted sources into `RESOURCES.md` (never parametric knowledge), authors short interactive HTML lessons built from reusable `assets/` components, records insights as numbered learning records, and distinguishes fluency from storage strength. Format helpers: `MISSION-FORMAT.md`, `RESOURCES-FORMAT.md`, `LEARNING-RECORD-FORMAT.md`, `GLOSSARY-FORMAT.md`.
**Inputs.** No config.json. Reads the topic workspace files and the four `*-FORMAT.md` reference files. Takes the learning topic as its argument.
**Outputs.** Files under the vault workspace: `MISSION.md`, `RESOURCES.md`, `NOTES.md`, `reference/*.html`, `lessons/NNNN-<name>.html`, `learning-records/NNNN-<name>.md`, and `assets/*`. Optionally publishes a lesson as a Claude Code Artifact (a view, not the canonical home).
**Vault dependencies.** Assumes the PARA Area `<vault>/2. Areas/Learning/<Topic>/`, alongside `2. Areas/Workflows/`. No git.
**Related.** `source-research`, `design-workflow`, `grill-me`.

### `to-questionnaire`

**Purpose.** Turns a decision the user cannot answer alone into a Markdown questionnaire handed to a third party who holds the missing knowledge, filled in async or over a meeting. It is the outbound inverse of the grill-me family.
**When to use.** When the user needs knowledge a third party holds, or invokes `/to-questionnaire`. User-invoked only (`disable-model-invocation: true`).
**How it works.** Interviews the user only about the send (who it goes to, what they need back), never about the subject, then drafts gap-targeting questions using the built-in questionnaire template: purpose, from/to line, context, how-to-answer, themed `##` sections with one-idea questions ordered most-important-first, and a closing catch-all. Follows the draft to confirm to write gate.
**Inputs.** No config.json. Reads the conversation and the recipient/need details gathered in the two-step interview.
**Outputs.** A Markdown questionnaire. Default `<vault>/1. Projects/<Project>/Questionnaire_<slug>.md` on a project match, else `<vault>/0. Inbox/Questionnaire_<slug>.md`; or `to-questionnaire-<slug>.md` in the cwd when it belongs beside a code repo.
**Vault dependencies.** Defaults to `<vault>/1. Projects/<Project>/` or `<vault>/0. Inbox/`, with the same fuzzy project matching as the other vault skills. Can target the code repo instead.
**Related.** `grill-me`, `batch-grill-me`, `to-spec`, `to-tickets`.

### `to-spec`

**Purpose.** Synthesizes the current conversation and codebase understanding into a spec (PRD) and publishes it to the project's configured issue tracker. It does not interview the user; it only synthesizes what has already been discussed.
**When to use.** When the user says "turn this into a spec", "write the PRD", or invokes `/to-spec`. User-invoked only (`disable-model-invocation: true`).
**How it works.** Explores the repo (reading `CONTEXT.md`, honoring `docs/adr/`), sketches the test seams and confirms them with the user (the one pause), then writes the spec from its template (Problem, Solution, User Stories, Implementation Decisions, Testing Decisions, Out of Scope, Further Notes) and publishes it, applying the `ready-for-agent` triage role. Avoids file paths and code snippets except prototype-derived decision snippets.
**Inputs.** No config.json. Reads `docs/agents/issue-tracker.md` for the backend (defaults to vault), `CONTEXT.md`, the domain glossary, and `docs/adr/`.
**Outputs.** A spec published per backend: vault `<vault>/1. Projects/<Project>/spec.md` (wikilinked), github a `gh` issue, or local `.scratch/<feature-slug>/spec.md`.
**Vault dependencies.** For the vault backend, `<vault>/1. Projects/<Project>/spec.md` following `issue-tracker-vault.md` conventions. None for github/local.
**Related.** `grill-me`, `grill-with-docs`, `to-tickets`, `codebase-design`, `setup-hackastak`.

### `to-tickets`

**Purpose.** Breaks a plan, spec, or conversation into tracer-bullet vertical-slice tickets, each declaring its blocking edges, and publishes them to the configured tracker.
**When to use.** When the user says "break this into tickets", "turn the spec into issues", or invokes `/to-tickets`. User-invoked only (`disable-model-invocation: true`).
**How it works.** Gathers context (optionally fetching a referenced spec/issue), optionally explores the codebase for prefactoring, drafts vertical slices sized to one context window with blocking edges (handling wide refactors via an expand-migrate-contract sequence instead), quizzes the user on granularity and edges until approved, then publishes in dependency order and works the frontier. Uses file-ticket and issue templates; applies the `ready-for-agent` role.
**Inputs.** No config.json. Reads `docs/agents/issue-tracker.md` for the backend (defaults to vault), the source spec/conversation, `CONTEXT.md` glossary, and relevant ADRs.
**Outputs.** One ticket per file/issue in dependency order: vault `<vault>/1. Projects/<Project>/issues/<NN>-<slug>.md` (wikilinked to the spec), github one `gh` issue each, or local `.scratch/<feature-slug>/issues/<NN>-<slug>.md`. Does not close or modify the parent issue or spec.
**Vault dependencies.** For the vault backend, `<vault>/1. Projects/<Project>/issues/` per `issue-tracker-vault.md`. None for github/local.
**Related.** `to-spec`, `implement`, `wayfinder`.

### `triage`

**Purpose.** Moves issues (and, on github, external PRs) through a small state machine of triage roles: categorize, verify the claim, grill if needed, and write agent-ready briefs.
**When to use.** When the user says "triage this", "what needs my attention", "move #42 to ready-for-agent", or invokes `/triage`. User-invoked only (`disable-model-invocation: true`).
**How it works.** Presents attention buckets (untriaged, needs-triage, needs-info with reporter activity) or triages a named item: gather context, check redundancy and prior rejection against `.out-of-scope/`, recommend a category and state role, verify the claim (reproduce a bug or run a PR diff), grill via `grill-with-docs` if needed, then apply the outcome (post an agent brief, needs-info notes, or wontfix). Roles are two categories (bug, enhancement) and five states (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). Remote comments carry an AI-generated disclaimer; all writes pass a confirm gate. Reference files: `AGENT-BRIEF.md`, `OUT-OF-SCOPE.md`.
**Inputs.** No config.json. Reads `docs/agents/issue-tracker.md` (backend and whether external PRs are a surface), `docs/agents/triage-labels.md` for label strings, `CONTEXT.md`, ADRs, and `.out-of-scope/*.md`.
**Outputs.** Updated role labels (github) or `Status:` lines (vault/local), posted agent briefs, triage notes, and `.out-of-scope/*.md` entries for rejected enhancements. External-PR triage applies only on github.
**Vault dependencies.** For the vault backend, tickets under `<vault>/1. Projects/<Project>/` with `Status:` lines and a `## Comments` heading. None for github; local uses `.scratch/`.
**Related.** `grill-with-docs`, `diagnosing-bugs`, `to-tickets`, `implement`, `setup-hackastak`.

### `wayfinder`

**Purpose.** Plans a chunk of work too big and foggy for one session as a shared map of decision tickets (questions whose resolution is a decision, not a build), resolving them one at a time until the way to the destination is clear.
**When to use.** When an effort is too big and too foggy to spec yet, or when the user invokes `/wayfinder`. User-invoked only (`disable-model-invocation: true`).
**How it works.** Two modes. Chart the map: name the destination via `grill-with-docs`, map the frontier breadth-first, create the map (Destination, Notes, Decisions-so-far, Not yet specified, Out of scope), create specifiable tickets and wire blocking edges in a second pass, fire `source-research` subagents for research tickets, then stop. Work the map: load the low-res map, claim the next frontier ticket, resolve it (by ticket type: research/prototype/grilling/task, each HITL or AFK), record the resolution, and update the map and its fog of war. Never resolves more than one ticket per session (except parallel research).
**Inputs.** No config.json. Reads the "Wayfinding operations" section of `docs/agents/issue-tracker.md` (backend, defaults to vault), the map body, ticket bodies on demand, and the skills named in the map's `## Notes`.
**Outputs.** A map artifact and child decision tickets with type/status/blocking edges. Vault `<vault>/1. Projects/<Project>/map.md` plus `issues/NN-<slug>.md`; github a `wayfinder:map` issue with `wayfinder:<type>` child issues using native dependencies; local the vault file shapes under `.scratch/<effort-slug>/`.
**Vault dependencies.** For the vault backend, `<vault>/1. Projects/<Project>/map.md` and `issues/`, wikilinked. None for github; local uses `.scratch/`.
**Related.** `grill-with-docs`, `source-research`, `prototype`, `to-spec`, `to-tickets`, `implement`.

### `wizard`

**Purpose.** Generates an interactive bash wizard that walks a human step by step through a tedious manual procedure (third-party setup, a one-off migration, an A-to-B transition), opening URLs, capturing values, confirming each step, and writing `.env` files and GitHub Actions secrets.
**When to use.** When a manual procedure is tedious to do by hand and to re-explain to an AI each time. User-invoked only (`disable-model-invocation: true`).
**How it works.** Copies `template.sh` (which already solves the UX: progress with time-remaining, confirmation gates, cross-platform URL opening including WSL, hidden secret entry, idempotent `.env` upserts, `gh secret`/`gh variable` writes, closing summary) and authors one `stage` per step below the `STAGES` marker, never editing the shared library above it. Steps: scope the procedure by reading repo config, map each stage's concrete click-path, author stages with the library helpers, then verify statically (`bash -n`, shellcheck, `chmod +x`) and hand off without running it end-to-end.
**Inputs.** No config.json. Reads `template.sh` and, when scoping, the repo's `.env`, `.env.example`, `.env.*`, `README`, `docker-compose*`, framework config, and `.github/workflows/*` (each `secrets.*`/`vars.*` reference is a value to produce).
**Outputs.** An executable bash wizard: ephemeral one-offs go to the scratchpad; a repeatable setup path worth keeping goes to `scripts/` with a README link, staged (not committed) for the user. At runtime it writes `.env` values and `gh` secrets/variables.
**Vault dependencies.** None. Operates on the code repo and scratchpad.
**Related.** `design-workflow`, `setup-pre-commit`, `setup-ts-deep-modules`, `diagnosing-bugs`.

## Code Review & Quality

### `a11y-review`

**Purpose.** Reviews frontend code for accessibility (semantic structure, keyboard and focus, ARIA correctness, text alternatives, forms, color/contrast, and dynamic-content announcements), ranked by WCAG severity and real user impact. It is the accessibility axis that neither `code-review` nor the frontend-patterns skill covers.
**When to use.** Auditing a web, React, Vue, Svelte, or template-based UI, or when the user says "accessibility review", "a11y", "is this WCAG compliant", or invokes `/a11y-review`.
**How it works.** Detects the UI layer and framework, prioritizes interactive and high-traffic surface (forms, modals, menus, custom controls), then walks nine accessibility dimensions citing the relevant WCAG success criterion. It runs read-only tooling (jsx-a11y lint, axe, pa11y, Lighthouse) only against an already-running server, and is explicit about the split between what static review can catch and what needs a rendered DOM.
**Inputs.** Frontend files (`.jsx`/`.tsx`, `.vue`, `.svelte`, `.astro`, `.html`, and template files), lint configs, component libraries. Read-only git.
**Outputs.** A single inline Markdown report using the house format: Summary with verdict, findings as `####` subsections tiered Critical/Major/Minor/Nits with WCAG SC, a "Not statically verifiable" section, and "What looks good". Nothing is written to a file or posted.
**Vault dependencies.** None. Operates on the code repo / working tree.
**Related.** `frontend-patterns`, `code-review`, `audit-codebase` (dispatches this when a frontend is detected), `dataviz`.

### `audit-codebase`

**Purpose.** Audits a whole codebase across every review dimension at once by fanning out the specialist reviewer agents and merging their output into one deduped, severity-ranked report. It is the front door for reviewing an unfamiliar repo end to end.
**When to use.** Reviewing an unfamiliar codebase end to end, or when the user says "audit this repo", "review the whole codebase", or invokes `/audit-codebase`.
**How it works.** Scopes the repo, probes build health once up front, builds a shared context brief (conventions, high-risk surface, build status), then dispatches the matching specialist agents in a single message: `code-reviewer`, `security-reviewer`, `architect`, `refactor-cleaner`, `database-reviewer`, language reviewers, `performance-reviewer`, plus optional test-coverage and accessibility passes via `general-purpose`. It then dedupes findings by `file:line` plus root cause, reconciles severity, and spot-checks every Critical and Major itself. Read-only briefs are mandatory for the agents that can edit.
**Inputs.** The entire repository by default (or a named directory/service/diff), manifests, conventions files (`CLAUDE.md`, ADRs, `CONTEXT.md`), build tooling. Read-only git.
**Outputs.** A single inline Markdown report: Summary, tiered findings with dimension tags (`Security · Correctness`), a Coverage section naming skipped/shallow passes, Architectural notes, and "What looks good".
**Vault dependencies.** None. Operates on the code repo / working tree.
**Related.** `code-review`, `security-scan`, `improve-codebase-architecture`, `review-changes` / `review-github-pr`, `adr-standard`.

### `backlog-review`

**Purpose.** Reconciles the Obsidian vault's backlog and todo notes with reality: finds open items, verifies with evidence from the associated code repos and other notes whether each is actually already done, and marks the confirmed ones complete. Review only, it never writes code or does the work.
**When to use.** When a backlog feels stale and should be reconciled against what actually shipped, after a stretch of dev work to sweep up done-but-unchecked items, or before planning to get an accurate picture of what is still open.
**How it works.** Requires a project name (asks if none is given, never defaults to the whole vault), locates the backlog files under `1. Projects/<Project>/`, parses open `- [ ]` items with their acceptance sub-items, gathers read-only evidence from the resolved code repo (git log, grep, CHANGELOG) and vault notes, and classifies each as Complete / Partially complete / Not complete / Cannot verify. Only Complete items are eligible to be checked off, and only after presenting findings and confirming.
**Inputs.** A project name (resolved case-insensitively to a vault folder) or a full backlog file path; reads backlog/todo notes, the `Repo:` reference, and read-only code repos under `~/Developer`.
**Outputs.** A grouped findings report, then edits to the vault backlog notes only: flips confirmed `- [ ]` to `- [x]` and appends a dated inline evidence note (` ✅ YYYY-MM-DD — <evidence>`). Never edits any file outside the vault.
**Vault dependencies.** Yes. Assumes `VAULT_PATH=~/Developer/My_Notes` with backlogs under `1. Projects/` (some in `2. Areas/`, `4. Archive/`), the `- [ ]`/`- [x]` task convention, a `## Done ✅` section, and inline `✅ YYYY-MM-DD` evidence annotations. `CODE_REPOS_ROOT=~/Developer`.
**Related.** Planning skills that consume an accurate backlog; the vault backlog convention shared with `<vault>/1. Projects/`.

### `code-review`

**Purpose.** Reviews all the code on the current branch (the whole state of what the branch has built, read broadly and architecturally), not a diff. This is the broad, architectural tier of the review family, run before pushing.
**When to use.** Before pushing or opening a PR, or when the user says "review this branch", "review my work", or invokes `/code-review`.
**How it works.** Scopes the branch against its merge-base, reads the touched files in full at their current state plus their neighbours (no attribution tags since there is no diff), finds the project's conventions and any spec, then reviews across six dimensions: correctness, security, style, test coverage, architecture, and performance. It applies the twelve-smell baseline from `SMELLS.md` under Architecture and Style, and for large branches fans dimensions out to `general-purpose` sub-agents with the smell baseline pasted into each brief.
**Inputs.** The current branch vs a base (default `main`/`master`), the changed-file list as a scoping list, conventions files, and an optional spec (argument, commit issue refs, or `1. Projects/<Project>/spec.md`). Read-only git.
**Outputs.** A single inline Markdown report: Summary with verdict, tiered findings as `####` subsections, optional Spec section, Architectural notes, "What looks good", and Open questions.
**Vault dependencies.** Optional only: the Spec axis may look for `<vault>/1. Projects/<Project>/spec.md`. Otherwise operates on the code repo / working tree.
**Related.** `review-changes`, `review-github-pr`, `codebase-design`, `security-review`, `adr-standard`.

### `improve-codebase-architecture`

**Purpose.** Scans a codebase for deepening opportunities (refactors that turn shallow modules into deep ones for testability and AI-navigability), presents them as a visual Markdown report saved in the vault, then grills through whichever candidate the user picks. It plans; it does not build.
**When to use.** When the user wants an architecture review, asks where the codebase is getting hard to change, or invokes `/improve-codebase-architecture`. (Model invocation is disabled, so it runs on explicit request.)
**How it works.** Scopes to recently-changed hot spots (via `git log`) unless the user names a direction, uses the `Explore` agent to find shallow modules and seam leakage, applies the deletion test, and classifies each candidate's dependencies by the four `codebase-design` categories. It writes a durable, wikilinkable review note to the vault, then runs a `grill-with-docs` loop on the chosen candidate, doing side effects inline via `domain-modeling` (updating `CONTEXT.md`, offering ADRs on load-bearing rejections). Uses the `codebase-design` vocabulary (module, interface, depth, seam, adapter, leverage, locality) throughout.
**Inputs.** The repo (weighted to hot spots) or a user-named module/subsystem/pain point; reads `CONTEXT.md` and `docs/adr/`. Uses the `Explore` agent to walk the code.
**Outputs.** A Markdown note written to `<vault>/1. Projects/<Project>/Architecture_Review_<YYYY-MM-DD>.md` following `MD-REPORT.md` (Mermaid for graph-shaped structure, ASCII depth-boxes for mass/depth, text badges, before/after per candidate, a Top recommendation). Optionally offers to publish the same report as a Claude Code Artifact. Never commits.
**Vault dependencies.** Yes. Locates the project folder by fuzzy-matching the repo name against `<vault>/1. Projects/` (asks if ambiguous, never creates one silently) and writes the review note there, wikilinking to the project's other notes and following the tracker's draft/confirm/write gate.
**Related.** `codebase-design`, `diagnosing-bugs`, `domain-modeling` / `adr-standard`, `to-tickets` / `implement`.

### `perf-review`

**Purpose.** Reviews code for performance (latency, throughput, memory, scalability) across a whole repo or a diff, flagging N+1 queries, algorithmic complexity, blocking I/O on async paths, unbounded work, missing pagination/caching, retry storms, and bundle/render cost, ranked by real hot-path impact. It is the performance axis `code-review` only touches in passing.
**When to use.** When the user says "review performance", "why is this slow", "perf review", or invokes `/perf-review`.
**How it works.** Scopes to the whole repo (or a named scope or diff), detects the stack, and finds the hot paths (request handlers, the wall-clock pipeline, loops over user-scale data). It ranks strictly by real hot-path impact (how often, over how much data, on a path the user waits on), walks five dimensions (database/IO, concurrency/blocking, memory/allocation, caching/redundant work, frontend), and distinguishes measured from reasoned findings using read-only tooling like `EXPLAIN` or `pprof` where present. For large repos it delegates to the `performance-reviewer` agent.
**Inputs.** The repo, a named scope, or a diff's file list (`git diff --name-only <base>...HEAD`); manifests and read-only measure tooling. Read-only git.
**Outputs.** A single inline Markdown report: Summary with verdict, tiered findings with a short `—` label, a Coverage section marking measured vs reasoned, and "What looks good".
**Vault dependencies.** None. Operates on the code repo / working tree.
**Related.** `performance-reviewer` (agent), `code-review`, `database-reviewer` / `postgres-patterns`, `cost-aware-llm-pipeline`.

### `review-changes`

**Purpose.** Reviews only the changes in the working tree (the staged and unstaged diff against `HEAD`), with attribution so inherited debt does not block your own work. This is the tight in-dev tier, run after each committable block of work.
**When to use.** As the tight in-dev loop, or when the user says "review my changes", "review the diff", or invokes `/review-changes`. Called by `implement` before handing back for the commit.
**How it works.** Captures the full diff including untracked files (read in full as introduced code), finds conventions, and reviews across the same six dimensions as `code-review` with the smell baseline. Its distinguishing step is attribution: before assigning severity, it checks `HEAD` to classify each finding as introduced (full severity ladder), improved-but-incomplete (capped at Minor), or pre-existing (never blocking, moved to a separate section). Attribution is a gate, not report content; the tag in the header is the only visible result. Citations must anchor to file lines the change actually touched, never patch positions.
**Inputs.** The working-tree and staged diff vs `HEAD`, untracked files, conventions files (`CLAUDE.md`, ADRs, `CONTEXT.md`). Read-only git.
**Outputs.** A single inline Markdown report: Summary with verdict, tiered findings (introduced or improved-but-incomplete only), a "Pre-existing — worth filing separately" section, "What looks good", and Open questions.
**Vault dependencies.** None. Operates on the code repo / working tree.
**Related.** `implement`, `code-review`, `review-github-pr`, `draft-commit`.

### `security-scan`

**Purpose.** Audits a whole codebase for security vulnerabilities inline in the main context, without spawning an agent, covering secrets, injection, authn/authz, SSRF, unsafe crypto, dependency CVEs, license/SBOM compliance, and the OWASP Top 10. It is the security-focused sibling of `code-review` with the same severity ladder and anchored-report format.
**When to use.** To security-review an unfamiliar repo, or when the user says "security scan", "audit this for security", "check licenses", or invokes `/security-scan`. Reach for it (rather than the `security-reviewer` agent) when you want the findings and follow-up conversation to stay in the main context.
**How it works.** Scopes the whole repo, learns the existing security posture so it does not report controls that exist, runs read-only tooling (dependency/CVE audit per ecosystem, secret scanning, SAST, license/SBOM resolution), then walks eleven security dimensions reading high-risk files in full. It ranks by exploitability in this codebase rather than raw CVSS, judges every dependency license against the project's declared license, and states at the top which tools ran and which were unavailable.
**Inputs.** The whole repo (or a named scope or diff), manifests, security config, `.gitignore`, `docs/adr/`, and read-only audit tooling (npm audit, pip-audit, cargo audit, govulncheck, gitleaks, semgrep, license/SBOM readers). Read-only git.
**Outputs.** A single inline Markdown report: Summary with risk verdict, tiered findings, Dependency advisories, License & SBOM, Coverage gaps, and "What looks good".
**Vault dependencies.** None. Operates on the code repo / working tree.
**Related.** `code-review`, `security-review`, `security-reviewer` (agent), `database-reviewer`, `adr-standard`.


## Testing & TDD

### `test-audit`

**Purpose.** Audits an existing test suite for coverage gaps and test quality (untested critical paths, weak assertions, tautological tests, and tests that mock internal collaborators instead of testing at a seam). It is the read-only counterpart to the TDD family, which write tests first; coverage percentage is treated as the start of the question, not the answer.
**When to use.** To assess a codebase's tests, or when the user says "audit the tests", "are these tests any good", "where are we under-tested", or invokes `/test-audit`.
**How it works.** Scopes the whole repo (or a diff), detects the test framework, maps test files to source to spot where risk and test effort mismatch, then measures coverage with the project's read-only tooling and looks past the number. It walks two axes: coverage gaps (untested critical paths, zero-test modules, happy-path-only) and test quality (weak/tautological/assertion-free tests, mock-the-internals, flaky-by-construction, brittle coupling, coverage padding), ranking by risk rather than percentage.
**Inputs.** The whole repo or a diff's file list; test files, source, and read-only coverage tooling (`go test -cover`, `pytest --cov`, `cargo llvm-cov`, jest/vitest coverage, JaCoCo). Read-only git.
**Outputs.** A single inline Markdown report: Summary with verdict, tiered findings with a short `—` label, a Coverage map turning the percentage into a decision, a "Coverage gaps (tooling)" section, and "What looks good".
**Vault dependencies.** None. Operates on the code repo / working tree.
**Related.** `tdd` and the language test skills (`go-test`, `python-testing`, `rust-test`, `cpp-test`), `code-review`, `codebase-design`, `audit-codebase` (dispatches this as its optional test-coverage pass).


## Docs & Lookup

### `code-to-docs-sync`

**Purpose.** Detects drift between code and documentation (READMEs, CLAUDE.md, API docs) and proposes automated fixes, catching cases where code changes but documentation does not keep up. Common drift patterns include README tech stack vs `package.json` deps, CLAUDE.md build commands vs scripts, and API docs vs actual routes.
**When to use.** Post-merge (via git hook), on a weekly documentation audit, pre-release, on-demand when docs are suspected stale, or in CI/CD.
**How it works.** A three-phase workflow driven by shell scripts: `detect-drift.sh` scans docs and code for inconsistencies, `analyze-drift.sh` analyzes what changed, and `sync-docs.sh` applies approved fixes while preserving manually-maintained sections (guarded by `<!-- sync:ignore -->` blocks). It supports git-hook and CI integration, uses semantic analysis to recognize synonyms and context, and backs up files before modifying them.
**Inputs.** Configured via `config.json`: `repos_root` directories to scan, `watch_files` (README.md, CLAUDE.md, CONTRIBUTING.md, docs globs, API_DOCUMENTATION.md), `ignore_repos`, `auto_commit` (default false, requires approval), `staleness_threshold_days`, and per-file `comparison_rules`. Depends on `jq`, `git`, `diff`, and Claude AI access.
**Outputs.** A drift report JSON at `~/.claude/homunculus/code-to-docs-sync/drift-report.json`, a side-by-side fix preview with rationale, and (on approval) edits to the documentation files, optionally auto-committed.
**Vault dependencies.** None. Operates on code repos configured in `config.json` (the shipped default points at `~/Developer/PROJECTS` and `~/Developer/SMILESTACKLABS`).
**Related.** `vault-to-code-bridge`, `weekly-momentum-report`, `skill-auto-extractor`, `/review-pr`.

## Writing & Content

### `blog-draft`

**Purpose.** Drafts a complete first-draft blog post for The HackaStak by mining the vault for evidence and writing in the established brand voice, so you edit from a full draft instead of a blank page.
**When to use.** You have a topic or idea ready to develop, want to turn vault notes into a polished article, or are expanding an idea surfaced by `blog-ideas`.
**How it works.** Loads the blog strategy, clarifies the topic, greps the vault for source material, studies published posts for voice, crystallizes a thesis, builds a listicle or deep-dive structure, writes the draft under strict voice rules (no em dashes, banned phrases, capped antithesis), runs a quality check, then saves the draft and archives any prior outline.
**Inputs.** A topic, title, or idea (asks if empty). Reads `Blog_Strategy.md` for voice/format/audience and `PUBLISHED/*.md` for voice matching, plus vault notes matched by topic keyword.
**Outputs.** A full draft with frontmatter, draft notes, tags, sources, and alternative titles, saved to `<vault>/2. Areas/Hackastak_Brand/Medium_Blog/[Topic_Name]_DRAFT.md`; any existing outline is moved to `<vault>/4. Archive/Blog_Outlines/`.
**Vault dependencies.** Assumes an Obsidian vault at `<vault>` (`~/Developer/My_Notes`) with the `Medium_Blog` brand folder holding `Blog_Strategy.md` and a `PUBLISHED/` subfolder, plus the PARA `1. Projects` / `2. Areas` / `3. Resources` / `4. Archive` structure for evidence and outline archiving.
**Related.** `blog-ideas` (feeds topics), `content` (pipeline tracking), `polish` (publish pass); mirrors the `/blog-draft` command.

### `blog-ideas`

**Purpose.** Generates blog post ideas for The HackaStak by mining the vault for actual expertise and filtering it through the blog strategy, five content pillars, and target audience.
**When to use.** Planning the content calendar, stuck on what to write next, or looking for topics where you have a unique, proven-performing angle.
**How it works.** Loads the strategy, inventories projects/areas/resources and recent notes, spots blog-worthy signals (hard-won lessons, contrarian takes, frameworks), cross-references existing published and draft posts to avoid repetition, scores each idea against fit/quality/winning-pattern criteria, then produces a ranked ideas report.
**Inputs.** No required argument. Reads `Blog_Strategy.md`, the vault's `1. Projects` / `2. Areas` / `3. Resources` trees and recent notes, and the `Medium_Blog` `PUBLISHED/` folder plus current drafts.
**Outputs.** A structured ideas report (Ready to Write, Needs Development, Contrarian Takes, Series Opportunities, Quick Hits, Next Steps) presented in-chat, not saved to a file by default.
**Vault dependencies.** Assumes `<vault>` (`~/Developer/My_Notes`) with the PARA structure and the `2. Areas/Hackastak_Brand/Medium_Blog` folder containing `Blog_Strategy.md` and `PUBLISHED/`.
**Related.** `blog-draft` (drafts a chosen idea), `content` (calendar/pipeline); mirrors the `/blog-ideas` command.

### `content`

**Purpose.** Manages The HackaStak content calendar and publishing pipeline, reporting buffer health and pillar balance and moving articles through the idea-to-published lifecycle via frontmatter.
**When to use.** Checking pipeline status and buffer health, deciding what to write or publish next, scheduling an article to a date, or marking one published and tracking cross-posts.
**How it works.** Scans all blog `.md` files and reads their frontmatter, routes on the input (`status`, `next`, `schedule`, `publish`, or an article name), then either generates a pipeline report or updates the target article's YAML status/date fields, preserving all other fields.
**Inputs.** One of `status`, `schedule [article] [date]`, `publish [article]`, `next`, or an article name. Reads `Blog_Strategy.md` and `Content_Calendar.md` for context.
**Outputs.** An in-chat pipeline status report (buffer health, pipeline tables, pillar balance, recommendations), and in-place frontmatter edits to article files in the `Medium_Blog` folder.
**Vault dependencies.** Assumes `<vault>/2. Areas/Hackastak_Brand/Medium_Blog` holding article `.md` files with status/pillar/date frontmatter, plus `Blog_Strategy.md` and a Dataview-powered `Content_Calendar.md`.
**Related.** `blog-ideas`, `blog-draft`, `polish`; the status progression it manages feeds the publish checklist in `polish`.

### `polish`

**Purpose.** Runs a voice, structure, and SEO audit on a written blog draft against The HackaStak style guidelines, applies fixes, and appends a pre-publish checklist with a suggested meta description.
**When to use.** A draft is written and you want it publication-ready, before scheduling, especially to enforce the no-em-dash, colon-restraint, and banned-phrase rules.
**How it works.** Loads the strategy, reads the full article, runs voice/structure/SEO audit tables plus the em-dash, colon, and antithesis rules, presents Must/Should/Optional findings, applies approved fixes with Edit, appends a pre-publish checklist, then saves and drops the `_DRAFT` suffix (rewiring any wikilinks that pointed at the draft name).
**Inputs.** An article filename or title (lists `ready`/`scheduled` articles if empty). Reads `Blog_Strategy.md` and the target article.
**Outputs.** A polish report, in-place fixes to the article, an appended pre-publish checklist, updated frontmatter, and a rename from `[Name]_DRAFT.md` to `[Name].md` in the `Medium_Blog` folder.
**Vault dependencies.** Assumes `<vault>/2. Areas/Hackastak_Brand/Medium_Blog` with `Blog_Strategy.md` and article `.md` files carrying status frontmatter; greps `<vault>` for wikilinks when renaming.
**Related.** `blog-draft` (produces the draft), `content` (scheduling after polish), the `writing-fragments`/`writing-beats`/`writing-shape` craft track (upstream drafting), `article-writing` (voice).

### `story-ideas`

**Purpose.** Generates ranked, documented story ideas for the "Stories You Won't Believe" TikTok channel: unbelievable-but-true historical events sourced from real accounts and filtered through the channel's pillars.
**When to use.** Planning the story calendar, the idea buffer is thin, you want a batch focused on a specific pillar, or you need to counterweight an over-used pillar (Survival tends to dominate).
**How it works.** Loads the pipeline strategy, inventories existing ideas and scripts to avoid duplicates and gauge pillar balance, generates at least 20 ideas ranked by viral potential (favoring documented sources and thin pillars per the 70/20/10 mix), then appends the batch under a dated heading.
**Inputs.** Optional pillar name or theme (empty = balanced, weighted to gaps). Reads `PIPELINE.md`, `IDEAS.md`, and the `SCRIPTS/` folder.
**Outputs.** New ranked ideas (hook, summary, pillar, why-people-watch, viral score) appended under a dated heading in `<vault>/1. Projects/Clipping/Unbelievable_Stories/IDEAS.md`, plus an in-chat summary.
**Vault dependencies.** Assumes `<vault>/1. Projects/Clipping/Unbelievable_Stories` containing `PIPELINE.md`, `IDEAS.md`, and a `SCRIPTS/` folder of scripts with pillar frontmatter.
**Related.** `story-script` (drafts an idea), `story-pipeline` (calendar); mirrors the `/story-ideas` command.

### `story-pipeline`

**Purpose.** Manages the "Stories You Won't Believe" TikTok content calendar, tracking buffer health, pillar balance, and scheduling to the Mon/Wed/Fri cadence via script frontmatter.
**When to use.** Checking pipeline status and buffer health, deciding what to write or post next, scheduling a ready script, marking one published, or auditing pillar balance.
**How it works.** Loads pipeline state from `PIPELINE.md` and each script's frontmatter, routes on the input (`status`, `next`, `schedule`, `publish`, or a script name), then generates a pipeline report or edits only the relevant YAML fields, suggesting the next open Mon/Wed/Fri slot when scheduling.
**Inputs.** Optional `status`, `next`, `schedule [script] [date]`, `publish [script]`, or a script name. Reads `PIPELINE.md` and all `SCRIPTS/*.md` frontmatter (status, pillar, scheduled, published, viral_score).
**Outputs.** An in-chat pipeline status report and in-place frontmatter updates to script files; buffer target is 5-6 ready/scheduled scripts.
**Vault dependencies.** Assumes `<vault>/1. Projects/Clipping/Unbelievable_Stories` with `PIPELINE.md`, a `SCRIPTS/` folder, and a Dataview `Content_Calendar.md`.
**Related.** `story-ideas` (fills the backlog), `story-script` (drafts scripts); mirrors the `/story-pipeline` command.

### `story-script`

**Purpose.** Drafts a publication-ready TikTok narration script for "Stories You Won't Believe," matching the owner's four canonical scripts for calm, documented, restrained tone and the channel's five-beat formula.
**When to use.** Turning an idea from `IDEAS.md` into a finished script, replenishing the ready buffer, or when you need a full narration with caption, on-screen text, and hashtags in the established voice.
**How it works.** Loads the strategy and source idea, reads all four canonical scripts as the gold-standard voice reference, confirms the event is documented history, writes a 60-90 second script on the five-beat formula (hook, setup, escalation, twist, payoff), produces the full output blocks, then saves and runs a six-point quality checklist to set `ready` or `scripted`.
**Inputs.** Optional idea title from `IDEAS.md`, a free-text topic, or a pillar/score to auto-pick (recommends the top unwritten idea if empty). Reads `PIPELINE.md`, `IDEAS.md`, the `SCRIPTS/` listing, and the four named canonical scripts.
**Outputs.** A complete script file (frontmatter plus CAPTION, SCRIPT, ON-SCREEN TEXT, THUMBNAIL TEXT, ENDING QUESTION) saved to `<vault>/1. Projects/Clipping/Unbelievable_Stories/SCRIPTS/[Descriptive_Title].md`.
**Vault dependencies.** Assumes `<vault>/1. Projects/Clipping/Unbelievable_Stories` with `PIPELINE.md`, `IDEAS.md`, and a `SCRIPTS/` folder holding the four canonical reference scripts (pinned by name, never to be overwritten).
**Related.** `story-ideas` (source ideas), `story-pipeline` (scheduling); mirrors the `/story-script` command.

### `writing-beats`

**Purpose.** The narrative exploit mode of the craft track: assembles a fixed pile of raw material into a journey of beats, grounding each concept before a beat leans on it, for pieces whose structure emerges as you walk it.
**When to use.** Narrative, personal-essay, or discovery-style pieces told rather than argued, where the shape is not known up front. For a thesis argued paragraph by paragraph, use `writing-shape`. Model-invocation is disabled, so it is user-invoked.
**How it works.** Establishes prerequisites (what the reader knows walking in), offers 2-3 candidate starting beats drawn from the pile, writes only the chosen beat to the article file, re-reads from disk, then loops offering reachable next beats (each noting what it grounds) until the journey reaches a natural end.
**Inputs.** A read-only markdown pile of raw material (typically from `writing-fragments`). The grounding rules come from the `writing-grounding` skill.
**Outputs.** An article built one beat at a time, written to `<vault>/2. Areas/Hackastak_Brand/Medium_Blog/<Title>.md` (or a user-named path).
**Vault dependencies.** Writes to the shared `Medium_Blog` folder under `<vault>` (`~/Developer/My_Notes`) by default; the raw material file may live anywhere and is read-only.
**Related.** `writing-grounding` (required shared reference), `writing-fragments` (produces the pile), `writing-shape` (argued mode), `polish` (publish pass).

### `writing-fragments`

**Purpose.** The pure explore mode of the craft track: mines raw fragments for a piece with no structure yet, widening the space of what could be written by running a relentless interview.
**When to use.** The user wants to gather material for something they are about to write, before committing to any structure. Model-invocation is disabled, so it is user-invoked (or via `/writing-fragments`).
**How it works.** Runs a `grill-me`-style interview aimed at producing material rather than a plan, capturing fragments (sharp sentences, vignettes, half-thoughts, quotes, and especially a load-bearing leading word) from both sides of the conversation, appending each silently to a single markdown file separated by horizontal rules.
**Inputs.** The conversation itself, captured from the initial prompt onward. No vault notes read; the interview discipline comes from `grill-me`.
**Outputs.** A heterogeneous fragments file with a single H1 working title, written to `<vault>/2. Areas/Hackastak_Brand/Medium_Blog/<Working_Title>_FRAGMENTS.md` (or a user-named path).
**Vault dependencies.** Writes to the shared `Medium_Blog` folder under `<vault>` (`~/Developer/My_Notes`) by default so the craft and brand tracks share one shelf.
**Related.** `writing-beats` / `writing-shape` (the two exploit modes it feeds), `grill-me` (interview engine), `blog-ideas` (decides what to write about, a different altitude).

### `writing-grounding`

**Purpose.** The shared grounding reference for the writing skills: every concept must be grounded before a move can lean on it, either as a prerequisite the reader brings or introduced by an earlier move.
**When to use.** Read by `writing-beats`, `writing-shape`, and `article-writing` before establishing prerequisites; it is a reference skill, not a standalone workflow. Model-invocation is disabled.
**How it works.** Defines the grounding rule and the two ways a concept gets grounded (prerequisite vs introduced), frames the piece as a dependency graph where each move both requires and grounds concepts, and explains how to apply it in each mode (journey of beats, argued structure, editing an existing article).
**Inputs.** None; it is a conceptual reference consumed by the other writing skills. Explicitly out of scope: voice, brand, SEO, formatting.
**Outputs.** None. It produces no file, it governs how the other skills order and sequence their moves.
**Vault dependencies.** None. It operates as shared guidance, not on any vault structure.
**Related.** `writing-beats` and `writing-shape` (both point at it), `article-writing` (editing mode), `polish` (handles the concerns grounding excludes).

### `writing-shape`

**Purpose.** The argued exploit mode of the craft track: shapes a fixed pile of raw material into an argued article block by block, with deliberate format choices, for technical or brand long-form that argues a thesis.
**When to use.** Technical or brand long-form where the piece argues a thesis paragraph by paragraph. For a piece that is walked rather than argued, use `writing-beats`. Model-invocation is disabled, so it is user-invoked.
**How it works.** Reads the pile end-to-end, establishes prerequisites, drafts 2-3 candidate openings each implying a different thesis, then grows the article block by block (asking what the reader needs next against the grounded set), arguing format choices out loud (prose vs list, inline vs callout, table, quote, code) and appending each agreed block immediately.
**Inputs.** A read-only markdown pile of raw material (fragments, prose, or a transcript, typically from `writing-fragments`). Grounding rules come from `writing-grounding`.
**Outputs.** An argued article built block by block, written to `<vault>/2. Areas/Hackastak_Brand/Medium_Blog/<Title>.md` (or a user-named path).
**Vault dependencies.** Writes to the shared `Medium_Blog` folder under `<vault>` (`~/Developer/My_Notes`) by default; the raw material file is read-only and may live anywhere.
**Related.** `writing-grounding` (required shared reference), `writing-fragments` (produces the pile), `writing-beats` (narrative mode), `article-writing` (voice pass, composable), `polish` (publish pass).

## Build, Debug & Merge

### `diagnosing-bugs`

**Purpose.** A disciplined six-phase diagnosis loop for hard bugs and performance regressions, built around constructing a tight, red-capable feedback signal before ever theorizing about causes. It exists to stop the classic failure of jumping straight to a hypothesis.
**When to use.** When the user says "diagnose" or "debug this", or reports something broken, throwing, failing, or slow.
**How it works.** Phase 1 builds a fast, deterministic, agent-runnable command that goes red on the exact symptom (test, curl, CLI diff, headless browser, trace replay, throwaway harness, fuzz/bisection/differential loop, or a HITL script); Phases 2-6 reproduce and minimise, generate 3-5 ranked falsifiable hypotheses, instrument one variable at a time with tagged `[DEBUG-...]` logs, write a regression test then fix, and finish with cleanup plus a post-mortem. It optionally reads `CONTEXT.md` and `docs/adr/` for context.
**Inputs.** The bug report; optional `CONTEXT.md` and `docs/adr/`; `scripts/hitl-loop.template.sh` for human-in-the-loop cases.
**Outputs.** A staged fix plus regression test (or a documented note that no correct test seam exists), the winning hypothesis recorded for the commit message, and all debug instrumentation removed. It never commits, it stages and hands back.
**Vault dependencies.** None, operates on the code repo / working tree.
**Related.** `codebase-design`, `improve-codebase-architecture`, `tdd-workflow`, `triage`, `draft-commit`.

### `draft-commit`

**Purpose.** Stages the relevant changes and drafts a tight, one-line conventional-commit message for the user to run themselves. It never commits, its only write action is `git add`.
**When to use.** When the user says "draft a commit", "stage and write a commit message", "prep a commit", invokes `/draft-commit`, or has working-tree changes to describe in house format.
**How it works.** Inspects the working tree (`git status --short`, `git diff`, `git diff --staged`), stages only the logically coherent set of changes with explicit paths (proposing a split when concerns are mixed), then drafts a `<type>: <imperative summary>` message. Format rules: aim for 72 characters or fewer, no scope (`type(scope):` is banned), no body or trailers unless asked, and no em dashes.
**Inputs.** The working-tree diff; the change-type table (`feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`, `build`).
**Outputs.** Staged paths plus a copy-paste-ready `git commit -m "..."` line presented for review. It stops without committing.
**Vault dependencies.** None, operates on the code repo / working tree.
**Related.** `diagnosing-bugs`, `resolving-merge-conflicts`, `git-guardrails`.

### `git-guardrails`

**Purpose.** Installs a Claude Code `PreToolUse` hook that blocks dangerous git commands before they run, enforcing the manual-git-control posture the rest of Staksmith assumes. It complements native `permissions.deny` by matching substrings rather than prefixes, so it catches variants buried in compound commands.
**When to use.** When the user wants to prevent destructive git operations or add git safety hooks.
**How it works.** Copies `scripts/block-dangerous-git.sh` (which reads the Bash tool's `command` via `jq`, greps a blocklist, and exits 2 with a BLOCKED message) into the project or global hooks dir, wires it into `settings.json` under `hooks.PreToolUse` (merging, never overwriting), then verifies by piping a dangerous and a safe command through it. Mode 1 is per-project or global opt-in, Mode 2 wires it into the plugin's own `hooks/hooks.json` for default-on coverage.
**Inputs.** Scope choice (project `.claude/settings.json` vs global `~/.claude/settings.json`); the default blocklist (`git push` including `--force`, `git reset --hard`, `git clean -f`/`-fd`, `git branch -D`, `git checkout .`/`git restore .`); requires `jq`.
**Outputs.** The installed hook script, a merged `settings.json` entry, and a verification result (exit 2 plus BLOCKED on stderr for dangerous commands, exit 0 for safe ones).
**Vault dependencies.** None, operates on the code repo / working tree and harness config.
**Related.** `update-config`, `draft-commit`, `resolving-merge-conflicts`.

### `resolving-merge-conflicts`

**Purpose.** Resolves an in-progress git merge or rebase conflict by reading the intent behind each side, resolving the hunks, running the project's checks, then handing back for the final commit. It resolves by default rather than aborting to dodge the work.
**When to use.** When a merge or rebase has stopped with conflicts.
**How it works.** Reads the current state (`git status`, `git log --oneline --left-right HEAD...MERGE_HEAD`, the conflicting files) and identifies which operation is in progress; traces each conflict back to its primary sources (commit messages, PRs, issues, and `CONTEXT.md`/`docs/adr/` if present); resolves each hunk preserving both intents without inventing new behaviour; discovers and runs the project's checks (typecheck, tests, format); then stages everything and summarises. It never commits and never runs `git rebase --continue`.
**Inputs.** The active merge/rebase state and conflicting files; commit/PR/issue history; optional `CONTEXT.md` and `docs/adr/`; the project's check scripts (`package.json`, `Makefile`, `justfile`, CI config).
**Outputs.** Resolved and staged files plus a summary of what conflicted, how each was resolved, trade-offs taken, and check results, with the exact next command (`git commit` or `git rebase --continue`) for the user to run.
**Vault dependencies.** None, operates on the code repo / working tree.
**Related.** `review-changes`, `draft-commit`, `git-guardrails`.

### `setup-pre-commit`

**Purpose.** Installs a durable in-repo commit-time quality gate: Husky runs lint-staged on staged files, then typecheck, then tests. Unlike an agent-side hook it belongs to the repo and binds every human and tool that commits.
**When to use.** When the user wants pre-commit hooks, Husky setup, lint-staged config, or commit-time formatting/typechecking/testing. Scoped to Node/JS-TS repos, it stops if there is no `package.json`.
**How it works.** Detects the package manager (Staksmith precedence: `CLAUDE_PACKAGE_MANAGER`, `.claude/package-manager.json`, `package.json` `packageManager`, lock-file, global preference, npm), detects the existing formatter (Biome, then Prettier, else Prettier as default), installs `husky` and `lint-staged` as devDependencies, runs `npx husky init`, and writes `.husky/pre-commit`, `.lintstagedrc`, and (only if no config existed) `.prettierrc`. Missing `typecheck`/`test` scripts are omitted from the hook rather than left to fail every commit.
**Inputs.** The repo's package manager and existing formatter config; existing `typecheck`/`test` scripts.
**Outputs.** `.husky/pre-commit`, `.lintstagedrc`, an optional `.prettierrc`, a `prepare: "husky"` script, and staged changes handed back with the message `chore: add pre-commit hooks (husky + lint-staged)`. It does not make the first commit.
**Vault dependencies.** None, operates on the code repo / working tree.
**Related.** `git-guardrails`, `setup-ts-deep-modules`, `review-changes`.


## Business & Research

### `money`

**Purpose.** A revenue advisor that mines the Obsidian vault for monetization opportunities, then deliberately goes beyond it to surface blind spots, market context, and positioning gaps the user cannot see from inside their own perspective. It diagnoses the revenue system first, then prescribes.
**When to use.** On `/money` (full) or `/money [domain]` (focused), when asking "how do I make more money from what I already have?", for a monthly/quarterly revenue review, or before a pricing change, launch, or new offering.
**How it works.** A nine-step pipeline: deep vault scan (orphans, deadends, unresolved links, tags, weekly notes, calendar), asset inventory, revenue diagnostics (attention-to-revenue CPM, revenue-type mix, sales system, pricing structure, product-vs-service ratio), beyond-the-vault analysis, ranked opportunities, temporal tracking of prior runs, anti-patterns, prioritization, and a closing list of artifacts to build now. Uses the Obsidian CLI when available, falling back to filesystem reads.
**Inputs.** `VAULT_PATH=~/Developer/My_Notes`; an optional domain argument to scope the analysis (e.g. `Hackastak_Brand`).
**Outputs.** A strategic revenue report ending with concrete buildable artifacts (rate cards, sponsorship decks, outreach templates, pitch docs, landing pages), then offers to build the chosen ones. This is the canonical source symlinked into the vault at `<vault>/.claude/skills/money/` (live command at `<vault>/.claude/commands/money.md`).
**Vault dependencies.** Reads the My_Notes vault broadly: `1. Projects/`, `2. Areas/` (especially `Hackastak_Brand/`), `4. Archive/`, `_Weekly/`, tags, backlinks, and the calendar.
**Related.** `product-ideas`, `package-product`, `product-pipeline`, `blog-ideas`, `blog-draft`.

### `product-ideas`

**Purpose.** Mines the Obsidian vault for sellable digital products (guides, templates, frameworks, skill bundles), evaluates market fit, recommends pricing, and identifies bundle opportunities.
**When to use.** On `/product-ideas`, when asking "what can I sell from my vault?", for monthly product discovery, or when planning the Gumroad launch calendar.
**How it works.** A multi-phase discovery: reads the Product Calendar to avoid duplicates, scans vault directories and the Staksmith skills folder for candidates, scores each on completeness/market-fit/effort, recommends pricing from fixed tiers, detects bundle groupings (topic, workflow, role, journey), and suggests supporting blog articles. Produces a structured report of quick wins, medium-effort, and long-term products with a 90-day revenue projection.
**Inputs.** `<vault>/2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md`; vault globs over `3. Resources/`, `2. Areas/`, `1. Projects/`, `_templates/`; `~/Developer/Staksmith/skills/*/SKILL.md`; built-in pricing tiers.
**Outputs.** A Markdown Product Ideas Report (executive summary, categorized products, bundle opportunities, blog article ideas, category balance, revenue projection, priority recommendations). It reports rather than writing files to the vault.
**Vault dependencies.** Reads the My_Notes vault: the Gumroad `Product_Calendar.md`, plus `3. Resources/`, `2. Areas/`, `1. Projects/`, and `_templates/`.
**Related.** `package-product`, `product-pipeline`, `blog-ideas`, `blog-draft`, `money`.

### `product-pipeline`

**Purpose.** Manages the Gumroad product pipeline: viewing status, recommending what to work on next, scheduling launches, and marking products published while tracking revenue toward a $500 MRR target.
**When to use.** On `/product-pipeline [status|next|schedule|publish]`, when asking "what should I work on next?" in a product context, or when scheduling a launch or tracking revenue.
**How it works.** `status` reads the Product Calendar, scans per-product `Product_Info.md` files, and computes buffer health, category balance, launch cadence, and revenue health. `next` runs a priority-score algorithm weighting value, urgency, and effort. `schedule` validates and sets `status: scheduled` plus `launch_date` in `Product_Info.md` and emits a pre-launch checklist. `publish` records the Gumroad URL and price, updates `Skills_Inventory.md` for skill products, and generates a post-launch report. Bundle-opportunity detection runs automatically during `status` and `next`.
**Inputs.** `<vault>/2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md`; per-product `Product_Info.md` (with fallbacks to `Gumroad_Listing_Instructions.md`/`Gumroad_Sales_Page.md`); `Skills_Inventory.md`; command args (product name, `YYYY-MM-DD`, gumroad-url, price).
**Outputs.** Status/recommendation/launch/post-launch Markdown reports, and updated `Product_Info.md` (and `Skills_Inventory.md`) frontmatter that flows into the calendar's Dataview queries. Revenue is tracked manually.
**Vault dependencies.** Reads and writes the My_Notes vault's `2. Areas/Hackastak_Brand/Gumroad/` tree: the Product Calendar, product directories, and Skills Inventory.
**Related.** `product-ideas`, `package-product`, `blog-draft`, `money`.

### `source-research`

**Purpose.** Investigates a question against high-trust primary sources (official docs, source code, specs, RFCs, first-party APIs) and captures the findings as a single cited Markdown file. It is delegated to a background agent so the caller keeps working.
**When to use.** When the user wants a technical topic researched, docs or API facts gathered, or reading legwork delegated.
**How it works.** Spins up a background agent whose brief carries the precise question, which sources count, the primary-source discipline verbatim, where the file goes, and what the answer is for. The agent follows every claim back to the source that owns it (marking untraceable claims unverified rather than asserting them), never answering from parametric knowledge, and writes one cited Markdown file. Output defaults to the repo (next to the code it describes), or the vault when the investigation is not tied to a codebase.
**Inputs.** The research question and its use; the relevant sources (project, docs site, repo, spec); the target output location and convention to match.
**Outputs.** A single Markdown file citing a source (URL, file path plus line, or spec section) for every claim, saved in the repo by default or in the vault otherwise.
**Vault dependencies.** Repo by default. Uses the vault only when the question is not tied to a codebase, writing to the matching `<vault>/1. Projects/<Project>/` folder, or `<vault>/3. Resources/` for reference material.
**Related.** `wayfinder`, `grill-with-docs`, `deep-research`, `documentation-lookup`, `search-first`.


## DevOps & Deployment

### `package-product`

**Purpose.** Automates the complete packaging workflow to get a digital product ready to sell on Gumroad, handling guides, templates, skills, frameworks, and bundles with type-appropriate documentation and listing copy.
**When to use.** On `/package-product [product-name]` (or `--type=[type]`), when asking to "package [product] for Gumroad", or after selecting products from a `/product-ideas` report.
**How it works.** Detects or asks the product type, auto-detects and validates the source (Staksmith skills dir, vault, or existing Gumroad folder), creates the product directory, prepares type-specific files (copying sources, generating HOW_TO_USE/README/IMPLEMENTATION_GUIDE/WORKFLOWS as appropriate), generates type-specific `Gumroad_Listing_Instructions.md`, and writes a `Product_Info.md` tracking file with `status: ready`. It respects existing work, never overwriting an existing PDF or completed file.
**Inputs.** Product name and optional `--type` (guide/template/skill/framework/bundle); sources from `~/Developer/Staksmith/skills/<name>/SKILL.md`, the vault, or `<vault>/2. Areas/Hackastak_Brand/Gumroad/<Product_Name>/`; built-in pricing tiers.
**Outputs.** A populated `<vault>/2. Areas/Hackastak_Brand/Gumroad/<Product_Name>/` directory (listing instructions, customer files, `Product_Info.md`) that surfaces in the calendar's Dataview queries. PDF generation and ZIP creation are noted as manual next steps.
**Vault dependencies.** Writes into the My_Notes vault's `2. Areas/Hackastak_Brand/Gumroad/` tree; may pull skill sources from `~/Developer/Staksmith/skills/`.
**Related.** `product-ideas`, `product-pipeline`, `blog-draft`, `money`.


## Language & Framework Patterns

### `setup-ts-deep-modules`

**Purpose.** Wires dependency-cruiser into a TypeScript package-structured repo so each package is a deep module: implementation hidden in subfolders, reachable only through its root-level entry-point files. It is the mechanical enforcement of the `codebase-design` vocabulary.
**When to use.** User-invoked (`disable-model-invocation: true`) on a TypeScript repo laid out as `src/packages/<name>/` or `packages/<name>/`. It stops on a single-package app that has no boundaries to guard.
**How it works.** Detects the package manager (Staksmith precedence) and packages root, installs `dependency-cruiser` as a devDependency, copies `dependency-cruiser.config.cjs` to the repo root as `.dependency-cruiser.cjs` (setting `PACKAGES_ROOT`), adds a `lint:boundaries` script folded into the repo's umbrella check, scaffolds an `example/` package, then proves the four `error` rules bite by observing pass then fail-on-deep-import then pass. Finally it documents the convention in a packages-folder `README.md` and appends a one-line context pointer to `CLAUDE.md`/`AGENTS.md`.
**Inputs.** Package manager and packages-root detection; existing `.dependency-cruiser.*` (merged, not overwritten); the bundled `dependency-cruiser.config.cjs` (four forbidden rules: entry-point boundary, intra-package freedom, tests-through-entry-points, no cycles, plus a commented layering stub).
**Outputs.** `.dependency-cruiser.cjs`, a `lint:boundaries` script, a committed `example/` template package, `<packages-root>/README.md`, and a one-line pointer in the repo's agent-instructions file. It stages everything and hands back, no auto-commit.
**Vault dependencies.** None, operates on the code repo / working tree.
**Related.** `codebase-design`, `setup-pre-commit`, `improve-codebase-architecture`.

---

## Keeping this current

- This file is hand-maintained. [`SKILLS.md`](SKILLS.md) is regenerated from frontmatter (`node scripts/ci/skills-catalog.js`); this one is not.
- When you add, rename, or materially change a custom skill, update its entry here (and regenerate `SKILLS.md`).
- See [`CONTRIBUTING.md`](CONTRIBUTING.md) for skill format and repo conventions.
