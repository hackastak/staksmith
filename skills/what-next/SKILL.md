---
name: what-next
description: Index a project's open todos from the Obsidian vault, prioritize them, and hand back the top 3 next tasks.
origin: Hackastak
disable-model-invocation: true
argument-hint: "A project name, or nothing to infer it from the current directory"
---

# What Next

Answer one question for one project: **what should I work on next?**

Open todos for a project are scattered across several notes and written in the order they were thought of, not the order they should be done. This skill gathers every open item, ranks them against a fixed model, and returns three tasks you can start today.

## Scope

Reading and ranking. The skill produces a priority map and a top 3.

- It **never** does the work described by a todo.
- It **never** writes code, and it reads code repos only as evidence of what is in flight.
- It **never** invents todos that are not already written down somewhere.
- Rewriting a vault note into priority order is **not** the default. It happens only when the user asks for it and approves it, per Step 6.

Nothing gets written to the vault without an explicit yes.

## Relationship to `backlog-review`

`backlog-review` asks *"is this item secretly already done?"* and checks off the ones that shipped. `what-next` asks *"of what is genuinely open, what matters most?"*

They chain: reconcile first, then rank. If Step 2 turns up items that look shipped but are still open, say so and offer `/backlog-review` rather than ranking stale work to the top.

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
PROJECTS_DIR=1. Projects
CODE_REPOS_ROOT=~/Developer
```

## Where Todos Live in This Vault

There is no single backlog convention. Expect several sources per project:

- **`Backlog.md`** — the richest form (RepoG, Citera). Sectioned by phase or tier, often with an explicit priority header like `## Reviewer-Readiness Pass — TIME-BOXED, TAKES PRIORITY` and a `## Done ✅` section at the bottom.
- **`*_Todos.md`** — `Dev_Todos.md` (Kithrow), `Software_Dev_Todos.md` and `Branding_&_Design_Todos.md` (Artemist). Often more than one per project, split by discipline.
- **`*Backlog*.md` variants** — `SRI_POC_Backlog.md`, `SRI_Sprint_Backlog.md` (SRI_Agent).
- **`TaskLists/` subfolders** — Artemist keeps a folder of them.
- **A todos section inside another note** — a `## Todo` / `## Next Steps` / `## Open Questions` heading inside `Dev_Notes.md`, `PRD.md`, or `Open_Questions.md`.
- **`0.1 Tasks_List/Master_Task_List.md`** — the cross-project list. Check it for items tagged to this project.

Task lines are `- [ ]` open and `- [x]` done. Indented sub-bullets under a task are its acceptance criteria: the parent is not done until they are.

## Instructions

### Step 1: Resolve the project

