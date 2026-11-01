---
name: backlog-review
description: Review a project's open backlog tasks in Notion, verify whether each open item is actually already done using evidence from the associated code repos and vault notes, and mark the confirmed ones Done in Notion. Review only — never writes code or does the work. Reads the Obsidian vault for evidence, not as the task list. Use to reconcile a stale Notion backlog with reality.
category: "Code Review & Quality"
origin: Hackastak
---

# Backlog Review

Reconcile a project's Notion backlog with reality. Open tasks go stale: work gets shipped in the code repo but the task's Status never moves off `In progress` or `Not started`. This skill finds open backlog tasks in Notion, checks whether each one is *actually already complete* using evidence, and marks the confirmed ones `Done`.

Open implementation tasks live in **Notion**, not in Obsidian checklists. Obsidian still holds everything else (project notes, decisions, weekly logs, CHANGELOGs), and this skill reads those as *evidence* — never as a second task list.

## Scope (read this first)

This skill is **review only**. Its job is to check status and update task Status in Notion, nothing more.

- It **never** writes, edits, runs, builds, or refactors code.
- It **never** does the work described by a backlog task, or partially completes it.
- It **only** reads code repos (git log, file listings, grep, CHANGELOG) and vault notes as *evidence*.
- The **only** write action it performs is marking a confirmed-complete Notion task `Done` (plus a dated evidence note). It never edits the vault, and it never creates, reorders, or deletes Notion tasks.

If a task is not done, it stays open. This skill does not create work; it closes the gap between what shipped and what the backlog says.

## When to Activate

- a Notion backlog feels stale and you want it reconciled against what actually shipped
- after a stretch of dev work, to sweep up tasks that are done but never moved to `Done`
- before planning, to get an accurate picture of what is genuinely still open
- auditing a single project's backlog

## Relationship to `what-next`

`what-next` is read-only: it ranks the open Notion tasks and hands back a top 3, and it lists suspected-done tasks under "possibly already done" without touching them. **This skill is the writer that closes those confirmed-done tasks.** When `what-next` flags something as probably shipped, run `backlog-review` to verify and mark it.

## Configuration

```
VAULT_PATH=~/Developer/My_Notes      # evidence only (decisions, weekly notes, CHANGELOGs)
CODE_REPOS_ROOT=~/Developer          # evidence only (git log, files)
```

Input: a **project name** to focus on (e.g. `repog`, `RepoG`), matched case-insensitively. **If no project name is given, ask which project to review before doing anything else** — do not default to reviewing everything.

## Where tasks and status live

Use the Notion MCP. Reading: `notion-search`, `notion-fetch`, `notion-query-data-sources`. Writing: the page-update tool (e.g. `notion-update-page`), used only in Step 6. Harnesses may prefix these names.

**Project status** is a row in **Top Level Epics**:

- Database: https://app.notion.com/p/40b039c0d2be801d8e0bd0f8ff3b4380
- Data source: `collection://40b039c0-d2be-8065-896c-000b4596755b`
- Title property: `Task name`. Status: `Not started`, `In progress`, `Done`. Also `Description` and `Due date`.

**Implementation tasks** are one database per project, not one global backlog. Titles look like `<Project> Tasks` or `<Project> Task Tracker`. Fetch the database, then query its `collection://` data source. Do not hardcode a closed list. Examples that exist today:

- Hackatrak: https://app.notion.com/p/fa02ab0f67884615bbd77b58f0e18911 (`collection://493593d4-0c58-455c-85d1-6a510b141da2`)
- Vault Upgrade Task Tracker: https://app.notion.com/p/e9afce8203124609a3a619342d0b321f
- MORE SEO Task Tracker: https://app.notion.com/p/e4b6009551324232b1cd98709da3033e

Typical task properties: `Task name`, `Status` (`Not started`, `In progress`, `Done`, sometimes `Archived`), `Phase` (select; this is the old section heading), `Due`, `Completed`, `Assignee`. Read the schema on the database you actually fetched. Property names can differ. The page body is detail, often including the old Obsidian import note. It is not a separate task.

