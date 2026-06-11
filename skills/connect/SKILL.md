---
name: connect
description: Find connections between two topics through the vault's wikilink graph, or analyze the whole vault for unlinked-but-related notes. Use to discover unexpected relationships between ideas.
origin: Hackastak
---

# Connect Topics

Find connections between two domains using the link graph in the vault. Discover unexpected relationships between ideas.

## When to Activate

- you want to find how two topics relate through your notes
- looking for bridge notes between two domains
- auditing the whole vault for related-but-unlinked notes
- hunting for non-obvious cross-pollination between areas

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Paths below are relative to the vault root. Input: two topics separated by "and", "to", or comma (optional). If empty, analyze the entire vault for potential unlinked connections.

## Instructions

### Mode Detection

First, determine the mode based on the input:

**If topics are provided:** Run Connection Discovery mode
**If no topics provided:** Run Vault-Wide Analysis mode

---

## Mode 1: Connection Discovery (Two Topics Provided)

### Step 1: Parse Topics
Extract topic A and topic B from the arguments. Handle separators: "and", "to", ",", "with"

### Step 2: Build the Link Graph
Search for all markdown files and extract their wikilinks:

```bash
# Find all markdown files
find . -name "*.md" -type f ! -path "./.obsidian/*" ! -path "./.claude/*"
```

For each file, extract:
- The file name (as a node)
- All `[[wikilinks]]` within the file (as edges)

Use grep to find wikilinks:
```bash
grep -oh '\[\[[^]]*\]\]' "filename.md"
```

### Step 3: Find Notes Mentioning Each Topic
Search for files that mention topic A and topic B:
- Direct mentions in content
- In the filename
- In wikilinks pointing to/from the file

### Step 4: Trace Connection Paths
Find paths between topic A and topic B through the link graph:

1. Start from notes mentioning topic A
2. Follow outgoing wikilinks from those notes
3. Check if any linked notes mention topic B or link to notes that do
4. Track the path: A → Note1 → Note2 → B

Look for:
- **Direct connections**: Notes that mention both topics
- **One-hop connections**: Note mentioning A links to note mentioning B
- **Two-hop connections**: A → intermediate → B
- **Shared references**: Notes that both A-notes and B-notes link to

### Step 5: Analyze Patterns
Look for:
- Common themes in connecting notes
- Shared tags or categories
- Similar folder locations (Projects, Areas, Resources)
- Temporal patterns (created/modified around same time)

### Step 6: Output Results

```
# Connection Analysis: [Topic A] ↔ [Topic B]

## Direct Connections
[Notes that explicitly mention or link both topics]
- **[Note name]** - [How it connects the topics]

## Link Paths Found
[Paths through the link graph]

### Path 1 (shortest)
[Topic A mention] → [[Link 1]] → [[Link 2]] → [Topic B mention]
- **[Note 1]**: [relevant excerpt]
- **[Note 2]**: [relevant excerpt]

### Path 2
[Another path if exists]

## Bridge Notes
[Notes that serve as connection points between the two domains]
- **[Note name]**: Links to [X] A-related notes and [Y] B-related notes

## Patterns Observed
- [Pattern 1: e.g., "Both topics appear frequently in your Systems Architecture notes"]
- [Pattern 2: e.g., "Connected through the concept of 'optimization'"]

## Potential Connections Not Yet Made
[Suggestions for new links that could strengthen the connection]
- Consider linking [[Note X]] to [[Note Y]] because...

## Insight
[1-2 sentence synthesis of how these topics relate in your thinking]
```

---

## Mode 2: Vault-Wide Analysis (No Topics Provided)

### Step 1: Build Complete Link Graph
Map all notes and their connections:
- Extract all wikilinks from every markdown file
- Build adjacency list of connections
- Identify clusters of highly connected notes

### Step 2: Identify Isolated Clusters
Find groups of notes that are:
- Heavily linked within themselves
- But have few or no links to other clusters

### Step 3: Semantic Similarity Search
For notes in different clusters, search for:
- Similar keywords or phrases
- Same tags
- Related concepts (e.g., "testing" and "quality assurance")
- Notes in same PARA category but not linked

### Step 4: Find Potential Bridges
Identify notes that could connect clusters:
- Notes with broad topics that span domains
- Notes in `3. Resources/` that could link to `1. Projects/`
- Concepts that appear in multiple areas but aren't cross-linked

### Step 5: Output Results

```
# Vault Connection Analysis

## Current Link Structure
- Total notes: [count]
- Total links: [count]
- Average links per note: [number]
- Most connected notes: [top 5]

## Identified Clusters
### Cluster 1: [Theme]
- [List of notes in cluster]
- Internal links: [count]
- External links: [count]

### Cluster 2: [Theme]
...

## Disconnected but Related
[Pairs or groups of notes that seem related but aren't linked]

### Potential Connection 1
**Notes:** [[Note A]] ↔ [[Note B]]
**Why they might connect:** [Shared concepts, keywords, themes]
**Suggested action:** [Add link from X to Y]

### Potential Connection 2
...

## Orphan Notes
[Notes with zero incoming or outgoing links that could be connected]
- **[[Note]]** - Could connect to: [suggestions]

## Bridge Opportunities
[Notes that could serve as hubs connecting multiple domains]
- **[[Note]]** touches on [Domain 1], [Domain 2], [Domain 3] - consider adding links

## Recommended Actions
1. [Most valuable connection to make]
2. [Second most valuable]
3. [Third most valuable]
```

---

## Notes
- Exclude `.obsidian/` and `.claude/` directories
- Exclude image files
- Wikilinks may include aliases: `[[actual note|display text]]` - use the actual note name
- Some links may be to notes that don't exist yet (future notes)
- Consider both explicit links and implicit connections (shared concepts)
- Weekly notes often contain many links but may not represent meaningful connections
