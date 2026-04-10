# Inbox Organize

Move inbox files to their classified destinations.

## When to Activate

- After running inbox-classify with satisfactory results
- When you have a classification JSON ready to execute
- As the final step in the inbox processing pipeline

## What This Skill Does

Takes classification decisions (from inbox-classify or manual input) and moves files to their designated PARA folders. Only moves files above the confidence threshold. Tags uncertain items for manual review.

**Input:** JSON array of classifications (from stdin or file)
**Output:** Summary of actions taken

## Configuration

Edit `config.json`:

```json
{
  "confidence_threshold": 0.7,
  "dry_run": true,
  "tag_uncertain": true,
  "uncertain_tag": "#needs-review"
}
```

**Parameters:**
- `confidence_threshold`: Minimum confidence to auto-move (0.0-1.0)
- `dry_run`: When true, only preview changes without moving files
- `tag_uncertain`: Add tag to files below threshold
- `uncertain_tag`: Tag to add for manual review

## Usage

### Full Pipeline

```bash
cd ~/Developer/Staksmith/skills/inbox-scan
./scripts/scan.sh | \
  ../inbox-classify/scripts/classify.sh | \
  ../inbox-organize/scripts/organize.sh
```

### From Cached Classification

```bash
cd ~/Developer/Staksmith/skills/inbox-organize
cat ~/.claude/cache/classifications.json | ./scripts/organize.sh
```

### Preview Mode (Dry Run)

With `dry_run: true` in config:
```bash
./scripts/organize.sh < classifications.json
# Output shows what WOULD happen without moving files
```

### Execute Moves

Set `dry_run: false` in config, then run:
```bash
./scripts/organize.sh < classifications.json
```

## Output Format

```
=== Inbox Organize ===
Mode: DRY RUN (no files moved)
Confidence threshold: 0.7

[MOVE] Note.md -> 1. Projects/OMS_Athena/
[SKIP] Other.md (confidence 0.45 < 0.7)
[TAG]  Other.md -> added #needs-review

=== Summary ===
Moved: 3 files
Skipped: 2 files
Tagged: 2 files
```

## Safety Features

- **Dry run by default**: Must explicitly enable moves
- **Confidence gating**: Only moves high-confidence items
- **No overwrites**: Skips if destination file exists
- **Audit trail**: Logs all actions to cache

## Related Skills

- **inbox-scan**: First step in pipeline
- **inbox-classify**: Provides input for this skill
