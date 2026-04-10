#!/usr/bin/env bash
# scan-inbox.sh - Phase 1: Inventory inbox items
# Outputs JSON array of inbox files with metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

INBOX_PATH=$(jq -r '.inbox_path' "$CONFIG_FILE")
EXCLUDE_FOLDERS=$(jq -r '.exclude_folders[]' "$CONFIG_FILE" 2>/dev/null || echo "")

# Expand tilde in path
INBOX_PATH="${INBOX_PATH/#\~/$HOME}"

if [[ ! -d "$INBOX_PATH" ]]; then
    echo "Error: Inbox directory not found: $INBOX_PATH" >&2
    exit 1
fi

echo "Scanning inbox: $INBOX_PATH" >&2

# Build find exclusion arguments
EXCLUDE_ARGS=()
while IFS= read -r folder; do
    [[ -n "$folder" ]] && EXCLUDE_ARGS+=(-not -path "*/$folder/*")
done <<< "$EXCLUDE_FOLDERS"

# Find all markdown files in inbox
results="["
first=true

while IFS= read -r -d '' file; do
    # Skip if file is empty or doesn't exist
    [[ ! -f "$file" ]] && continue

    # Extract metadata
    filename=$(basename "$file")
    mtime=$(stat -f "%m" "$file" 2>/dev/null || stat -c "%Y" "$file" 2>/dev/null || echo "0")
    size=$(wc -w < "$file" | tr -d ' ')

    # Extract wikilinks [[...]]
    wikilinks=$(grep -o '\[\[[^]]*\]\]' "$file" 2>/dev/null | sed 's/\[\[\(.*\)\]\]/\1/g' | jq -R . | jq -s . || echo "[]")

    # Extract tags #tag
    tags=$(grep -o '#[a-zA-Z0-9_-]\+' "$file" 2>/dev/null | jq -R . | jq -s . || echo "[]")

    # Read first 500 words for preview
    preview=$(head -c 2000 "$file" | tr '\n' ' ' | sed 's/"/\\"/g')

    # Build JSON object
    if [[ "$first" == "true" ]]; then
        first=false
    else
        results+=","
    fi

    results+=$(cat <<EOF
{
  "path": "$file",
  "filename": "$filename",
  "mtime": $mtime,
  "word_count": $size,
  "wikilinks": $wikilinks,
  "tags": $tags,
  "preview": "$preview"
}
EOF
)

done < <(find "$INBOX_PATH" -type f -name "*.md" "${EXCLUDE_ARGS[@]}" -print0)

results+="]"

# Output JSON
echo "$results" | jq '.'

# Log summary to stderr
count=$(echo "$results" | jq 'length')
echo "Found $count inbox items" >&2