**Do not use My Tasks** (https://app.notion.com/p/8e320dd3a31947919c03cdd4bc0d8335) as a project backlog. It is an assignee rollup.

## Instructions

### Step 1: Resolve the project and locate its task database

**If the user passed no project name, stop and ask which project to review.** Do not proceed until you have a project name. Do not silently fall back to reviewing every database.

With a project name:

1. Search Notion for a **database** whose title contains the project name and `Tasks`, `Task Tracker`, or `Backlog`. Case-insensitive (`repog` may match `RepoG Tasks`).
2. Query Top Level Epics for the project's status row, for context:

```sql
SELECT "Task name", "Status", "Description", "date:Due date:start", url
FROM "collection://40b039c0-d2be-8065-896c-000b4596755b"
```

If the known data source URL fails, search for a database titled `Top Level Epics` and fetch it before querying.

**Completion criterion:** you have told the user which task database you will review. If several task databases tie, ask. If there is no task database for the project, stop and say so. Do not fall back to Obsidian checklists.

### Step 2: Index the open tasks

Fetch the task database so you have its data source URL and schema. Query open rows and paginate until `has_more` is false.

Open means Status is not in the schema's complete group, and is not `Archived`. `In progress` is open. If the schema uses different option names, trust the status groups, not this paragraph.

```sql
SELECT "Task name", "Status", "Phase", "date:Due:start", url, createdTime
FROM "collection://<task-data-source>"
WHERE "Status" NOT IN ('Done', 'Archived')
```

Adjust column names to the fetched schema. Date columns are `date:<Name>:start`, not the property name.

For each open row keep: URL (needed to update it later), title, status, phase, due date, and any indented acceptance detail in the page body. Fetch a page body when the title is too thin to judge completion, or when you need the acceptance criteria to decide whether all of a task shipped.

Report the count of open tasks (and the count per Phase) before moving on.

### Step 3: Identify the evidence sources

For the project, determine what to check the open tasks against:

- **The code repo.** Resolve a local path under `~/Developer` by matching the project name. The epic `Description` or the task database may name the repo explicitly; prefer that. For a repo with no local clone, note it and fall back to vault-only evidence — do **not** clone.
- **Vault notes.** Read (never modify) the project's folder under `1. Projects/<Project>/`: CHANGELOGs, `Dev_Notes`, weekly notes (`_Weekly/`), and decision logs can all record that something shipped. These are evidence, not a task list.

### Step 4: Verify each open task (evidence only — no work)

For each open task, gather evidence that it is *already* complete. Use read-only inspection:

```bash
# Example evidence gathering against a resolved local repo (READ ONLY)
git -C <repo> log --oneline -n 40
git -C <repo> log --oneline --all --grep "<keywords from the task>"
git -C <repo> log -n 1 --format="%ci" -- <relevant/path>   # was the file touched?
```

Also read CHANGELOGs, README sections, and relevant source files to confirm a feature or fix exists. Cross-reference vault notes with Grep.

Then classify the task into exactly one of:

- **Complete** — clear evidence all of it (including acceptance criteria in the body) shipped. Note the specific evidence (commit, file, changelog line, note).
- **Partially complete** — some of it done, the rest not. Stays open; summarize what remains.
- **Not complete** — no evidence it shipped. Stays open.
- **Cannot verify** — no local repo / not checkable from available evidence. Stays open; say why.

Be conservative. Only "Complete" is eligible to be marked `Done`. When evidence is thin or ambiguous, classify as "Cannot verify," not "Complete."

### Step 5: Present findings and confirm

Before writing anything to Notion, show the user a report:

```
## Backlog Review — <Project>

Task database: <database title> (<database url>)
Open tasks reviewed: N

✅ Complete (will mark Done in Notion):
- "<task name>" — <evidence: commit hash / file / changelog line> [<url>]

🟡 Partially complete (left open):
- "<task name>" — done: <...>; remaining: <...> [<url>]

⬜ Not complete (left open):
- "<task name>" [<url>]

❔ Cannot verify (left open):
- "<task name>" — <why> [<url>]

Summary: X tasks confirmed complete, ready to mark Done.
```

Ask the user to confirm before marking, unless they already said to mark automatically.

### Step 6: Mark the confirmed tasks in Notion

For each **Complete** task, and only those, update the Notion page via the page-update tool:

- Set `Status` to `Done`.
- If the schema has a `Completed` date property, set it to today.
- Append a dated evidence line to the page body in the house style: `✅ YYYY-MM-DD — <one-line evidence>` (use today's date, 2026-11-01 format). One line, naming the commit / file / note that confirmed it.

Never change `Status` on any task that is not "Complete." Never create, reorder, archive, or delete tasks. Never edit the vault.

### Step 7: Final summary

Report what changed: which tasks were marked `Done` (with their Notion URLs), and a reminder of what is genuinely still open (the partial / not-complete / cannot-verify counts). This is the accurate backlog picture for planning.

## Notes

- Read-only toward all code and the vault. The one and only write action is setting confirmed-complete Notion tasks to `Done` (plus the dated evidence note).
- Prefer precision over recall: a false `Done` hides real work. When in doubt, leave it open.
- In any evidence note you write (into Notion or elsewhere), avoid em dashes (use a comma plus a conjunction, a colon, or split the sentence) to match the user's writing preference.
- Resolve open tasks by their Notion page URL; never guess a page id. Exclude `.obsidian/` and image files from vault searches.
- A repo with no local clone is a legitimate "Cannot verify" — never clone repos to check them.
