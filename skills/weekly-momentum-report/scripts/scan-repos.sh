#!/usr/bin/env bash
# scan-repos.sh - Phase 1: Scan git repositories for activity
# Outputs JSON with commits, branches, uncommitted changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

REPOS_ROOT=($(jq -r '.repos_root[]' "$CONFIG_FILE"))
AUTHOR_NAME=$(jq -r '.author_name' "$CONFIG_FILE")
DAYS_BACK=$(jq -r '.days_back' "$CONFIG_FILE")
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

echo "Scanning repositories since: $SINCE_DATE" >&2
echo "Author filter: $AUTHOR_NAME" >&2

# Initialize results array
results="[]"

# Function to check if repo should be excluded
is_excluded() {
    local repo_name="$1"
    while IFS= read -r excluded; do
        [[ "$repo_name" == *"$excluded"* ]] && return 0
    done <<< "$EXCLUDE_REPOS"
    return 1
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
        echo "  Skipping excluded repo: $repo_name" >&2
        return
    fi

    echo "  Scanning: $repo_name" >&2

    # Get commits since date
    commits=$(git -C "$repo_path" log \
        --since="$SINCE_DATE" \
        --author="$AUTHOR_NAME" \
        --regexp-ignore-case \
        --pretty=format:'{"hash":"%h","date":"%ad","message":"%s"}' \
        --date=short 2>/dev/null | jq -s '.' || echo "[]")

    commit_count=$(echo "$commits" | jq 'length')

    # Get uncommitted changes
    uncommitted=$(git -C "$repo_path" status --short 2>/dev/null | wc -l | tr -d ' ')

    # Get current branch
    current_branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    # Get all branches
    branches=$(git -C "$repo_path" branch -a 2>/dev/null | sed 's/^[* ] //' | jq -R . | jq -s '.' || echo "[]")

    # Get package.json version if exists
    version="null"
    if [[ -f "$repo_path/package.json" ]]; then
        version=$(jq -r '.version // "unknown"' "$repo_path/package.json" 2>/dev/null || echo "null")
        version="\"$version\""
    fi

    # Check for go.mod
    if [[ -f "$repo_path/go.mod" && "$version" == "null" ]]; then
        version="\"go-module\""
    fi

    # Build repo result object
    repo_result=$(cat <<EOF
{
  "name": "$repo_name",
  "path": "$repo_path",
  "commits": $commits,
  "commit_count": $commit_count,
  "uncommitted_changes": $uncommitted,
  "current_branch": "$current_branch",
  "branches": $branches,
  "version": $version
}
EOF
)

    # Add to results if has activity
    if [[ $commit_count -gt 0 || $uncommitted -gt 0 ]]; then
        results=$(echo "$results" | jq ". += [$repo_result]")
    fi
}

# Scan all repositories in each root directory
for root in "${REPOS_ROOT[@]}"; do
    root="${root/#\~/$HOME}"

    if [[ ! -d "$root" ]]; then
        echo "Warning: Repos root not found: $root" >&2
        continue
    fi

    echo "Scanning repos in: $root" >&2

    # Find all directories that are git repositories
    while IFS= read -r -d '' repo_path; do
        scan_repo "$repo_path"
    done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -print0)
done

# Save results to cache
cache_file="$CACHE_PATH/repos-scan.json"
echo "$results" | jq '.' > "$cache_file"

# Generate summary
total_repos=$(echo "$results" | jq 'length')
total_commits=$(echo "$results" | jq '[.[].commit_count] | add // 0')
total_uncommitted=$(echo "$results" | jq '[.[].uncommitted_changes] | add // 0')

echo "" >&2
echo "=== Scan Summary ===" >&2
echo "Active repositories: $total_repos" >&2
echo "Total commits: $total_commits" >&2
echo "Uncommitted changes: $total_uncommitted files" >&2
echo "Results cached: $cache_file" >&2

# Output results
echo "$results" | jq '.'
