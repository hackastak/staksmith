# Inbox Gradient Accelerator

Auto-classify and organize Obsidian vault inbox items based on content analysis.

## When to Activate

- **Nightly automation**: Run via cron/launchd for continuous inbox maintenance
- **On-demand**: When inbox has accumulated 10+ unprocessed items
- **Post-capture**: After a note-taking session to immediately organize new captures
- **Weekly review prep**: Before weekly planning sessions to ensure clean inbox

## What This Skill Does

The Inbox Gradient Accelerator analyzes unprocessed notes in your Obsidian vault's inbox and automatically classifies them using AI. It follows the PARA method (Projects, Areas, Resources, Archives) to move notes to their appropriate locations.

**3-Phase Workflow:**

1. **Scan Phase**: Inventories all inbox items, extracting metadata (word count, links, creation date)
2. **Classify Phase**: Uses AI to analyze content and determine the best destination
3. **Organize Phase**: Moves files with high-confidence classifications, tags uncertain items for manual review

## Configuration

Edit `config.json` to customize behavior:

```json
{
  "inbox_path": "/Users/hackastak/Developer/My_Notes/0. Inbox/",
  "confidence_threshold": 0.7,
  "exclude_folders": ["Graduates", "Matter", "Excalidraw"],
  "dry_run": true
}
```

**Parameters:**
- `inbox_path`: Root directory of your Obsidian inbox
- `confidence_threshold`: Minimum confidence (0.0-1.0) to auto-move files
- `exclude_folders`: Subdirectories to skip during scanning
- `dry_run`: When `true`, only preview changes without moving files

## Usage

### Quick Start

```bash
# Preview classifications without making changes
cd ~/Developer/Staksmith/skills/inbox-gradient-accelerator
./scripts/scan-inbox.sh | ./scripts/classify.sh

# Execute moves (requires dry_run: false in config)
./scripts/organize.sh
```

### Integration with Claude Code

When using this skill through Claude Code, the AI will:
1. Run the scan phase to inventory inbox items
2. Analyze each item to determine classification
3. Present proposed moves for your approval
4. Execute approved moves and generate a summary report

### Manual Review

Items with confidence < threshold are tagged with `#needs-review` and remain in inbox. Review these periodically:

```bash
# List items needing manual review
grep -r "#needs-review" ~/Developer/My_Notes/0.\ Inbox/
```

## Examples

### Example 1: Project Note Auto-Classification

**Input**: Note titled "OMS API Authentication Requirements" with content about JWT tokens and OAuth flows

**Classification Result**:
```json
{
  "path": "0. Inbox/OMS API Authentication Requirements.md",
  "classification": "1. Projects/OMS_Athena/Architecture",
  "confidence": 0.92,
  "reason": "Content discusses specific technical requirements for OMS project authentication"
}
```

**Action**: Automatically moved to `1. Projects/OMS_Athena/Architecture/`

### Example 2: Resource Note Auto-Classification

**Input**: Note titled "Docker Networking Cheatsheet" with general reference content

**Classification Result**:
```json
{
  "path": "0. Inbox/Docker Networking Cheatsheet.md",
  "classification": "3. Resources/Development/DevOps",
  "confidence": 0.85,
  "reason": "General reference material about Docker networking, not project-specific"
}
```

**Action**: Automatically moved to `3. Resources/Development/DevOps/`

### Example 3: Uncertain Classification

**Input**: Brief note "Meeting with Sarah about Q2 goals"

**Classification Result**:
```json
{
  "path": "0. Inbox/Meeting with Sarah.md",
  "classification": "uncertain",
  "confidence": 0.45,
  "reason": "Insufficient context to determine if this relates to a specific project or area"
}
```

**Action**: Tagged with `#needs-review`, remains in inbox

## Outputs

### Summary Report

After each run, generates `~/.claude/homunculus/inbox-gradient-accelerator/last-run.json`:

```json
{
  "timestamp": "2026-04-07T10:30:00Z",
  "items_processed": 15,
  "auto_moved": 11,
  "needs_review": 4,
  "categories": {
    "Projects": 6,
    "Areas": 2,
    "Resources": 3
  }
}
```

## Tuning Tips

- **Lower threshold (0.5-0.6)**: More aggressive auto-classification, occasional mistakes
- **Higher threshold (0.8-0.9)**: Conservative, most items need manual review
- **Recommended (0.7)**: Balanced - handles obvious cases, flags ambiguous ones

## Troubleshooting

**Issue**: Files not being classified correctly

**Solution**: Check that vault structure matches expected PARA folders. Edit classification prompts in `scripts/classify.sh` to match your vault organization.

**Issue**: Too many items flagged for review

**Solution**: Lower confidence_threshold in config.json or add more context to inbox notes (tags, wikilinks).

**Issue**: Script can't find inbox directory

**Solution**: Verify `inbox_path` in config.json points to correct absolute path.

## Dependencies

- `jq`: JSON parsing in bash scripts
- `ripgrep` (rg): Fast content searching
- Claude AI access: For classification analysis

## Related Skills

- **/sync**: Synchronize vault with external tools
- **/inbox**: Quick capture to inbox
- **/graduate**: Promote notes from inbox to permanent storage (manual alternative)
