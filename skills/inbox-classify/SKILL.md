# Inbox Classify

AI-powered classification of inbox items into PARA categories.

## When to Activate

- After running inbox-scan to get inventory
- When you have inbox items that need sorting
- Before running inbox-organize

## What This Skill Does

Takes a JSON array of inbox files (from inbox-scan) and classifies each into PARA categories (Projects, Areas, Resources, Archive). Extracts content, analyzes wikilinks and tags, and determines the best destination folder.

**Input:** JSON array of file paths (from stdin or file)
**Output:** JSON array with classification decisions

## Configuration

Edit `config.json`:

```json
{
  "vault_path": "~/path/to/vault/",
  "confidence_threshold": 0.7,
  "cache_path": "~/.claude/cache/inbox-classify/"
}
```

## Usage

### From inbox-scan Output

```bash
cd ~/Developer/Staksmith/skills/inbox-scan
./scripts/scan.sh | ../inbox-classify/scripts/classify.sh
```

### From Cached Inventory

```bash
cd ~/Developer/Staksmith/skills/inbox-classify
cat ~/.claude/cache/inbox-inventory.json | ./scripts/classify.sh
```

### Output Format

```json
[
  {
    "path": "/path/to/inbox/Note.md",
    "filename": "Note.md",
    "category": "Projects",
    "destination": "1. Projects/OMS_Athena/",
    "confidence": 0.85,
    "reason": "Contains OMS-related technical content and wikilinks to OMS docs"
  }
]
```

## Classification Logic

The classifier analyzes:
1. **Filename** - Project names, keywords
2. **Wikilinks** - Connections to existing notes
3. **Tags** - Explicit categorization hints
4. **Content preview** - Topic analysis

### Confidence Levels

- **0.8-1.0**: High confidence, safe to auto-move
- **0.6-0.8**: Medium confidence, review recommended
- **0.0-0.6**: Low confidence, requires manual decision

## Current Limitations

This skill currently outputs placeholder classifications. For full AI-powered classification:

1. Use the `/inbox` command in Claude Code (has built-in AI)
2. Or integrate with Claude API directly
3. Or manually review and edit the classification output

## Related Skills

- **inbox-scan**: Provides input for this skill
- **inbox-organize**: Consumes output from this skill
