#!/usr/bin/env bash
# organize.sh - Move inbox files based on classification
# Reads classification JSON from stdin, moves files to destinations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

CONFIDENCE_THRESHOLD=$(jq -r '.confidence_threshold' "$CONFIG_FILE")
DRY_RUN=$(jq -r '.dry_run' "$CONFIG_FILE")
TAG_UNCERTAIN=$(jq -r '.tag_uncertain' "$CONFIG_FILE")
UNCERTAIN_TAG=$(jq -r '.uncertain_tag' "$CONFIG_FILE")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE")
CACHE_PATH="${CACHE_PATH/#\~/$HOME}"

mkdir -p "$CACHE_PATH"

# Read classification input from stdin
classifications=$(cat)
item_count=$(echo "$classifications" | jq 'length')

echo "=== Inbox Organize ===" >&2
if [[ "$DRY_RUN" == "true" ]]; then
    echo "Mode: DRY RUN (no files moved)" >&2
else
    echo "Mode: EXECUTE (files will be moved)" >&2
fi
echo "Confidence threshold: $CONFIDENCE_THRESHOLD" >&2
echo "" >&2

moved=0
skipped=0
tagged=0
errors=0

# Process each classification
for i in $(seq 0 $((item_count - 1))); do
    item=$(echo "$classifications" | jq ".[$i]")
    filepath=$(echo "$item" | jq -r '.path')
    filename=$(echo "$item" | jq -r '.filename')
    category=$(echo "$item" | jq -r '.category')
    destination=$(echo "$item" | jq -r '.destination')
    confidence=$(echo "$item" | jq -r '.confidence')
    reason=$(echo "$item" | jq -r '.reason')

    # Skip if file doesn't exist
    if [[ ! -f "$filepath" ]]; then
        echo "[ERROR] File not found: $filepath" >&2
        ((errors++)) || true
        continue
    fi

    # Check confidence threshold
    meets_threshold=$(echo "$confidence >= $CONFIDENCE_THRESHOLD" | bc -l)

    if [[ "$meets_threshold" -eq 1 && "$destination" != "uncertain" ]]; then
        # High confidence - move the file
        dest_dir=$(dirname "$filepath" | sed "s|0\\. Inbox|${destination%/}|")

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[MOVE] $filename -> $destination" >&2
        else
            # Create destination directory if needed
            mkdir -p "$dest_dir"

            # Check if destination file exists
            dest_file="$dest_dir/$filename"
            if [[ -f "$dest_file" ]]; then
                echo "[SKIP] $filename (destination exists)" >&2
                ((skipped++)) || true
                continue
            fi

            # Move the file
            mv "$filepath" "$dest_file"
            echo "[MOVED] $filename -> $destination" >&2
        fi
        ((moved++)) || true
    else
        # Low confidence - skip and optionally tag
        echo "[SKIP] $filename (confidence $confidence < $CONFIDENCE_THRESHOLD)" >&2
        ((skipped++)) || true

        if [[ "$TAG_UNCERTAIN" == "true" ]]; then
            # Check if file already has the tag
            if ! grep -q "$UNCERTAIN_TAG" "$filepath" 2>/dev/null; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[TAG]  $filename -> would add $UNCERTAIN_TAG" >&2
                else
                    # Add tag at the end of the file
                    echo "" >> "$filepath"
                    echo "$UNCERTAIN_TAG" >> "$filepath"
                    echo "[TAG]  $filename -> added $UNCERTAIN_TAG" >&2
                fi
                ((tagged++)) || true
            fi
        fi
    fi
done

echo "" >&2
echo "=== Summary ===" >&2
if [[ "$DRY_RUN" == "true" ]]; then
    echo "Would move: $moved files" >&2
    echo "Would skip: $skipped files" >&2
    echo "Would tag: $tagged files" >&2
else
    echo "Moved: $moved files" >&2
    echo "Skipped: $skipped files" >&2
    echo "Tagged: $tagged files" >&2
fi
[[ $errors -gt 0 ]] && echo "Errors: $errors" >&2

# Save action log
log_file="$CACHE_PATH/last-run.json"
jq -n \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --argjson moved "$moved" \
    --argjson skipped "$skipped" \
    --argjson tagged "$tagged" \
    --argjson errors "$errors" \
    --arg mode "$([ "$DRY_RUN" == "true" ] && echo "dry_run" || echo "execute")" \
    '{
        timestamp: $timestamp,
        mode: $mode,
        moved: $moved,
        skipped: $skipped,
        tagged: $tagged,
        errors: $errors
    }' > "$log_file"

echo "Log saved: $log_file" >&2

# Output the classifications with status
echo "$classifications" | jq '.'
