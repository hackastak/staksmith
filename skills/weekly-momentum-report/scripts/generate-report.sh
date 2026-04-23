#!/usr/bin/env bash
# generate-report.sh - Phase 3: Generate weekly momentum report
# Synthesizes repo and task data into formatted markdown
#
# Usage:
#   ./generate-report.sh                      # Uses current week
#   ./generate-report.sh --week 2025-W16      # Specific week ID
#   ./generate-report.sh --week 2025-W16 --since 2025-04-14 --until 2025-04-20

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

VAULT_PATH=$(jq -r '.vault_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")

# Parse command line arguments
WEEK_ARG=""
SINCE_DATE=""
UNTIL_DATE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --week)
            WEEK_ARG="$2"
            shift 2
            ;;
        --since)
            SINCE_DATE="$2"
            shift 2
            ;;
        --until)
            UNTIL_DATE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--week YYYY-WXX] [--since YYYY-MM-DD --until YYYY-MM-DD]" >&2
            exit 1
            ;;
    esac
done

# Check for cache files
REPOS_CACHE="$CACHE_PATH/repos-scan.json"
TASKS_CACHE="$CACHE_PATH/tasks-scan.json"

if [[ ! -f "$REPOS_CACHE" ]]; then
    echo "Error: Repos cache not found. Run scan-repos.sh first." >&2
    exit 1
fi

if [[ ! -f "$TASKS_CACHE" ]]; then
    echo "Error: Tasks cache not found. Run scan-vault-tasks.sh first." >&2
    exit 1
fi

# Load cached data
repos_data=$(cat "$REPOS_CACHE")
tasks_data=$(cat "$TASKS_CACHE")

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

# Calculate week ID
if [[ -n "$WEEK_ARG" ]]; then
    # Normalize week format
    WEEK_ARG=$(normalize_week "$WEEK_ARG")
    if [[ -z "$WEEK_ARG" ]]; then
        echo "Error: Invalid week format. Use YYYY-WXX, WXX, or just XX (e.g., 2025-W16, W16, 16)" >&2
        exit 1
    fi
    WEEK_ID="$WEEK_ARG"
    YEAR="${WEEK_ID%-W*}"
else
    # Calculate current week
    if [[ "$OSTYPE" == "darwin"* ]]; then
        YEAR=$(date +"%Y")
        WEEK=$(date +"%V")
    else
        YEAR=$(date +"%G")
        WEEK=$(date +"%V")
    fi
    WEEK_ID="$YEAR-W$WEEK"
fi

# Build date range string for report
DATE_RANGE_STR=""
if [[ -n "$SINCE_DATE" && -n "$UNTIL_DATE" ]]; then
    DATE_RANGE_STR=" ($SINCE_DATE to $UNTIL_DATE)"
fi

echo "Generating report for: $WEEK_ID" >&2

# Create weekly directory if needed
WEEKLY_DIR="$VAULT_PATH/_Weekly/$YEAR"
mkdir -p "$WEEKLY_DIR"

REPORT_FILE="$WEEKLY_DIR/$WEEK_ID.md"

# Generate report content
cat > "$REPORT_FILE" <<EOF
# $WEEK_ID - Weekly Review

Generated: $(date +"%Y-%m-%d %H:%M")${DATE_RANGE_STR:+
Date Range: ${SINCE_DATE} to ${UNTIL_DATE}}

## Highlights

EOF

# Extract top accomplishments from completed tasks
echo "$(echo "$tasks_data" | jq -r '
  to_entries
  | map(select(.value.completed_count > 0))
  | sort_by(.value.completed_count)
  | reverse
  | .[0:3]
  | .[]
  | "- ✅ \(.key): \(.value.completed_count) tasks completed"
')" >> "$REPORT_FILE"

# Add repo highlights
total_commits=$(echo "$repos_data" | jq '[.[].commit_count] | add // 0')
active_repos=$(echo "$repos_data" | jq 'length')

cat >> "$REPORT_FILE" <<EOF

- 🚀 $total_commits commits across $active_repos active repositories

## Commits by Repository

EOF

# List commits per repository
echo "$repos_data" | jq -r '
  .[]
  | select(.commit_count > 0)
  | "### \(.name) (\(.commit_count) commits)\n\n" +
    (.commits | map("- \(.message)") | join("\n")) +
    "\n"
' >> "$REPORT_FILE"

# Add vault tasks section
cat >> "$REPORT_FILE" <<EOF

## Vault Tasks Completed

EOF

# List completed tasks by project
echo "$tasks_data" | jq -r '
  to_entries
  | map(select(.value.completed_count > 0))
  | sort_by(.key)
  | .[]
  | "### \(.key)\n\n" +
    (.value.completed | map("- [x] \(.text) ✅ \(.completed_date)") | join("\n")) +
    "\n"
' >> "$REPORT_FILE"

# Add pending tasks section
cat >> "$REPORT_FILE" <<EOF

## Pending Tasks

EOF

echo "$tasks_data" | jq -r '
  to_entries
  | map(select(.value.pending_count > 0))
  | sort_by(.key)
  | .[]
  | "### \(.key)\n\n" +
    (.value.pending[0:5] | map("- [ ] \(.text)") | join("\n")) +
    (if .value.pending_count > 5 then "\n- ... and \(.value.pending_count - 5) more" else "" end) +
    "\n"
' >> "$REPORT_FILE"

# Add uncommitted changes section if any
uncommitted_repos=$(echo "$repos_data" | jq '[.[] | select(.uncommitted_changes > 0)]')
uncommitted_count=$(echo "$uncommitted_repos" | jq 'length')

if [[ $uncommitted_count -gt 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF

## Uncommitted Changes

EOF

    echo "$uncommitted_repos" | jq -r '
      .[]
      | "### \(.name)\n- \(.uncommitted_changes) uncommitted files\n- Current branch: \(.current_branch)\n"
    ' >> "$REPORT_FILE"
fi

# Add metrics section
total_completed=$(echo "$tasks_data" | jq '[.[].completed_count] | add // 0')
total_pending=$(echo "$tasks_data" | jq '[.[].pending_count] | add // 0')
total_uncommitted=$(echo "$repos_data" | jq '[.[].uncommitted_changes] | add // 0')

cat >> "$REPORT_FILE" <<EOF

## Metrics

- **Total commits**: $total_commits across $active_repos repositories
- **Tasks completed**: $total_completed
- **Pending tasks**: $total_pending
- **Active branches**: $(echo "$repos_data" | jq '[.[].branches | length] | add // 0')
- **Uncommitted changes**: $total_uncommitted files

## Next Week Priorities

<!-- AI-generated suggestions would go here -->
<!-- User can manually add priorities -->

## Notes

<!-- Additional observations, blockers, insights -->

---

*Generated by Weekly Momentum Report skill*
EOF

# Save report metadata to cache
report_metadata=$(cat <<EOF
{
  "week_id": "$WEEK_ID",
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "report_path": "$REPORT_FILE",
  "metrics": {
    "total_commits": $total_commits,
    "active_repos": $active_repos,
    "tasks_completed": $total_completed,
    "tasks_pending": $total_pending,
    "uncommitted_files": $total_uncommitted
  }
}
EOF
)

echo "$report_metadata" | jq '.' > "$CACHE_PATH/last-report.json"

# Output summary
echo "" >&2
echo "=== Report Generated ===" >&2
echo "Week: $WEEK_ID" >&2
echo "File: $REPORT_FILE" >&2
echo "Commits: $total_commits" >&2
echo "Tasks completed: $total_completed" >&2
echo "" >&2

# Output report path
echo "$REPORT_FILE"
