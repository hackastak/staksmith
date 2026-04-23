#!/usr/bin/env bash
# scan-vault-tasks.sh - Phase 2: Parse vault tasks
# Extracts completed and pending tasks from project backlogs
#
# Usage:
#   ./scan-vault-tasks.sh                      # Uses days_back from config
#   ./scan-vault-tasks.sh --week 2025-W16      # Specific ISO week
#   ./scan-vault-tasks.sh --since 2025-04-14 --until 2025-04-20  # Date range

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

VAULT_PATH=$(jq -r '.vault_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
DAYS_BACK=$(jq -r '.days_back' "$CONFIG_FILE")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")

# Create cache directory
mkdir -p "$CACHE_PATH"

# Function to calculate ISO week start (Monday) and end (Sunday) dates
calc_week_dates() {
    local week_str="$1"  # Format: YYYY-WXX
    local year="${week_str%-W*}"
    local week="${week_str#*-W}"
    week="${week#0}"  # Remove leading zero

    if [[ "$OSTYPE" == "darwin"* ]]; then
        local jan4=$(date -j -f "%Y-%m-%d" "${year}-01-04" +"%s")
        local jan4_dow=$(date -j -f "%Y-%m-%d" "${year}-01-04" +"%u")
        local week1_monday=$((jan4 - (jan4_dow - 1) * 86400))
        local target_monday=$((week1_monday + (week - 1) * 7 * 86400))
        local target_sunday=$((target_monday + 6 * 86400))

        SINCE_DATE=$(date -j -f "%s" "$target_monday" +"%Y-%m-%d")
        UNTIL_DATE=$(date -j -f "%s" "$target_sunday" +"%Y-%m-%d")
    else
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
    echo "Date range: $SINCE_DATE to $UNTIL_DATE" >&2
elif [[ -n "$SINCE_DATE" || -n "$UNTIL_DATE" ]]; then
    echo "Error: Both --since and --until must be provided together" >&2
    exit 1
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SINCE_DATE=$(date -v-${DAYS_BACK}d +"%Y-%m-%d")
    else
        SINCE_DATE=$(date -d "$DAYS_BACK days ago" +"%Y-%m-%d")
    fi
    UNTIL_DATE=""  # No upper bound for rolling window
fi

if [[ -n "$UNTIL_DATE" ]]; then
    echo "Scanning vault tasks: $SINCE_DATE to $UNTIL_DATE" >&2
else
    echo "Scanning vault tasks since: $SINCE_DATE" >&2
fi
echo "Vault path: $VAULT_PATH" >&2

# Check if vault exists
if [[ ! -d "$VAULT_PATH" ]]; then
    echo "Error: Vault path not found: $VAULT_PATH" >&2
    exit 1
fi

PROJECTS_PATH="$VAULT_PATH/1. Projects"

if [[ ! -d "$PROJECTS_PATH" ]]; then
    echo "Error: Projects directory not found: $PROJECTS_PATH" >&2
    exit 1
fi

# Initialize results
results="{}"

# Function to parse tasks from a file
parse_tasks() {
    local file="$1"
    local project_name="$2"

    if [[ ! -f "$file" ]]; then
        return
    fi

    echo "  Parsing: $project_name" >&2

    # Extract completed tasks with dates
    # Format: - [x] Task description ✅ YYYY-MM-DD
    completed_tasks="[]"
    while IFS= read -r line; do
        # Match completed tasks with date
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[x\][[:space:]](.*)[[:space:]]✅[[:space:]]([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            task_text="${BASH_REMATCH[1]}"
            task_date="${BASH_REMATCH[2]}"

            # Check if date is within range (>= since AND <= until if set)
            local in_range=false
            if [[ "$task_date" > "$SINCE_DATE" || "$task_date" == "$SINCE_DATE" ]]; then
                if [[ -z "$UNTIL_DATE" || "$task_date" < "$UNTIL_DATE" || "$task_date" == "$UNTIL_DATE" ]]; then
                    in_range=true
                fi
            fi
            if [[ "$in_range" == "true" ]]; then
                task_json=$(cat <<EOF
{
  "text": "$(echo "$task_text" | sed 's/"/\\"/g')",
  "completed_date": "$task_date"
}
EOF
)
                completed_tasks=$(echo "$completed_tasks" | jq ". += [$task_json]")
            fi
        fi
    done < "$file"

    # Extract pending tasks
    # Format: - [ ] Task description
    pending_tasks="[]"
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]]\][[:space:]](.*) ]]; then
            task_text="${BASH_REMATCH[1]}"

            # Skip if it has a completion date (malformed completed task)
            if [[ "$task_text" =~ ✅ ]]; then
                continue
            fi

            task_json=$(cat <<EOF
{
  "text": "$(echo "$task_text" | sed 's/"/\\"/g')"
}
EOF
)
            pending_tasks=$(echo "$pending_tasks" | jq ". += [$task_json]")
        fi
    done < "$file"

    completed_count=$(echo "$completed_tasks" | jq 'length')
    pending_count=$(echo "$pending_tasks" | jq 'length')

    # Add to results
    project_result=$(cat <<EOF
{
  "completed": $completed_tasks,
  "pending": $pending_tasks,
  "completed_count": $completed_count,
  "pending_count": $pending_count
}
EOF
)

    results=$(echo "$results" | jq ". += {\"$project_name\": $project_result}")
}

# Scan all project directories
while IFS= read -r -d '' project_dir; do
    project_name=$(basename "$project_dir")

    # Look for Backlog.md or Tasks.md
    if [[ -f "$project_dir/Backlog.md" ]]; then
        parse_tasks "$project_dir/Backlog.md" "$project_name"
    elif [[ -f "$project_dir/Tasks.md" ]]; then
        parse_tasks "$project_dir/Tasks.md" "$project_name"
    fi
done < <(find "$PROJECTS_PATH" -mindepth 1 -maxdepth 1 -type d -print0)

# Save results to cache
cache_file="$CACHE_PATH/tasks-scan.json"
echo "$results" | jq '.' > "$cache_file"

# Generate summary
total_completed=$(echo "$results" | jq '[.[].completed_count] | add // 0')
total_pending=$(echo "$results" | jq '[.[].pending_count] | add // 0')
projects_with_activity=$(echo "$results" | jq '[.[] | select(.completed_count > 0 or .pending_count > 0)] | length')

echo "" >&2
echo "=== Scan Summary ===" >&2
echo "Projects with activity: $projects_with_activity" >&2
echo "Completed tasks: $total_completed" >&2
echo "Pending tasks: $total_pending" >&2
echo "Results cached: $cache_file" >&2

# Output results
echo "$results" | jq '.'
