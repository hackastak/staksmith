#!/usr/bin/env bash
# organize.sh - Phase 3: Move files based on classification
# Reads classification results and executes moves

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

CONFIDENCE_THRESHOLD=$(jq -r '.confidence_threshold' "$CONFIG_FILE")
DRY_RUN=$(jq -r '.dry_run' "$CONFIG_FILE")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
VAULT_PATH=$(dirname "$(jq -r '.inbox_path' "$CONFIG_FILE" | sed "s|~|$HOME|")")

# Check if cache exists
if [[ ! -f "$CACHE_PATH" ]]; then
    echo "Error: No classification cache found. Run classify.sh first." >&2
    exit 1
fi

# Load classifications
classifications=$(cat "$CACHE_PATH")

# Initialize counters
moved=0
tagged=0
errors=0

# Process each classification
item_count=$(echo "$classifications" | jq 'length')
echo "Processing $item_count classifications..." >&2
echo "Dry run: $DRY_RUN" >&2
echo "Confidence threshold: $CONFIDENCE_THRESHOLD" >&2
echo "" >&2

for i in $(seq 0 $((item_count - 1))); do
    item=$(echo "$classifications" | jq ".[$i]")
    path=$(echo "$item" | jq -r '.path')
    filename=$(echo "$item" | jq -r '.filename')
    classification=$(echo "$item" | jq -r '.classification')
    confidence=$(echo "$item" | jq -r '.confidence')
    reason=$(echo "$item" | jq -r '.reason')

    # Skip if file doesn't exist
    if [[ ! -f "$path" ]]; then
        echo "  SKIP: File not found: $filename" >&2
        continue
    fi

    # Check confidence threshold
    if (( $(echo "$confidence < $CONFIDENCE_THRESHOLD" | bc -l) )); then
        echo "  TAG: $filename (confidence: $confidence)" >&2
        echo "       Reason: $reason" >&2

        # Add needs-review tag if not in dry-run mode
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! grep -q "#needs-review" "$path"; then
                echo "" >> "$path"
                echo "#needs-review" >> "$path"
                echo "<!-- Low confidence classification: $reason -->" >> "$path"
            fi
        fi

        ((tagged++))
        continue
    fi

    # Skip uncertain classifications
    if [[ "$classification" == "uncertain" ]]; then
        echo "  UNCERTAIN: $filename" >&2
        echo "             Reason: $reason" >&2
        ((tagged++))
        continue
    fi

    # Build destination path
    destination="$VAULT_PATH/$classification/$filename"
    destination_dir=$(dirname "$destination")

    # Check if destination directory exists
    if [[ ! -d "$destination_dir" ]]; then
        echo "  ERROR: Destination directory doesn't exist: $destination_dir" >&2
        ((errors++))
        continue
    fi

    # Move file
    echo "  MOVE: $filename" >&2
    echo "        → $classification/" >&2
    echo "        Confidence: $confidence" >&2
    echo "        Reason: $reason" >&2

    if [[ "$DRY_RUN" != "true" ]]; then
        # Check if file already exists at destination
        if [[ -f "$destination" ]]; then
            echo "        WARNING: File already exists at destination, skipping" >&2
            ((errors++))
            continue
        fi

        # Move the file
        if mv "$path" "$destination"; then
            ((moved++))
        else
            echo "        ERROR: Failed to move file" >&2
            ((errors++))
        fi
    else
        ((moved++))
    fi
done

echo "" >&2
echo "=== Summary ===" >&2
echo "Total items: $item_count" >&2
echo "Auto-moved: $moved" >&2
echo "Tagged for review: $tagged" >&2
echo "Errors: $errors" >&2

# Generate summary JSON
summary=$(cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "items_processed": $item_count,
  "auto_moved": $moved,
  "needs_review": $tagged,
  "errors": $errors,
  "dry_run": $DRY_RUN
}
EOF
)

# Save summary
summary_path="$HOME/.claude/homunculus/inbox-gradient-accelerator/last-run.json"
echo "$summary" | jq '.' > "$summary_path"
echo "" >&2
echo "Summary saved to: $summary_path" >&2

# Output summary
echo "$summary" | jq '.'
