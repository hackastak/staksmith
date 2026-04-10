#!/usr/bin/env bash
# sync-docs.sh - Phase 3: Apply documentation fixes
# Executes approved changes to sync docs with code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
AUTO_COMMIT=$(jq -r '.auto_commit' "$CONFIG_FILE")

# Check for analysis results
ANALYSIS_FILE="$CACHE_PATH/drift-analysis.json"

if [[ ! -f "$ANALYSIS_FILE" ]]; then
    echo "Error: No analysis found. Run analyze-drift.sh first." >&2
    exit 1
fi

# Load analysis results
analysis_data=$(cat "$ANALYSIS_FILE")
item_count=$(echo "$analysis_data" | jq 'length')

if [[ $item_count -eq 0 ]]; then
    echo "No drift items to sync." >&2
    exit 0
fi

echo "Syncing $item_count documentation items..." >&2
echo "Auto-commit: $AUTO_COMMIT" >&2
echo "" >&2

# Initialize counters
applied=0
skipped=0
errors=0

# Process each analysis item
for i in $(seq 0 $((item_count - 1))); do
    item=$(echo "$analysis_data" | jq ".[$i]")
    repo=$(echo "$item" | jq -r '.repo')
    file=$(echo "$item" | jq -r '.file')
    file_path=$(echo "$item" | jq -r '.file_path')
    drift_type=$(echo "$item" | jq -r '.drift_type')
    proposed_content=$(echo "$item" | jq -r '.proposed_content')
    rationale=$(echo "$item" | jq -r '.rationale')
    auto_fixable=$(echo "$item" | jq -r '.auto_fixable')

    echo "[$((i + 1))/$item_count] $repo/$file" >&2
    echo "  Type: $drift_type" >&2
    echo "  Rationale: $rationale" >&2

    # Skip if not auto-fixable
    if [[ "$auto_fixable" != "true" ]]; then
        echo "  Status: SKIPPED (manual review required)" >&2
        ((skipped++))
        continue
    fi

    # Skip if proposed content is a placeholder comment
    if [[ "$proposed_content" == *"Manual review"* || "$proposed_content" == *"to be determined"* ]]; then
        echo "  Status: SKIPPED (needs AI analysis)" >&2
        ((skipped++))
        continue
    fi

    # Check if file exists
    if [[ ! -f "$file_path" ]]; then
        echo "  Status: ERROR (file not found)" >&2
        ((errors++))
        continue
    fi

    # Create backup
    backup_file="$file_path.backup.$(date +%s)"
    cp "$file_path" "$backup_file"

    # Apply fix
    echo "  Status: APPLYING FIX" >&2

    # Write proposed content
    echo "$proposed_content" > "$file_path"

    # Verify file was written
    if [[ ! -s "$file_path" ]]; then
        echo "  Status: ERROR (file write failed, restoring backup)" >&2
        mv "$backup_file" "$file_path"
        ((errors++))
        continue
    fi

    # Remove backup if successful
    rm "$backup_file"

    echo "  Status: ✓ APPLIED" >&2
    ((applied++))

    # Git commit if auto-commit enabled
    if [[ "$AUTO_COMMIT" == "true" ]]; then
        repo_path=$(dirname "$file_path")

        # Navigate to repo and commit
        (
            cd "$repo_path"

            if git rev-parse --is-inside-work-tree &>/dev/null; then
                git add "$file"

                commit_message="docs: sync $file with codebase

$rationale

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

                if git commit -m "$commit_message" 2>/dev/null; then
                    echo "  Status: ✓ COMMITTED" >&2
                else
                    echo "  Status: WARNING (commit failed)" >&2
                fi
            fi
        )
    fi
done

echo "" >&2
echo "=== Sync Summary ===" >&2
echo "Total items: $item_count" >&2
echo "Applied: $applied" >&2
echo "Skipped: $skipped" >&2
echo "Errors: $errors" >&2

# Generate summary
summary=$(cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "total_items": $item_count,
  "applied": $applied,
  "skipped": $skipped,
  "errors": $errors,
  "auto_committed": $AUTO_COMMIT
}
EOF
)

# Save summary
summary_file="$CACHE_PATH/sync-summary.json"
echo "$summary" | jq '.' > "$summary_file"

echo "" >&2
echo "Summary saved: $summary_file" >&2

# Output summary
echo "$summary" | jq '.'
