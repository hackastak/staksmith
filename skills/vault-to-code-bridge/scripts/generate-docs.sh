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

# Function to build a Markdown index of existing ADR files
build_adr_index() {
    local adr_dir="$1"
    local found=0 f base title

    if [[ -d "$adr_dir" ]]; then
        for f in "$adr_dir"/[0-9][0-9][0-9][0-9]-*.md; do
            [[ -e "$f" ]] || continue
            found=1
            base=$(basename "$f")
            title=$(grep -m1 '^# ' "$f" | sed 's/^# *//' || true)
            [[ -n "$title" ]] || title="$base"
            echo "- [$title](docs/adr/$base)"
        done
    fi

    [[ "$found" -eq 1 ]] || echo "_No ADRs recorded yet._"
}

# Function to scaffold ADR files into docs/adr/
#
# Append-only by design: an ADR that already exists is NEVER rewritten. Accepted
# decisions are immutable — to change one, write a new ADR that supersedes it.
# See the `adr-standard` skill for the house format and the supersede rule.
generate_adrs() {
    local project_name="$1"
    local vault_path="$2"
    local repo_path="$3"

    local arch_file="$vault_path/Architecture.md"
    [[ -f "$arch_file" ]] || return 0

    if ! grep -qE '^##+ *ADR' "$arch_file"; then
        echo "  No ADR headings in vault notes; skipping docs/adr/" >&2
        return 0
    fi

    echo "  Scaffolding ADRs..." >&2

    local adr_dir="$repo_path/docs/adr"

    # Next number = highest existing + 1. Numbers are never reused, even when an
    # ADR has been superseded or withdrawn.
    local next_num=1 highest
    if [[ -d "$adr_dir" ]]; then
        highest=$(find "$adr_dir" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -exec basename {} \; 2>/dev/null \
            | cut -c1-4 | sort -n | tail -1)
        [[ -n "$highest" ]] && next_num=$((10#$highest + 1))
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Split the vault note into one block per ADR heading
    awk -v out="$tmp_dir" '
        /^##+ *ADR/ {
            n++
            file = sprintf("%s/%03d.block", out, n)
            title = $0
            sub(/^#+ */, "", title)
            print title > (file)
            next
        }
        n { print >> (file) }
    ' "$arch_file"

    local block raw_title clean_title slug num_padded out_file body content
    for block in "$tmp_dir"/*.block; do
        [[ -e "$block" ]] || continue

        raw_title=$(head -1 "$block")
        # Drop any "ADR-001:" prefix from the vault note — numbering is assigned here
        clean_title=$(printf '%s' "$raw_title" | sed -E 's/^ADR[[:space:]_-]*[0-9]*[[:space:]]*[:.-]?[[:space:]]*//')
        [[ -n "$clean_title" ]] || clean_title="$raw_title"

        slug=$(printf '%s' "$clean_title" | tr '[:upper:]' '[:lower:]' \
            | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
        [[ -n "$slug" ]] || continue

        # Immutability guard: an ADR for this decision already exists, leave it alone
        if [[ -d "$adr_dir" ]] && compgen -G "$adr_dir/[0-9][0-9][0-9][0-9]-$slug.md" > /dev/null; then
            echo "    = Exists, left untouched: $slug" >&2
            continue
        fi

        num_padded=$(printf '%04d' "$next_num")
        out_file="$adr_dir/$num_padded-$slug.md"
        body=$(tail -n +2 "$block")

        content=$(cat <<EOF
# ADR-$num_padded: $clean_title

**Status:** Proposed
**Date:** $(date +"%Y-%m-%d")

## Problem Statement

<!-- Raw material from the vault note follows. Shape it into the house sections
     below, then delete this comment. See the \`adr-standard\` skill. -->

$body

## Considered Options

### Option A — <name>

**Pros:**
**Cons:**

### Option B — <name>

**Pros:**
**Cons:**

## Decision

## Consequences
EOF
)

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "    [DRY RUN] Would write: $out_file" >&2
        else
            mkdir -p "$adr_dir"
            printf '%s\n' "$content" > "$out_file"
            echo "    ✓ Written: $out_file" >&2
        fi

        next_num=$((next_num + 1))
    done

    rm -rf "$tmp_dir"
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

    # Read architecture content, minus the ADR blocks — those live in docs/adr/
    # and must not be copied into a file that gets regenerated.
    local overview
    overview=$(awk '
        /^##+ *ADR/ { in_adr = 1; next }
        /^##+ / { in_adr = 0 }
        !in_adr
    ' "$arch_file")

    local adr_index
    adr_index=$(build_adr_index "$repo_path/docs/adr")

    # Generate content (simplified - AI would structure the overview sections)
    local content=$(cat <<EOF
# Architecture - $project_name

*Generated from vault notes*

## System Overview

$overview

## Architecture Decision Records

ADRs are not stored in this file. This document is regenerated from vault notes, and
regeneration would overwrite them — accepted ADRs are immutable. Each decision lives in
its own file under \`docs/adr/\`, following the house standard (see the \`adr-standard\`
skill). The index below is safe to regenerate.

$adr_index

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
    # ADRs first, so ARCHITECTURE.md's index picks up anything newly scaffolded
    generate_adrs "$project_name" "$vault_path" "$repo_path"
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
