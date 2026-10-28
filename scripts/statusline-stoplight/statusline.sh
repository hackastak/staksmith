#!/usr/bin/env bash
# statusline.sh — Claude Code statusline renderer.
# Invoked on every render (~300ms cadence). Reads stdin JSON + the session state
# file, prints the bottom bar. Does NOT touch the tab title — the 🔴/🟢 tab icon
# is owned entirely by statusline-hook.sh (Claude Code doesn't relay a statusLine
# command's OSC to the tab, so the renderer can't set it anyway).
# Hot path: no gh fork, no git fork, reads via bash builtins.
#
# Reads:
#   - stdin: statusline JSON (session_id, workspace.current_dir, optional pr.*,
#     optional model.display_name, optional context_window.used_percentage,
#     optional rate_limits.seven_day.used_percentage — the 7d gauge)
#   - $STATUSLINE_STATE_DIR/<session_id>            (from statusline-hook.sh)
#   - $STATUSLINE_STATE_DIR/<session_id>.turns      (user-prompt count from
#     statusline-hook.sh; rendered as the 🔄 session-length gauge)
#   - $STATUSLINE_STATE_DIR/<session_id>.wt         (active-worktree pointer from
#     statusline-hook.sh; redirects PR resolution to that worktree — see the PR
#     resolution directory block)
#   - $STATUSLINE_STATE_DIR/<session_id>.active     (intent pointer from
#     active_repo_tracker.sh; records stated-intent signals like git -C, abs-path
#     edits, gh -R without a physical cd; lower priority than .wt / .cd_target;
#     also carries gh-only slug+PR for the no-local-checkout case)
#   - $STATUSLINE_STATE_DIR/pr-cache/<sha1(session:dir:branch)>  (the gh-lookup path:
#     \x1f-delimited number\x1furl\x1fisDraft\x1fstate\x1freviewDecision\x1fCI — legacy
#     2-field number\turl entries still read; see PR-segment block)
#
# PR resolution — two paths, gated on whether the payload already resolved the
# PR: a host that sends pr.* is used directly; otherwise the PR is resolved
# via a background-refreshed gh cache. Detail at the PR-segment block below.
#
# Never exits non-zero — a crash would clobber the statusline UI.
# Shell prologue: `set -uo pipefail` (no -e) — see [[bash-set-e-command-substitution]].

set -uo pipefail

STATE_DIR="${STATUSLINE_STATE_DIR:-$HOME/.claude/statusline-state}"
PR_CACHE_TTL_SEC=600       # terminal PR state (MERGED/CLOSED): re-fetch rarely.
PR_CACHE_LIVE_TTL_SEC=60   # still-changing state (none/open/draft/in-review):
                           # short, so a flip surfaces within ~1 min not ~10.
WT_POINTER_TTL_SEC=43200   # 12h. How long a `cd` into a worktree implies you're
                           # still on it. Long because a session is one-tab-per-
                           # worktree in practice: an idle gap (lunch, a meeting)
                           # must NOT revert the badge to root:branch — the bug this
                           # bounds against. The hook only ever WRITES this pointer
                           # (on cd-into-worktree), never clears it on cd-out, so the
                           # TTL is the sole expiry; a torn-down worktree is handled
                           # separately by the HEAD re-read below (self-heals to cwd).
                           # Distinct from the PR-cache freshness bounds above.

# Portable mtime: BSD `stat -f %m` vs GNU `stat -c %Y`. Detect once — Linux stat
# prints a partial "File:" header to stdout on the wrong flag, which would poison
# arithmetic under set -u.
if stat -f %m / >/dev/null 2>&1; then
    _mtime() { stat -f %m "$1" 2>/dev/null; }
else
    _mtime() { stat -c %Y "$1" 2>/dev/null; }
fi

# Set git_segment (and branch, for attached HEADs) from a HEAD line.
# $1 = icon, $2 = HEAD line.
_parse_head() {
    local icon="$1" head_line="$2"
    if [[ "$head_line" == "ref: refs/heads/"* ]]; then
        branch="${head_line#ref: refs/heads/}"
        git_segment="$icon $branch"
    elif [[ "$head_line" == ref:* ]]; then
        # Detached onto a tag/remote ref — show the last component, not the
        # full ref string.
        branch="${head_line##*/}"
        git_segment="$icon $branch"
    else
        branch="${head_line:0:7}"
        git_segment="$icon $branch"
    fi
}

