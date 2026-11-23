---
name: project-triage
description: Run the Finish Line Test and the four-burner WIP cap over 1. Projects/ and 2. Areas/, then report which "projects" are really areas, which are stalled (14-day verdict due), whether the active count is over the burner cap, and which areas have no floor. Read-and-recommend only — it never pauses, kills, archives, or moves anything; the verdict stays the user's. Use at weekly close or before a planning cycle.
category: "Second Brain & Vault"
origin: Hackastak
---

# Project Triage — Finish Line + Burner Cap

Apply a small, deterministic discipline to the project list so it stays honest without willpower. Most things filed as projects are areas of life wearing project costumes, plus a few zombies nobody buried. This skill names which is which and whose verdict is due — it does not decide for you.

Method source: [[A_project_earns_a_burner_or_it_waits]] (`5. Notes/`). The four mechanisms are the Finish Line Test, area floors, the four-burner WIP cap, and the 14-day verdict.

This skill is **read-and-recommend**. It reads `1. Projects/` and `2. Areas/` and writes exactly one optional artifact: a dated snapshot for drift tracking. It never edits, pauses, kills, archives, or moves a project or area. Same posture as `/reflect`.

## When to Activate

- weekly close (pairs with `/weekly-momentum-report` and the "Friday Fifteen")
- the project list feels bloated, or "finish over start" is slipping
- before a planning cycle or a direction decision
- the user invokes `/project-triage`, or asks "which projects are real / stalled / zombies?"
- **Not** for: finding the next task inside one project (`what-next`), reconciling done-vs-open backlog items (`backlog-review`), or the whole-mind goals-vs-behavior mirror (`reflect`). This skill is narrow: it triages the project *roster* against four rules.

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
PROJECTS_PATH=1. Projects
AREAS_PATH=2. Areas
GOALS_PATH=2. Areas/Core_Goals
SNAPSHOTS_PATH=2. Areas/Core_Goals/Project_Triage
METHOD_NOTE=5. Notes/A_project_earns_a_burner_or_it_waits.md
```

Paths are relative to the vault root.

## Parameters (tunable, from the method note — these are heuristics, not laws)

```
BURNER_CAP=4          # max active discretionary projects
STALE_DAYS=14         # untouched this long -> verdict due
AREA_MAX=8            # more areas than this usually means tasks mislabeled as areas
```

A key nuance from the method note's open thread: the cap is **four discretionary burners**, with non-negotiable fixed work (the SAP day job) treated as a fixed background, not one of the four. Identify fixed-obligation projects (e.g. `SBN_SCM`, `SRI_Agent`, anything that is really the employer's work) and hold them *outside* the cap, labelled as such, rather than counting them against the four.

## Arguments

`/project-triage [focus]` — optional. Narrow the triage to one project or area (e.g. `/project-triage Lorien_AI`). With no argument, triage the whole roster.

## Instructions

### Step 1: Inventory the roster

```bash
ls -1 "1. Projects"/ 2>/dev/null
ls -1 "2. Areas"/ 2>/dev/null
```

Read each project's main note / `Backlog` / `README` frontmatter enough to judge it (objective, `status`, `due`/`deadline`, stated end state). You do not need to read every file in a project — you need its *shape*: is there a finish line, and when was it last touched.

### Step 2: Measure last-touched (staleness)

Prefer git history (most reliable signal of real work), fall back to file mtime for untracked edits. For each project folder:

```bash
git log -1 --format="%cr | %ci" -- "1. Projects/[NAME]" 2>/dev/null
find "1. Projects/[NAME]" -name "*.md" -type f -newermt "-${STALE_DAYS} days" 2>/dev/null | head -1
```

A project with no commit and no recently modified file inside `STALE_DAYS` is **stale** (verdict due). Record the actual last-touched date so the report is checkable.

### Step 3: Run the Finish Line Test on each project

For each item in `1. Projects/`, try to complete the sentence from the method note:

> *By [date], [this specific thing] exists or has happened.*

- **Passes** (a specific, completable outcome with or implying a finish line) -> a real project.
- **Fails** (an ongoing responsibility with no end state: "Home Lab", "Brand", "Software Engineering") -> it is really an **Area wearing a project costume**. Recommend demotion to `2. Areas/`, however urgent it feels. Do not move it — recommend.

Judge by the note's actual content, not its folder name. When genuinely ambiguous, say so and quote the line that makes it ambiguous rather than forcing a verdict.

### Step 4: Apply the burner cap

- Count the projects that pass Step 3 **and** are discretionary (exclude fixed-obligation day-job work, labelled separately).
- Compare to `BURNER_CAP`. If over, the roster is over capacity: name the overflow and note that the method says a fifth project waits in "Next Up" until a burner frees. Do **not** pick which ones to pause — present the stale-first ordering (Step 2) so the user's choice is informed, and let the verdict be theirs.

### Step 5: Flag verdicts due (the 14-day rule)

For every stale project (Step 2), mark a **verdict due**: paused (-> Next Up) or dead (-> Archive with one sentence on why). The method allows no third option ("I'll get back to it" is how a roster reaches 31). Present these as a list awaiting the user's one-word ruling each. The skill records nothing until the user rules.

### Step 6: Check area floors

For each item in `2. Areas/`, look for a stated **floor** — one measurable sentence describing the minimum standard that counts as fine (e.g. Money: "every invoice sent within 48 hours"). Flag areas with **no floor**, since an area with no standard is just a worry with a label on it. Also flag if the area count exceeds `AREA_MAX` (a sign tasks are mislabeled as areas). Recommend writing one floor per unfloored area; do not write them.

### Step 7: Generate the report

Present in chat. Lead with demotions and over-cap, since those are the highest-value findings.

```
# Project Triage — [date]
*Roster: [P] projects, [A] areas · Burner cap: [N]/[BURNER_CAP] discretionary active · Stale threshold: [STALE_DAYS]d*

