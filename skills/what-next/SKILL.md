---
name: what-next
description: Read a project's open backlog and status from Notion, prioritize the open tasks, and hand back the top 3 next tasks.
category: "Second Brain & Vault"
origin: Hackastak
disable-model-invocation: true
argument-hint: "A project name, or nothing to infer it from the current directory"
---

# What Next

Answer one question for one project: **what should I work on next?**

Open implementation tasks live in Notion, not in Obsidian checklists. This skill finds that project's task database and its project-status row, ranks the genuinely open tasks, and returns three tasks you can start today.

## Scope

Reading and ranking. The skill produces a priority map and a top 3.

- It **never** does the work described by a task.
- It **never** writes code, and it reads code repos only as evidence of what is in flight.
- It **never** invents tasks that are not already in Notion.
- It **never** writes to Notion or to the vault. It does not change Status, reorder rows, check items off, or create tasks.
- It does **not** read Obsidian `Backlog.md`, `*_Todos.md`, or `Master_Task_List.md`. Those notes are not the backlog anymore. Obsidian still holds everything else (notes, decisions, weekly logs). Read a vault note only to disambiguate a task that is already in Notion, and never treat that note as a second task list.

Nothing gets written without a later, explicit skill that is allowed to write. This one is not that skill.

## Relationship to `backlog-review`

`backlog-review` reconciles the same Notion backlog, but it is the **writer**: it verifies suspected-done tasks against evidence and marks the confirmed ones `Done`. This skill never writes. If git evidence says a Notion task already shipped, list it under "possibly already done," leave its Status alone, and point the user at `backlog-review` to close it.

## Where tasks and status live

Use the Notion MCP (`notion-search`, `notion-fetch`, `notion-query-data-sources`). Harnesses may prefix those names.

**Project status** is a row in **Top Level Epics**:

- Database: https://app.notion.com/p/40b039c0d2be801d8e0bd0f8ff3b4380
- Data source: `collection://40b039c0-d2be-8065-896c-000b4596755b`
- Title property: `Task name`. Status: `Not started`, `In progress`, `Done`. Also `Description` and `Due date`.

**Implementation tasks** are one database per project, not one global backlog. Titles look like `<Project> Tasks` or `<Project> Task Tracker`. Fetch the database, then query its `collection://` data source. Do not hardcode a closed list. Examples that exist today:

- Hackatrak: https://app.notion.com/p/fa02ab0f67884615bbd77b58f0e18911 (`collection://493593d4-0c58-455c-85d1-6a510b141da2`)
- Vault Upgrade Task Tracker: https://app.notion.com/p/e9afce8203124609a3a619342d0b321f
- MORE SEO Task Tracker: https://app.notion.com/p/e4b6009551324232b1cd98709da3033e

Typical task properties: `Task name`, `Status` (`Not started`, `In progress`, `Done`, sometimes `Archived`), `Phase` (select; this is the old section heading), `Due`, `Completed`, `Assignee`. Read the schema on the database you actually fetched. Property names can differ. Page body is detail, often including the old Obsidian import note. It is not a separate task.