# Resolve a worktree/submodule ".git" FILE ($1/.git) to its HEAD line, into the
# caller's `_gitdir_head` (empty if malformed/missing). The .git file holds
# `gitdir: <path>` — git may write it relative (`--relative-paths`), resolved
# against $1. Bail without the `gitdir: ` prefix so a garbage file can't resolve
# to an arbitrary dir. Fork-free, like _parse_head.
_read_gitdir_head() {
    local base="$1" gitfile_line gitdir
    _gitdir_head=""
    [[ -f "$base/.git" ]] || return
    read -r gitfile_line < "$base/.git"
    [[ "$gitfile_line" == "gitdir: "* ]] || return
    gitdir="${gitfile_line#gitdir: }"
    [[ -n "$gitdir" && "$gitdir" != /* ]] && gitdir="$base/$gitdir"
    [[ -n "$gitdir" && -f "$gitdir/HEAD" ]] && read -r _gitdir_head < "$gitdir/HEAD"
}

# Set `_tok` to the display suffix (leading space included) for a review-state
# token. Empty/unknown → empty. Assigns to the caller's `_tok` rather than
# printing, so callers invoke it as `_review_token X` (no $()) and stay
# fork-free on the ~3/sec render path — same convention as _parse_head.
# Shared by both PR paths so they can't drift. The payload path passes
# review_state verbatim (`pending`, `changes_requested`); the lookup path
# passes its own tokens (`draft`, `approved`, `changes`, `merged`) —
# the aliases below accept both. `merged` is lookup-path only (the native payload
# carries no merged state).
_review_token() {
    case "$1" in
        draft)                      _tok=' ·draft' ;;
        pending|ready)              _tok=' ·ready' ;;
        approved)                   _tok=' ✓approved' ;;
        changes|changes_requested)  _tok=' ⚠changes' ;;
        merged)                     _tok=' ✓merged' ;;
        *)                          _tok='' ;;
    esac
}

# Set `_citok` to the CI display suffix (leading space included) for a
# statusCheckRollup state. Only the lookup cache path carries this (the native
# native payload has no rollup), so github.com PRs render no CI token — absent,
# not wrong. Empty/unknown/none → empty (no checks configured → nothing shown).
# SUCCESS → ✓(ci), PENDING → 🔧(ci) (building/queued), FAILURE/ERROR → ✗(ci).
_ci_token() {
    case "$1" in
        SUCCESS)              _citok=' ✓(ci)' ;;
        PENDING|EXPECTED)     _citok=' 🔧(ci)' ;;
        FAILURE|ERROR)        _citok=' ✗(ci)' ;;
        *)                    _citok='' ;;
    esac
}

# ── Read stdin JSON (bash regex, zero forks — matches statusline-hook.sh) ──
# jq was one fork per render (~3/sec); these matches are fork-free. Matches the
# "current_dir" key by name anywhere in the blob — assumes a single such key
# (true today; revisit if a payload ever nests another).
# Assumes a single "number"/"url"/"review_state" key in the blob (true today:
# they appear only under "pr"). Revisit if a future payload nests another.
INPUT=$(cat)
session_id=""
cwd=""
git_worktree=""
pr_number=""
pr_url=""
pr_review=""
model_name=""   # model.display_name — the LEAD model; see the model segment below
ctx_pct=""      # context_window.used_percentage — empty if the harness omits it (older builds)
ctx_win_size="" # context_window.context_window_size — the model's actual token window (newer builds)
[[ "$INPUT" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && session_id="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"current_dir\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && cwd="${BASH_REMATCH[1]}"
# project_dir is the session LAUNCH dir (pinned at start, never updated).
# It is parsed here but deliberately unused by older logic; the new precedence
# rule (use_side_channel below) needs it to distinguish "cwd moved away from
# launch" (follow cwd) from "cwd == launch" (root+cd-subshell; trust side channel).
project_dir=""
[[ "$INPUT" =~ \"project_dir\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && project_dir="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"git_worktree\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && git_worktree="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"number\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && pr_number="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"url\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && pr_url="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"review_state\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && pr_review="${BASH_REMATCH[1]}"
# model.display_name = the LEAD (main-session) model. The payload has no field
# for the subagent tier, and can't read CLAUDE_CODE_SUBAGENT_MODEL — so this
# honestly labels "the model you're driving," NOT the turn's effective cost
# (dispatched work runs Sonnet under the floor). No cost figure: cost.total_cost_usd
# is a client-side list-price estimate, not the billed rate.
# Single "display_name" key in the payload (only under "model") — bare match, same
# single-key assumption as the pr fields above.
[[ "$INPUT" =~ \"display_name\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && model_name="${BASH_REMATCH[1]}"
# used_percentage may render as int or float (e.g. 84 or 84.3); capture the integer part.
# Scope it to the object: rate_limits.five_hour and rate_limits.seven_day carry the same
# key, and a bare first-match would paint the weekly (or 5h) figure as context.
_json_object_after_key() {
    local key="$1" rest i ch depth
    _obj=""
    [[ "$INPUT" == *"\"$key\""* ]] || return 1
    rest="${INPUT#*"\"$key\""}"
    rest="${rest#*:}"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    [[ "${rest:0:1}" == "{" ]] || return 1
    depth=0
    for ((i=0; i<${#rest}; i++)); do
        ch="${rest:i:1}"
        _obj+="$ch"
        if [[ "$ch" == "{" ]]; then
            depth=$((depth + 1))
        elif [[ "$ch" == "}" ]]; then
            depth=$((depth - 1))
            (( depth == 0 )) && return 0
        fi
    done
    _obj=""
    return 1
}
week_pct=""
if _json_object_after_key context_window; then
    [[ "$_obj" =~ \"used_percentage\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && ctx_pct="${BASH_REMATCH[1]}"
    [[ "$_obj" =~ \"context_window_size\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && ctx_win_size="${BASH_REMATCH[1]}"
fi
if _json_object_after_key seven_day; then
    [[ "$_obj" =~ \"used_percentage\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && week_pct="${BASH_REMATCH[1]}"
fi

# ── State segment ──────────────────────────────────────────────────────
# `waiting` (🔴) is deliberately NOT rendered here: the focused pane already
# shows the permission prompt, so a bottom-bar 🔴 is redundant — and it goes
# stale when you approve into manual mode (no PostToolUse fires to clear it).
# 🔴 lives only on the tab title (statusline-hook.sh), where it flags an
# UNFOCUSED tab that needs you. The bar uses ⏳/✏️ (NOT circles) — "still
# working" vs "your turn to type" — so the bar's glyph language is visually
# distinct from the tab's 🔴/🟢 circles and the two surfaces don't blur.
# `thrashing` IS rendered in the bar: unlike a permission prompt, thrash has
# no in-pane UI, so the focused-session user would see nothing otherwise.
state=""
state_segment=""
now=""
if [[ -n "$session_id" && -r "$STATE_DIR/$session_id" ]]; then
    read -r state < "$STATE_DIR/$session_id"
    # A closed session fires no final hook, so its state file stays "running"
    # forever. Treat stale "running" (no hook in >30 min) as idle so the bar
    # shows ✏️ ready instead of the misleading ⏳ working.
    # 30 min floor: the longest a single foreground tool call realistically
    # runs is ~10 min (Claude Code's max configurable timeout); 30 min of
    # silence without any hook event implies the session is force-closed.
    if [[ "$state" == "running" ]]; then
        _state_mtime=$(_mtime "$STATE_DIR/$session_id")
        if [[ "$_state_mtime" =~ ^[0-9]+$ && "$_state_mtime" -gt 0 ]]; then
            [[ -z "$now" ]] && now=$(date +%s)
            if (( now - _state_mtime > 1800 )); then
                state="idle"
            fi
        fi
    fi
    case "$state" in
        running)   state_segment="⏳ working" ;;
        idle)      state_segment="✏️ ready" ;;
        thrashing) state_segment="⚠️ autocompact thrashing — /compact or route heavy MCP calls to subagents" ;;
        waiting)   state_segment="" ;;   # tab-only; see comment above
        *)         state_segment="" ;;
    esac
fi

# ── Turn-count segment ─────────────────────────────────────────────────
# Plain session-length gauge: 🔄 N, where N is the user-prompt count that
# statusline-hook.sh persists to <session_id>.turns. Colors match context
# health bands — green <20, yellow 20-40, red >40 — so the visual language
# is consistent across the bar. Advisory only: a high count on a long same-
# task loop is fine; it's the cue to /clear when switching topics.
turns_segment=""
if [[ -n "$session_id" && -r "$STATE_DIR/$session_id.turns" ]]; then
    read -r _turns < "$STATE_DIR/$session_id.turns"
    if [[ "$_turns" =~ ^[0-9]+$ ]]; then
        if   (( _turns >= 40 )); then _tc=$'\033[31m'
        elif (( _turns >= 20 )); then _tc=$'\033[33m'
        else                          _tc=$'\033[32m'; fi
        turns_segment=$(printf '%s↺ %d\033[0m' "$_tc" "$_turns")
    fi
fi

# ── Git segment (direct file read, no fork) ────────────────────────────
git_segment=""
branch=""
cwd_is_worktree=""   # set to "1" when cwd itself resolved as a linked worktree; used to
                     # suppress the .wt pointer override in the PR-resolution block below
cwd_is_repo=""       # set to "1" when cwd is any git repo (main checkout OR worktree/submodule)
if [[ -n "$git_worktree" ]]; then
    git_segment="🪵 $git_worktree"
    branch="$git_worktree"   # worktree NAME (not necessarily the git ref); set so the no-repo fallback sees a value
fi
if [[ -z "$git_segment" && -n "$cwd" && -f "$cwd/.git/HEAD" ]]; then
    read -r head_line < "$cwd/.git/HEAD"
    _parse_head "🌿" "$head_line"
    cwd_is_repo="1"
elif [[ -z "$git_segment" && -n "$cwd" && -f "$cwd/.git" ]]; then
    # A worktree/submodule .git FILE — resolve it to its HEAD line via the shared
    # helper (handles the gitdir prefix + relative-path form), then parse.
    # Submodule dirs also have a .git FILE (gitdir: ../.git/modules/<name>);
    # _read_gitdir_head follows it and yields the submodule branch — correct.
    # Repo-name prefix uses basename $cwd (the submodule dir), not the superproject.
    # Do NOT add --show-superproject-working-tree here: it is a git fork, forbidden
    # on this ~3/sec hot path.
    _read_gitdir_head "$cwd"
    if [[ -n "$_gitdir_head" ]]; then
        _parse_head "🪵" "$_gitdir_head"
        cwd_is_worktree="1"   # cwd IS a linked worktree; its cwd:branch is authoritative
        cwd_is_repo="1"
    fi
fi

# PRECEDENCE: git_worktree > cwd(moved) > .wt > .cd_target > .active
# When cwd is a real repo AND has moved from the launch dir, it is authoritative:
# promote it above the side-channel files (.wt, .cd_target) which may be stale.
# Side channels are trusted ONLY when cwd == launch dir (the root+cd-subshell case
# where the Bash tool resets cwd between calls and the payload never sees the move).
# If project_dir is absent (older harness), cwd_moved stays 0 → safe degradation.
cwd_moved=0
[[ -n "$project_dir" && -n "$cwd" && "$cwd" != "$project_dir" ]] && cwd_moved=1
use_side_channel=1
[[ -n "$git_worktree" || ( "$cwd_is_repo" == "1" && "$cwd_moved" -eq 1 ) ]] && use_side_channel=0
# ── cd_target override: session is driving a different repo via `cd <abs-path>` ──
# cd_target_tracker.sh writes <session_id>.cd_target when an agent Bash-tools
# `cd` into a dir outside this session's own cwd. When that pointer is present
# and live, redirect the git badge to the target repo so the bar shows the
# actual working repo, not the session launch repo. The pointer has no TTL — it stays
# until the session returns to the launch cwd (at which point cd_target_tracker
# clears it) or the session ends. The cwd_is_worktree guard still wins: if the
# payload cwd is itself a linked worktree it is authoritative; don't override.
# Note: no git_segment guard here — the session cwd may itself be a git repo
# and the cd_target must override that badge when the agent has
# cd'd away to work on a different repo.
#
# Own-worktree suppression: when .wt points to a live same-repo (own) worktree
# AND .wt is newer than .cd_target, suppress .cd_target. "Newer .wt" is the
# "later write wins" test: if the agent cd'd cross-repo AFTER entering the own
# worktree, .cd_target mtime > .wt mtime and suppression must NOT fire. Only
# when .wt is newer (EnterWorktree came after the cross-repo cd) is .cd_target
# the stale one. Guard is skipped entirely when cwd_is_worktree=1 (the cwd
# block already resolved the badge authoritatively) or when session_id/cwd
# are absent — skip avoids both the stat fork and an unbound-var risk on $now.
#
# .wt state is read here and reused by the PR-resolution block below (same file,
# same session — one stat + one read shared across both blocks).
now=""   # lazy-init shared by the suppression TTL check and the PR-resolution TTL check
wt_file=""   # resolved inside the suppression block; reused by PR-resolution block
wt_dir=""
wt_mtime=0
_ct_suppressed_by_wt=0
if [[ "$use_side_channel" -eq 1 && -n "$session_id" && -n "$cwd" && "$cwd_is_worktree" != "1" ]]; then
    wt_file="$STATE_DIR/$session_id.wt"
    if [[ -r "$wt_file" ]]; then
        wt_mtime=$(_mtime "$wt_file"); [[ "$wt_mtime" =~ ^[0-9]+$ ]] || wt_mtime=0
        now=$(date +%s)
        if [[ $(( now - wt_mtime )) -lt "$WT_POINTER_TTL_SEC" ]]; then
            read -r wt_dir < "$wt_file"
            if [[ "$wt_dir" == "$cwd/.claude/worktrees/"* || \
                  "$wt_dir" == "$cwd/.worktrees/"* ]]; then
                # Own worktree: suppress only when .wt is strictly newer than .cd_target.
                # Same-second mtime (equal) means a cross-repo cd arrived within the same
                # second as EnterWorktree — treat the cd_target as authoritative, not stale.
                # If .cd_target doesn't exist (_ct_mtime=0), wt_mtime >> 0 so -gt always holds.
                _ct_file_pre="$STATE_DIR/$session_id.cd_target"
                _ct_mtime=0
                [[ -r "$_ct_file_pre" ]] && { _ct_mtime=$(_mtime "$_ct_file_pre"); [[ "$_ct_mtime" =~ ^[0-9]+$ ]] || _ct_mtime=0; }
                [[ $wt_mtime -gt $_ct_mtime ]] && _ct_suppressed_by_wt=1
            fi
        fi
    fi
fi
cd_target_dir=""
if [[ "$use_side_channel" -eq 1 && -n "$session_id" && "$cwd_is_worktree" != "1" && "$_ct_suppressed_by_wt" -eq 0 ]]; then
    _ct_file="$STATE_DIR/$session_id.cd_target"
    if [[ -r "$_ct_file" ]]; then
        read -r cd_target_dir < "$_ct_file"
        if [[ -n "$cd_target_dir" && -f "$cd_target_dir/.git/HEAD" ]]; then
            read -r head_line < "$cd_target_dir/.git/HEAD"
            _parse_head "🌿" "$head_line"
        elif [[ -n "$cd_target_dir" && -f "$cd_target_dir/.git" ]]; then
            _read_gitdir_head "$cd_target_dir"
            [[ -n "$_gitdir_head" ]] && _parse_head "🪵" "$_gitdir_head"
        else
            # Target dir has no .git — clear stale pointer, fall back to cwd.
            cd_target_dir=""
        fi
    fi
fi

# ── .active override: intent pointer from active_repo_tracker.sh ─────────────
# active_repo_tracker.sh writes <session_id>.active when tool calls signal work
# in a different repo (git -C <path>, gh -R owner/repo, abs-path Edit/Write).
# This covers the gh-only case (no local checkout, no physical cd fired) — the
# root cause of the "shows the launch repo while working in another repo" bug.
# Lower priority than .wt and .cd_target — physical moves win over intent.
# No turn-delta freshness guard: active_repo_tracker.sh explicitly removes
# .active on return-home, so a file that exists is a live pointer by definition.
# Caveat: the tracker fires only on Bash/Edit/Write tool calls — an MCP-only
# return-home leaves .active set until the next Bash/Edit fires.
active_dir=""
active_slug=""
active_pr_num=""
if [[ "$use_side_channel" -eq 1 && -n "$session_id" && "$cwd_is_worktree" != "1" && -z "$cd_target_dir" && ( -z "$wt_dir" || ! -d "$wt_dir" ) ]]; then
    _active_file="$STATE_DIR/$session_id.active"
    if [[ -r "$_active_file" ]]; then
        _act_dir=""; _act_slug=""; _act_branch=""; _act_pr=""
        { read -r _act_dir; read -r _; read -r _act_slug; read -r _act_branch; read -r _act_pr; } \
            < "$_active_file" 2>/dev/null || true
        if [[ -n "$_act_dir" && -d "$_act_dir" ]]; then
            # Local dir present: parse its git state. Only activate after a readable
            # HEAD is confirmed so a stale/non-git dir cannot reuse cwd-derived git_segment.
            if [[ -f "$_act_dir/.git/HEAD" ]]; then
                read -r head_line < "$_act_dir/.git/HEAD"
                active_dir="$_act_dir"
                active_slug="$_act_slug"
                active_pr_num="$_act_pr"
                _parse_head "🌿" "$head_line"
            elif [[ -f "$_act_dir/.git" ]]; then
                _read_gitdir_head "$_act_dir"
                if [[ -n "$_gitdir_head" ]]; then
                    active_dir="$_act_dir"
                    active_slug="$_act_slug"
                    active_pr_num="$_act_pr"
                    _parse_head "🪵" "$_gitdir_head"
                fi
            fi
        elif [[ -z "$_act_dir" && -n "$_act_slug" ]]; then
            # gh-only: no local checkout. Render slug + PR only (decision 2).
            active_slug="$_act_slug"
            active_pr_num="$_act_pr"
            _act_repo_name="${_act_slug##*/}"
            git_segment="$_act_repo_name"
            # Skip the git HEAD parse — no local repo. branch stays empty.
        fi
    fi
fi

# ── Repo name prefix: prepend "repo-basename icon branch" to git_segment ──────
# Derive from the effective repo dir (active_dir, cd_target, or cwd in that
# order). Strip worktree suffix to reach the repo root, then take the basename.
# Fork-free.
if [[ -n "$git_segment" ]]; then
    # When .active has only a slug (gh-only, no local checkout), skip the repo-prefix:
    # active_dir is empty so we'd fall back to cwd, labeling the wrong repo.
    if [[ -n "$active_slug" && -z "$active_dir" && -z "$cd_target_dir" ]]; then
        _repo_ref=""
    else
        _repo_ref="${cd_target_dir:-${active_dir:-$cwd}}"
    fi
    # Strip a linked-worktree suffix (.claude/worktrees/<name> or .worktrees/<name>).
    _repo_root="$_repo_ref"
    if [[ "$_repo_ref" =~ ^(.*)(\.claude/worktrees/[^/]+)$ ]]; then
        _repo_root="${BASH_REMATCH[1]}"
    elif [[ "$_repo_ref" =~ ^(.*)(\.worktrees/[^/]+)$ ]]; then
        _repo_root="${BASH_REMATCH[1]}"
    fi
    _repo_root="${_repo_root%/}"   # strip any trailing slash
    _repo_name="${_repo_root##*/}"
    [[ -n "$_repo_name" ]] && git_segment="$_repo_name $git_segment"
fi

# ── PR resolution directory. Normally the badge resolves against the session's
#    cwd:branch — but a session at the repo root works PRs in worktrees, so on the
#    lookup path (no payload pr.*) resolve against the worktree that
#    statusline-hook.sh recorded to <session_id>.wt instead.
#
#    Cross-repo .wt: when the recorded worktree is in a different repo (its path
#    does not start with cwd), the git segment and repo name are also updated to
#    reflect the target repo — otherwise the bar shows the launch repo for a PR
#    that lives elsewhere. Detection is a path-prefix check
#    (fork-free); a .wt under cwd/ is same-repo, anything outside
#    is cross-repo.
#
#    Guard: skip the .wt override when the payload cwd is itself a linked worktree
#    (cwd_is_worktree set). In that case cwd:branch is the authoritative location
#    and a stale .wt pointer from a prior cd into a DIFFERENT worktree must not
#    hijack the PR resolution — the user moved here; follow them. The .wt path
#    exists only for the root-with-subshells case (cwd=main root, Claude works a
#    worktree via cd subshells whose cwd the payload never carries); when cwd IS a
#    worktree, we already have the right dir and branch from the .git file above.
#
#    `wt_file`, `wt_dir`, `wt_mtime`, and `now` were already initialized by the
#    suppression block above — reuse them here to avoid a second stat + read. ──
pr_dir="$cwd"
pr_branch="$branch"
if [[ -z "$pr_number" && "$use_side_channel" -eq 1 && -n "$session_id" && "$cwd_is_worktree" != "1" ]]; then
    # Re-read wt_file only when the suppression block skipped it (cwd_is_worktree=1
    # guarded the block but the PR block needs it). That guard fires together here,
    # so in practice the suppression block always ran if we're in this branch.
    # The wt_file/wt_dir/wt_mtime/now vars are set; use them directly.
    if [[ -r "$wt_file" ]]; then
        # TTL already checked (or wt_mtime=0 means not-yet-read → re-check).
        if [[ $wt_mtime -eq 0 ]]; then
            wt_mtime=$(_mtime "$wt_file"); [[ "$wt_mtime" =~ ^[0-9]+$ ]] || wt_mtime=0
            [[ -z "$now" ]] && now=$(date +%s)
        fi
        if [[ $(( now - wt_mtime )) -lt "$WT_POINTER_TTL_SEC" ]]; then
            # wt_dir already read by suppression block if it was within TTL.
            [[ -z "$wt_dir" ]] && read -r wt_dir < "$wt_file"
            # Redirect only if HEAD is a branch — a detached-SHA or removed
            # worktree yields empty/non-ref and falls through to the session cwd.
            if [[ -n "$wt_dir" ]]; then
                _read_gitdir_head "$wt_dir"
                _wt_head_for_pr="$_gitdir_head"
                if [[ "$_wt_head_for_pr" == "ref: refs/heads/"* ]]; then
                    pr_branch="${_wt_head_for_pr#ref: refs/heads/}"; pr_dir="$wt_dir"
                elif [[ "$_wt_head_for_pr" == ref:* ]]; then
                    pr_branch="${_wt_head_for_pr##*/}"; pr_dir="$wt_dir"
                fi
                # Cross-repo: wt_dir is not a worktree of this session's repo —
                # update git segment + repo name so the bar reads
                # the target repo and branch, not the launch repo's main.
                # Linked worktrees live at <cwd>/.claude/worktrees/<task> or
                # <cwd>/.worktrees/<task>; anything else is a different repo.
                # Only fires when cd_target_dir is empty (cd_target already owns
                # the git segment when it is active).
                _is_own_wt=0
                [[ "$wt_dir" == "$cwd/.claude/worktrees/"* || \
                   "$wt_dir" == "$cwd/.worktrees/"* ]] && _is_own_wt=1
                if [[ -n "$_wt_head_for_pr" && "$pr_dir" != "$cwd" && \
                      "$_is_own_wt" -eq 0 && -z "$cd_target_dir" ]]; then
                    # Reparse the git segment from the wt HEAD (already in _wt_head_for_pr).
                    _parse_head "🪵" "$_wt_head_for_pr"
                    # Rebuild repo name from the wt path (strip .claude/worktrees/<task>).
                    _xr_root="$wt_dir"
                    if [[ "$wt_dir" =~ ^(.*)(\.claude/worktrees/[^/]+)$ ]]; then
                        _xr_root="${BASH_REMATCH[1]}"
                    elif [[ "$wt_dir" =~ ^(.*)(\.worktrees/[^/]+)$ ]]; then
                        _xr_root="${BASH_REMATCH[1]}"
                    fi
                    _xr_root="${_xr_root%/}"
                    _xr_name="${_xr_root##*/}"
                    [[ -n "$_xr_name" ]] && git_segment="$_xr_name $git_segment"
                fi
            fi
        fi
    fi
fi
# ── .active PR resolution: when active_dir is set (intent pointer), resolve
#    the PR against that repo's branch. Falls through here when neither .wt
#    nor cd_target redirected pr_dir.
#    When active_pr_num is known from .active, set pr_number directly so the
#    cache lookup is skipped — the tracker already has the answer.
if [[ -z "$pr_number" && "$use_side_channel" -eq 1 && \
      ( -n "$active_dir" || -n "$active_pr_num" ) && "$pr_dir" == "$cwd" ]]; then
    if [[ -n "$active_pr_num" ]]; then
        # PR number is known from the intent pointer — skip the cache lookup.
        pr_number="$active_pr_num"
    fi
    if [[ -n "$active_dir" ]]; then
        if [[ -f "$active_dir/.git/HEAD" ]]; then
            read -r _ad_head < "$active_dir/.git/HEAD"
            if [[ "$_ad_head" == "ref: refs/heads/"* ]]; then
                pr_branch="${_ad_head#ref: refs/heads/}"; pr_dir="$active_dir"
            elif [[ "$_ad_head" == ref:* ]]; then
                pr_branch="${_ad_head##*/}"; pr_dir="$active_dir"
            fi
        elif [[ -f "$active_dir/.git" ]]; then
            _read_gitdir_head "$active_dir"
            if [[ "$_gitdir_head" == "ref: refs/heads/"* ]]; then
                pr_branch="${_gitdir_head#ref: refs/heads/}"; pr_dir="$active_dir"
            elif [[ "$_gitdir_head" == ref:* ]]; then
                pr_branch="${_gitdir_head##*/}"; pr_dir="$active_dir"
            fi
        fi
    fi
fi
# ── cd_target PR resolution: when driving a different repo, resolve the PR
#    against that repo's branch, not the session's launch cwd. Only falls
#    through here when the .wt block above did not redirect pr_dir (i.e.,
#    there is no active worktree pointer). The cd_target_dir var was set
#    in the git-segment block above when the pointer was valid.
if [[ -z "$pr_number" && "$use_side_channel" -eq 1 && -n "$cd_target_dir" && "$pr_dir" == "$cwd" ]]; then
    if [[ -f "$cd_target_dir/.git/HEAD" ]]; then
        read -r _ct_head < "$cd_target_dir/.git/HEAD"
        if [[ "$_ct_head" == "ref: refs/heads/"* ]]; then
            pr_branch="${_ct_head#ref: refs/heads/}"; pr_dir="$cd_target_dir"
        elif [[ "$_ct_head" == ref:* ]]; then
            pr_branch="${_ct_head##*/}"; pr_dir="$cd_target_dir"
        fi
    elif [[ -f "$cd_target_dir/.git" ]]; then
        _read_gitdir_head "$cd_target_dir"
        if [[ "$_gitdir_head" == "ref: refs/heads/"* ]]; then
            pr_branch="${_gitdir_head#ref: refs/heads/}"; pr_dir="$cd_target_dir"
        elif [[ "$_gitdir_head" == ref:* ]]; then
            pr_branch="${_gitdir_head##*/}"; pr_dir="$cd_target_dir"
        fi
    fi
fi

# ── .wt_prev fallback: resolve the previous worktree's dir/branch so the
#    PR-segment block can fall back to it when the current .wt worktree (B)
#    has no PR. Only sets pr_dir_prev/pr_branch_prev — never touches pr_dir,
#    pr_branch, git_segment, branch, or repo name (location shows B; PR shows A).
#    Guards mirror the .wt block: use_side_channel, session_id set,
#    not already inside a worktree, valid TTL, dir live, HEAD is a branch ref.
#    Extra guard: content must differ from .wt (no self-fallback).
#    Requires pr_dir == wt_dir: the .wt block must have resolved B successfully
#    (HEAD validated as a branch ref → pr_dir redirected to wt_dir). Without
#    a confirmed live B, showing A's PR would be stale. ──
pr_dir_prev=""
pr_branch_prev=""
if [[ -z "$pr_number" && "$use_side_channel" -eq 1 && -n "$session_id" && \
      "$cwd_is_worktree" != "1" && -n "$wt_dir" && "$pr_dir" == "$wt_dir" ]]; then
    _wt_prev_file="$STATE_DIR/$session_id.wt_prev"
    if [[ -r "$_wt_prev_file" ]]; then
        _wt_prev_mtime=$(_mtime "$_wt_prev_file")
        [[ "$_wt_prev_mtime" =~ ^[0-9]+$ ]] || _wt_prev_mtime=0
        [[ -z "$now" ]] && now=$(date +%s)
        if [[ $(( now - _wt_prev_mtime )) -lt "$WT_POINTER_TTL_SEC" ]]; then
            _wt_prev_dir=""
            read -r _wt_prev_dir < "$_wt_prev_file" || true
            # Self-fallback guard: .wt_prev must differ from the current .wt.
            # wt_dir is already populated by the suppression block above — reuse it.
            # Same-repo guard: strip both paths to their repo root (the part before
            # /.claude/worktrees/ or /.worktrees/) and require they match — prevents
            # a cross-repo .wt_prev from showing a foreign repo's PR badge.
            _wt_root="${wt_dir%/.claude/worktrees/*}"
            [[ "$_wt_root" == "$wt_dir" ]] && _wt_root="${wt_dir%/.worktrees/*}"
            _wt_prev_root="${_wt_prev_dir%/.claude/worktrees/*}"
            [[ "$_wt_prev_root" == "$_wt_prev_dir" ]] && _wt_prev_root="${_wt_prev_dir%/.worktrees/*}"
            if [[ -n "$_wt_prev_dir" && "$_wt_prev_dir" != "$wt_dir" && \
                  -d "$_wt_prev_dir" && -n "$_wt_root" && \
                  "$_wt_root" == "$_wt_prev_root" ]]; then
                _read_gitdir_head "$_wt_prev_dir"
                _wt_prev_head="$_gitdir_head"
                if [[ "$_wt_prev_head" == "ref: refs/heads/"* ]]; then
                    pr_branch_prev="${_wt_prev_head#ref: refs/heads/}"
                    pr_dir_prev="$_wt_prev_dir"
                elif [[ "$_wt_prev_head" == ref:* ]]; then
                    pr_branch_prev="${_wt_prev_head##*/}"
                    pr_dir_prev="$_wt_prev_dir"
                fi
            fi
        fi
    fi
fi

# ── PR segment. Gated on whether the payload already resolved the PR:
#    github.com → Claude hands us pr.* (zero fork, carries review_state).
#    hosts that omit pr.* resolve via
#    a pr_dir:pr_branch-keyed `gh pr view` cache with background refresh. ──
pr_segment=""
if [[ -n "$pr_number" ]]; then
    # github.com path: pr.* already in the payload. No fork, no cache.
    _review_token "$pr_review"; tok="$_tok"
    if [[ -n "$pr_url" ]]; then
        pr_segment=$(printf '\033]8;;%s\033\\#%s\033]8;;\033\\%s' "$pr_url" "$pr_number" "$tok")
    else
        pr_segment="#$pr_number$tok"
    fi
elif [[ -n "$pr_branch" && -n "$pr_dir" ]]; then
    # Lookup path: no pr.* in the payload, so resolve the PR ourselves from a
    # pr_dir:pr_branch-keyed cache (pr_dir is the session cwd, or the active
    # worktree when one is recorded — see the PR resolution directory block).
    # Read-only on the hot path; a background `gh` refresh fills/updates it on
    # miss/stale. Cache line holds 6 \x1f-separated fields (see the read below
    # for why \x1f, not tab): number, url, isDraft, state, reviewDecision,
    # statusCheckRollup — the renderer normalizes fields 3–5 into a review-state
    # token and field 6 into a CI token. A legacy 2- or 5-field entry reads the
    # missing vars empty → no CI token (self-heals to the 6-field form on the next
    # TTL refresh); a legacy \t-delimited entry fails the numeric guard → miss.
    # shasum (Perl, always on macOS) may be absent on minimal Linux — fall back
    # to sha1sum. Both print "<hash>  <file>"; cut takes the hash column. An
    # empty key (neither tool present) would collapse cache_file to the pr-cache
    # dir, so gate the whole cache branch on a non-empty key.
    # Key includes session_id so two Claude sessions sharing one checkout never
    # collide on the same cache file. When both sessions fall through to
    # cwd:branch (no .wt/.active/.cd_target redirect — the common case when a
    # session checked out its branch via a Bash-subshell cd or git switch rather
    # than an EnterWorktree cd, so no side-channel pointer was written), pr_dir
    # and pr_branch are identical for both, and the last background gh writer
    # wins, showing session A the PR session B resolved. session_id is stable per
    # session, so a session still hits its own warm cache across its ~3/sec
    # renders; only between-session sharing stops. An empty session_id (older
    # harness) hashes an empty first field (":dir:branch") — a distinct key from
    # the old dir:branch files, so old-format files get a cache miss and trigger
    # a background refresh rather than a stale hit. Old-format dir:branch files
    # already on disk expire via the 1-day mtime sweep in statusline-hook.sh.
    cache_key=$(printf '%s:%s:%s' "${session_id:-}" "$pr_dir" "$pr_branch" | { shasum 2>/dev/null || sha1sum; } | cut -d' ' -f1)
    if [[ -n "$cache_key" ]]; then
        cache_file="$STATE_DIR/pr-cache/$cache_key"
        cache_refresh_needed=true   # default: refresh unless a fresh entry proves otherwise
        if [[ -r "$cache_file" ]]; then
            cache_mtime=$(_mtime "$cache_file"); [[ "$cache_mtime" =~ ^[0-9]+$ ]] || cache_mtime=0
            [[ -z "$now" ]] && now=$(date +%s)   # reuse the worktree-block fork if set
            # Fields are unit-separator (\x1f) delimited, NOT tab: bash `read`
            # collapses consecutive tabs (whitespace-class IFS), which would let
            # an empty reviewDecision eat the CI field. \x1f is non-whitespace, so
            # empty interior fields survive. (Legacy \t-delimited entries read as a
            # single field → cached_pr holds the whole line → fails the numeric
            # guard below → treated as a miss and self-heals on the next refresh.)
            IFS=$'\x1f' read -r cached_pr cached_url cached_isdraft cached_state cached_review cached_ci < "$cache_file"
            # Render TTL: terminal state (MERGED/CLOSED) → long TTL so the ✓merged
            # link stays visible after a ship; everything still-changing → live TTL
            # so a flip surfaces within ~a minute. A "none" line never carries
            # MERGED/CLOSED, so the else arm covers it.
            # Refresh TTL: always the live TTL for all states, including terminal.
            # This lets a background re-query detect a branch reused for a new PR
            # (the reused-branch bug) while still rendering ✓merged continuously
            # between refreshes. For truly finished PRs the writer's preservation
            # logic keeps the terminal entry alive when gh returns empty.
            if [[ "${cached_state:-}" == "MERGED" || "${cached_state:-}" == "CLOSED" ]]; then
                ttl="$PR_CACHE_TTL_SEC"
            else
                ttl="$PR_CACHE_LIVE_TTL_SEC"
            fi
            cache_age=$(( now - cache_mtime ))
            if [[ $cache_age -lt "$ttl" ]]; then
                # Render only when field 1 is a real PR number. Purely-numeric
                # guard also rejects "none", "0", and a legacy \t-delimited line
                # (which lands wholesale in cached_pr and contains tabs) → those
                # miss and self-heal on the next refresh.
                if [[ "$cached_pr" =~ ^[1-9][0-9]*$ ]]; then
                    # Normalize raw gh fields → _review_token vocabulary.
                    # MERGED wins; then draft; then review decision. An OPEN PR
                    # awaiting its first review (REVIEW_REQUIRED, or no decision
                    # yet) → ·ready, matching the github.com native path's
                    # `pending`→·ready so the lookup path and the payload path don't drift.
                    # Closed-unmerged falls through to empty → bare #N (a token
                    # there would mislead).
                    gtok=""
                    if [[ "${cached_state:-}" == "MERGED" ]]; then
                        gtok=merged
                    elif [[ "${cached_isdraft:-}" == "true" ]]; then
                        gtok=draft
                    elif [[ "${cached_review:-}" == "APPROVED" ]]; then
                        gtok=approved
                    elif [[ "${cached_review:-}" == "CHANGES_REQUESTED" ]]; then
                        gtok=changes
                    elif [[ "${cached_state:-}" == "OPEN" ]]; then
                        # Open, not draft, no approval/changes decision yet:
                        # REVIEW_REQUIRED or empty → awaiting review → ·ready.
                        gtok=ready
                    fi
                    _review_token "$gtok"; tok="$_tok"
                    # CI token from statusCheckRollup (lookup path only; absent for
                    # a legacy 5-field entry → empty → no CI token shown).
                    _ci_token "${cached_ci:-}"; citok="$_citok"
                    if [[ -n "${cached_url:-}" ]]; then
                        pr_segment=$(printf '\033]8;;%s\033\\#%s\033]8;;\033\\%s%s' "$cached_url" "$cached_pr" "$tok" "$citok")
                    else
                        pr_segment="#$cached_pr$tok$citok"
                    fi
                fi
            fi
            # Rate-limit the background refresh: suppress it when the entry is
            # younger than the live TTL regardless of state. Entries older than
            # the live TTL (≥60s) always need a refresh — including terminal
            # entries that are still render-fresh — so a reused-branch new open
            # PR replaces the stale MERGED entry within ~60s.
            # A future-dated mtime (clock skew) gives a negative cache_age, which
            # is also < PR_CACHE_LIVE_TTL_SEC — correctly treated as very fresh.
            if [[ $cache_age -lt "$PR_CACHE_LIVE_TTL_SEC" ]]; then
                cache_refresh_needed=false
            fi
        fi
        if [[ "$cache_refresh_needed" == true && "${STATUSLINE_NO_REFRESH:-}" != "1" ]]; then
            # Background refresh on miss/stale. STATUSLINE_NO_REFRESH=1 disables it
            # (test suite; see test-statusline.sh) and fully silences gh.
            (
                mkdir -p "$STATE_DIR/pr-cache"
                if command -v gh >/dev/null 2>&1; then
                    # Fields 1–5 as before; field 6 is the CI rollup. gh's
                    # statusCheckRollup is an ARRAY of individual checks — reduce
                    # it to ONE word here (cached), so the hot render path just
                    # maps a single token. Rollup rule: any FAILURE/ERROR/CANCELLED
                    # → FAILURE; else any PENDING/QUEUED/IN_PROGRESS → PENDING; else
                    # SUCCESS; empty array (no checks) → empty field → no CI token.
                    # Joined with \x1f (unit separator), NOT \t: the reader's `read`
                    # collapses runs of a whitespace-class delim, so a \t would let
                    # an empty reviewDecision eat the CI field. \x1f is non-whitespace.
                    # Derive GH_HOST from pr_dir's origin remote so cross-repo PRs on
                    # the origin host resolve correctly (without this, gh defaults to
                    # github.com, 401s, and cached_url stays empty → no OSC-8 link).
                    # Falls back to an already-set GH_HOST, then github.com.
                    _pr_origin_url=$(git -C "$pr_dir" remote get-url origin 2>/dev/null || true)
                    _pr_gh_host=""
                    case "$_pr_origin_url" in
                        http://*|https://*)
                            _pr_gh_host=$(printf '%s' "$_pr_origin_url" | sed -E 's#^https?://([^/@]+@)?([^/]+)/.*#\2#')
                            ;;
                        ssh://*@*|*@*:*)
                            _pr_gh_host=$(printf '%s' "$_pr_origin_url" | sed -E 's#^(ssh://)?[^@]+@([^/:]+)[:/].*#\2#')
                            ;;
                    esac
                    _pr_gh_host="${_pr_gh_host:-${GH_HOST:-github.com}}"
                    line=$(cd "$pr_dir" && GH_HOST="$_pr_gh_host" gh pr view --json number,url,isDraft,state,reviewDecision,statusCheckRollup \
                        --jq '[(.number|tostring),.url,(.isDraft|tostring),.state,(.reviewDecision//""),
                              ( [.statusCheckRollup[]? | (.conclusion // .state // "")] as $c
                                | if   ($c | any(. == "FAILURE" or . == "ERROR" or . == "CANCELLED" or . == "TIMED_OUT" or . == "ACTION_REQUIRED")) then "FAILURE"
                                  elif ($c | any(. == "PENDING" or . == "QUEUED" or . == "IN_PROGRESS" or . == "EXPECTED" or . == "")) then "PENDING"
                                  elif ($c | length) == 0 then ""
                                  else "SUCCESS" end )
                              ] | @tsv' 2>/dev/null | tr '\t' '\037' || echo "none")
                    [[ -z "$line" ]] && line="none"
                    # headRefName fallback: `gh pr view` keys off the checked-out branch
                    # NAME and misses when a foreign-repo worktree branch differs from the
                    # PR headRefName. Bridge by matching the HEAD commit SHA against open
                    # PRs' commits - name-independent. Forks stay in this background
                    # subshell; the render path is unaffected.
                    if [[ "$line" == "none" ]]; then
                        _head_sha=$(git -C "$pr_dir" rev-parse HEAD 2>/dev/null || true)
                        if [[ "$_head_sha" =~ ^[0-9a-f]{7,40}$ ]]; then
                            _sha_line=$(cd "$pr_dir" && GH_HOST="$_pr_gh_host" \
                                gh pr list --state all --search "$_head_sha" \
                                    --json number,url,isDraft,state,reviewDecision,statusCheckRollup,commits \
                                    --jq '[ .[] | select(any(.commits[]?; .oid == "'"$_head_sha"'")) ] as $matches
                                          | [ $matches[] | select(.state == "OPEN") ] as $open
                                          | if ($open | length) == 1 then $open[0]
                                            elif ($open | length) > 1 then empty
                                            elif ($matches | length) == 1 then $matches[0]
                                            else empty end
                                          | [(.number|tostring),.url,(.isDraft|tostring),.state,(.reviewDecision//""),
                                             ( [.statusCheckRollup[]? | (.conclusion // .state // "")] as $c
                                               | if   ($c | any(. == "FAILURE" or . == "ERROR" or . == "CANCELLED" or . == "TIMED_OUT" or . == "ACTION_REQUIRED")) then "FAILURE"
                                                 elif ($c | any(. == "PENDING" or . == "QUEUED" or . == "IN_PROGRESS" or . == "EXPECTED" or . == "")) then "PENDING"
                                                 elif ($c | length) == 0 then ""
                                                 else "SUCCESS" end )
                                            ] | @tsv' 2>/dev/null | tr '\t' '\037' || true)
                            [[ -n "$_sha_line" ]] && line="$_sha_line"
                        fi
                    fi
                    # Preserve a terminal (MERGED/CLOSED) cache entry when gh returns
                    # empty — the common squash-merge-and-delete-branch flow makes
                    # `gh pr view` return nothing (branch gone), but the PR itself
                    # still exists and its URL is already in the cache. Overwriting
                    # to "none" would kill the clickable ✓merged link; preserving
                    # lets the terminal entry age out naturally (long 600s TTL) and
                    # keeps the link alive after the ship.
                    if [[ "$line" == "none" && -r "$cache_file" ]]; then
                        _prev_state=""
                        IFS=$'\x1f' read -r _ _ _ _prev_state _ < "$cache_file" 2>/dev/null || true
                        if [[ "$_prev_state" == "MERGED" || "$_prev_state" == "CLOSED" ]]; then
                            # Preserve the terminal entry but bump its mtime so the TTL
                            # window resets from now. Without the touch the stale mtime
                            # keeps triggering refreshes on every render until the entry
                            # is purged by the 24h sweep rather than the 600s TTL.
                            touch "$cache_file" 2>/dev/null || true
                            line=""   # content already up-to-date; skip the printf write
                        fi
                    fi
                    [[ -n "$line" ]] && printf '%s' "$line" > "$cache_file"
                else
                    # gh not available — only write "none" if there's no
                    # existing terminal entry to preserve.
                    _gh_absent_state=""
                    [[ -r "$cache_file" ]] && IFS=$'\x1f' read -r _ _ _ _gh_absent_state _ < "$cache_file" 2>/dev/null || true
                    if [[ "$_gh_absent_state" != "MERGED" && "$_gh_absent_state" != "CLOSED" ]]; then
                        printf 'none' > "$cache_file"
                    else
                        # Bump mtime so the TTL window resets — same reason as
                        # the gh-available preservation path above.
                        touch "$cache_file" 2>/dev/null || true
                    fi
                fi
            ) &>/dev/null &
        fi
    fi
fi
# ── .wt_prev PR fallback: when the primary PR-segment pass yielded nothing
#    and a previous-worktree candidate was resolved above, try the cache for
#    that worktree. Renders PR number + review token only — git_segment,
#    branch, and repo name are not changed (location stays on B; PR shows A).
#    Background refresh uses the same pr_dir_prev so A's cache entry stays warm.
#    Cache key schema is identical to the primary block (session:dir:branch SHA1)
#    so the two blocks always resolve the same file for a given worktree.
#    NOTE: keep this block in sync with the primary PR-segment block above
#    (cache read, TTL logic, field parsing, token generation, gh refresh subshell).
if [[ -z "$pr_segment" && -n "$pr_dir_prev" && -n "$pr_branch_prev" ]]; then
    prev_cache_key=$(printf '%s:%s:%s' "${session_id:-}" "$pr_dir_prev" "$pr_branch_prev" | { shasum 2>/dev/null || sha1sum; } | cut -d' ' -f1)
    if [[ -n "$prev_cache_key" ]]; then
        prev_cache_file="$STATE_DIR/pr-cache/$prev_cache_key"
        prev_cache_refresh_needed=true   # default: refresh unless a fresh entry proves otherwise
        if [[ -r "$prev_cache_file" ]]; then
            prev_cache_mtime=$(_mtime "$prev_cache_file")
            [[ "$prev_cache_mtime" =~ ^[0-9]+$ ]] || prev_cache_mtime=0
            [[ -z "$now" ]] && now=$(date +%s)
            # Read the cache entry first so we can determine the correct TTL
            # (terminal MERGED/CLOSED state gets the long render TTL).
            # Refresh TTL is always the live TTL — see the primary block comment.
            IFS=$'\x1f' read -r prev_cached_pr prev_cached_url prev_cached_isdraft prev_cached_state prev_cached_review prev_cached_ci < "$prev_cache_file" || true
            if [[ "${prev_cached_state:-}" == "MERGED" || "${prev_cached_state:-}" == "CLOSED" ]]; then
                prev_ttl="$PR_CACHE_TTL_SEC"
            else
                prev_ttl="$PR_CACHE_LIVE_TTL_SEC"
            fi
            prev_cache_age=$(( now - prev_cache_mtime ))
            if [[ $prev_cache_age -lt "$prev_ttl" ]]; then
                if [[ "$prev_cached_pr" =~ ^[1-9][0-9]*$ ]]; then
                    prev_gtok=""
                    if [[ "${prev_cached_state:-}" == "MERGED" ]]; then
                        prev_gtok=merged
                    elif [[ "${prev_cached_isdraft:-}" == "true" ]]; then
                        prev_gtok=draft
                    elif [[ "${prev_cached_review:-}" == "APPROVED" ]]; then
                        prev_gtok=approved
                    elif [[ "${prev_cached_review:-}" == "CHANGES_REQUESTED" ]]; then
                        prev_gtok=changes
                    elif [[ "${prev_cached_state:-}" == "OPEN" ]]; then
                        prev_gtok=ready
                    fi
                    _review_token "$prev_gtok"; tok="$_tok"
                    _ci_token "${prev_cached_ci:-}"; citok="$_citok"
                    if [[ -n "${prev_cached_url:-}" ]]; then
                        pr_segment=$(printf '\033]8;;%s\033\\#%s\033]8;;\033\\%s%s' "$prev_cached_url" "$prev_cached_pr" "$tok" "$citok")
                    else
                        pr_segment="#$prev_cached_pr$tok$citok"
                    fi
                fi
            fi
            # Rate-limit refresh: suppress when younger than the live TTL.
            # See primary block comment for the terminal-entry refresh rationale
            # and the future-mtime (negative age) edge case note.
            if [[ $prev_cache_age -lt "$PR_CACHE_LIVE_TTL_SEC" ]]; then
                prev_cache_refresh_needed=false
            fi
        fi
        if [[ "$prev_cache_refresh_needed" == true && "${STATUSLINE_NO_REFRESH:-}" != "1" ]]; then
            (
                mkdir -p "$STATE_DIR/pr-cache"
                if command -v gh >/dev/null 2>&1; then
                    _pr_origin_url=$(git -C "$pr_dir_prev" remote get-url origin 2>/dev/null || true)
                    _pr_gh_host=""
                    case "$_pr_origin_url" in
                        http://*|https://*)
                            _pr_gh_host=$(printf '%s' "$_pr_origin_url" | sed -E 's#^https?://([^/@]+@)?([^/]+)/.*#\2#')
                            ;;
                        ssh://*@*|*@*:*)
                            _pr_gh_host=$(printf '%s' "$_pr_origin_url" | sed -E 's#^(ssh://)?[^@]+@([^/:]+)[:/].*#\2#')
                            ;;
                    esac
                    _pr_gh_host="${_pr_gh_host:-${GH_HOST:-github.com}}"
                    line=$(cd "$pr_dir_prev" && GH_HOST="$_pr_gh_host" gh pr view --json number,url,isDraft,state,reviewDecision,statusCheckRollup \
                        --jq '[(.number|tostring),.url,(.isDraft|tostring),.state,(.reviewDecision//""),
                              ( [.statusCheckRollup[]? | (.conclusion // .state // "")] as $c
                                | if   ($c | any(. == "FAILURE" or . == "ERROR" or . == "CANCELLED" or . == "TIMED_OUT" or . == "ACTION_REQUIRED")) then "FAILURE"
                                  elif ($c | any(. == "PENDING" or . == "QUEUED" or . == "IN_PROGRESS" or . == "EXPECTED" or . == "")) then "PENDING"
                                  elif ($c | length) == 0 then ""
                                  else "SUCCESS" end )
                              ] | @tsv' 2>/dev/null | tr '\t' '\037' || echo "none")
                    [[ -z "$line" ]] && line="none"
                    # headRefName fallback - mirror of the primary block above.
                    if [[ "$line" == "none" ]]; then
                        _head_sha=$(git -C "$pr_dir_prev" rev-parse HEAD 2>/dev/null || true)
                        if [[ "$_head_sha" =~ ^[0-9a-f]{7,40}$ ]]; then
                            _sha_line=$(cd "$pr_dir_prev" && GH_HOST="$_pr_gh_host" \
                                gh pr list --state all --search "$_head_sha" \
                                    --json number,url,isDraft,state,reviewDecision,statusCheckRollup,commits \
                                    --jq '[ .[] | select(any(.commits[]?; .oid == "'"$_head_sha"'")) ] as $matches
                                          | [ $matches[] | select(.state == "OPEN") ] as $open
                                          | if ($open | length) == 1 then $open[0]
                                            elif ($open | length) > 1 then empty
                                            elif ($matches | length) == 1 then $matches[0]
                                            else empty end
                                          | [(.number|tostring),.url,(.isDraft|tostring),.state,(.reviewDecision//""),
                                             ( [.statusCheckRollup[]? | (.conclusion // .state // "")] as $c
                                               | if   ($c | any(. == "FAILURE" or . == "ERROR" or . == "CANCELLED" or . == "TIMED_OUT" or . == "ACTION_REQUIRED")) then "FAILURE"
                                                 elif ($c | any(. == "PENDING" or . == "QUEUED" or . == "IN_PROGRESS" or . == "EXPECTED" or . == "")) then "PENDING"
                                                 elif ($c | length) == 0 then ""
                                                 else "SUCCESS" end )
                                            ] | @tsv' 2>/dev/null | tr '\t' '\037' || true)
                            [[ -n "$_sha_line" ]] && line="$_sha_line"
                        fi
                    fi
                    if [[ "$line" == "none" && -r "$prev_cache_file" ]]; then
                        _prev_state=""
                        IFS=$'\x1f' read -r _ _ _ _prev_state _ < "$prev_cache_file" 2>/dev/null || true
                        if [[ "$_prev_state" == "MERGED" || "$_prev_state" == "CLOSED" ]]; then
                            touch "$prev_cache_file" 2>/dev/null || true
                            line=""
                        fi
                    fi
                    [[ -n "$line" ]] && printf '%s' "$line" > "$prev_cache_file"
                else
                    _gh_absent_state=""
                    [[ -r "$prev_cache_file" ]] && IFS=$'\x1f' read -r _ _ _ _gh_absent_state _ < "$prev_cache_file" 2>/dev/null || true
                    if [[ "$_gh_absent_state" != "MERGED" && "$_gh_absent_state" != "CLOSED" ]]; then
                        printf 'none' > "$prev_cache_file"
                    else
                        touch "$prev_cache_file" 2>/dev/null || true
                    fi
                fi
            ) &>/dev/null &
        fi
    fi
fi

# ── No-repo fallback ───────────────────────────────────────────────────
if [[ -z "$git_segment" && -n "$cwd" ]]; then
    git_segment="📁 no-repo"
fi

# ── Context gauge segment ────────────────────────────────────────────────────
# Reads context_window.used_percentage from stdin (Claude Code pre-calculates it
# from input + cache tokens). Renders nothing if the field is absent.
#
# Colors are fixed best-practice bands (not relative to user threshold) so the
# signal means the same thing regardless of the user's setting:
#   green  <60  — plenty of headroom
#   yellow 60+  — filling; consider compacting at a natural seam
#   yellow (budget-5)+  — nag fires: "approaching" (≥budget-5, below budget)
#   red    ≥budget      — "⚠ /compact recommended"
#              floor is max(60, budget-5) so approaching never fires below the yellow band
#
# Budget is derived from the live context_window_size per render so it is correct
# for both 200K and 1M-window models and survives a mid-session /model switch.
# Default: 80% of the window (a practical advisory for tool-heavy agents;
# see docs/cost-governance.md). User overrides: autoCompactWindow (tokens, wins) or
# legacy autoCompactThreshold (%, fallback; accepts 1-100) resolved across
# all settings layers anchored to project_dir from the payload.
#
# used_percentage can exceed 100 once the window is overrun — handled explicitly.
# When context_window_size is absent (older harness builds) the budget falls back
# to a fixed 80% band so the nag still fires and the gauge still renders.
_resolve_compact_budget_pct() {
    # Returns: _budget_pct  (integer 1-100, default 80; 100 = budget beyond current window)
    # Precedence (highest wins, checked first):
    #   1. env CLAUDE_CODE_AUTO_COMPACT_WINDOW (token count → exits early)
    #   2. settings layers (global → project → project-local; last non-empty wins):
    #      autoCompactWindow (token count) tracked independently, wins over autoCompactThreshold
    #   3. env CLAUDE_AUTOCOMPACT_PCT_OVERRIDE (launch-time %; beats file-based threshold)
    #   4. settings layers: autoCompactThreshold (legacy % fallback; accepts 1-100)
    #   5. built-in default: 80%
    # Legacy percentage keys: CLAUDE_AUTOCOMPACT_PCT_OVERRIDE can only lower the
    # threshold (values above 80 are silently ignored by the harness); clamp to 1-80
    # so the statusline matches actual harness behavior. autoCompactThreshold is
    # undocumented; render whatever value the user set (1-100).
    _budget_pct=80  # built-in default: 80% of the live window
    local _val
    # Pass proj/cws via env so paths with apostrophes or backslashes are safe.
    _val=$(STATUSLINE_PROJ="${project_dir:-}" STATUSLINE_CWS="${ctx_win_size:-0}" python3 -c "
import json, os
try:
    proj = os.environ.get('STATUSLINE_PROJ', '')
    cws  = int(os.environ.get('STATUSLINE_CWS', '0') or 0)
    # CLAUDE_CODE_AUTO_COMPACT_WINDOW env var (documented equivalent of autoCompactWindow)
    env_win = os.environ.get('CLAUDE_CODE_AUTO_COMPACT_WINDOW', '')
    if env_win.strip().lstrip('-').isdigit() and cws > 0:
        pct = (int(env_win) * 100 + cws - 1) // cws  # ceiling: don't fire early
        if pct >= 1:
            print(min(pct, 100))  # cap at 100: beyond window = always past budget
            raise SystemExit(0)
    paths = [
        os.path.expanduser('~/.claude/settings.json'),
        os.path.join(proj, '.claude/settings.json')       if proj else None,
        os.path.join(proj, '.claude/settings.local.json') if proj else None,
    ]
    # Track keys independently across all layers so a higher-priority layer with
    # only autoCompactThreshold does not shadow a lower-priority autoCompactWindow.
    window_result = None
    threshold_result = None
    for p in paths:
        if not p or not os.path.isfile(p):
            continue
        try:
            d = json.load(open(p))
            win = d.get('autoCompactWindow')
            if win is not None and not isinstance(win, bool) and isinstance(win, (int, float)) and cws > 0:
                pct = (int(win) * 100 + cws - 1) // cws  # ceiling: don't fire early
                if pct >= 1:
                    window_result = min(pct, 100)  # cap: beyond window = always past budget
            # Also check env block inside settings file
            env_win2 = d.get('env', {}).get('CLAUDE_CODE_AUTO_COMPACT_WINDOW', '')
            if str(env_win2).strip().lstrip('-').isdigit() and cws > 0:
                pct2 = (int(env_win2) * 100 + cws - 1) // cws  # ceiling: don't fire early
                if pct2 >= 1:
                    window_result = min(pct2, 100)  # cap: beyond window = always past budget
            thr = d.get('autoCompactThreshold')
            if thr is not None and str(thr).isdigit():
                t = int(thr)
                if 1 <= t <= 100:
                    threshold_result = t
        except Exception:
            pass  # skip malformed layer; don't discard values from other layers
    # token budget wins; then process-env % override (launch-time, beats file-based %);
    # then file-based threshold; then the built-in default.
    if window_result is not None:
        result = window_result
    else:
        pct_override = os.environ.get('CLAUDE_AUTOCOMPACT_PCT_OVERRIDE', '').strip()
        if pct_override.isdigit():
            t = int(pct_override)
            result = t if 1 <= t <= 80 else threshold_result
        else:
            result = threshold_result
    if result is not None:
        print(result)
except Exception:
    pass
" 2>/dev/null)
    [[ "$_val" =~ ^[0-9]+$ ]] && _budget_pct="$_val"
}
ctx_segment=""
if [[ -n "$ctx_pct" ]]; then
    # cap bar fill at 8 blocks; used_percentage > 100 treated as full bar
    _display_pct=$(( ctx_pct > 100 ? 100 : ctx_pct ))
    filled=$(( (_display_pct * 8 + 50) / 100 )); (( filled > 8 )) && filled=8
    bar=""; for ((n=0; n<8; n++)); do (( n < filled )) && bar+="▓" || bar+="░"; done
    _budget_pct=80  # built-in default; overridden by _resolve_compact_budget_pct if settings found
    _resolve_compact_budget_pct
    # Approaching band: budget-5, floored at 60 (yellow starts there).
    # Keeps approaching strictly below budget even when the user sets a low threshold.
    _approach_floor=$(( _budget_pct - 5 < 60 ? 60 : _budget_pct - 5 ))
    if   (( ctx_pct >= _budget_pct )); then
        color=$'\033[31m'; nag="  ⚠ /compact recommended"                  # red, past advisory
    elif (( ctx_pct >= _approach_floor )); then
        color=$'\033[33m'; nag="  ⚠ /compact approaching"                 # yellow, approaching
    elif (( ctx_pct >= 60 )); then color=$'\033[33m'; nag=""               # yellow
    else                          color=$'\033[32m'; nag=""; fi             # green
    ctx_segment=$(printf '%sctx %s %d%%\033[0m%s' "$color" "$bar" "$ctx_pct" "$nag")
fi

# ── 7-day token-limit gauge ────────────────────────────────────────────────
# Same bar language as context: 8-cell ▓/░, green <60, yellow 60-79, red ≥80.
# Account weekly limit from rate_limits.seven_day.used_percentage. Omitted when
# the field is absent (before the first API response, or non-subscription usage).
week_segment=""
if [[ -n "$week_pct" ]]; then
    _display_pct=$(( week_pct > 100 ? 100 : week_pct ))
    filled=$(( (_display_pct * 8 + 50) / 100 )); (( filled > 8 )) && filled=8
    bar=""; for ((n=0; n<8; n++)); do (( n < filled )) && bar+="▓" || bar+="░"; done
    if   (( week_pct >= 80 )); then color=$'\033[31m'
    elif (( week_pct >= 60 )); then color=$'\033[33m'
    else                            color=$'\033[32m'; fi
    week_segment=$(printf '%s7d %s %d%%\033[0m' "$color" "$bar" "$week_pct")
fi

# ── Model segment ──────────────────────────────────────────────────────────
# The LEAD model's display name (e.g. "Claude Opus 5"). Lead only — the payload
# carries no subagent-tier field, so dispatched work silently runs Sonnet under
# the floor while this still reads the lead. Renders nothing if the field is
# absent. No cost figure by design (see the parse comment above).
model_segment=""
[[ -n "$model_name" ]] && model_segment="🧠 $model_name"

# ── Bottom bar. Two domains split by a │ divider. ────────────────────────────
# (The cross-tab tab-title icon is emitted by statusline-hook.sh via the
#  terminalSequence channel — NOT here. Claude Code does not relay OSC that a
#  statusLine command prints to stdout, so the renderer only draws the bar.)
# LEFT of │ = your work (location, PR, CI). RIGHT of │ = Claude session state
# (working/ready, context gauge + ⚠ /compact nag). One glance tells you which
# domain you're reading. The divider appears only when BOTH halves have content;
# a half alone renders with no stray │. Location anchors the left; the segments
# that change turn-to-turn and may want action sit at the right edge.
_join() { local out="" seg; for seg in "$@"; do [[ -n "$seg" ]] && out="${out:+$out  }$seg"; done; printf '%s' "$out"; }
work_half=$(_join "$git_segment" "$pr_segment")
claude_half=$(_join "$state_segment" "$ctx_segment" "$turns_segment" "$model_segment" "$week_segment")
if [[ -n "$work_half" && -n "$claude_half" ]]; then
    line="$work_half  |  $claude_half"
else
    line="$work_half$claude_half"   # one is empty; no divider, no stray spaces
fi
printf '%s\n' "$line"

exit 0

