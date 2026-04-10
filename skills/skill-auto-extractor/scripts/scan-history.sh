#!/usr/bin/env bash
# scan-history.sh - Phase 1: Scan git history for patterns
# Extracts commit sequences, file changes, and common workflows

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

REPOS_ROOT=($(jq -r '.repos_root[]' "$CONFIG_FILE"))
DAYS_BACK=$(jq -r '.days_back' "$CONFIG_FILE")
AUTHOR_NAME=$(jq -r '.author_name' "$CONFIG_FILE")
EXCLUDE_REPOS=$(jq -r '.exclude_repos[]' "$CONFIG_FILE" 2>/dev/null || echo "")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")

# Create cache directory
mkdir -p "$CACHE_PATH"

# Calculate date threshold
if [[ "$OSTYPE" == "darwin"* ]]; then
    SINCE_DATE=$(date -v-${DAYS_BACK}d +"%Y-%m-%d")
else
    SINCE_DATE=$(date -d "$DAYS_BACK days ago" +"%Y-%m-%d")
fi

echo "Scanning git history since: $SINCE_DATE" >&2
echo "Author filter: $AUTHOR_NAME" >&2

# Initialize results
commit_data="[]"
file_changes="[]"

# Function to check if repo should be excluded
is_excluded() {
    local repo_name="$1"
    while IFS= read -r excluded; do
        [[ "$repo_name" == *"$excluded"* ]] && return 0
    done <<< "$EXCLUDE_REPOS"
    return 1
}

# Function to extract file changes from a commit
extract_file_changes() {
    local repo_path="$1"
    local commit_hash="$2"

    # Get files changed in this commit
    git -C "$repo_path" show --name-only --pretty=format: "$commit_hash" 2>/dev/null | \
        grep -v '^$' | jq -R . | jq -s '.'
}

# Function to scan a single repository
scan_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")

    # Skip if not a git repository
    if ! git -C "$repo_path" rev-parse --is-inside-work-tree &>/dev/null; then
        return
    fi

    # Skip if excluded
    if is_excluded "$repo_name"; then
        return
    fi

    echo "  Scanning: $repo_name" >&2

    # Get commits with details
    while IFS='|' read -r hash date message; do
        [[ -z "$hash" ]] && continue

        # Extract files changed
        files=$(extract_file_changes "$repo_path" "$hash")

        # Check for common pattern indicators in commit message
        pattern_type="general"

        if [[ "$message" =~ (add|install|setup).*(drizzle|prisma|orm) ]]; then
            pattern_type="framework_addition"
        elif [[ "$message" =~ (add|setup|configure).*(ci|github actions|workflow) ]]; then
            pattern_type="config_setup"
        elif [[ "$message" =~ (add|implement).*(auth|authentication) ]]; then
            pattern_type="architecture_pattern"
        fi

        # Build commit record
        commit_record=$(cat <<EOF
{
  "repo": "$repo_name",
  "hash": "$hash",
  "date": "$date",
  "message": "$(echo "$message" | sed 's/"/\\"/g')",
  "files": $files,
  "pattern_type": "$pattern_type"
}
EOF
)

        commit_data=$(echo "$commit_data" | jq ". += [$commit_record]")

        # Track file change patterns
        files_count=$(echo "$files" | jq 'length')
        for ((i=0; i<files_count; i++)); do
            file=$(echo "$files" | jq -r ".[$i]")

            # Create file change record
            file_record=$(cat <<EOF
{
  "file": "$file",
  "repo": "$repo_name",
  "commit": "$hash",
  "message": "$(echo "$message" | sed 's/"/\\"/g')",
  "pattern_type": "$pattern_type"
}
EOF
)
            file_changes=$(echo "$file_changes" | jq ". += [$file_record]")
        done

    done < <(git -C "$repo_path" log \
        --since="$SINCE_DATE" \
        --author="$AUTHOR_NAME" \
        --pretty=format:'%h|%ad|%s' \
        --date=short 2>/dev/null)
}

# Scan all repositories
total_repos=0
for root in "${REPOS_ROOT[@]}"; do
    root="${root/#\~/$HOME}"

    if [[ ! -d "$root" ]]; then
        echo "Warning: Repos root not found: $root" >&2
        continue
    fi

    echo "Scanning repos in: $root" >&2

    while IFS= read -r -d '' repo_path; do
        scan_repo "$repo_path"
        ((total_repos++))
    done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -print0)
done

# Save raw commit data
commits_file="$CACHE_PATH/commits.json"
echo "$commit_data" | jq '.' > "$commits_file"

# Save file changes data
files_file="$CACHE_PATH/file-changes.json"
echo "$file_changes" | jq '.' > "$files_file"

# Generate summary statistics
total_commits=$(echo "$commit_data" | jq 'length')
total_files=$(echo "$file_changes" | jq 'length')
unique_files=$(echo "$file_changes" | jq '[.[] | .file] | unique | length')

echo "" >&2
echo "=== Scan Summary ===" >&2
echo "Repositories scanned: $total_repos" >&2
echo "Commits analyzed: $total_commits" >&2
echo "Files changed: $total_files" >&2
echo "Unique files: $unique_files" >&2
echo "Data cached: $commits_file" >&2

# Generate file frequency analysis
file_frequency=$(echo "$file_changes" | jq '
  group_by(.file) |
  map({
    file: .[0].file,
    frequency: length,
    repos: [.[].repo] | unique,
    pattern_types: [.[].pattern_type] | unique
  }) |
  sort_by(.frequency) |
  reverse
')

freq_file="$CACHE_PATH/file-frequency.json"
echo "$file_frequency" | jq '.' > "$freq_file"

echo "File frequency: $freq_file" >&2

# Output summary
summary=$(cat <<EOF
{
  "scan_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "repositories_scanned": $total_repos,
  "commits_analyzed": $total_commits,
  "files_changed": $total_files,
  "unique_files": $unique_files,
  "commits_file": "$commits_file",
  "file_changes_file": "$files_file",
  "file_frequency_file": "$freq_file"
}
EOF
)

echo "$summary" | jq '.'
