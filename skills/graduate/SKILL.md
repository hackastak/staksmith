---
name: graduate
description: Extract undeveloped ideas from weekly notes and promote them into standalone seedling notes in 0. Inbox/Graduates/. Use to capture half-formed thoughts before they're lost.
origin: Hackastak
---

# Graduate Ideas from Weekly Notes

Extract undeveloped ideas from weekly notes and promote them into standalone files for further development.

## When to Activate

- weekly notes are accumulating half-formed ideas worth saving
- you want to capture recurring thoughts before they're lost
- turning scattered reflections into developable seedling notes
- periodic review of recent weeks for promising threads

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Paths below are relative to the vault root. Input: number of weeks to scan (default 4) or "all".

## Instructions

### Step 1: Find Weekly Notes to Scan

Determine the scope based on arguments:

```bash
# List all weekly notes, sorted by date (newest first)
ls -t "_Weekly"/**/*.md 2>/dev/null
```

The weekly note filename format is `YYYY-WXX.md` (e.g., `2026-W12.md`).

If a number is provided, take that many recent files. Default to 4 weeks.

### Step 2: Read Each Weekly Note

For each weekly note, read the full content and look for:

**Idea Indicators:**
- Standalone observations or insights not tied to a task
- Questions that weren't answered
- Statements that could be expanded ("I think...", "Maybe...", "What if...")
- Parenthetical asides that contain novel thoughts
- Comments after task items that go beyond the task itself
- Reflections or realizations
- Connections noticed between disparate topics
- Opinions or takes on something
- Half-finished thoughts or "TODO: think more about..."
- Ideas prefixed with markers like "Idea:", "Note to self:", "Thought:"

**Exclude:**
- Task items themselves (lines starting with `- [ ]` or `- [x]`)
- Git changelog entries
- Standard template content (task queries, end-of-week checklist)
- Links without commentary
- Pure status updates

### Step 3: Evaluate Each Idea

For each potential idea found, assess:

1. **Standalone Potential**: Could this be a full note on its own?
2. **Novelty**: Is this a new thought, not already captured elsewhere?
3. **Development Potential**: Is there more to explore here?
4. **Connection Richness**: Does it relate to multiple other concepts?

Score each idea mentally. Focus on ideas that:
- Appear multiple times across weeks (recurring thoughts)
- Connect to active projects or areas
- Represent original thinking, not just information capture
- Could lead to action, further research, or content creation

### Step 4: Check for Existing Notes

Before creating a new note, search the vault to ensure the idea doesn't already have a home:

```bash
# Search for related content
grep -r -l "[key phrase from idea]" --include="*.md" . 2>/dev/null
```

If a related note exists:
- Consider if the idea should be added to that note instead
- Or if it's distinct enough to warrant its own note

### Step 5: Create Graduate Directory

Ensure the destination exists:
```bash
mkdir -p "0. Inbox/Graduates"
```

### Step 6: Create Standalone Notes

For each idea worth graduating, create a new file:

**Filename**: Use a descriptive name based on the core claim
- Format: `[Core_Concept_Name].md`
- Example: `Recursion_as_Delegation.md`
- Example: `Why_Microservices_Fail_Small_Teams.md`

**File Structure**:
```markdown
# [Core Claim as Title]

**Graduated from**: [[YYYY-WXX]]
**Date**: [current date]
**Status**: Seedling

## Core Claim

[One clear sentence stating the idea]

## Context

[2-3 sentences explaining where this thought came from, what prompted it, what you were thinking about at the time]

## Original Excerpt

> [Quote the exact text from the weekly note where this appeared]

## Initial Thoughts

[Expand slightly on the idea - what makes it interesting? Why does it matter?]

## Connections

- [[Related Note 1]] - [how it connects]
- [[Related Note 2]] - [how it connects]
- [Potential connection to explore]

## Questions to Explore

- [Question this idea raises]
- [Another question]

## Next Steps

- [ ] [Suggested action to develop this idea further]
```

### Step 7: Update Source Weekly Notes

Optionally, add a marker in the original weekly note showing the idea was graduated:

```markdown
[Original text] → *Graduated to [[Note Name]]*
```

Or add a section at the bottom:
```markdown
## Graduated Ideas
- [[Note Name]] - [brief description]
```

### Step 8: Output Summary

```
# Weekly Notes Review: Idea Graduation

**Scanned**: [X] weekly notes from [date range]
**Ideas Found**: [total count]
**Ideas Graduated**: [count]

## Graduated Ideas

### 1. [[Note Name]]
- **Source**: [[YYYY-WXX]]
- **Core Claim**: [one sentence]
- **Connections**: [[Note A]], [[Note B]]

### 2. [[Note Name]]
- **Source**: [[YYYY-WXX]]
- **Core Claim**: [one sentence]
- **Connections**: [[Note A]], [[Note B]]

[...continue for each graduated idea...]

## Ideas Considered but Not Graduated

| Idea | Source | Reason Skipped |
|------|--------|----------------|
| [brief description] | [[YYYY-WXX]] | [already exists / too vague / needs more context] |

## Recurring Themes

[Patterns noticed across weekly notes that might deserve attention]

## Suggestions

- [Ideas that might be ready for graduation with more context]
- [Topics appearing frequently that might need their own Area]
```

### Step 9: Confirm Before Creating

Before creating any files, present the list of ideas to be graduated and ask for confirmation:

> "I found [X] ideas worth graduating. Here's what I'll create:
> 1. [[Note Name]] - [core claim]
> 2. [[Note Name]] - [core claim]
>
> Should I proceed with all, some, or none?"

## Notes

- "Seedling" status indicates a new idea that needs development
- Graduated notes go to Inbox first so they can be processed by `/inbox` later
- Focus on quality over quantity - better to graduate 2-3 strong ideas than 10 weak ones
- Recurring ideas across multiple weeks are strong candidates
- The goal is to capture thoughts before they're lost, not to create finished notes
- Connections may include notes that don't exist yet (future notes)
- Weekly notes use Obsidian Tasks plugin queries - skip these sections
