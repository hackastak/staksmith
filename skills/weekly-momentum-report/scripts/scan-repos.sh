#!/usr/bin/env bash
# scan-repos.sh - Phase 1: Scan git repositories for activity
# Outputs JSON with commits, branches, uncommitted changes
#
# Usage:
#   ./scan-repos.sh                      # Uses days_back from config
#   ./scan-repos.sh --week 2025-W16      # Specific ISO week
#   ./scan-repos.sh --since 2025-04-14 --until 2025-04-20  # Date range

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

# Function to calculate ISO week start (Monday) and end (Sunday) dates
# ISO 8601: Week 1 is the week containing the first Thursday of the year
calc_week_dates() {
    local week_str="$1"  # Format: YYYY-WXX
    local year="${week_str%-W*}"
    local week="${week_str#*-W}"
    week="${week#0}"  # Remove leading zero

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Find Jan 4 (always in week 1), get its weekday, calculate week 1 Monday
        local jan4=$(date -j -f "%Y-%m-%d" "${year}-01-04" +"%s")
        local jan4_dow=$(date -j -f "%Y-%m-%d" "${year}-01-04" +"%u")  # 1=Mon, 7=Sun
        local week1_monday=$((jan4 - (jan4_dow - 1) * 86400))

        # Calculate target week's Monday (add (week-1) * 7 days)
        local target_monday=$((week1_monday + (week - 1) * 7 * 86400))
        local target_sunday=$((target_monday + 6 * 86400))

        SINCE_DATE=$(date -j -f "%s" "$target_monday" +"%Y-%m-%d")
        UNTIL_DATE=$(date -j -f "%s" "$target_sunday" +"%Y-%m-%d")
    else
        # Linux: Use date's ISO week support
        local jan4=$(date -d "${year}-01-04" +"%s")
        local jan4_dow=$(date -d "${year}-01-04" +"%u")
        local week1_monday=$((jan4 - (jan4_dow - 1) * 86400))

        local target_monday=$((week1_monday + (week - 1) * 7 * 86400))
        local target_sunday=$((target_monday + 6 * 86400))

        SINCE_DATE=$(date -d "@$target_monday" +"%Y-%m-%d")
        UNTIL_DATE=$(date -d "@$target_sunday" +"%Y-%m-%d")
    fi
}

# Parse command line arguments
SINCE_DATE=""
UNTIL_DATE=""
WEEK_ARG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --since)
            SINCE_DATE="$2"
            shift 2
            ;;
        --until)
            UNTIL_DATE="$2"
            shift 2
            ;;
        --week)
            WEEK_ARG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--week YYYY-WXX] [--since YYYY-MM-DD --until YYYY-MM-DD]" >&2
            exit 1
            ;;
    esac
done

# Function to normalize week input to YYYY-WXX format
normalize_week() {
    local input="$1"
    local current_year=$(date +"%Y")

    # Convert to uppercase for consistent matching
    input=$(echo "$input" | tr '[:lower:]' '[:upper:]')

    if [[ "$input" =~ ^[0-9]{4}-W[0-9]{2}$ ]]; then
        # Already full format: 2025-W16
        echo "$input"
    elif [[ "$input" =~ ^W([0-9]{1,2})$ ]]; then
        # Format: W16 or W5
        local week="${BASH_REMATCH[1]}"
        printf "%s-W%02d" "$current_year" "$week"
    elif [[ "$input" =~ ^([0-9]{1,2})$ ]]; then
        # Format: 16 or 5 (just the week number)
        local week="${BASH_REMATCH[1]}"
        printf "%s-W%02d" "$current_year" "$week"
    else
        echo ""  # Invalid format
    fi
}

# Calculate dates based on arguments
if [[ -n "$WEEK_ARG" ]]; then
    # Normalize week format
    WEEK_ARG=$(normalize_week "$WEEK_ARG")
    if [[ -z "$WEEK_ARG" ]]; then
        echo "Error: Invalid week format. Use YYYY-WXX, WXX, or just XX (e.g., 2025-W16, W16, 16)" >&2
        exit 1
    fi
    calc_week_dates "$WEEK_ARG"
    echo "Week $WEEK_ARG: $SINCE_DATE to $UNTIL_DATE" >&2
