#!/usr/bin/env bash
# classify.sh - Classify inbox items into PARA categories
# Reads scan output from stdin, outputs classification decisions
#
# NOTE: This script provides the classification structure but uses
# placeholder logic. For full AI classification, use the /inbox
# command in Claude Code or integrate with Claude API.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

VAULT_PATH=$(jq -r '.vault_path' "$CONFIG_FILE")
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE")
CACHE_PATH="${CACHE_PATH/#\~/$HOME}"

mkdir -p "$CACHE_PATH"

# Read scan input from stdin
scan_input=$(cat)
item_count=$(echo "$scan_input" | jq 'length')

echo "Classifying $item_count items..." >&2

# Get available PARA destinations for context
projects=$(find "$VAULT_PATH/1. Projects" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -I{} basename {} | head -20 || echo "")
areas=$(find "$VAULT_PATH/2. Areas" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -I{} basename {} | head -20 || echo "")

echo "  Found $(echo "$projects" | wc -w | tr -d ' ') projects, $(echo "$areas" | wc -w | tr -d ' ') areas" >&2

# Process each item
{
    echo "["
    first=true

    for i in $(seq 0 $((item_count - 1))); do
        item=$(echo "$scan_input" | jq ".[$i]")
        filepath=$(echo "$item" | jq -r '.path')
        filename=$(echo "$item" | jq -r '.filename')

        [[ ! -f "$filepath" ]] && continue

        echo "  Processing: $filename" >&2

        # Extract content for classification
        preview=$(head -c 2000 "$filepath" 2>/dev/null || echo "")

        # Extract wikilinks
        wikilinks=$(grep -o '\[\[[^]]*\]\]' "$filepath" 2>/dev/null | sed 's/\[\[\(.*\)\]\]/\1/g' | tr '\n' ',' | sed 's/,$//' || echo "")

        # Extract tags
        tags=$(grep -o '#[a-zA-Z0-9_-]\+' "$filepath" 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "")

        # Simple heuristic classification (placeholder for AI)
        # In production, this would call Claude API
        category="uncertain"
        destination="uncertain"
        confidence=0.5
        reason="Requires manual review or AI classification"

        # Basic keyword matching as placeholder logic
        filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')

        if echo "$filename_lower" | grep -qE "(oms|athena|artemist|billscribe|repog|moss)"; then
            category="Projects"
            destination="1. Projects/"
            confidence=0.7
            reason="Filename contains project keyword"
        elif echo "$filename_lower" | grep -qE "(cheatsheet|tutorial|reference|guide|how.?to)"; then
            category="Resources"
            destination="3. Resources/"
            confidence=0.65
            reason="Filename suggests reference material"
        elif [[ -n "$wikilinks" ]]; then
            # Check if wikilinks point to known projects
            for proj in $projects; do
                if echo "$wikilinks" | grep -qi "$proj"; then
                    category="Projects"
                    destination="1. Projects/$proj/"
                    confidence=0.75
                    reason="Wikilinks reference project: $proj"
                    break
                fi
            done
        fi

        # Output classification
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi

        jq -n \
            --arg path "$filepath" \
            --arg filename "$filename" \
            --arg category "$category" \
            --arg destination "$destination" \
            --argjson confidence "$confidence" \
            --arg reason "$reason" \
            --arg wikilinks "$wikilinks" \
            --arg tags "$tags" \
            '{
                path: $path,
                filename: $filename,
                category: $category,
                destination: $destination,
                confidence: $confidence,
                reason: $reason,
                extracted: {wikilinks: $wikilinks, tags: $tags}
            }'
    done

    echo "]"
} | jq '.'

# Save to cache
echo "$scan_input" | jq '.' > "$CACHE_PATH/last-scan.json"
echo "Cached scan input: $CACHE_PATH/last-scan.json" >&2
