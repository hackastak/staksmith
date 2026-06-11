---
name: backlinks
description: Wire the vault graph — find orphans, missing connections, and cluster bridges, score them, and add links/stubs. Connects notes without generating content. Optional cluster focus.
origin: Hackastak
---

# Backlinks — Wire the Graph

**Purpose:** Make the vault graph traversable. Connect notes. Don't generate content. When you find an empty hub, flag it—don't fill it. When you find notes that should link, wire them—don't rewrite them. The substance in this vault is human thinking. Your contribution is the wiring between those thoughts.

## When to Activate

- the vault graph feels disconnected or orphan-heavy
- you want to wire related notes together without writing content
- bridging isolated clusters across PARA folders
- triaging unresolved `[[links]]` into stubs worth creating

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Paths below are relative to the vault root. Input: optional cluster name to focus on (e.g. "OMS_Athena", "Software_Engineering"). If provided, skip the full scan and focus Phases 3-4 on that cluster and neighbors. If empty, full vault analysis.

---

## Phase 1: Structural Inventory

Graph-only analysis. No content reads yet.

### 1.1 Vault Statistics
```bash
# Count total notes
find . -name "*.md" -type f ! -path "./.obsidian/*" ! -path "./.claude/*" ! -path "./_templates/*" | wc -l
```

### 1.2 Find Orphan Notes
Notes with no incoming or outgoing links:
```bash
# Get all wikilinks in vault
grep -roh '\[\[[^]|]*' . --include="*.md" | sed 's/\[\[//' | sort | uniq -c | sort -rn
```

Then compare against actual files to find:
- **Orphans**: Files that no other note links to
- **Dead-ends**: Files with zero outgoing links
- **Unresolved**: `[[links]]` pointing to non-existent notes

### 1.3 Identify Hub Notes
Hub notes have many incoming links. Check PARA folders for natural hubs:

**Project hubs** (check for Backlog.md, Index.md, or main project note):
```bash
ls "1. Projects"/*/
```

**Area hubs** (main notes in each area):
```bash
ls "2. Areas"/*/
```

**Resource hubs** (index or overview notes):
```bash
ls "3. Resources"/*/
```

For top 15-20 most-linked notes, map their connections by extracting wikilinks with:
```bash
grep -oh '\[\[[^]]*\]\]' "path/to/note.md"
```

### 1.4 Build Cluster Map
Group notes by their primary folder (PARA category + subfolder). This creates natural clusters:
- `1. Projects/OMS_Athena/*` → OMS_Athena cluster
- `2. Areas/Software_Engineering/*` → Software_Engineering cluster
- etc.

---

## Phase 2: Priority Context

Read 5-7 context files to build a priority filter. This determines what connections matter most.

### 2.1 Recent Weekly Notes
Read the last 2-3 weekly notes to understand current focus:
```bash
ls -t "_Weekly/2026/"*.md | head -3
```

Extract:
- Active projects being worked on
- Open questions and threads of thinking
- People and concepts getting current attention

### 2.2 Master Task List
```bash
# Check current open tasks
cat "0.1 Tasks_List/Master_Task_List.md"
```

### 2.3 Active Project Backlogs
For each active project mentioned in weekly notes, read the backlog:
```bash
cat "1. Projects/[ProjectName]/Backlog.md"
```

### 2.4 Priority Summary
From these reads, extract:
- **Current priorities**: Projects with recent activity
- **Open questions**: Ideas being explored
- **Active concepts**: Topics appearing repeatedly

This becomes the scoring filter in Phase 6.

---

## Phase 3: Orphan Rescue Scan

### 3.1 Filter Orphans
From Phase 1 orphans, skip non-notes:
- Images: .heic, .jpg, .jpeg, .png, .gif, .webp
- Media: .mov, .mp4, .wav, .mp3
- Excalidraw: .excalidraw.md
- Canvases: .canvas
- Templates: anything in `_templates/`

