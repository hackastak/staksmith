# Inbox Scan

Inventory markdown files in your Obsidian vault inbox with basic metadata.

## When to Activate

- Before running inbox-classify to get a fresh inventory
- To audit what's in your inbox
- As input for any inbox processing workflow

## What This Skill Does

Scans your inbox directory for markdown files and outputs a JSON array with basic metadata for each file. Keeps it simple - just paths and stats, no content parsing.

## Configuration

Edit `config.json`:

```json
{
  "inbox_path": "~/path/to/vault/0. Inbox/",
  "exclude_folders": ["Graduates", "Matter", "Excalidraw"]
}
```

## Usage

```bash
cd ~/Developer/Staksmith/skills/inbox-scan
./scripts/scan.sh
```

### Output Format

```json
[
  {
    "path": "/path/to/inbox/Note.md",
    "filename": "Note.md",
    "mtime": 1712345678,
    "size_bytes": 1234
  }
]
```

### Piping to Other Skills

```bash
# Pipe to inbox-classify
./scripts/scan.sh | ../inbox-classify/scripts/classify.sh

# Save for later processing
./scripts/scan.sh > ~/.claude/cache/inbox-inventory.json
```

## Examples

### Example 1: Quick Inbox Count

```bash
./scripts/scan.sh | jq 'length'
# Output: 12
```

### Example 2: Find Large Files

```bash
./scripts/scan.sh | jq '[.[] | select(.size_bytes > 5000)]'
```

### Example 3: Sort by Modification Time

```bash
./scripts/scan.sh | jq 'sort_by(.mtime) | reverse'
```

## Related Skills

- **inbox-classify**: Classifies items from scan output
- **inbox-organize**: Moves files based on classification
