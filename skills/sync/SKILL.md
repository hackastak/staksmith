---
name: sync
description: Load full vault context into Claude Code — recent weekly notes, active projects, master task list, recent inbox, and notes modified in the last 7 days — and output a structured state summary. Use at the start of a work session.
category: "Second Brain & Vault"
origin: Hackastak
---

# Sync Vault Context

Load the full vault context into Claude Code, providing a comprehensive view of current life and work state.

## When to Activate

- starting a work session and want full current context loaded
- need a snapshot of active projects, tasks, and focus areas
- returning after time away and catching up on recent activity
- before planning what to work on next

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Paths below are relative to the vault root.

## Instructions

You are loading the user's full context from their Obsidian vault. Follow these steps systematically:

### 1. Load Recent Weekly Notes

Find and read weekly notes from the last 7 days:
```bash
find "_Weekly" -name "*.md" -mtime -7 -type f
```

Read each recent weekly note to understand:
- What projects are being actively worked on
- What tasks are in progress
- End-of-week reflections or notes

### 2. Load Active Projects

List all project folders and their contents:
```bash
ls -la "1. Projects/"
```

For each active project folder, read any overview or main note files to understand:
- Project purpose and goals
- Current status
- Recent activity

### 3. Load Master Task List

Read the task aggregation file:
- `0.1 Tasks_List/Master_Task_List.md`

This shows all open tasks across Projects and Areas.

### 4. Check Recent Inbox Items

List items in the inbox that were modified recently:
```bash
find "0. Inbox" -name "*.md" -mtime -7 -type f
```

Read recent inbox items to capture new ideas or incoming work.

### 5. Scan Recently Modified Notes

Find all notes modified in the last 7 days across the vault:
```bash
find . -name "*.md" -mtime -7 -type f ! -path "./.obsidian/*" ! -path "./.claude/*"
```

Prioritize reading notes from:
- `2. Areas/` - Ongoing responsibilities and reflections
- `1. Projects/` - Active work

### 6. Look for Priorities and Focus

Search for priority indicators in recent notes:
- Lines containing "priority", "focus", "important", "urgent"
- Task items marked with high priority
- Any explicit goals or objectives mentioned

### 7. Output Context Summary

Present the findings in this format:

```
# Current Context Sync
*Generated: [current date]*

## Active Projects
[List each project with 1-2 sentence status]

## Current Focus
[What appears to be the primary focus based on recent activity]

## Open Tasks
### High Priority
[Tasks that appear urgent or important]

### In Progress
[Tasks currently being worked on]

### Upcoming
[Tasks queued for attention]

## Recent Activity (Last 7 Days)
[Summary of what's been worked on, decisions made, progress achieved]

## Areas of Attention
[Ongoing areas that have seen recent activity]

## Inbox Items
[New items requiring processing or decisions]

## Priorities Mentioned
[Any explicit priorities, goals, or focus areas found in recent notes]

## Context Notes
[Any other relevant context: upcoming deadlines, blockers, dependencies]
```

### 8. Offer Next Steps

After presenting the summary, ask:
> "I've loaded your current context. What would you like to focus on?"

## Notes
- Exclude `.obsidian/` and `.claude/` directories
- Exclude image files
- Focus on markdown files only
- If weekly notes use Templater syntax that hasn't been rendered, note what week it represents based on filename
- The weekly note filename format is `YYYY-WXX.md` (e.g., `2026-W12.md`)