If the user passed a project name, use it. Otherwise infer one from the current directory (`basename "$PWD"`, or the git remote's repo name) and **state the inferred name before continuing** so a wrong guess is caught early.

Resolve it to a folder under `1. Projects/`, matched case-insensitively since the argument rarely matches the folder casing (`repog` → `RepoG`):

```bash
cd ~/Developer/My_Notes
proj=$(find "1. Projects" -maxdepth 1 -type d -iname "<name>" | head -1)
```

If nothing matches exactly, try a partial match (`-iname "*<name>*"`), then widen to the rest of the vault:

```bash
find "2. Areas" "3. Resources" "4. Archive" "0. Inbox" -maxdepth 2 -type d -iname "*<name>*"
grep -ril "<name>" --include="*.md" . | grep -v ".obsidian" | head -20
```

If the project sits in `4. Archive/`, say so before ranking anything: archived work usually should not get a top 3 without a word from the user.

**Completion criterion:** you can name one folder (or one explicit set of notes) as the project's home, and you have told the user which one. If several plausible candidates tie, ask rather than picking.

### Step 2: Index every open todo

Sweep the project folder for todo-bearing notes, then read them:

```bash
find "$proj" \( -iname "*backlog*.md" -o -iname "*todo*.md" -o -iname "*task*.md" \) | sort
grep -rln "^\s*- \[ \]" "$proj" --include="*.md"
grep -n "<ProjectName>" "0.1 Tasks_List/Master_Task_List.md"
```

The second command is the one that catches todos buried in `Dev_Notes.md` or `PRD.md`. Run it even when a `Backlog.md` exists.

For every open item record: source file, line number, task text, sub-items, and the heading it sits under. The heading carries most of the priority signal, so never drop it.

Skip `.obsidian/`, `.bak` files, and anything already `- [x]` or sitting under a `## Done ✅` heading.

**Completion criterion:** every note in the project folder containing `- [ ]` has been read, and each open item is accounted for with its source location. Report the counts per file before moving on.

### Step 3: Gather priority signal

Cheap, read-only context that changes the ranking:

- **In-note markers** — `TAKES PRIORITY`, `Tier 0`, `P0`, `TIME-BOXED`, `Phase N`, `blocked by`, dates, and the note's own section ordering. An explicit marker written by the user outranks anything you infer.
- **Dependencies** — items whose text names another item, a phase gate, or an external unblock.
- **Momentum** — what is already in flight. `git -C <repo> log --oneline -n 20` and `git -C <repo> status --short` show what was touched recently. Resolve the repo from the backlog's `Repo:` reference or by matching the project name under `~/Developer`. If there is no local clone, skip this signal, do not clone.
- **Dates** — deadlines in the note, and how stale the file is (`git log -1 --format=%cr` on the vault, or the file mtime).

**Completion criterion:** each open item has at least one recorded signal, or is explicitly marked "no signal."

### Step 4: Build the priority map

Sort every open item into one of four bands:

| Band | Meaning |
|------|---------|
| **Now** | Blocks other work, is explicitly marked top priority, or has a live deadline |
| **Next** | Clear value, unblocked, ready to pick up once Now is clear |
| **Later** | Real but not urgent, or waiting on something outside the project |
| **Icebox** | Speculative, superseded, or stale enough to question whether it still applies |

Within a band, order by these tiebreakers in sequence:

1. **Unblocks the most other items** — a task three others wait on beats a bigger task nobody waits on.
2. **Explicit user marker** — `Tier 0`, `TAKES PRIORITY`, and the like.
3. **Deadline proximity.**
4. **Momentum** — already partially done or touched in recent commits. Finishing beats starting.
5. **Payoff per unit of effort** — cheap and valuable before expensive and valuable.

Two rules that keep this honest:

- **Every open item lands in exactly one band.** No item is silently dropped. If something is unrankable, put it in Icebox with the reason.
- **Flag suspected-done items rather than ranking them.** If evidence says an item already shipped, list it separately and point at `/backlog-review`.

### Step 5: Present the map and get approval

Show the map before doing anything else with it:

```
## What Next — <Project>

Indexed N open items across M notes:
  - <path> (N items)
  - <path> (N items)

### Now
1. "<task text>" — <one-line why> [<file>:<line>]
2. ...

### Next
...

### Later
...

### Icebox
...

⚠️ Possibly already done (verify with /backlog-review):
- "<task text>" — <what suggests it shipped>
```

**When the index runs large** (past roughly 40 items, and Kithrow's `Dev_Todos.md` alone carries 213), do not print every item. Show **Now and Next in full**, then summarize Later and Icebox by count and by the section they came from:

```
### Later (34)
  - Phase 3 — Billing (11 items)
  - Deferred polish (23 items)

### Icebox (9) — superseded by the v2 rewrite
```

Every item is still banded, only the printing is condensed. Say the full list is available on request.

Then ask the user to approve or adjust the mapping. Do not proceed to the top 3 on an unapproved map: the whole point is that the ranking matches their judgment, not yours.

If they move items between bands, apply the change and re-show the affected bands.

**Completion criterion:** the user has said the map is right, or has corrected it and you have applied the corrections.

### Step 6: Offer the rewrite (only if asked)

A rewrite reorders a vault note to match the approved map. **It is opt-in and it is not the default.** Do not offer it unprompted more than once, and never perform it without a yes.

If the user wants it, state exactly what will change before touching the file: which file, which section, and that the order changes while the text does not. Then:

- Preserve every open item **verbatim**, including sub-items. Reordering only.
- Never delete an item, never merge two items, never reword one, never add one.
- Leave `## Done ✅` sections and completed items exactly where they are.
- Add band headings (`### Now`, `### Next`, …) only if the note has no competing section structure. When it already has meaningful sections (phases, tiers), reorder **within** them and leave the structure alone.
- Avoid em dashes in anything written into the vault: use a comma plus a conjunction, a colon, or two sentences.

**Completion criterion:** the count of `- [ ]` lines in the file is identical before and after. Verify it and say so.

### Step 7: Deliver the top 3

The deliverable. Three tasks, drawn from the top of the approved map:

```
## Top 3

1. **<task text>**
   Why now: <the signal that put it here>
   First move: <the concrete first action>
   Lives in: <file>:<line>

2. ...

3. ...
```

Each entry needs a **first move** that is specific enough to start on without re-reading the backlog: a file to open, a command to run, a decision to make. "Work on auth" is a failure; "add the session-refresh branch to `middleware.ts:40`" is the bar.

If fewer than three items are genuinely actionable, return fewer and say why. Three padded suggestions are worse than one real one.

## Examples

### Example 1: Minimal happy path

```
User: /what-next repog

→ Resolved to 1. Projects/RepoG/
→ Indexed 23 open items across Backlog.md (19) and Future_Features.md (4)
→ Map presented: Now (3), Next (7), Later (9), Icebox (4)
User: looks right
→ Top 3 delivered, no files written
```

### Example 2: No project name given

```
User: /what-next   (cwd: ~/Developer/kithrow)

→ "Inferring project Kithrow from the current directory."
→ 1. Projects/Kithrow/ has no Backlog.md; found Dev_Todos.md and a
  ## Open Questions section in Open_Questions.md
→ Both indexed, ranked together
```

The lesson: the absence of `Backlog.md` is normal and is not a dead end. Grep for `- [ ]` across the whole folder.

### Example 3: The map is wrong

```
User: move the Homebrew formula item to Now, it's blocking the release
→ Moved. Re-shown: Now is now 4 items, formula item first
  (unblocks 3 others, beating the Tier 0 marker on the previous top item)
→ Top 3 rebuilt from the corrected map
```

Never argue the user out of a band change. Their context beats the signal in the file.

### Example 4: Stale backlog

```
→ 6 of 14 open items name features that appear in recent commits
→ "Six items look like they may already be done. Ranking these would put
  finished work at the top. Run /backlog-review first?"
```

Flag and stop. Do not verify done-ness item by item here, that is `backlog-review`'s job.

## Notes

- Read-only by default. The single possible write is the Step 6 rewrite, and only after an explicit yes.
- The map is a proposal, not a verdict. The user's correction in Step 5 is the real ranking.
- Prefer honest uncertainty over invented confidence: "no signal on this one" is a valid entry.
- Exclude `.obsidian/`, `.bak` files, and images from every search.
