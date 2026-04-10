#!/usr/bin/env bash
# detect-patterns.sh - Phase 2: Detect reusable patterns
# Analyzes commit data to identify repeated workflows

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

MIN_FREQUENCY=$(jq -r '.min_frequency' "$CONFIG_FILE")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")

# Check for cached data
COMMITS_FILE="$CACHE_PATH/commits.json"
FILE_FREQ_FILE="$CACHE_PATH/file-frequency.json"

if [[ ! -f "$COMMITS_FILE" ]]; then
    echo "Error: No commit data found. Run scan-history.sh first." >&2
    exit 1
fi

if [[ ! -f "$FILE_FREQ_FILE" ]]; then
    echo "Error: No file frequency data found. Run scan-history.sh first." >&2
    exit 1
fi

echo "Detecting patterns..." >&2
echo "Minimum frequency: $MIN_FREQUENCY" >&2

# Load cached data
commits=$(cat "$COMMITS_FILE")
file_frequency=$(cat "$FILE_FREQ_FILE")

# Initialize patterns array
patterns="[]"

# Pattern 1: Drizzle ORM setup
# Look for commits that modify drizzle.config.ts, db/schema.ts, package.json together
drizzle_repos=$(echo "$commits" | jq -r '
  [.[] | select(.message | test("drizzle"; "i"))] |
  group_by(.repo) |
  map({
    repo: .[0].repo,
    count: length,
    commits: [.[] | {hash, date, message, files}]
  }) |
  map(select(.count >= 1))
')

drizzle_count=$(echo "$drizzle_repos" | jq 'length')

if [[ $drizzle_count -ge $MIN_FREQUENCY ]]; then
    echo "  Pattern detected: Drizzle ORM setup (frequency: $drizzle_count)" >&2

    # Extract common files
    common_files=$(echo "$drizzle_repos" | jq -r '
      [.[].commits[].files[]] |
      group_by(.) |
      map({file: .[0], count: length}) |
      sort_by(.count) |
      reverse |
      [.[0:5][].file]
    ')

    # Extract common steps from commit messages
    common_steps=$(echo "$drizzle_repos" | jq -r '
      [.[].commits[].message] |
      unique |
      [.[0:5]]
    ')

    pattern=$(cat <<EOF
{
  "pattern_id": "add-drizzle-orm",
  "name": "Add Drizzle ORM to Next.js Project",
  "frequency": $drizzle_count,
  "repos": $(echo "$drizzle_repos" | jq '[.[].repo]'),
  "common_files": $common_files,
  "common_steps": $common_steps,
  "pattern_type": "framework_addition",
  "confidence": 0.9
}
EOF
)

    patterns=$(echo "$patterns" | jq ". += [$pattern]")
fi

# Pattern 2: GitHub Actions CI setup
ci_repos=$(echo "$commits" | jq -r '
  [.[] | select(.message | test("ci|github.*action|workflow"; "i"))] |
  group_by(.repo) |
  map({
    repo: .[0].repo,
    count: length,
    commits: [.[] | {hash, date, message, files}]
  }) |
  map(select(.count >= 1))
')

ci_count=$(echo "$ci_repos" | jq 'length')

if [[ $ci_count -ge $MIN_FREQUENCY ]]; then
    echo "  Pattern detected: GitHub Actions CI (frequency: $ci_count)" >&2

    common_files=$(echo "$ci_repos" | jq -r '
      [.[].commits[].files[]] |
      group_by(.) |
      map({file: .[0], count: length}) |
      sort_by(.count) |
      reverse |
      [.[0:5][].file]
    ')

    pattern=$(cat <<EOF
{
  "pattern_id": "github-actions-ci",
  "name": "Setup GitHub Actions CI/CD",
  "frequency": $ci_count,
  "repos": $(echo "$ci_repos" | jq '[.[].repo]'),
  "common_files": $common_files,
  "pattern_type": "config_setup",
  "confidence": 0.85
}
EOF
)

    patterns=$(echo "$patterns" | jq ". += [$pattern]")
fi

# Pattern 3: Authentication setup
auth_repos=$(echo "$commits" | jq -r '
  [.[] | select(.message | test("auth|jwt|login|session"; "i"))] |
  group_by(.repo) |
  map({
    repo: .[0].repo,
    count: length,
    commits: [.[] | {hash, date, message, files}]
  }) |
  map(select(.count >= 1))
')

auth_count=$(echo "$auth_repos" | jq 'length')

if [[ $auth_count -ge $MIN_FREQUENCY ]]; then
    echo "  Pattern detected: Authentication setup (frequency: $auth_count)" >&2

    common_files=$(echo "$auth_repos" | jq -r '
      [.[].commits[].files[]] |
      group_by(.) |
      map({file: .[0], count: length}) |
      sort_by(.count) |
      reverse |
      [.[0:5][].file]
    ')

    pattern=$(cat <<EOF
{
  "pattern_id": "api-authentication",
  "name": "Add Authentication to API",
  "frequency": $auth_count,
  "repos": $(echo "$auth_repos" | jq '[.[].repo]'),
  "common_files": $common_files,
  "pattern_type": "architecture_pattern",
  "confidence": 0.8
}
EOF
)

    patterns=$(echo "$patterns" | jq ". += [$pattern]")
fi

# Pattern 4: Package.json file patterns
# Look for files frequently modified together with package.json
package_json_commits=$(echo "$commits" | jq '[.[] | select(.files[] | contains("package.json"))]')
package_json_count=$(echo "$package_json_commits" | jq 'length')

if [[ $package_json_count -ge $MIN_FREQUENCY ]]; then
    # Find files commonly modified with package.json
    comodified=$(echo "$package_json_commits" | jq -r '
      [.[].files[]] |
      group_by(.) |
      map({file: .[0], count: length}) |
      map(select(.file != "package.json")) |
      sort_by(.count) |
      reverse |
      .[0:10]
    ')

    echo "  Found $package_json_count package.json modifications" >&2
    echo "    Commonly co-modified files:" >&2
    echo "$comodified" | jq -r '.[] | "      - \(.file) (x\(.count))"' >&2
fi

# Save patterns report
patterns_file="$CACHE_PATH/patterns-detected.json"

patterns_report=$(cat <<EOF
{
  "scan_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "patterns_detected": $(echo "$patterns" | jq 'length'),
  "patterns": $patterns
}
EOF
)

echo "$patterns_report" | jq '.' > "$patterns_file"

# Generate summary
pattern_count=$(echo "$patterns" | jq 'length')

echo "" >&2
echo "=== Pattern Detection Summary ===" >&2
echo "Patterns detected: $pattern_count" >&2
echo "Report saved: $patterns_file" >&2

# List detected patterns
if [[ $pattern_count -gt 0 ]]; then
    echo "" >&2
    echo "Detected patterns:" >&2
    echo "$patterns" | jq -r '.[] | "  - \(.name) (frequency: \(.frequency), confidence: \(.confidence))"' >&2
fi

# Output patterns
echo "$patterns_report" | jq '.'