### 3.2 Prioritize Orphan Reading
Apply this decision tree to remaining orphans:

1. **PARA Priority**:
   - `1. Projects/*` orphans → Read first (active work shouldn't be orphaned)
   - `2. Areas/*` orphans → Read second (ongoing responsibilities)
   - `3. Resources/*` orphans → Read third (reference material)
   - `4. Archive/*` orphans → Skip unless title matches current priority
   - `0. Inbox/*` orphans → Flag for /inbox processing instead

2. **Title contains word from current priorities or hub backlink chain?**
   - Yes → Read title + first 30 lines

3. **Title contains question mark?**
   - Yes → Read title + first 30 lines (often valuable thinking notes)

4. **Otherwise**:
   - Read title only, flag if semantically related to active clusters

### 3.3 Find Nearest Neighbors
For each meaningful orphan, search for its nearest cluster:
```bash
# Search for key concepts from the orphan
grep -r "key concept" --include="*.md" -l
```

**Cap**: Do not read more than 100 notes total across all phases. Be selective.

---

## Phase 4: Cluster Bridge Analysis

### 4.1 Identify Isolated Clusters
For each PARA subfolder cluster, count:
- Internal links (within cluster)
- External links (to other clusters)

Clusters with high internal / low external links are isolated.

### 4.2 Cross-Cluster Search
For top 5-6 isolated cluster pairs, search for shared themes:
```bash
# Search Cluster B for themes from Cluster A
grep -r "theme from A" "2. Areas/Cluster_B/" --include="*.md"
```

### 4.3 Synonym Discovery
Try 2-3 vocabulary variants for each concept. Ideas evolve under different names:
- "MCP" / "Model Context Protocol" / "tool protocol"
- "skills" / "capabilities" / "agent behaviors"
- "PARA" / "Projects Areas Resources Archive" / "organization method"

Read intermediary notes that might serve as bridges.

---

## Phase 5: Unresolved Link Triage

From unresolved `[[links]]` found in Phase 1:

| References | Action |
|------------|--------|
| 3+ | Likely worth creating as a stub note |
| 2 | Check for near-duplicates or name variants of existing notes |
| 1 | Skip unless it's a critical concept from current priorities |

Before recommending new stubs, check for:
- Name variants: `[[SAP Athena]]` vs `[[SAP_Athena]]`
- Aliases: `[[note|alias]]` format
- Case differences

---

## Phase 6: Score and Recommend

Score each candidate connection on 3 dimensions (multiplicative):

| Dimension | What it measures | 1 | 3 | 5 |
|-----------|------------------|---|---|---|
| **Conceptual Strength** | How real is this connection? | Same word, different context | Related problems/questions | Same thesis from different angles |
| **Structural Impact** | How much does this improve the graph? | 6th link to well-connected note | Rescues valuable orphan | Bridges two isolated clusters |
| **Priority Alignment** | Does it touch current priorities? | Neither note is active | One note relates to a priority | Both notes relate to active work |

### PARA Bonus
Add structural weight for connections that:
- Link `1. Projects/*` to relevant `3. Resources/*` (+5)
- Link `2. Areas/*` to supporting `3. Resources/*` (+3)
- Link active projects to related areas (+5)

### Scoring
- **Composite** = Conceptual x Structural x Priority + PARA Bonus (max ~135)
- **Critical** (75+), **High** (40-74), **Medium** (15-39), **Low** (<15)

### Quality Controls
- Minimum Conceptual Strength of 2. Same word but different concept = skip
- Cap at 30 total recommendations. Quality over quantity
- Each connection must be explainable in one sentence
- Include borderline cases with lower scores rather than silently excluding

### Connection Taxonomy

Label each recommendation:

1. **Orphan to Hub** - Orphaned note connected to its nearest cluster hub
2. **Cluster Bridge** - Two clusters share themes but zero links between them
3. **Internal Gap** - Within-cluster notes missing cross-references
4. **Empty Hub** (flag only) - Hub note referenced by many but has no content. Flag for user to write. NOT filled by agent
5. **Semantic Twin** - Two notes about the same concept, different vocabulary
6. **Person to Concept** - Person note that should link to associated concepts
7. **Temporal Bridge** - Old thinking relevant to new work, never connected
8. **Unresolved Worth Creating** - `[[link]]` appearing 3+ times, worth formalizing
9. **PARA Cross-Link** - Project needs Resource reference, or Area needs supporting material

### Connection Card Format

For each recommendation:

```
### [#]. [Type]: [Short description]
**Score:** [X] (Conceptual [N] x Structural [N] x Priority [N] + PARA [N])
**What:** [One-sentence description]
**Edit:** Add `[[Target Note]]` to [Source Note] in [section/location]
**Why:** [One sentence on what this unlocks]
```

For Empty Hub flags:

```
### [#]. Empty Hub: [Note name]
**Referenced by:** [list of notes that link to it]
**What this needs:** Your thinking. [N] notes point here and find nothing.
```

---

## Phase 7: Present and Execute

### 7.1 Present Report

```
BACKLINKS REPORT — [Date]
Vault size: [N] notes
Orphans assessed: [N] meaningful (of [N] total)
Connections recommended: [N] across [N] tiers

PARA Distribution:
- Projects: [N] notes, [N] orphans
- Areas: [N] notes, [N] orphans
- Resources: [N] notes, [N] orphans
- Archive: [N] notes (excluded from analysis)

---
## Critical ([N])
[Connection cards]

## High ([N])
[Connection cards]

## Medium ([N])
[Connection cards]

## Summary
[Narrative: biggest structural gaps, PARA integration issues, what executing these changes unlocks]

---
Execute: All Critical+High / Critical only / Pick specific / None
```

### 7.2 Ask for Execution Choice

Present options:
- **All Critical + High** (recommended default)
- **Critical only**
- **Pick specific ones** (by number)
- **None** (save report only)

### 7.3 Execution Rules

When executing approved connections:

**Adding `[[links]]`:**
- Read the note structure first
- Place link in the relevant section, not dumped at bottom
- For Project notes: add to "Related" or "Resources" section if exists
- For Resource notes: add to "See Also" or create one
- Preserve existing formatting

**Creating stub notes** (for Unresolved Worth Creating):
- Title + "Related" section listing backlinks ONLY
- No synthesized content
- No descriptions
- Use this format:
```markdown
# [Note Title]

## Related
- [[Note that links here]]
- [[Another note that links here]]

---
*Stub created by /backlinks — needs your thinking*
```

**Empty Hubs:**
- DO NOT fill
- Report only as flags
- User writes the content

### 7.4 Post-Execution Verification

After making changes:
```bash
# Verify links resolved
grep -oh '\[\[[^]]*\]\]' "path/to/modified/note.md"
```

Report: "Made X connections across Y notes. Z new stub notes created."

---

## Limitations

Be honest about these:

- **False positives**: Include with lower score rather than silently exclude. Let the user decide
- **Vocabulary drift**: Try 2-3 variants. Ideas evolve under different names
- **Recency bias**: Flag old-but-rich orphans even if they don't match current priorities. Old thinking can be most valuable
- **Graph vs. content tension**: Well-connected notes can have shallow content. Poorly-connected notes can be deeply thoughtful. Connection count alone doesn't indicate value
- **PARA assumptions**: The scoring assumes PARA structure. Manual review for edge cases

---

## Notes

- Exclude `.obsidian/`, `.claude/`, `_templates/` from all scans
- Exclude image and media files
- Wikilinks may include aliases: `[[actual note|display text]]` — use actual note name
- Some links may be to notes that don't exist yet (future notes)
- Weekly notes (`_Weekly/`) contain many links for logging purposes — weight these lower
- Inbox notes should be processed with `/inbox` first, not wired in place
- Archive notes are excluded from recommendations but may be flagged as sources
