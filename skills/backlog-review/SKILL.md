---
name: backlog-review
description: Review backlog and todo notes across the Obsidian vault, verify whether open items are actually already done using evidence from the associated code repos and other notes, and mark the confirmed ones complete. Review only — never writes code or does the work. Use to reconcile stale backlogs with reality.
category: "Code Review & Quality"
origin: Hackastak
---

# Backlog Review

Reconcile the vault's backlog and todo notes with reality. Open items go stale: work gets shipped in the code repo but the checkbox never gets flipped. This skill finds open backlog items, checks whether each one is *actually already complete* using evidence, and marks the confirmed ones done.

## Scope (read this first)

This skill is **review only**. Its job is to check status and update checkboxes, nothing more.

- It **never** writes, edits, runs, builds, or refactors code.
- It **never** does the work described by a backlog item, or partially completes it.
- It **only** reads code repos (git log, file listings, grep, CHANGELOG) as *evidence*.
- The **only** files it edits are vault backlog/todo markdown notes, and only to flip a completed item's checkbox and add a dated evidence note.

If an item is not done, it stays open. This skill does not create work; it closes the gap between what shipped and what the backlog says.

## When to Activate

- a backlog feels stale and you want it reconciled against what actually shipped
- after a stretch of dev work, to sweep up items that are done but never checked off
- before planning, to get an accurate picture of what is genuinely still open
- auditing a single project's backlog, or all of them at once

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
CODE_REPOS_ROOT=~/Developer
```

Input: a **project name** to focus on (e.g. `repog`, `RepoG`). A project name resolves to the folder `1. Projects/<ProjectName>/` under the vault, matched case-insensitively. You may also pass a full backlog file path. **If no project name is given, ask which project to review before doing anything else** — do not default to reviewing the whole vault.

## Backlog Conventions in This Vault

- **File names**: `Backlog.md`, `BACKLOG*.md`, `*_Todos.md`, `Dev_Todos.md`, `Software_Dev_Todos.md`, `Migration_TODO.md`, and similar. Mostly under `1. Projects/`, some under `2. Areas/`, a few under `4. Archive/`.
- **Task lines**: `- [ ]` = open, `- [x]` = done. Sub-bullets under a task are its acceptance criteria; a task is only done when its sub-items are.
- **Done section**: many backlogs keep a `## Done ✅` heading where completed items are collected.
- **Evidence annotation**: completed items are commonly annotated inline with `✅ YYYY-MM-DD` plus a short note on what confirmed it (see `1. Projects/RepoG/Backlog.md` for the house style).
- **Repo reference**: backlogs usually name their code repo near the top via a `Repo:` line (a path like `~/Developer/hackafolio`, or a git remote like `git@github.com:hackastak/repog`).

## Instructions

### Step 1: Locate the backlog files

**If the user passed no project name, stop and ask which project to review** (offer to list the folders under `1. Projects/` if that helps). Do not proceed until you have a project name. Do not silently fall back to a whole-vault review.

**If the user passed a project name** (e.g. `repog`), go straight to that project's folder under `1. Projects/` and find the backlog(s) there. Match the folder case-insensitively, since the argument may not match the folder's casing (`repog` → `RepoG`):

```bash
cd ~/Developer/My_Notes
# Resolve the project folder case-insensitively
proj=$(find "1. Projects" -maxdepth 1 -type d -iname "<arg>" 2>/dev/null | head -1)
echo "Project folder: $proj"
# Find backlog/todo notes within it (recurse for sub-project backlogs, e.g. OMS_Athena/ProjectGTR/)
find "$proj" \( -iname "*backlog*.md" -o -iname "*todo*.md" \) 2>/dev/null | sort
```

If no folder matches under `1. Projects/`, say so and offer to search `2. Areas/` and `4. Archive/` for the same name before giving up.

**If the user passed a full file path**, use it directly.

