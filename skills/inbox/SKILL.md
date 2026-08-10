---
name: inbox
description: Process notes in 0. Inbox/ and organize them into PARA directories with per-file confirmation. Multi-relevance notes go to Resources and are linked from relevant Projects/Areas. Use to clear the inbox.
category: "Second Brain & Vault"
origin: Hackastak
---

# Process Inbox

Process notes in the Inbox and organize them into the appropriate PARA directories based on relevance analysis.

## When to Activate

- the inbox has accumulated unsorted notes
- processing Readwise/Matter imports into Resources
- you want notes filed into Projects/Areas/Resources/Archive with confirmation
- periodic inbox cleanup

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Paths below are relative to the vault root.

## PARA Priority Order
1. **Projects** (`1. Projects/`) - Active work with deadlines, current focus
2. **Areas** (`2. Areas/`) - Ongoing responsibilities, no end date
3. **Resources** (`3. Resources/`) - Reference material, topics of interest
4. **Archive** (`4. Archive/`) - Completed or inactive items

## Instructions

### Step 1: Inventory the Inbox

List all notes in the inbox:
```bash
find "0. Inbox" -name "*.md" -type f ! -path "*/Readwise/*" ! -path "*/Matter/*"
```

Also check the Readwise subfolder separately:
```bash
find "0. Inbox/Readwise" -name "*.md" -type f 2>/dev/null
```

Also check the Matter subfolder separately:
```bash
find "0. Inbox/Matter" -name "*.md" -type f 2>/dev/null
```

Read each note to understand its content and purpose.

### Step 2: Map Existing Structure

Build a mental map of what exists in each PARA directory:

**Projects** - List active project folders:
```bash
ls -d "1. Projects"/*/ 2>/dev/null
```

**Areas** - List area folders:
```bash
ls -d "2. Areas"/*/ 2>/dev/null
```

**Resources** - List resource categories:
```bash
ls -d "3. Resources"/*/ 2>/dev/null
```

For each top-level folder, also check subfolders to understand the taxonomy.

### Step 3: Analyze Each Inbox Note

For each note in the inbox, determine:

1. **Content Type**
   - Article highlights/notes → likely Resources
   - Meeting notes → likely Areas or Projects
   - Task list or action items → likely Projects
   - Reference material → likely Resources
   - Personal reflection → likely Areas
   - Project-specific work → likely Projects

2. **Relevance Scoring**
   - Search for keywords from the note in existing directories
   - Check for existing notes on similar topics
   - Look for potential wikilink targets

3. **Multi-Relevance Detection**
   - If a note is relevant to both Projects AND Areas → move to Resources, link from both
   - If relevant to multiple Projects → move to Resources, link from each project
   - If relevant to only one location → move directly there

### Step 4: Determine Destination

Apply this decision tree:

```
Is this actionable work with a deadline?
├─ YES → 1. Projects/[relevant project]
└─ NO
   ├─ Is this an ongoing responsibility?
   │  ├─ YES → 2. Areas/[relevant area]
   │  └─ NO
   │     ├─ Is this reference/learning material?
   │     │  ├─ YES → 3. Resources/[relevant category]
   │     │  └─ NO
   │     │     └─ Is this completed/no longer relevant?
   │     │        ├─ YES → 4. Archive/
   │     │        └─ NO → Ask user for guidance
   └─ MULTIPLE RELEVANCE DETECTED
      └─ Move to 3. Resources/, create links in relevant Projects/Areas
```

### Step 5: Confirm Each File (IMPORTANT)

**Process notes one at a time with user confirmation.**

For each inbox note, present:

```
---
## [Note Name]

**Content Summary:** [1-2 sentence description of what this note contains]

**Recommended Destination:** [full path]
**Reason:** [why this location makes sense]

**Alternative Locations:**
- [other option 1] - [why it could go here]
- [other option 2] - [why it could go here]

**Links to Create:** [if multi-relevance detected]
- [[Note in Projects/Areas]] - [relationship]

**Action?**
1. Move to recommended location
2. Move to [alternative 1]
3. Move to [alternative 2]
4. Skip (leave in inbox)
5. Other (specify)
---
```

**Wait for user response before proceeding to the next note.**

### Step 6: Execute Confirmed Action

Only after user confirms, perform the action:

**A. Simple Move** (single relevance):
```bash
mv "0. Inbox/[note].md" "[destination]/[note].md"
```

**B. Move + Link** (multiple relevance):
1. Move note to Resources:
```bash
mv "0. Inbox/[note].md" "3. Resources/[category]/[note].md"
```

2. Create or update a note in each relevant location with a link:
   - If a relevant note exists, add the wikilink to it
   - If no relevant note exists, create a brief index note with the link

Link format to add:
```markdown
## Related Resources
- [[note name]] - [brief description of relevance]
```

Then proceed to the next note and repeat Step 5.

### Step 7: Output Summary

Present results in this format:

```
# Inbox Processing Complete

## Processed Notes

### Moved to Projects
| Note | Destination | Reason |
|------|-------------|--------|
| [name] | 1. Projects/[path] | [why it belongs there] |

### Moved to Areas
| Note | Destination | Reason |
|------|-------------|--------|
| [name] | 2. Areas/[path] | [why it belongs there] |

### Moved to Resources (with links created)
| Note | Destination | Linked From |
|------|-------------|-------------|
| [name] | 3. Resources/[path] | [[Project Note]], [[Area Note]] |

### Moved to Archive
| Note | Reason |
|------|--------|
| [name] | [why archived] |

### Skipped (needs clarification)
| Note | Issue |
|------|-------|
| [name] | [why unclear - ask user] |

## Links Created
- Added link to [[note]] in [location]
- Created new index note [[name]] in [location]

## Suggestions
- [Any organizational improvements noticed]
- [Potential new folders that might be useful]
```

### Step 8: Handle Edge Cases

**Readwise imports** (`0. Inbox/Readwise/`):
- These are typically article highlights
- Default destination: `3. Resources/` under relevant category
- Check if they relate to active projects and link if so

**Matter imports** (`0. Inbox/Matter/`):
- These are saved articles and highlights from Matter read-later app
- Default destination: `3. Resources/` under relevant category
- Check if they relate to active projects and link if so

**Books subfolder** (`0. Inbox/Books/`):
- Book notes typically go to Resources
- Link to relevant Areas if applicable (e.g., a software engineering book links to `2. Areas/Software_Engineering`)

**Notes with no clear home**:
- Ask the user before moving
- Suggest possible destinations with reasoning

**Empty or stub notes**:
- Flag for user review
- May indicate an idea to develop or delete

## Notes
- **CRITICAL: Confirm EACH file individually before moving** - never batch move without per-file approval
- Present recommendation with alternatives for each note
- Wait for explicit user response before moving any file
- Preserve any existing wikilinks within moved notes
- When creating links, use the note name without the .md extension
- If a destination folder doesn't exist, suggest creating it
- Check for duplicate filenames before moving
- User can skip any note to leave it in inbox for later