## Over the cap?
[N discretionary active vs BURNER_CAP. If over, the overflow, stale-first. Fixed day-job work listed separately, outside the cap.]

## Really an area, not a project (Finish Line Test failed)
| Project | Why it fails | Recommend |
|---------|-------------|-----------|
| [name]  | no completable end state | demote to 2. Areas/ |

## Verdicts due (untouched > [STALE_DAYS]d)
| Project | Last touched | Your ruling? |
|---------|-------------|--------------|
| [name]  | [date, relative] | pause / kill __ |

## Real projects, on the burners
| Project | Finish line | Last touched |
|---------|-------------|--------------|
| [name]  | [the completable sentence] | [date] |

## Areas without a floor
| Area | Floor today | Suggested floor to write |
|------|-------------|--------------------------|
| [name] | (none) | [one measurable sentence] |

## Drift since last triage
[Only if a prior snapshot exists — see Step 8. Else: "First triage — baseline."]
```

Every row traces to a read note and a measured date. Recommend; never rule.

### Step 8: Save the snapshot (optional, drift tracking)

If the user wants longitudinal tracking (offer it), write `$SNAPSHOTS_PATH/[YYYY-MM-DD]_Project_Triage.md` (create the folder if missing) with machine-readable frontmatter:

```yaml
---
date: 2026-11-23
discretionary_active: 7
burner_cap: 4
over_cap_by: 3
demotion_candidates: [Home_Lab_Build, Staksmith]
verdicts_due: [Pokemon_Ink, MORE]
unfloored_areas: [Home, Hobbies]
---
```

Before writing, read the most recent prior snapshot and compute the Drift section: did the active count move toward the cap, did stalls clear or grow, did any area get a floor. This is what turns the skill from a one-off into a longitudinal check.

### Step 9: Offer follow-up

> "Want me to:
> 1. For each verdict-due project, record your pause/kill ruling (I'll stage the moves, you confirm)?
> 2. Draft one measurable floor per unfloored area for you to approve?
> 3. Re-run focused on one project or area?
> 4. Set a weekly reminder so the roster stays honest?"

Only act on an explicit yes. Even then, moving a project to Archive or writing a floor is a separate, confirmed step — this skill's own run never mutates the roster.

## Quality Criteria

A good triage is:
- **Deterministic** — the Finish Line Test and the 14-day rule are mechanical; apply them the same way every run.
- **Evidentiary** — every stale flag cites an actual last-touched date; every demotion quotes the missing finish line.
- **Non-prescriptive** — it surfaces verdicts due and overflow; the ruling (pause vs kill, which burner to free) stays the user's.
- **Honest about fixed work** — the day job is a fixed background, not a burner; never recommend "pausing" it.

Avoid:
- Judging by folder name instead of note content.
- Picking which projects die. Order them stale-first and let the user rule.
- Mutating the roster during the triage run itself.

## Notes

- Heuristics are tunable (`BURNER_CAP`, `STALE_DAYS`, `AREA_MAX`) — they come from one practitioner's essay, so adjust to fit. The method note records them as starting points, not validated thresholds.
- Silence is data: a project with no activity in the window is a finding, not an omission.
- Pairs with `/reflect` (which reads "finish over start" as a goal-vs-behavior divergence), `/weekly-momentum-report` (the cadence partner), and `/what-next` (once the roster is clean, pick the next task inside a surviving project).
- Ties directly to the stated risk in `2. Areas/Core_Goals/2026_Career_Goals.md` goal #5 (consolidate side projects, finish over start) and `10_Core_Problems.md` #2/#10.