**Do not use My Tasks** (https://app.notion.com/p/8e320dd3a31947919c03cdd4bc0d8335) as a project backlog. It is an assignee rollup.

## Instructions

### Step 1: Resolve the project

If the user passed a project name, use it. Otherwise infer one from the current directory (`basename "$PWD"`, or the git remote's repo name) and **state the inferred name before continuing**.

Then find both sources:

1. Search Notion for a **database** whose title contains the project name and `Tasks`, `Task Tracker`, or `Backlog`. Case-insensitive. `repog` may match `RepoG Tasks`.
2. Query Top Level Epics for a row whose `Task name` contains the project name.

```sql
SELECT "Task name", "Status", "Description", "date:Due date:start", url
FROM "collection://40b039c0-d2be-8065-896c-000b4596755b"
```

If the known data source URL fails, search for a database titled `Top Level Epics` and fetch it before querying.

**Completion criterion:** you have told the user which task database you will rank, and which epic row (or that none matched). If several task databases tie, ask. If the epic Status is `Done`, say so and wait before ranking. If there is no task database, stop. Do not fall back to Obsidian checklists.

### Step 2: Index every open task

Fetch the task database so you have its data source URL and schema. Query open rows. Paginate until `has_more` is false.

Open means Status is not in the schema's complete group, and is not `Archived`. `In progress` is open. If the schema uses different option names, trust the status groups, not this paragraph.

```sql
SELECT "Task name", "Status", "Phase", "date:Due:start", url, createdTime
FROM "collection://<task-data-source>"
WHERE "Status" NOT IN ('Done', 'Archived')
```

Adjust column names to the fetched schema. Date columns are `date:<Name>:start`, not the property name.

For every open row record: URL, title, status, phase, due date, and created time. Phase carries most of the priority signal, so never drop it.

Fetch a page body only when the title is too thin to rank, or when you need acceptance detail for an item you are about to put in Now or Next. Do not fetch every body on a large tracker.

**Completion criterion:** every open row in that database is accounted for. Report the count, and the count per Phase, before moving on.

### Step 3: Gather priority signal

Cheap, read-only context that changes the ranking:

- **Notion markers.** `In progress` outranks `Not started` when nothing else differs. `Phase` order, names like `Tier 0` or `TAKES PRIORITY` in the title, phase, or body, and `Due` dates are explicit user signal. An explicit marker outranks anything you infer.
- **Project status.** An `In progress` epic means this project is already the active bet. A `Not started` epic is not a reason to skip the backlog, but say so.
- **Dependencies.** Tasks whose text names another task, a phase gate, or an external unblock.
- **Momentum.** `git -C <repo> log --oneline -n 20` and `git -C <repo> status --short`. Resolve the repo by matching the project name under `~/Developer`. If there is no local clone, skip this signal. Do not clone.
- **Staleness.** `createdTime` and how long a `Not started` task has sat there. Stale is a reason to question it, not to delete it.

**Completion criterion:** each open task has at least one recorded signal, or is explicitly marked "no signal."

### Step 4: Build the priority map

Sort every open task into one of four bands:

| Band | Meaning |
|------|---------|
| **Now** | Blocks other work, is explicitly marked top priority, is `In progress`, or has a live deadline |
| **Next** | Clear value, unblocked, ready once Now is clear |
| **Later** | Real but not urgent, or waiting on something outside the project |
| **Icebox** | Speculative, superseded, or stale enough to question whether it still applies |

Within a band, order by these tiebreakers in sequence:

1. **Unblocks the most other tasks.**
2. **Explicit user marker** (`Tier 0`, `TAKES PRIORITY`, a phase the user already called current).
3. **Deadline proximity.**
4. **Momentum.** `In progress`, or touched in recent commits. Finishing beats starting.
5. **Payoff per unit of effort.**

Two rules:

- **Every open task lands in exactly one band.** If something is unrankable, put it in Icebox with the reason.
- **Flag suspected-done tasks rather than ranking them.** If commits say it shipped, list it separately. Do not change its Notion Status.

### Step 5: Deliver the map and the top 3

Do not ask for approval. Show the map and the top 3 in the same reply.

```
## What Next — <Project>

Project status: <epic status> — "<epic name>" (<epic url>)
  or: no Top Level Epic matched

Indexed N open tasks in <database title> (<database url>):
  - <Phase> (N)
  - <Phase> (N)

### Now
1. "<task name>" — <one-line why> [<url>]
2. ...

### Next
...

### Later
...

### Icebox
...

Possibly already done (left open in Notion; this skill does not close them):
- "<task name>" — <what suggests it shipped>

## Top 3

1. **<task name>**
   Why now: <the signal that put it here>
   First move: <the concrete first action>
   Lives in: <url>

2. ...

3. ...
```

**When the index runs large** (past roughly 40 tasks), do not print every task. Show **Now and Next in full**, then summarize Later and Icebox by count and Phase. Say the full list is available on request. The top 3 is never summarized away.

The top 3 comes from the top of the map you just built. Each entry needs a **first move** specific enough to start without re-reading the tracker: a file to open, a command to run, a decision to make. "Work on auth" is a failure. "Add the session-refresh branch in `middleware.ts`" is the bar. Use the page body, or a quick read of the named repo, to make the first move concrete. Do not widen that read into doing the task.

If fewer than three tasks are genuinely actionable, return fewer and say why.

If the user later moves a task between bands, rebuild the map and the top 3. Do not write that change back to Notion. Do not wait for that correction before delivering the first top 3.

**Completion criterion:** the user has the map and the top 3, with no approval step in between.

## Examples

### Example 1: Task database and epic both match

```
User: /what-next hackatrak

→ Task database: Hackatrak Tasks
→ Epic: "Finish the Hackatrak work tracker" is In progress
→ Indexed 40 open tasks.
→ Map and top 3 delivered in one reply. Notion unchanged.
```

### Example 2: No project name given

```
User: /what-next   (cwd: ~/Developer/kithrow)

→ "Inferring project Kithrow from the current directory."
→ No Notion task database matches. Stopping.
→ Not reading Obsidian Dev_Todos.md.
```

### Example 3: Looks shipped

```
→ 6 open tasks name work that appears in recent commits
→ Listed under "possibly already done." Status left as-is.
→ Ranked the rest.
```

## Notes

- Read-only. Deliver the map and the top 3 together. Do not stop to ask if the ranking is right.
- Prefer honest uncertainty over invented confidence: "no signal on this one" is a valid entry.
- If Notion search and the epic row disagree about which project this is, ask. Do not merge two projects into one top 3.
