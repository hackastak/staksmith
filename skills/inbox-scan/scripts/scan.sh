#!/usr/bin/env bash
# scan.sh - Inventory inbox markdown files
# Outputs JSON array with basic file metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

INBOX_PATH=$(jq -r '.inbox_path' "$CONFIG_FILE")
INBOX_PATH="${INBOX_PATH/#\~/$HOME}"

if [[ ! -d "$INBOX_PATH" ]]; then
    echo "Error: Inbox directory not found: $INBOX_PATH" >&2
    exit 1
fi

# Build exclusion patterns for grep
EXCLUDE_PATTERN=""
while IFS= read -r folder; do
    [[ -n "$folder" ]] && EXCLUDE_PATTERN="${EXCLUDE_PATTERN}|/${folder}/"
done < <(jq -r '.exclude_folders[]' "$CONFIG_FILE" 2>/dev/null)
EXCLUDE_PATTERN="${EXCLUDE_PATTERN#|}"  # Remove leading pipe

echo "Scanning inbox: $INBOX_PATH" >&2

# Find files and build JSON using a simple approach
# Use find, filter exclusions, then build JSON per file
{
    echo "["
    first=true

    while IFS= read -r filepath; do
        # Skip excluded folders
        if [[ -n "$EXCLUDE_PATTERN" ]] && echo "$filepath" | grep -qE "$EXCLUDE_PATTERN"; then
            continue
        fi

        [[ ! -f "$filepath" ]] && continue

        # Get metadata
        filename=$(basename "$filepath")
        mtime=$(stat -f "%m" "$filepath" 2>/dev/null || stat -c "%Y" "$filepath" 2>/dev/null || echo "0")
        size_bytes=$(stat -f "%z" "$filepath" 2>/dev/null || stat -c "%s" "$filepath" 2>/dev/null || echo "0")

        # Output JSON object (use jq for proper escaping)
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi

        jq -n \
            --arg path "$filepath" \
            --arg filename "$filename" \
            --argjson mtime "$mtime" \
            --argjson size_bytes "$size_bytes" \
            '{path: $path, filename: $filename, mtime: $mtime, size_bytes: $size_bytes}'

    done < <(find "$INBOX_PATH" -type f -name "*.md" 2>/dev/null)

    echo "]"
} | jq '.'

# Summary
count=$(find "$INBOX_PATH" -type f -name "*.md" 2>/dev/null | grep -vE "$EXCLUDE_PATTERN" 2>/dev/null | wc -l | tr -d ' ')
echo "Found $count inbox items" >&2
