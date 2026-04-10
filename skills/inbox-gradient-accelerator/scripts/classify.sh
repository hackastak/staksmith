#!/usr/bin/env bash
# classify.sh - Phase 2: AI classification of inbox items
# Reads JSON from stdin, outputs classification results

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

VAULT_PATH=$(dirname "$(jq -r '.inbox_path' "$CONFIG_FILE" | sed "s|~|$HOME|")")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
CACHE_DIR=$(dirname "$CACHE_PATH")

# Create cache directory if needed
mkdir -p "$CACHE_DIR"

# Read inbox scan results from stdin
inbox_items=$(cat)

# Get available projects, areas, resources from vault
echo "Analyzing vault structure..." >&2

projects=$(find "$VAULT_PATH/1. Projects" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed "s|$VAULT_PATH/||" || echo "")
areas=$(find "$VAULT_PATH/2. Areas" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed "s|$VAULT_PATH/||" || echo "")
resources=$(find "$VAULT_PATH/3. Resources" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | sed "s|$VAULT_PATH/||" || echo "")

# Build classification prompt
vault_structure=$(cat <<EOF
Available destinations:

PROJECTS:
$projects

AREAS:
$areas

RESOURCES:
$resources

PARA Guidelines:
- Projects: Specific outcomes with deadlines (e.g., "Launch OMS v2", "Write book")
- Areas: Ongoing responsibilities (e.g., "Health", "Engineering", "Finance")
- Resources: Reference material, not project-specific (e.g., "Docker tutorials", "Design patterns")
EOF
)

# Initialize results array
classifications="[]"

# Process each item
item_count=$(echo "$inbox_items" | jq 'length')
echo "Classifying $item_count items..." >&2

for i in $(seq 0 $((item_count - 1))); do
    item=$(echo "$inbox_items" | jq ".[$i]")
    path=$(echo "$item" | jq -r '.path')
    filename=$(echo "$item" | jq -r '.filename')
    preview=$(echo "$item" | jq -r '.preview')
    wikilinks=$(echo "$item" | jq -r '.wikilinks | join(", ")')
    tags=$(echo "$item" | jq -r '.tags | join(", ")')

    echo "  Classifying: $filename" >&2

    # NOTE: In actual implementation, this would call Claude AI API
    # For now, this is a placeholder that demonstrates the structure
    # The actual AI call would be made by the Claude Code skill system

    # Create classification prompt for AI
    prompt=$(cat <<EOF
Classify this Obsidian note into the PARA system.

$vault_structure

Note Details:
- Filename: $filename
- Content preview: $preview
- Wikilinks: $wikilinks
- Tags: $tags

Analyze the content and determine:
1. Which PARA category (Project/Area/Resource)?
2. Which specific folder within that category?
3. Confidence level (0.0-1.0)
4. Brief reasoning

Respond ONLY with valid JSON in this exact format:
{
  "category": "Projects|Areas|Resources|Uncertain",
  "destination": "1. Projects/ProjectName" or "uncertain",
  "confidence": 0.85,
  "reason": "Brief explanation"
}
EOF
)

    # Placeholder: In real implementation, AI would process this
    # For now, we'll create a simple heuristic-based classification
    classification=$(cat <<EOF
{
  "path": "$path",
  "filename": "$filename",
  "classification": "uncertain",
  "confidence": 0.5,
  "reason": "AI classification pending - requires Claude Code skill integration"
}
EOF
)

    # Add to results
    classifications=$(echo "$classifications" | jq ". += [$classification]")
done

# Save to cache
echo "$classifications" | jq '.' > "$CACHE_PATH"
echo "Classifications saved to: $CACHE_PATH" >&2

# Output results
echo "$classifications" | jq '.'
