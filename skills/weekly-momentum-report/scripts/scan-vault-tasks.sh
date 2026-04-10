#!/usr/bin/env bash
# scan-vault-tasks.sh - Phase 2: Parse vault tasks
# Extracts completed and pending tasks from project backlogs

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

# Calculate date threshold
if [[ "$OSTYPE" == "darwin"* ]]; then
    SINCE_DATE=$(date -v-${DAYS_BACK}d +"%Y-%m-%d")
else
    SINCE_DATE=$(date -d "$DAYS_BACK days ago" +"%Y-%m-%d")
fi

echo "Scanning vault tasks since: $SINCE_DATE" >&2
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

            # Check if date is within range
            if [[ "$task_date" > "$SINCE_DATE" || "$task_date" == "$SINCE_DATE" ]]; then
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
