#!/usr/bin/env bash
# scan-vault-projects.sh - Phase 1: Map vault projects to code repositories
# Outputs JSON with project-to-repo mappings

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

VAULT_PATH=$(jq -r '.vault_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
REPOS_ROOT=($(jq -r '.repos_root[]' "$CONFIG_FILE"))
AUTO_MATCH_THRESHOLD=$(jq -r '.auto_match_threshold' "$CONFIG_FILE")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
MANUAL_MAPPINGS=$(jq -r '.manual_mappings' "$CONFIG_FILE")

# Create cache directory
mkdir -p "$CACHE_PATH"

echo "Scanning vault projects..." >&2
echo "Vault path: $VAULT_PATH" >&2

# Check vault exists
if [[ ! -d "$VAULT_PATH" ]]; then
    echo "Error: Vault projects path not found: $VAULT_PATH" >&2
    exit 1
fi

# Initialize mappings
mappings="{}"

# Function to normalize name for comparison
normalize_name() {
    local name="$1"
    # Convert to lowercase, replace spaces/underscores with hyphens
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' | sed 's/--*/-/g'
}

# Function to calculate similarity score (simple heuristic)
similarity_score() {
    local str1="$1"
    local str2="$2"

    # Normalize both strings
    local norm1=$(normalize_name "$str1")
    local norm2=$(normalize_name "$str2")

    # Exact match
    if [[ "$norm1" == "$norm2" ]]; then
        echo "1.0"
        return
    fi

    # Check if one contains the other
    if [[ "$norm1" == *"$norm2"* || "$norm2" == *"$norm1"* ]]; then
        echo "0.9"
        return
    fi

    # Check common substrings (simplified Levenshtein)
    local len1=${#norm1}
    local len2=${#norm2}
    local common=0

    # Count matching characters in sequence
    for ((i=0; i<len1 && i<len2; i++)); do
        if [[ "${norm1:$i:1}" == "${norm2:$i:1}" ]]; then
            ((common++))
        fi
    done

    local max_len=$((len1 > len2 ? len1 : len2))
    if [[ $max_len -eq 0 ]]; then
        echo "0.0"
        return
    fi

    # Calculate score
    score=$(echo "scale=2; $common / $max_len" | bc)
    echo "$score"
}

# Function to find best matching repository
find_matching_repo() {
    local project_name="$1"
    local best_repo=""
    local best_score=0.0
    local best_path=""

    echo "  Matching: $project_name" >&2

    # Check manual mappings first
    manual_match=$(echo "$MANUAL_MAPPINGS" | jq -r ".[\"$project_name\"] // empty")
    if [[ -n "$manual_match" ]]; then
        # Find this repo in repos_root
        for root in "${REPOS_ROOT[@]}"; do
            root="${root/#\~/$HOME}"
            candidate="$root/$manual_match"

            if [[ -d "$candidate" ]]; then
                echo "    Manual mapping → $manual_match (1.0)" >&2
                echo "$candidate|1.0|manual"
                return
            fi
        done
    fi

    # Auto-match by name similarity
    for root in "${REPOS_ROOT[@]}"; do
        root="${root/#\~/$HOME}"

        if [[ ! -d "$root" ]]; then
            continue
        fi

        while IFS= read -r -d '' repo_path; do
            repo_name=$(basename "$repo_path")

            # Skip if not a git repo
            if ! git -C "$repo_path" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
                continue
            fi

            # Calculate similarity
            score=$(similarity_score "$project_name" "$repo_name")

            # Update best match if higher score
            if (( $(echo "$score > $best_score" | bc -l) )); then
                best_score=$score
                best_repo=$repo_name
                best_path=$repo_path
            fi
        done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -print0)
    done

    # Return best match if above threshold
    if [[ -n "$best_repo" ]]; then
        echo "    Auto-match → $best_repo ($best_score)" >&2
        echo "$best_path|$best_score|fuzzy_name"
    else
        echo "    No match found" >&2
        echo "||0.0|none"
    fi
}

# Scan all vault projects
while IFS= read -r -d '' project_dir; do
    project_name=$(basename "$project_dir")

    echo "Scanning: $project_name" >&2

    # Find matching repo
    match_result=$(find_matching_repo "$project_name")

    IFS='|' read -r repo_path confidence match_method <<< "$match_result"

    # Skip if no match or below threshold
    if [[ -z "$repo_path" || $(echo "$confidence < $AUTO_MATCH_THRESHOLD" | bc -l) -eq 1 ]]; then
        echo "  Skipped (confidence $confidence < threshold $AUTO_MATCH_THRESHOLD)" >&2
        continue
    fi

    # Check for vault project files
    has_backlog=false
    has_architecture=false

    [[ -f "$project_dir/Backlog.md" ]] && has_backlog=true
    [[ -f "$project_dir/Architecture.md" ]] && has_architecture=true

    # Build mapping
    mapping=$(cat <<EOF
{
  "vault_path": "$project_dir",
  "repo_path": "$repo_path",
  "confidence": $confidence,
  "match_method": "$match_method",
  "has_backlog": $has_backlog,
  "has_architecture": $has_architecture
}
EOF
)

    mappings=$(echo "$mappings" | jq ". += {\"$project_name\": $mapping}")
done < <(find "$VAULT_PATH" -mindepth 1 -maxdepth 1 -type d -print0)

# Save mappings
mappings_file="$CACHE_PATH/project-mappings.json"
echo "$mappings" | jq '.' > "$mappings_file"

# Generate summary
matched_count=$(echo "$mappings" | jq '. | length')

echo "" >&2
echo "=== Scan Summary ===" >&2
echo "Projects matched: $matched_count" >&2
echo "Mappings saved: $mappings_file" >&2

# Output mappings
echo "$mappings" | jq '.'
