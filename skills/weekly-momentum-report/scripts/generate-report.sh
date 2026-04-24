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

# Calculate metrics
total_commits=$(echo "$repos_data" | jq '[.[].commit_count] | add // 0')
active_repos=$(echo "$repos_data" | jq '[.[] | select(.commit_count > 0)] | length')
total_repos=$(echo "$repos_data" | jq 'length')
total_completed=$(echo "$tasks_data" | jq '[.[].completed_count] | add // 0')
total_pending=$(echo "$tasks_data" | jq '[.[].pending_count] | add // 0')

# Get list of projects with activity
active_projects=$(echo "$tasks_data" | jq -r '
  to_entries
  | map(select(.value.completed_count > 0 or .value.pending_count > 0))
  | map(.key)
  | join(", ")
')

# Generate report content
cat > "$REPORT_FILE" <<EOF
# $WEEK_ID - Weekly Momentum Report

Generated: $(date +"%Y-%m-%d %H:%M")${DATE_RANGE_STR:+
Date Range: ${SINCE_DATE} to ${UNTIL_DATE}}

---

## Highlights
<!-- Top 3-4 accomplishments for the week. Focus on shipped features, milestones reached, and significant progress. -->

-
-
-

## Summary
<!-- Narrative breakdown by project area. Describe what was worked on, decisions made, and progress achieved. -->

EOF

# Add project sections based on active projects
echo "$tasks_data" | jq -r '
  to_entries
  | map(select(.value.completed_count > 0 or .value.pending_count > 0))
  | sort_by(.key)
  | .[]
  | "**\(.key)**: \n"
' >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

## Learning & New Ideas
<!-- New knowledge, insights, technologies explored, or ideas that emerged this week. -->

-

## Blockers & Challenges
<!-- Issues faced, platform problems, architectural concerns, or anything that slowed progress. -->

-

## Metrics
- **Commits**: $total_commits across $active_repos active repos
- **Tasks completed**: $total_completed
- **Active projects**: $active_projects

---

## Changelog

EOF

# List commits per repository (only repos with commits)
echo "$repos_data" | jq -r '
  .[]
  | select(.commit_count > 0)
  | "### \(.name)\n" +
    (.commits | map("- \(.message) (\(.date))") | join("\n")) +
    "\n"
' >> "$REPORT_FILE"

# Add SAP repos section placeholder
cat >> "$REPORT_FILE" <<EOF
---
### SAP Repos (run commands to populate)
#### oms-joule
\`\`\`shell
git log --author="Hunter Wiginton" --since="$SINCE_DATE" --until="$UNTIL_DATE" --pretty=format:"- [%s](https://github.tools.sap/OMS/oms-joule/commits/%H) (%ad)" --date=format:"%Y-%m-%d %H:%M" | pbcopy
\`\`\`
#### omf-joule
\`\`\`shell
git log --author="Hunter Wiginton" --since="$SINCE_DATE" --until="$UNTIL_DATE" --pretty=format:"- [%s](https://github.tools.sap/OMS/omf-joule/commits/%H) (%ad)" --date=format:"%Y-%m-%d %H:%M" | pbcopy
\`\`\`
#### oms-knowledge-graph-models
\`\`\`shell
git log --author="Hunter Wiginton" --since="$SINCE_DATE" --until="$UNTIL_DATE" --pretty=format:"- [%s](https://github.tools.sap/OMS/oms-knowledge-graph-models/commits/%H) (%ad)" --date=format:"%Y-%m-%d %H:%M" | pbcopy
\`\`\`
#### oms-knowledge-graph-scripts
\`\`\`shell
git log --author="Hunter Wiginton" --since="$SINCE_DATE" --until="$UNTIL_DATE" --pretty=format:"- [%s](https://github.tools.sap/OMS/oms-knowledge-graph-scripts/commits/%H) (%ad)" --date=format:"%Y-%m-%d %H:%M" | pbcopy
\`\`\`
#### oms-knowledge-graph-service
\`\`\`shell
git log --author="Hunter Wiginton" --since="$SINCE_DATE" --until="$UNTIL_DATE" --pretty=format:"- [%s](https://github.tools.sap/OMS/oms-knowledge-graph-service/commits/%H) (%ad)" --date=format:"%Y-%m-%d %H:%M" | pbcopy
\`\`\`

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
    "tasks_pending": $total_pending
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