Skip anything under `.obsidian/`. Report the list of backlogs you will review.

### Step 2: Parse the open items

For each backlog, read the file and collect every open task (`- [ ]`), keeping:
- the file path and line number
- the task text and any indented sub-items (acceptance criteria)
- the surrounding section heading for context (e.g. "Phase 5 Sign-off — Testing & CI")

Ignore items already under a `## Done ✅` section and items already `- [x]`.

### Step 3: Identify the evidence sources

For each backlog, determine what to check the items against:
- **The code repo.** Read the `Repo:` reference near the top of the file. Resolve a local path under `~/Developer` (match the project name if no explicit path). For a git remote with no local clone, note that and fall back to vault-only evidence — do **not** clone.
- **Other vault notes.** CHANGELOGs, Dev_Notes, weekly notes (`_Weekly/`), and the backlog's own `## Done ✅` section can all record that something shipped.

### Step 4: Verify each open item (evidence only — no work)

For each open item, gather evidence that it is *already* complete. Use read-only inspection:

```bash
# Example evidence gathering against a resolved local repo (READ ONLY)
git -C <repo> log --oneline -n 40
git -C <repo> log --oneline --all --grep "<keywords from the task>"
git -C <repo> log -n 1 --format="%ci" -- <relevant/path>   # was the file touched?
```

Also read (never modify) CHANGELOGs, README sections, and relevant source files to confirm a feature or fix exists. Cross-reference vault notes with Grep.

Then classify the item into exactly one of:
- **Complete** — clear evidence all of it (including sub-items) shipped. Note the specific evidence (commit, file, changelog line, note).
- **Partially complete** — some sub-items done, others not. Stays open; summarize what remains.
- **Not complete** — no evidence it shipped. Stays open.
- **Cannot verify** — no local repo / not checkable from available evidence. Stays open; say why.

Be conservative. Only "Complete" is eligible to be checked off. When evidence is thin or ambiguous, classify as "Cannot verify," not "Complete."

### Step 5: Present findings and confirm

Before editing anything, show the user a report grouped by backlog:

```
## Backlog Review

### <Project> — <backlog path>
Open items reviewed: N

✅ Complete (will mark done):
- "<task text>" — <evidence: commit hash / file / changelog line>

🟡 Partially complete (left open):
- "<task text>" — done: <...>; remaining: <...>

⬜ Not complete (left open):
- "<task text>"

❔ Cannot verify (left open):
- "<task text>" — <why>

[repeat per backlog]

Summary: X items confirmed complete across Y backlogs, ready to mark.
```

Ask the user to confirm before marking, unless they already said to mark automatically.

### Step 6: Mark the confirmed items

For each **Complete** item, and only those, edit the vault backlog file:
- Flip `- [ ]` to `- [x]`.
- Append an inline evidence note in the house style: ` ✅ YYYY-MM-DD — <one-line evidence>` (use today's date). Match the annotation style already present in that file.
- If the item's sub-bullets are acceptance criteria, they are covered by the parent note; do not restructure the list.
- Do **not** move items into the `## Done ✅` section unless the user asks — flipping in place preserves context and section history. Mention that moving is an option.

Never touch items that are not "Complete." Never edit any file outside the vault.

### Step 7: Final summary

Report what changed: which items were marked done in which files, and a reminder of what is genuinely still open (the partial / not-complete / cannot-verify counts). This is the accurate backlog picture for planning.

## Notes

- Read-only toward all code. The one and only write action is flipping confirmed-complete checkboxes (plus their dated note) in vault backlog notes.
- Prefer precision over recall: a false "done" hides real work. When in doubt, leave it open.
- In any note you write into the vault, avoid em dashes (use a comma plus a conjunction, a colon, or split the sentence) to match the user's writing preference.
- Exclude `.obsidian/` and image files from searches.
- A git remote with no local clone is a legitimate "Cannot verify" — never clone repos to check them.
