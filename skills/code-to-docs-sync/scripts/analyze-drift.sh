#!/usr/bin/env bash
# analyze-drift.sh - Phase 2: AI analysis of detected drift
# Proposes specific fixes for each drift item

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
REPOS_ROOT=($(jq -r '.repos_root[]' "$CONFIG_FILE"))

# Check for drift report
DRIFT_REPORT="$CACHE_PATH/drift-report.json"

if [[ ! -f "$DRIFT_REPORT" ]]; then
    echo "Error: No drift report found. Run detect-drift.sh first." >&2
    exit 1
fi

# Load drift report
drift_data=$(cat "$DRIFT_REPORT")
drift_count=$(echo "$drift_data" | jq '.drift_detected')

if [[ $drift_count -eq 0 ]]; then
    echo "No drift detected. Nothing to analyze." >&2
    exit 0
fi

echo "Analyzing $drift_count drift items..." >&2

# Initialize analysis results
analysis_results="[]"

# Function to find repo path
find_repo_path() {
    local repo_name="$1"

    for root in "${REPOS_ROOT[@]}"; do
        root="${root/#\~/$HOME}"
        local candidate="$root/$repo_name"

        if [[ -d "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

# Analyze each drift item
for i in $(seq 0 $((drift_count - 1))); do
    drift_item=$(echo "$drift_data" | jq ".drift_items[$i]")
    repo=$(echo "$drift_item" | jq -r '.repo')
    file=$(echo "$drift_item" | jq -r '.file')
    drift_type=$(echo "$drift_item" | jq -r '.drift_type')
    details=$(echo "$drift_item" | jq -r '.details')

    echo "  Analyzing: $repo/$file ($drift_type)" >&2

    # Find repo path
    repo_path=$(find_repo_path "$repo")
    if [[ -z "$repo_path" ]]; then
        echo "    Warning: Repo not found: $repo" >&2
        continue
    fi

    file_path="$repo_path/$file"
    if [[ ! -f "$file_path" ]]; then
        echo "    Warning: File not found: $file_path" >&2
        continue
    fi

    # Read current file content
    current_content=$(cat "$file_path")

    # Generate analysis based on drift type
    proposed_fix=""
    rationale=""

    case "$drift_type" in
        "stale")
            rationale="File has not been updated recently. Manual review recommended."
            proposed_fix="<!-- Manual review needed -->"
            ;;

        "outdated")
            # Extract details for specific fix
            if [[ "$details" == *"Express"*"Fastify"* ]]; then
                rationale="README mentions Express but package.json uses Fastify. Update framework reference."
                proposed_fix=$(echo "$current_content" | sed 's/Express\.js/Fastify/g' | sed 's/Express/Fastify/g')
            else
                rationale="Documentation is outdated. $details"
                proposed_fix="<!-- Specific fix to be determined by AI -->"
            fi
            ;;

        "missing")
            rationale="Documentation is missing information that exists in code. $details"
            proposed_fix="<!-- Add missing documentation -->"
            ;;

        *)
            rationale="Unknown drift type: $drift_type"
            proposed_fix="<!-- Manual review needed -->"
            ;;
    esac

    # Build analysis result
    analysis=$(cat <<EOF
{
  "repo": "$repo",
  "file": "$file",
  "file_path": "$file_path",
  "drift_type": "$drift_type",
  "current_content": $(echo "$current_content" | jq -Rs .),
  "proposed_content": $(echo "$proposed_fix" | jq -Rs .),
  "rationale": "$rationale",
  "auto_fixable": $(echo "$drift_item" | jq '.auto_fixable')
}
EOF
)

    analysis_results=$(echo "$analysis_results" | jq ". += [$analysis]")
done

# Save analysis results
analysis_file="$CACHE_PATH/drift-analysis.json"
echo "$analysis_results" | jq '.' > "$analysis_file"

analyzed_count=$(echo "$analysis_results" | jq 'length')
auto_fixable_count=$(echo "$analysis_results" | jq '[.[] | select(.auto_fixable == true)] | length')

echo "" >&2
echo "=== Analysis Summary ===" >&2
echo "Items analyzed: $analyzed_count" >&2
echo "Auto-fixable: $auto_fixable_count" >&2
echo "Analysis saved: $analysis_file" >&2

# Output analysis
echo "$analysis_results" | jq '.'
