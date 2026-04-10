#!/usr/bin/env bash
# detect-drift.sh - Phase 1: Detect documentation drift
# Compares documentation against code reality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

REPOS_ROOT=($(jq -r '.repos_root[]' "$CONFIG_FILE"))
WATCH_FILES=($(jq -r '.watch_files[]' "$CONFIG_FILE"))
IGNORE_REPOS=$(jq -r '.ignore_repos[]' "$CONFIG_FILE" 2>/dev/null || echo "")
STALENESS_DAYS=$(jq -r '.staleness_threshold_days' "$CONFIG_FILE")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")

# Create cache directory
mkdir -p "$CACHE_PATH"

echo "Detecting documentation drift..." >&2
echo "Staleness threshold: $STALENESS_DAYS days" >&2

# Initialize drift results
drift_items="[]"

# Function to check if repo should be ignored
is_ignored() {
    local repo_name="$1"
    while IFS= read -r ignored; do
        [[ "$repo_name" == *"$ignored"* ]] && return 0
    done <<< "$IGNORE_REPOS"
    return 1
}

# Function to check file staleness
check_staleness() {
    local repo_path="$1"
    local doc_file="$2"

    if [[ ! -f "$doc_file" ]]; then
        return
    fi

    # Get last modification time of doc file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        doc_mtime=$(stat -f "%m" "$doc_file")
        threshold_time=$(date -v-${STALENESS_DAYS}d +"%s")
    else
        doc_mtime=$(stat -c "%Y" "$doc_file")
        threshold_time=$(date -d "$STALENESS_DAYS days ago" +"%s")
    fi

    # Get last modification time of code files
    latest_code_mtime=0
    while IFS= read -r -d '' code_file; do
        if [[ "$OSTYPE" == "darwin"* ]]; then
            code_mtime=$(stat -f "%m" "$code_file")
        else
            code_mtime=$(stat -c "%Y" "$code_file")
        fi

        if [[ $code_mtime -gt $latest_code_mtime ]]; then
            latest_code_mtime=$code_mtime
        fi
    done < <(find "$repo_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.go" -o -name "*.py" \) -print0 2>/dev/null)

    # Check if doc is stale
    if [[ $doc_mtime -lt $threshold_time && $latest_code_mtime -gt $doc_mtime ]]; then
        days_stale=$(( (latest_code_mtime - doc_mtime) / 86400 ))

        drift_item=$(cat <<EOF
{
  "repo": "$(basename "$repo_path")",
  "file": "$(basename "$doc_file")",
  "drift_type": "stale",
  "severity": "low",
  "details": "Documentation not updated in $days_stale days while code changed",
  "auto_fixable": false
}
EOF
)
        drift_items=$(echo "$drift_items" | jq ". += [$drift_item]")
    fi
}

# Function to check README tech stack vs package.json
check_readme_techstack() {
    local repo_path="$1"
    local readme="$repo_path/README.md"
    local package_json="$repo_path/package.json"

    if [[ ! -f "$readme" || ! -f "$package_json" ]]; then
        return
    fi

    # Extract dependencies from package.json
    deps=$(jq -r '.dependencies // {} | keys[]' "$package_json" 2>/dev/null | sort)
    dev_deps=$(jq -r '.devDependencies // {} | keys[]' "$package_json" 2>/dev/null | sort)

    # Extract tech stack section from README (heuristic: look for common framework names)
    readme_content=$(cat "$readme")

    # Check for common mismatches
    mismatches=""

    # Check Express vs Fastify
    if echo "$deps" | grep -q "fastify"; then
        if echo "$readme_content" | grep -qi "express"; then
            mismatches="README mentions Express but package.json uses Fastify"
        fi
    fi

    # Check React vs Vue vs Angular
    if echo "$deps" | grep -q "react"; then
        if echo "$readme_content" | grep -Eqi "vue|angular"; then
            mismatches="README mentions Vue/Angular but package.json uses React"
        fi
    fi

    # Report mismatch if found
    if [[ -n "$mismatches" ]]; then
        drift_item=$(cat <<EOF
{
  "repo": "$(basename "$repo_path")",
  "file": "README.md",
  "drift_type": "outdated",
  "severity": "medium",
  "section": "Tech Stack",
  "details": "$mismatches",
  "auto_fixable": true
}
EOF
)
        drift_items=$(echo "$drift_items" | jq ". += [$drift_item]")
    fi
}

# Function to check CLAUDE.md build commands vs package.json scripts
check_claude_commands() {
    local repo_path="$1"
    local claude_md="$repo_path/CLAUDE.md"
    local package_json="$repo_path/package.json"

    if [[ ! -f "$claude_md" || ! -f "$package_json" ]]; then
        return
    fi

    # Get actual scripts from package.json
    scripts=$(jq -r '.scripts // {} | keys[]' "$package_json" 2>/dev/null)

    # Read CLAUDE.md content
    claude_content=$(cat "$claude_md")

    # Check for common build/test commands
    for cmd in "build" "test" "dev" "start"; do
        # Check if script exists in package.json
        if echo "$scripts" | grep -q "^$cmd$"; then
            # Check if CLAUDE.md mentions this command
            if ! echo "$claude_content" | grep -q "npm run $cmd"; then
                drift_item=$(cat <<EOF
{
  "repo": "$(basename "$repo_path")",
  "file": "CLAUDE.md",
  "drift_type": "missing",
  "severity": "low",
  "section": "Build Commands",
  "details": "package.json has 'npm run $cmd' but CLAUDE.md doesn't document it",
  "auto_fixable": true
}
EOF
)
                drift_items=$(echo "$drift_items" | jq ". += [$drift_item]")
            fi
        fi
    done
}

# Function to scan a single repository
scan_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")

    # Skip if not a git repository
    if ! git -C "$repo_path" rev-parse --is-inside-work-tree &>/dev/null; then
        return
    fi

    # Skip if ignored
    if is_ignored "$repo_name"; then
        return
    fi

    echo "  Scanning: $repo_name" >&2

    # Check each watched file pattern
    for pattern in "${WATCH_FILES[@]}"; do
        # Handle glob patterns
        if [[ "$pattern" == *"*"* ]]; then
            # Expand glob in repo
            while IFS= read -r -d '' file; do
                check_staleness "$repo_path" "$file"
            done < <(find "$repo_path" -path "*/$pattern" -type f -print0 2>/dev/null)
        else
            # Direct file match
            file="$repo_path/$pattern"
            if [[ -f "$file" ]]; then
                check_staleness "$repo_path" "$file"
            fi
        fi
    done

    # Run specific drift checks
    check_readme_techstack "$repo_path"
    check_claude_commands "$repo_path"
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

# Generate drift report
drift_count=$(echo "$drift_items" | jq 'length')

drift_report=$(cat <<EOF
{
  "scan_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "repositories_scanned": $total_repos,
  "drift_detected": $drift_count,
  "drift_items": $drift_items
}
EOF
)

# Save report
report_file="$CACHE_PATH/drift-report.json"
echo "$drift_report" | jq '.' > "$report_file"

echo "" >&2
echo "=== Drift Detection Summary ===" >&2
echo "Repositories scanned: $total_repos" >&2
echo "Drift items found: $drift_count" >&2
echo "Report saved: $report_file" >&2

# Output report
echo "$drift_report" | jq '.'

# Exit with error if drift detected (for CI/CD)
[[ $drift_count -gt 0 ]] && exit 1 || exit 0
