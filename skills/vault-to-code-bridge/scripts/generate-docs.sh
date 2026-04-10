#!/usr/bin/env bash
# generate-docs.sh - Phase 2: Generate documentation from vault notes
# Creates CLAUDE.md, ARCHITECTURE.md, updates README

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Parse arguments
TARGET_PROJECT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project)
            TARGET_PROJECT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
DRY_RUN=$(jq -r '.dry_run' "$CONFIG_FILE")
TEMPLATES_PATH=$(jq -r '.templates_path' "$CONFIG_FILE")

# Resolve templates path (relative to skill directory)
if [[ "$TEMPLATES_PATH" == ./* ]]; then
    TEMPLATES_PATH="$SCRIPT_DIR/../${TEMPLATES_PATH#./}"
fi

# Check for mappings
MAPPINGS_FILE="$CACHE_PATH/project-mappings.json"

if [[ ! -f "$MAPPINGS_FILE" ]]; then
    echo "Error: No project mappings found. Run scan-vault-projects.sh first." >&2
    exit 1
fi

# Load mappings
mappings=$(cat "$MAPPINGS_FILE")

# Check templates exist
CLAUDE_TEMPLATE="$TEMPLATES_PATH/CLAUDE.template.md"
ARCH_TEMPLATE="$TEMPLATES_PATH/ARCHITECTURE.template.md"

if [[ ! -f "$CLAUDE_TEMPLATE" ]]; then
    echo "Warning: CLAUDE.template.md not found at $CLAUDE_TEMPLATE" >&2
fi

if [[ ! -f "$ARCH_TEMPLATE" ]]; then
    echo "Warning: ARCHITECTURE.template.md not found at $ARCH_TEMPLATE" >&2
fi

echo "Generating documentation..." >&2
echo "Dry run: $DRY_RUN" >&2

# Initialize counters
generated=0
skipped=0

# Function to extract section from vault note
extract_section() {
    local file="$1"
    local section_name="$2"

    if [[ ! -f "$file" ]]; then
        echo ""
        return
    fi

    # Extract content under ## Section Name until next ## or EOF
    awk -v section="$section_name" '
        /^## / {
            if (found) exit
            if ($0 ~ "^## " section) {
                found = 1
                next
            }
        }
        found { print }
    ' "$file"
}

# Function to generate CLAUDE.md
generate_claude_md() {
    local project_name="$1"
    local vault_path="$2"
    local repo_path="$3"

    echo "  Generating CLAUDE.md..." >&2

    local output_file="$repo_path/CLAUDE.md"

    # Read backlog if exists
    local backlog="$vault_path/Backlog.md"
    local tech_stack=""
    local build_notes=""
    local architecture=""

    if [[ -f "$backlog" ]]; then
        tech_stack=$(extract_section "$backlog" "Tech Stack")
        build_notes=$(extract_section "$backlog" "Build")
        architecture=$(extract_section "$backlog" "Architecture")
    fi

    # Read package.json for additional context
    local package_json="$repo_path/package.json"
    local scripts_section=""

    if [[ -f "$package_json" ]]; then
        # Extract npm scripts
        scripts_section=$(jq -r '.scripts // {} | to_entries | map("- \(.key): \(.value)") | join("\n")' "$package_json" 2>/dev/null || echo "")
    fi

    # Generate content (simplified - AI would enhance this)
    local content=$(cat <<EOF
# CLAUDE.md - Developer Guide

*Generated from vault notes: $project_name*

## Build & Test Commands

$build_notes

### Available NPM Scripts
$scripts_section

## Tech Stack

$tech_stack

## Architecture Overview

$architecture

## Code Conventions

(To be extracted from vault notes)

## Strict Constraints

(To be extracted from vault notes)

---

*Last generated: $(date +"%Y-%m-%d")*
EOF
)

    # Write file
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "    [DRY RUN] Would write: $output_file" >&2
    else
        echo "$content" > "$output_file"
        echo "    ✓ Written: $output_file" >&2
    fi
}

# Function to generate ARCHITECTURE.md
generate_architecture_md() {
    local project_name="$1"
    local vault_path="$2"
    local repo_path="$3"

    local arch_file="$vault_path/Architecture.md"

    # Skip if no architecture notes
    if [[ ! -f "$arch_file" ]]; then
        echo "  Skipping ARCHITECTURE.md (no vault notes)" >&2
        return
    fi

    echo "  Generating ARCHITECTURE.md..." >&2

    local output_file="$repo_path/ARCHITECTURE.md"

    # Read architecture content
    local arch_content=$(cat "$arch_file")

    # Generate content (simplified - AI would structure ADRs)
    local content=$(cat <<EOF
# Architecture - $project_name

*Generated from vault notes*

## System Overview

(To be extracted from vault notes)

## Architecture Decisions

$arch_content

---

*Last generated: $(date +"%Y-%m-%d")*
EOF
)

    # Write file
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "    [DRY RUN] Would write: $output_file" >&2
    else
        echo "$content" > "$output_file"
        echo "    ✓ Written: $output_file" >&2
    fi
}

# Process each project
project_names=($(echo "$mappings" | jq -r 'keys[]'))

for project_name in "${project_names[@]}"; do
    # Skip if target project specified and this isn't it
    if [[ -n "$TARGET_PROJECT" && "$project_name" != "$TARGET_PROJECT" ]]; then
        continue
    fi

    echo "Processing: $project_name" >&2

    vault_path=$(echo "$mappings" | jq -r ".[\"$project_name\"].vault_path")
    repo_path=$(echo "$mappings" | jq -r ".[\"$project_name\"].repo_path")

    # Generate docs
    generate_claude_md "$project_name" "$vault_path" "$repo_path"
    generate_architecture_md "$project_name" "$vault_path" "$repo_path"

    ((generated++))
done

echo "" >&2
echo "=== Generation Summary ===" >&2
echo "Projects processed: $generated" >&2
echo "Dry run: $DRY_RUN" >&2

# Output summary
summary=$(cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "projects_processed": $generated,
  "dry_run": $DRY_RUN
}
EOF
)

echo "$summary" | jq '.'
