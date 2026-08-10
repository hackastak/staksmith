---
name: story-pipeline
description: Manage the "Stories You Won't Believe" TikTok content calendar — buffer health, pillar balance, scheduling to the Mon/Wed/Fri cadence, and publish tracking via script frontmatter. Use to see pipeline status or move scripts through the pipeline.
category: "Writing & Content"
origin: Hackastak
---

# Story Pipeline Manager

Manage the "Stories You Won't Believe" content calendar and posting pipeline (TikTok, 3x/week — Mon/Wed/Fri).

## When to Activate

- checking pipeline status and buffer health
- deciding what to write or post next
- scheduling a ready script to a posting date
- marking a script as published
- auditing pillar balance across the catalog

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
STORY_PATH=1. Projects/Clipping/Unbelievable_Stories
```

Optional input: `status`, `next`, `schedule [script] [date]`, `publish [script]`, or a script name to inspect/update.

## Step 1: Load Pipeline State

```bash
cat "$VAULT_PATH/$STORY_PATH/PIPELINE.md"
ls "$VAULT_PATH/$STORY_PATH/SCRIPTS/"
grep -A8 "^---" "$VAULT_PATH/$STORY_PATH/SCRIPTS/"*.md
```

Read each script's frontmatter (status, pillar, scheduled, published, viral_score). The buffer target is **5-6 ready/scheduled**; cadence is **Mon/Wed/Fri**.

## Step 2: Route on Input

**Empty or `status`** → full pipeline report (Step 3).

**`next`** → recommend what to work on, based on:
1. Buffer health — if below 5 ready/scheduled, the priority is writing more (`story-script`)
2. Pillar balance — which pillar is thin (counterweight Survival's tendency to dominate)
3. What's closest to shippable (`scripted` scripts that need a quality pass)

**`schedule [script] [date]`** → set `status: scheduled` and `scheduled: [date]`. If no date given, suggest the next open Mon/Wed/Fri slot after the last scheduled post. Warn on double-booked dates.

**`publish [script]`** → set `status: published` and `published: [today]`. Remind to grab the posted TikTok URL for records.

**A script name** → show its current frontmatter and offer to update.

## Step 3: Pipeline Report

```markdown
# Story Pipeline Status
*Generated: [date]*

---

## Buffer Health
**Ready/Scheduled:** [X] scripts
**Target:** 5-6 (≈2 weeks at 3x/week)
**Status:** [Healthy ✅ | Low ⚠️ | Critical 🚨]

---

## Pipeline

### Scheduled ([X])
| Script | Post Date | Pillar |
|--------|-----------|--------|

### Ready to Schedule ([X])
| Script | Pillar | Score |
|--------|--------|-------|

### In Progress ([X])
| Script | Status | Pillar |
|--------|--------|--------|

### Idea Backlog
[Count of unwritten ideas in IDEAS.md]

---

## Pillar Balance
| Pillar | Ready/Scheduled | Published |
|--------|-----------------|-----------|
[8 pillars]

**Gap:** [Most underrepresented pillar]

---

## Recommendations
1. **Post next:** [Script] on [next Mon/Wed/Fri] — [reason]
2. **Write next:** [Pillar or idea] — [reason]
3. **Buffer:** [On track / write N more to hit target]
```

## Step 4: Apply Frontmatter Updates

When updating status:
1. Read the script file
2. Edit only the relevant YAML frontmatter fields (preserve all others)
3. Confirm the change

Status progression: `idea → scripted → ready → scheduled → published`. Use ISO dates (YYYY-MM-DD).

## Step 5: Offer Follow-Ups

> "Next steps:
> 1. Schedule a ready script
> 2. Mark one published
> 3. Generate ideas (`/story-ideas`)
> 4. Draft a script (`/story-script [idea]`)
> 5. Open Content_Calendar.md in Obsidian"

## Notes

- Strategy lives in `PIPELINE.md`; the calendar view is `Content_Calendar.md` (Dataview, auto-updates from frontmatter).
- Consistency beats perfection — keep the Mon/Wed/Fri cadence fed.
- Never use em dashes in any text you write.
- Mirrors the `/story-pipeline` slash command in the vault's `.claude/commands/`.