elif [[ -n "$SINCE_DATE" && -n "$UNTIL_DATE" ]]; then
    # Use provided date range
    echo "Date range: $SINCE_DATE to $UNTIL_DATE" >&2
elif [[ -n "$SINCE_DATE" || -n "$UNTIL_DATE" ]]; then
    echo "Error: Both --since and --until must be provided together" >&2
    exit 1
else
    # Default: use days_back from config
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SINCE_DATE=$(date -v-${DAYS_BACK}d +"%Y-%m-%d")
    else
        SINCE_DATE=$(date -d "$DAYS_BACK days ago" +"%Y-%m-%d")
    fi
    UNTIL_DATE=""  # No upper bound for rolling window
fi

if [[ -n "$UNTIL_DATE" ]]; then
    echo "Scanning repositories: $SINCE_DATE to $UNTIL_DATE" >&2
else
    echo "Scanning repositories since: $SINCE_DATE" >&2
fi
echo "Author filter: $AUTHOR_NAME" >&2

# Initialize results array
results="[]"

# Function to check if repo should be excluded
is_excluded() {
    local repo_name="$1"
    [[ -z "$EXCLUDE_REPOS" ]] && return 1  # Nothing excluded if list is empty
    while IFS= read -r excluded; do
        [[ -n "$excluded" && "$repo_name" == *"$excluded"* ]] && return 0
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

    # Get commits in date range (use -sc for compact JSON)
    # Handle repos with no commits yet (git log returns error)
    local git_log_args=(
        -C "$repo_path" log
        --since="$SINCE_DATE"
        --author="$AUTHOR_NAME"
        --regexp-ignore-case
        --pretty=format:'{"hash":"%h","date":"%ad","message":"%s"}'
        --date=short
    )
    # Add --until if specified (for specific week/date range)
    if [[ -n "$UNTIL_DATE" ]]; then
        git_log_args+=(--until="$UNTIL_DATE 23:59:59")
    fi
    git_log_output=$(git "${git_log_args[@]}" 2>/dev/null) || git_log_output=""

    if [[ -n "$git_log_output" ]]; then
        commits=$(echo "$git_log_output" | jq -sc '.' 2>/dev/null)
    else
        commits="[]"
    fi
    [[ -z "$commits" ]] && commits="[]"

    commit_count=$(echo "$commits" | jq 'length' 2>/dev/null)
    [[ -z "$commit_count" ]] && commit_count=0

    # Get uncommitted changes
    uncommitted=$(git -C "$repo_path" status --short 2>/dev/null | wc -l | tr -d ' ')

    # Get current branch
    current_branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    # Get all branches (use -c for compact JSON)
    branches=$(git -C "$repo_path" branch -a 2>/dev/null | sed 's/^[* ] //' | jq -R . | jq -sc '.' 2>/dev/null)
    [[ -z "$branches" ]] && branches="[]"

    # Get package.json version if exists (as proper JSON)
    version="null"
    if [[ -f "$repo_path/package.json" ]]; then
        version=$(jq '.version // null' "$repo_path/package.json" 2>/dev/null || echo "null")
    fi

    # Check for go.mod
    if [[ -f "$repo_path/go.mod" && "$version" == "null" ]]; then
        version='"go-module"'
    fi

    # Build repo result object using jq for safe JSON construction
    repo_result=$(jq -n \
        --arg name "$repo_name" \
        --arg path "$repo_path" \
        --argjson commits "$commits" \
        --argjson commit_count "$commit_count" \
        --argjson uncommitted "$uncommitted" \
        --arg branch "$current_branch" \
        --argjson branches "$branches" \
        --argjson version "$version" \
        '{
            name: $name,
            path: $path,
            commits: $commits,
            commit_count: $commit_count,
            uncommitted_changes: $uncommitted,
            current_branch: $branch,
            branches: $branches,
            version: $version
        }'
    )

    # Add to results if has activity
    if [[ $commit_count -gt 0 || $uncommitted -gt 0 ]]; then
        results=$(echo "$results" | jq --argjson item "$repo_result" '. += [$item]')
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
