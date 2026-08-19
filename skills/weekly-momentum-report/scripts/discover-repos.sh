#!/usr/bin/env bash
# discover-repos.sh - Derive the week's repos from the weekly note itself.
#
# Instead of hardcoding a repo list, this reads the weekly note's Daily Journal
# sections and extracts the projects you actually mentioned that week:
#   - [[wikilinks]]            e.g. [[supply-chain-monitor]]  -> supply-chain-monitor
#   - leading "Label:" tokens  e.g. "- Staksmith: ..."        -> Staksmith
# Each mention is resolved to a local git repo under search_roots (case- and
# separator-insensitive; repo_aliases wins). Mentions that don't resolve locally
# (e.g. SAP repos checked out on another machine) are reported as unresolved so
# the report can still name them without inventing commits.
#
# Usage:
#   ./discover-repos.sh                 # current ISO week
#   ./discover-repos.sh --week 2026-W33 # specific week
#
# Output: JSON array to stdout AND cached to discovered-repos.json
#   [{ "token": "...", "normalized": "...", "resolved": true|false,
#      "repo_name": "...", "path": "..." }]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

VAULT_PATH=$(jq -r '.vault_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
# search_roots (new) with fallback to repos_root (legacy)
mapfile -t SEARCH_ROOTS < <(jq -r '(.search_roots // .repos_root // [])[]' "$CONFIG_FILE")
mapfile -t IGNORE_LABELS < <(jq -r '(.ignore_labels // [])[] | ascii_downcase' "$CONFIG_FILE")
mkdir -p "$CACHE_PATH"

# ---- Resolve target week -> note path ------------------------------------
WEEK_ARG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --week) WEEK_ARG="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$WEEK_ARG" ]]; then
    # Current ISO week (GNU/BSD compatible)
    if date -v+0d +%G-W%V >/dev/null 2>&1; then
        WEEK_ARG=$(date +%G-W%V)      # BSD/macOS
    else
        WEEK_ARG=$(date +%G-W%V)      # GNU
    fi
fi
WEEK_ARG=$(echo "$WEEK_ARG" | tr '[:lower:]' '[:upper:]')
YEAR="${WEEK_ARG%-W*}"
NOTE_PATH="$VAULT_PATH/_Weekly/$YEAR/$WEEK_ARG.md"

if [[ ! -f "$NOTE_PATH" ]]; then
    echo "Warning: weekly note not found: $NOTE_PATH" >&2
    echo "[]"
    echo "[]" > "$CACHE_PATH/discovered-repos.json"
    exit 0
fi
echo "Reading mentions from: $NOTE_PATH" >&2

# ---- Extract project tokens ----------------------------------------------
# 1) wikilinks: [[token]] (strip any trailing "|alias" and heading "#...")
wikilinks=$(grep -oE '\[\[[^]]+\]\]' "$NOTE_PATH" 2>/dev/null \
    | sed -E 's/^\[\[//; s/\]\]$//; s/\|.*$//; s/#.*$//' || true)

# 2) leading single-word labels on bullets: "- Label: ..." / "\t- Label: ..."
#    single token only (letters/digits/_-), so wikilink+paren lines are ignored here
labels=$(grep -oE '^[[:space:]]*[-*][[:space:]]+[A-Za-z][A-Za-z0-9_-]*:' "$NOTE_PATH" 2>/dev/null \
    | sed -E 's/^[[:space:]]*[-*][[:space:]]+//; s/:$//' || true)

tokens=$(printf "%s\n%s\n" "$wikilinks" "$labels" | sed '/^[[:space:]]*$/d' | sort -u)

# ---- Build a normalized index of local repos ------------------------------
# normalized basename -> path (first match wins)
declare -A REPO_INDEX
normalize() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' | sed -E 's/-+/-/g; s/^-//; s/-$//'; }

for root in "${SEARCH_ROOTS[@]}"; do
    root="${root/#\~/$HOME}"
    [[ -d "$root" ]] || continue
    while IFS= read -r -d '' gitdir; do
        repo_path="${gitdir%/.git}"
        base=$(basename "$repo_path")
        norm=$(normalize "$base")
        [[ -z "${REPO_INDEX[$norm]:-}" ]] && REPO_INDEX["$norm"]="$repo_path"
    done < <(find "$root" -maxdepth 2 -name .git -type d -print0 2>/dev/null)
done

is_ignored() {
    local t; t=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    for ig in "${IGNORE_LABELS[@]}"; do [[ "$t" == "$ig" ]] && return 0; done
    return 1
}

# ---- Resolve each token ---------------------------------------------------
results="[]"
while IFS= read -r token; do
    [[ -z "$token" ]] && continue
    is_ignored "$token" && continue
    norm=$(normalize "$token")

    # alias override, then normalized-basename match
    alias_target=$(jq -r --arg t "$token" '.repo_aliases[$t] // empty' "$CONFIG_FILE")
    path=""
    if [[ -n "$alias_target" ]]; then
        path=$(jq -r --arg t "$token" '.repo_aliases[$t]' "$CONFIG_FILE")
        [[ "$path" != /* ]] && path="${REPO_INDEX[$(normalize "$path")]:-}"
    else
        path="${REPO_INDEX[$norm]:-}"
    fi

    if [[ -n "$path" ]]; then
        item=$(jq -n --arg tok "$token" --arg n "$norm" --arg name "$(basename "$path")" --arg p "$path" \
            '{token:$tok, normalized:$n, resolved:true, repo_name:$name, path:$p}')
    else
        item=$(jq -n --arg tok "$token" --arg n "$norm" \
            '{token:$tok, normalized:$n, resolved:false, repo_name:$tok, path:null}')
    fi
    results=$(echo "$results" | jq --argjson it "$item" '. += [$it]')
done <<< "$tokens"

# de-dupe by resolved path (keep unresolved distinct by token)
results=$(echo "$results" | jq '
    (map(select(.resolved))   | group_by(.path)  | map(.[0])) +
    (map(select(.resolved|not)) | group_by(.token) | map(.[0]))
')

echo "$results" | jq '.' > "$CACHE_PATH/discovered-repos.json"

resolved_n=$(echo "$results" | jq '[.[]|select(.resolved)]|length')
unresolved_n=$(echo "$results" | jq '[.[]|select(.resolved|not)]|length')
echo "Discovered: $resolved_n local repo(s), $unresolved_n mentioned but not local" >&2
echo "$results" | jq -r '.[] | "  \(if .resolved then "[local]  " else "[remote] " end)\(.token) -> \(.path // "(no local checkout)")"' >&2

echo "$results" | jq '.'
