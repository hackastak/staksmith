---
name: trace
description: Track how a specific idea has evolved across the Obsidian vault over time — find all mentions, follow wikilinks, and build a chronological timeline with connections. Use to see the history of a concept.
origin: Hackastak
---

# Trace Idea Evolution

Track how a specific idea has evolved over time across this Obsidian vault.

## When to Activate

- you want to see when and where an idea first appeared
- tracing how your thinking on a topic has changed
- finding every note connected to a concept before writing or deciding
- auditing the lineage of a project or belief

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Paths below are relative to the vault root. Input: the topic/idea to trace (required).

## Instructions

You are tracing the evolution of the topic: **[the input topic]**

Follow these steps:

### 1. Find All Mentions
Search the entire vault for files containing the topic (case-insensitive). Use Grep to find all matching files and their content.

### 2. Gather File Metadata
For each matching file, collect:
- File path
- Creation date (use `stat -f "%SB" -t "%Y-%m-%d"` on macOS)
- Last modified date (use `stat -f "%Sm" -t "%Y-%m-%d"` on macOS)
- The context around each mention (surrounding lines)

### 3. Extract Connections
For each matching file, find:
- Outgoing links: `[[wikilinks]]` in the file
- Which of those linked notes also mention the topic
- Tags if present (format: `#tagname`)

### 4. Build the Timeline
Sort all findings chronologically by creation date and present:

```
## Idea Timeline: [TOPIC]

### First Appearance
- **Date**: [earliest creation date]
- **File**: [file path]
- **Context**: [relevant excerpt]

### Evolution
[For each subsequent file, chronologically:]
- **[Date]** - [File name]
  - Context: [how the topic appears]
  - Connections: [linked notes that also discuss this topic]
  - Changes: [how thinking evolved from previous mentions]

### Current State
- **Total mentions**: [count]
- **Most recent**: [latest file with date]
- **Key connections**: [most frequently co-linked notes]

### Connection Map
[List notes that are connected to multiple files mentioning this topic]
```

### 5. Insights
Provide a brief analysis:
- How has the understanding of this topic deepened over time?
- What themes or areas is it most connected to?
- Are there any gaps or unexplored connections?

## Notes
- Exclude `.obsidian/` directory from searches
- Exclude image files (*.png, *.jpg)
- Weekly notes (`_Weekly/`) may show when the topic was actively worked on
- Check `1. Projects/` for active work and `4. Archive/` for completed thinking
