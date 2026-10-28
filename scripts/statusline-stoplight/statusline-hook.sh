#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Hook: statusline-hook  (v2)
#
# Fires on:    UserPromptSubmit, PermissionRequest, PermissionDenied,
#              Notification, PreToolUse, PostToolUse, PostToolBatch,
#              PostToolUseFailure, Elicitation, ElicitationResult,
#              Stop, StopFailure, SubagentStop,
#              PreCompact, PostCompact  (per .claude/hooks/statusline/hooks.json)
# What it does: Writes one of "running" | "waiting" | "idle" to the session's state
#              file (read by statusline.sh for the bottom bar) AND emits the cross-tab
#              tab-title icon via the `terminalSequence` hook-output channel — the only
#              path that reaches the terminal tab (hooks run detached, so a /dev/tty
#              write goes nowhere; and Claude Code does not relay OSC that a statusLine
#              command prints to stdout). The event → state → icon mapping lives in the
#              `case` block below (each arm is commented); this header explains the WHY
#              the code can't.
#
# Two-icon tab: 🔴 = this tab needs you (a permission prompt or a blocking
#              AskUserQuestion). 🟢 = this tab is done and waiting for your next prompt
#              (a passive "don't forget me" reminder).
#              No icon = working, leave it alone. The title is REPLACED, not prefixed:
#              Claude Code never exposes its own task-summary title text to a hook, and
#              re-asserts its own OSC-2 title as the conversation progresses — so the
#              installer sets CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 to silence Claude's
#              writer and stop it racing this hook (env var confirmed by anthropics/
#              claude-code#3396; title-not-in-payload by #3161).
#
# WHY 🔴 fires on PermissionRequest, not Notification:
#              Measured live — `PermissionRequest` fires ~6s BEFORE the `Notification`
#              event for the same permission prompt (Claude Code debounces Notification
#              internally; confirmed by anthropics/claude-code#43530). PermissionRequest
#              is near-instant, so it drives 🔴; Notification+permission_prompt is a slow
#              backstop.
#
# WHY AskUserQuestion uses PreToolUse as the fast 🔴 setter (and needs the .ask_pending
#              guard on Notification:agent_needs_input):
#              AskUserQuestion fires PreToolUse (ask-time) and PostToolUse (answer-time)
#              like any normal tool. The Notification:agent_needs_input backstop fires
#              AFTER the question is displayed — often after the user has already answered
#              and PostToolUse has already cleared 🔴 back to running. Without the guard,
#              the late Notification re-paints 🔴 while Claude is already crafting,
#              stranding it until Stop (~10-21s). Fix: PreToolUse(AskUserQuestion) → 🔴
#              immediately (fast, same model as PermissionRequest); PostToolUse clears it;
#              a .ask_pending marker lets agent_needs_input distinguish "question still live"
#              (reinforce) from "already answered" (no-op). AskUserQuestion is a lead-session
#              tool — the .agents counter and .subagent_drained are left untouched.
#
# WHY 🟢 is LATE (and that's OK): there is no fast "turn finished" event. `Stop` (the
#              only one) fires 10–21s late and fires on every response, not just the
#              final one (anthropics/claude-code#43507). 🟢 here is a *passive reminder*
#              ("this tab is ready, don't forget it"), not a time-sensitive alert, so the
#              lag is acceptable. The FLICKER GUARD handles Stop firing mid-turn: a
#              premature 🟢 is cleared by the very next PreToolUse/PostToolUse/
#              UserPromptSubmit (→running, no icon), so 🟢 only PERSISTS once the session
#              truly settles. The bottom bar carries the instant 🟢 for the focused pane.
#              RESIDUAL-LAG EDGE CASE: if the approved tool is the *last* action of the
#              turn AND the CLI fires no PostToolBatch/PostToolUseFailure/PermissionDenied
#              for it, 🔴 lingers until Stop (~10–21s). Whether those events fire depends
#              on the installed CLI version — this hook adopts them to minimize the lag,
#              but a single non-batch approval with no subsequent notification is still
#              bounded by Stop. No PermissionApproved event exists in Claude Code.
#
# WHY SubagentStop is GUARDED (resolves to running/no-icon, not idle):
#              (1) A subagent's PermissionRequest fires in the parent session and
#              correctly paints 🔴. If the subagent then stops, an unconditional
#              SubagentStop → idle would overwrite that 🔴 with 🟢, masking the
#              pending permission. (2) A subagent finishing mid-turn is NOT proof
#              the parent lead is done — it should not paint 🟢 prematurely. (3) A
#              late SubagentStop arriving after Stop/idle_prompt already wrote idle
#              must not erase the 🟢. The guard reads the persisted session state:
#              SubagentStop exits 0 (no write) when state is waiting or idle, and
#              resolves to running (no-icon) otherwise. The same guard applies to
#              the Notification agent_completed type.
#
# WHY background work needs a deferred-idle mechanism:
#              When the user dispatches work that outlives the current turn —
#              either an Agent tool call or a Bash run_in_background:true task —
#              the parent turn ends and Stop fires while the work is still
#              running. Stop → idle would paint 🟢 ("done") prematurely.
#
#              Two separate deferred-idle paths cover the two work types:
#
#              (A) BACKGROUND AGENTS: tracked via a per-session counter file
#              (.agents). PreToolUse(Agent) increments it; SubagentStop
#              decrements it. Stop/StopFailure/idle_prompt check the counter: if
#              > 0 they set stop_pending and stay running. When SubagentStop
#              decrements to 0 with stop_pending set, idle fires. Claude Code
#              fires BOTH SubagentStop and Notification+agent_completed for each
#              completion; SubagentStop is the sole counter owner to avoid
#              double-decrement. agent_completed participates in the terminal-
#              state guard and deferred-idle visual transition only (reads
#              counter, never writes). UserPromptSubmit clears stop_pending but
#              leaves the counter intact: old agents may still run across a new
#              turn, and their SubagentStop events drain the shared counter.
#
#              (A1) INLINE SUBAGENT TIMING RACE: SubagentStop fires as the
#              subagent finishes but BEFORE the lead's turn ends (Stop hasn't
#              fired yet). The counter drains to 0 with no stop_pending set.
#              Then Stop fires with counter=0 and no background tasks in the
#              payload — the plain Stop else-branch writes idle prematurely.
#              Fix: PreToolUse(Agent) increments a token counter
#              (.subagent_drained) at dispatch time — one token per dispatch.
#              This is the only event that reliably identifies a current-turn
#              dispatch: SubagentStop has no per-agent identity and cannot
#              distinguish current-turn from prior-turn completions. The token
#              counter generalises the original one-shot boolean: M dispatches
#              survive M Stop events before idle, so a session with multiple
#              concurrent backgrounded agents does not go 🟢 while any agent
#              is still live. Stop decrements the token and stays running while
#              tokens remain > 0; when the last token is consumed, Stop removes
#              the file and stays running one more event — the next Stop (or
#              idle_prompt / StopFailure) writes idle. SubagentStop only
#              decrements the .agents counter; it also clears the drain counter
#              when the counter drains to 0 in a terminal state (waiting or
#              idle) — in that case the drain-race cannot occur (Stop will not
#              spuriously defer). PostToolUseFailure(Agent) and
#              PermissionDenied(Agent) are the sole drain events for
#              failed/denied dispatches (no SubagentStop fires): they decrement
#              the counter AND clear the drain tokens when the decrement reaches
#              0. This is safe: if a sibling SubagentStop had already
#              decremented the counter to 0, the PostToolUseFailure/
#              PermissionDenied if-guard (_agents > 0) is false — no decrement,
#              no clear — so the drain tokens are preserved for the mixed-batch
#              case where Stop still needs to defer. If Stop already fired while
#              the agent was in flight (stop_pending set), and PostToolUseFailure/
#              PermissionDenied is the final drain, they complete the deferred
#              idle directly — no SubagentStop will arrive to do it. Stop checks
#              the drain counter: if non-zero and the only blocker, consume one
#              token and stay running; idle_prompt (which fires after Stop in
#              the turn-end sequence) then writes idle. StopFailure and
#              idle_prompt are direct-idle fallbacks when Stop cannot fire again.
#              If other blockers also exist (agents, shell tasks, cron), Stop
#              sets stop_pending and clears the drain counter — stop_pending
#              already covers the deferral, and leaving the counter would cause
#              a spurious extra deferral when the last blocker clears. PreToolUse
#              clears the counter only when no Agent is in flight (counter == 0);
#              a sibling non-Agent PreToolUse in the same parallel batch must
#              not clear a counter armed by a sibling PreToolUse(Agent) in that
#              same batch. UserPromptSubmit (new turn) unconditionally clears.
#              PostToolUse, PostToolBatch,
#              PostToolUseFailure(non-Agent), and PermissionDenied(non-Agent)
#              intentionally do NOT clear it: all can fire as completions of
#              sibling tools in a parallel batch, reopening the premature-idle
#              race. Residual limitation: a backgrounded agent whose completion
#              event never arrives self-heals on the next UserPromptSubmit
#              (line 680 unconditionally clears) — the same self-heal the
#              .agents counter relies on.
#
#              (B) BACKGROUND BASH TASKS (run_in_background:true): unlike
#              agents, background bash tasks have NO completion hook event —
#              they re-invoke the model as a UserPromptSubmit (new prompt_id,
#              indistinguishable from a real user message). There is also no
#              start-time counter to decrement. Instead, the Stop/StopFailure
#              handlers read the background_tasks array in the Stop
#              payload itself (available since Claude Code v2.1.145). If the
#              array contains any entry with type "shell", the turn ended while
#              a background bash task is still running; defer idle with the same
#              stop_pending mechanism. The UserPromptSubmit that fires on task
#              completion already sets state=running and clears stop_pending, so
#              no additional decrement step is needed — the re-invocation IS the
#              completion signal.
#
#              (C) SCHEDULED CRON WAKES (CronCreate recurring:false): /ship P5
#              and /bot-review Step 6 use a one-shot CronCreate to resume across
#              turns. This appears in neither the .agents counter nor the
#              background_tasks array, so without special handling Stop fires
#              idle (🟢) while a scheduled poll is still queued. Tracked via a
#              single-bit presence file (.cron_pending), modelled on
#              .stop_pending (.stop_pending clears every UserPromptSubmit;
#              .cron_pending does not) — NOT a counter, because a one-shot cron
#              has no observable completion event; a counter would never
#              decrement on silent-expiry rounds and strand the tab iconless.
#              .cron_pending stores the turn number at which it was last armed
#              (a single line, e.g. "3"). Stop and StopFailure check this stamp
#              against the current .turns value: if stamped-turn < current-turn
#              the wake has driven at least one full turn since arming; the
#              marker is stale and is drained (turn-age drain). A stampless or
#              unparseable body is treated as "current turn — do not drain" for
#              backward compatibility with externally-armed or legacy markers.
#              In an autonomous loop each wake re-arms CronCreate, refreshing the
#              stamp to the current turn; the marker persists until the loop stops
#              re-scheduling, at which point the next Stop sees a stale stamp.
#              Known tradeoff: if the user sends a manual prompt before a queued
#              one-shot fires, the turn counter increments and the drain fires
#              prematurely (tab shows 🟢 while the cron is still queued). This is
#              cosmetic — the tab self-corrects when the wake fires and re-arms.
#              There is no in-hook signal that identifies a cron-wake UPS vs. a
#              manual prompt, so this tradeoff is inherent to the turn-age design.
#              The 2h TTL reaper is retained as the orphan backstop for externally-
#              cancelled crons and resumed sessions.
#              CronDelete clears the marker on confirmed success (PostToolUse) —
#              a failed or denied delete leaves the marker armed since the wake
#              is still queued. UserPromptSubmit does NOT clear .cron_pending for
#              a live wake; a queued one-shot wake's marker survives across the
#              prompt that the wake itself delivers. The marker is drained by
#              PostToolUse(CronDelete) success, the turn-age drain at Stop, a TTL
#              reaper at UserPromptSubmit (2h ceiling — any marker older than that
#              is orphaned), or the cross-session orphan reaper.
#              A second file (.cron_pending_new) is set by PreToolUse(CronCreate)
#              only when it creates .cron_pending from scratch (no prior marker).
#              PostToolUseFailure/PermissionDenied use it to distinguish "this
#              call created the marker, wake never registered — safe to clear"
#              from "marker pre-existed, prior wake still queued — leave it".
#              .cron_pending_new is consumed (cleared) on PostToolUse(CronCreate)
#              success so a later failure in the same turn cannot mistake the
#              stale bit for a freshly-created marker. PostToolUse(CronDelete)
#              also clears it alongside .cron_pending. UserPromptSubmit sweeps
#              the stop markers and .cron_pending_new (a same-turn discriminator
#              that must not survive across turns) but NOT .cron_pending.
#
# What it modifies: $STATE_DIR/<session_id>; and prints a
#                   {"terminalSequence": "<OSC-0 set-title>"} JSON line on EVERY handled
#                   state — 🔴/🟢 + label on waiting/idle, bare label on running. The
#                   bare-label write CLEARS a prior icon (a tab title persists until
#                   overwritten, so we must actively reset it, not just stop emitting).
# State files:   <sid>              — current state string (running/waiting/idle)
#                <sid>.agents       — in-flight Agent dispatch counter (all turns)
#                <sid>.stop_pending — deferred-idle bit: Stop fired while agents live
#                <sid>.stop_pending_shell — deferred-idle bit: Stop fired with shell bg
#                <sid>.cron_pending — one-shot CronCreate wake is still queued;
#                                   body = turn number when last armed (for turn-age drain)
#                <sid>.cron_pending_new — same-turn discriminator for CronCreate
#                <sid>.subagent_drained — token counter: incremented by PreToolUse(Agent)
#                                at dispatch time (one token per dispatch); Stop
#                                decrements by one and stays running while tokens > 0;
#                                when the last token is consumed Stop removes the file
#                                and stays running one more event so idle_prompt can
#                                write idle correctly. Generalises the original boolean
#                                to handle M concurrent dispatches (M Stops needed).
#                                Cleared wholesale by Stop/StopFailure when other
#                                blockers exist (stop_pending covers the deferral).
#                                Also cleared wholesale by PreToolUse(non-Agent),
#                                ElicitationResult,
#                                Notification[elicitation_complete|elicitation_response],
#                                and PreCompact — but ONLY when no Agent is in flight
#                                (counter == 0); if an Agent is running, these events
#                                must not erase the marker or Stop will idle prematurely
#                                before the Agent drains. UserPromptSubmit (new turn)
#                                unconditionally clears.
#                                PostToolUse, PostToolBatch do NOT clear it.
#                                PostToolUseFailure(Agent) and PermissionDenied(Agent)
#                                clear it ONLY when their decrement drains the counter
#                                to 0 — that means they ARE the sole drain event, so
#                                Stop deferral is not needed; if the counter was already
#                                0 (a sibling SubagentStop ran first) their guard does
#                                not fire and the marker is preserved for Stop deferral.
#                                PostToolUseFailure(non-Agent) and PermissionDenied
#                                (non-Agent) do NOT clear it: both can fire as
#                                completions of sibling tools in a parallel batch before
#                                Stop, reopening the premature-idle race.
#                <sid>.turns        — turn counter (user prompts; session-length gauge)
#                <sid>.wt           — active worktree path (for tab label derivation)
# Tab icon limitation: terminals suppress the OSC-0 dot for the FOCUSED tab
#                   (there is nothing to indicate to a user already looking at it).
#                   🔴 on the focused tab is not visible in WezTerm or most terminals —
#                   this is expected. Use the bottom bar for active-tab status.
# Tab label:    a user-set/AI session name (from ~/.claude/sessions/<pid>.json —
#               the hook payload has no session_name field, only statusLine
#               stdin does) when one exists; otherwise a git-derived label off the
#               active worktree (recorded to <session_id>.wt) or, absent that, the
#               payload cwd. The resolver + priority order live at the label block
#               below.
# Failure mode: no-op — exit 0 on unrecognized event, malformed input, or missing
#               session_id. Hooks must not crash Claude Code.
# Shell prologue: `set -uo pipefail` intentional — `set -e` OMITTED so $(cat) and
#               benign non-zero inner stages don't abort. See
#               [[bash-set-e-command-substitution]].
# Self-test:  ./statusline-hook.sh --self-test
# ──────────────────────────────────────────────────────────────────────────────

set -uo pipefail

if [[ "${1:-}" == "--self-test" ]]; then
    echo "✓ statusline-hook self-test passed"
    exit 0
fi

STATE_DIR="${STATUSLINE_STATE_DIR:-$HOME/.claude/statusline-state}"
WT_POINTER_TTL_SEC=43200   # 12h — mirrors statusline.sh; both renderers must agree.

# Retention window for orphan state files (session + .turns + .wt) and pr-cache
# entries. Set longer than the 12h .wt TTL so orphan files drain within a day
# even on machines with busy sessions. pr-cache entries are cheap per file but
# accumulate; the age-based sweep below keeps them from accumulating indefinitely.
STATE_RETENTION_SEC=86400   # 1 day

# PreCompact-cadence thrash detector: THRASH_COUNT compactions within
# THRASH_WINDOW_SEC → state=thrashing (🔴 + bottom-bar alert). Self-heals on compaction gap.
THRASH_WINDOW_SEC=180
THRASH_COUNT=3

# Portable mtime — same BSD/GNU split as statusline.sh; one fork per event (not
# per ~3/sec render), so acceptable. Only used for the .wt TTL check below.
if stat -f %m / >/dev/null 2>&1; then
    _mtime() { stat -f %m "$1" 2>/dev/null; }
else
    _mtime() { stat -c %Y "$1" 2>/dev/null; }
fi

# Extract flat top-level string fields with bash regex — zero forks on the hot path.
INPUT=$(cat)
event=""
session_id=""
cwd=""
notif_type=""
tool_name=""
[[ "$INPUT" =~ \"hook_event_name\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && event="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && session_id="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && cwd="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"notification_type\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && notif_type="${BASH_REMATCH[1]}"
[[ "$INPUT" =~ \"tool_name\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && tool_name="${BASH_REMATCH[1]}"
# CLAUDE_PROJECT_DIR is set by the harness on every hook process, pinned to the
# session launch dir (never updated across cd/worktree moves). The hook payload's
# `cwd` field is live. When they differ the user genuinely moved mid-session.
launch_dir="${CLAUDE_PROJECT_DIR:-}"

# ── Debug probe (opt-in, off by default) ────────────────────────────────
# Set STATUSLINE_HOOK_DEBUG_LOG to an absolute file path to append one
# tab-separated log line per event:
#   <timestamp>\t<pid>\t<event>\t<notif_type>\t<tool_name>\t<agent_id>\t<agent_type>\t<prompt_id>\t<session_id>
# Useful for discovering which events the installed CLI actually fires
# (docs describe a superset; live probing is required before adopting new
# events). Safe: wrapped in `{ …; } 2>/dev/null || true` — must never crash.
# BSD date has no %N (macOS); use seconds only — $$ suffices for ordering.
if [[ -n "${STATUSLINE_HOOK_DEBUG_LOG:-}" ]]; then
    {
        _dbg_agent_id=""; _dbg_agent_type=""; _dbg_prompt_id=""
        [[ "$INPUT" =~ \"agent_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]   && _dbg_agent_id="${BASH_REMATCH[1]}"
        [[ "$INPUT" =~ \"agent_type\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && _dbg_agent_type="${BASH_REMATCH[1]}"
        [[ "$INPUT" =~ \"prompt_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]  && _dbg_prompt_id="${BASH_REMATCH[1]}"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$$" \
            "$event" "$notif_type" "$tool_name" \
            "$_dbg_agent_id" "$_dbg_agent_type" "$_dbg_prompt_id" "$session_id" \
            >> "$STATUSLINE_HOOK_DEBUG_LOG"
    } 2>/dev/null || true
fi

[[ -z "$session_id" ]] && exit 0
# session_id flows into file paths ($STATE_DIR/$session_id{,.wt,.turns}) and the
# grep needle below. Claude Code's own IDs are UUIDs, but honor the no-op-on-
# malformed-input contract: reject anything outside [A-Za-z0-9_-] so a crafted
# payload can't path-traverse the state writes (e.g. session_id="../../x").
[[ "$session_id" =~ ^[A-Za-z0-9_-]+$ ]] || exit 0

# ── Hook-fire counter (adoption telemetry, Layer 2) ─────────────────────
# Increment once per hook invocation, regardless of event type. A single
# aggregate file avoids per-event explosion. Same fork-free RMW idiom as
# the .turns counter; no new egress, no new hook.
[[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
_fires=0
[[ -r "$STATE_DIR/$session_id.fires" ]] && read -r _fires < "$STATE_DIR/$session_id.fires"
[[ "$_fires" =~ ^[0-9]+$ ]] || _fires=0
printf '%s' "$(( 10#$_fires + 1 ))" > "$STATE_DIR/$session_id.fires"
# Claude Code exposes a user-set/AI session name to the statusLine command
# (stdin `session_name`) but NOT to hooks — and the tab title is emitted here,
# in the hook (statusLine-stdout OSC isn't relayed to the tab; see header). So
# resolve the name from the on-disk session index instead: ~/.claude/sessions/
# <pid>.json holds {sessionId, name, nameSource}. Match our session_id to a
# file's sessionId and use its `name` ONLY when the user set it — nameSource
# absent (a `/rename`, `--name`, or AI title) wins; nameSource:"derived" is the
# auto default (e.g. "my-app-3f") and must NOT override branch·repo / basename.
# Grep-based (no jq/python dependency), one scan per event — immaterial like the
# unconditional `tr` below. SESSIONS_DIR override keeps the test hermetic.
# Sets `session_name` (empty when none / only a derived default).
session_name=""
_session_index_hit=0
_session_index_derived=0
_sessions_dir="${STATUSLINE_SESSIONS_DIR:-$HOME/.claude/sessions}"
if [[ -d "$_sessions_dir" ]]; then
    # Find the session file whose sessionId matches ours, then read its name +
    # nameSource from that same file. -l returns the path; -F keeps the match
    # literal. Grep the whole quoted field `"sessionId":"<id>"` rather than the
    # bare id: it scopes the match to the sessionId value (a UUID recurring in
    # another key's value can't false-match) and needs no `-w` — whose word
    # boundaries are ill-defined on a hyphenated UUID anyway. Real session files
    # are compact JSON (no space after the colon), so the no-space needle is
    # exact. Only the first match is used (session_id is unique across files).
    # Pass the DIR + --include rather than a shell glob: under `nullglob` an empty
    # dir would erase the glob and leave grep with no file args (it can't hang
    # here — stdin was drained by `cat` above — but the dir form is simply the
    # correct way to scope a recursive grep to *.json). --include goes BEFORE the
    # operands: BSD/GNU grep here permute it fine either way, but leading options
    # is what strict-POSIX getopt (no permutation) needs.
    _sf=$(grep -rlF --include='*.json' "\"sessionId\":\"$session_id\"" "$_sessions_dir" 2>/dev/null | head -1)
    if [[ -n "$_sf" && -r "$_sf" ]]; then
        _blob=$(<"$_sf")
        _session_index_hit=1
        # Only override when the name is NOT the derived default. A user rename /
        # AI title omits nameSource entirely; a derived name carries
        # "nameSource":"derived". Anchor the key to a preceding object boundary
        # ({ or , with optional whitespace) so the check matches nameSource as a
        # real JSON field, not the same bytes embedded inside another value: a
        # serializer escapes quotes inside a string (name `x "nameSource":"derived"`
        # → on disk `\"nameSource\":\"derived\"`), and the escaped `\"` fails the
        # bare `"` here — but the boundary anchor is the belt-and-suspenders that
        # also rejects any hand-crafted/malformed blob that slipped the escaping.
        # Assumes compact single-line JSON (what Claude Code writes); a pretty-
        # printed blob with a line-leading `"nameSource"` has no {/, on its line
        # and would be missed — not a supported input.
        if [[ ! "$_blob" =~ [{,][[:space:]]*\"nameSource\"[[:space:]]*:[[:space:]]*\"derived\" ]]; then
            # Capture the JSON string body allowing escapes: a name may contain
            # \" or \\ (e.g. `tab "q" \slash`). `(\\.|[^"\\])*` consumes either an
            # escaped pair or a plain char, so the capture spans the whole value
            # and stops at the real closing quote — a bare `[^"]*` would truncate
            # at the first \". Then unescape \" and \\ back to literals. The `[{,]`
            # boundary anchor mirrors the nameSource check above for consistency:
            # the leading literal `"` of `\"name\"` already pins the match to a
            # real quoted-key boundary (a key-suffix like `"app_name"` or an
            # escaped `\"name\"` inside another value can't match — the byte before
            # `name` is `_` / `\`, not `"`), so the anchor is defense-in-depth, not
            # load-bearing here; it keeps the two adjacent extractions identical.
            if [[ "$_blob" =~ [{,][[:space:]]*\"name\"[[:space:]]*:[[:space:]]*\"((\\.|[^\"\\])*)\" ]]; then
                session_name="${BASH_REMATCH[1]}"
                session_name="${session_name//\\\"/\"}"
                session_name="${session_name//\\\\/\\}"
            fi
        else
            # Name is derived — defer cleanup to after the event filter so
            # unsupported events remain fully no-op.
            _session_index_derived=1
        fi
    fi
fi

# ── Active-worktree tracking ────────────────────────────────────────────
# The session cwd stays at the repo root; Claude works a PR via `cd
# .claude/worktrees/<task> && …` subshells whose resulting cwd is unobservable
# (no hook payload carries it), so the badge would resolve root:main → none.
# Approximate the signal by matching a directory-ENTERING command — cd/pushd, or
# a `-C <dir>` flag — into a worktree, and record its abs path to
# <session_id>.wt. Requires a real verb, not a bare mention, so ls/grep/cp and
# `git worktree add|remove` don't repoint the badge. Last worktree entered wins;
# the renderer re-derives branch+PR and self-heals when the dir is gone.
#
# EnterWorktree tool: record .wt on PostToolUse using either:
#   (a) the payload cwd when it reflects the new worktree dir (.git is a file) —
#       covers versions of Claude Code where PostToolUse carries the updated cwd.
#   (b) the tool_input.path field — the explicit path passed to EnterWorktree
#       (path= form); absolute, so no resolution needed.
#   (c) the tool_input.name field — reconstruct the path as
#       $cwd/.claude/worktrees/<name> against the pre-switch cwd.
#       cwd in PostToolUse may already reflect the new dir; using the pre-switch
#       cwd (recorded in the PreToolUse arm) is safer for the (c) construction.
# Recording at PostToolUse (not Pre) means the worktree dir exists when we check.
# If the tool failed the renderer's TTL and self-heal paths handle stale pointers.
# PreToolUse arm: snapshot cwd before the switch so PostToolUse case (c) can
# reconstruct the linked-worktree path even when PostToolUse's cwd already
# reflects the new worktree (making cwd useless as a base for reconstruction).
if [[ "$tool_name" == "EnterWorktree" && "$event" == "PreToolUse" && -n "$cwd" ]]; then
    [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
    printf '%s' "$cwd" > "$STATE_DIR/$session_id.ewt_pre"
fi
if [[ "$tool_name" == "EnterWorktree" && "$event" == "PostToolUse" ]]; then
    _ewt_dir=""
    # (a) cwd is already the new worktree — PostToolUse cwd reflects the switch.
    if [[ -n "$cwd" && -f "$cwd/.git" ]]; then
        _ewt_dir="$cwd"
    fi
    # (b) explicit path= form: extract tool_input.path from the payload.
    if [[ -z "$_ewt_dir" ]]; then
        _ewt_path=""
        [[ "$INPUT" =~ \"path\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] && _ewt_path="${BASH_REMATCH[1]}"
        if [[ -n "$_ewt_path" && "$_ewt_path" == /* && -f "$_ewt_path/.git" ]]; then
            _ewt_dir="$_ewt_path"
        fi
    fi
    # (c) name= form: reconstruct from the pre-switch cwd + .claude/worktrees/<name>.
    if [[ -z "$_ewt_dir" ]]; then
        _ewt_name=""
        [[ "$INPUT" =~ \"name\"[[:space:]]*:[[:space:]]*\"([A-Za-z0-9._-]+)\" ]] && _ewt_name="${BASH_REMATCH[1]}"
        _ewt_pre_file="$STATE_DIR/$session_id.ewt_pre"
        _ewt_base="$cwd"
        [[ -r "$_ewt_pre_file" ]] && read -r _ewt_base < "$_ewt_pre_file"
        if [[ -n "$_ewt_name" && -n "$_ewt_base" ]]; then
            _ewt_candidate="$_ewt_base/.claude/worktrees/$_ewt_name"
            [[ -f "$_ewt_candidate/.git" ]] && _ewt_dir="$_ewt_candidate"
        fi
    fi
    if [[ -n "$_ewt_dir" ]]; then
        [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
        # Before overwriting .wt, save the displaced path to .wt_prev so the
        # renderer can fall back to the previous worktree's PR number.
        # Skip if .wt is already expired — copying a stale pointer resets its mtime
        # and would let the renderer treat it as fresh for another 12h.
        if [[ -r "$STATE_DIR/$session_id.wt" ]]; then
            _ewt_wt_mtime=$(_mtime "$STATE_DIR/$session_id.wt")
            [[ "$_ewt_wt_mtime" =~ ^[0-9]+$ ]] || _ewt_wt_mtime=0
            _ewt_now=$(date +%s)
            if (( _ewt_now - _ewt_wt_mtime < WT_POINTER_TTL_SEC )); then
                _ewt_old_wt=""
                read -r _ewt_old_wt < "$STATE_DIR/$session_id.wt" || true
                if [[ -n "$_ewt_old_wt" && "$_ewt_old_wt" != "$_ewt_dir" ]]; then
                    printf '%s' "$_ewt_old_wt" > "$STATE_DIR/$session_id.wt_prev"
                fi
            fi
        fi
        printf '%s' "$_ewt_dir" > "$STATE_DIR/$session_id.wt"
        # Clear any stale .cd_target when entering an own (same-repo) worktree.
        # EnterWorktree doesn't go through cd_target_tracker (no Bash cd command),
        # so a stale cross-repo pointer from an earlier stint is never auto-cleared.
        # Own worktrees: <base>/.claude/worktrees/<name> or <base>/.worktrees/<name>.
        # Derive the repo root from ewt_pre; if ewt_pre is missing and cwd already
        # reflects the new worktree, strip the worktree suffix to recover the root.
        _ewt_base_for_clear="$cwd"
        [[ -r "$STATE_DIR/$session_id.ewt_pre" ]] && read -r _ewt_base_for_clear < "$STATE_DIR/$session_id.ewt_pre"
        # Guard: if the base still contains a worktree path (ewt_pre was missing and
        # PostToolUse cwd reflects the new worktree), strip the suffix so the prefix
        # check is against the repo root, not the worktree dir itself.
        [[ "$_ewt_base_for_clear" =~ ^(.*)/\.claude/worktrees/[^/]+$ ]] && _ewt_base_for_clear="${BASH_REMATCH[1]}"
        [[ "$_ewt_base_for_clear" =~ ^(.*)/\.worktrees/[^/]+$ ]] && _ewt_base_for_clear="${BASH_REMATCH[1]}"
        if [[ -n "$_ewt_base_for_clear" && \
              ( "$_ewt_dir" == "$_ewt_base_for_clear/.claude/worktrees/"* || \
                "$_ewt_dir" == "$_ewt_base_for_clear/.worktrees/"* ) ]]; then
            # Clear .cd_target only (not .cd_ack): the ack tracks whether the
            # one-time cross-repo warning has fired; clearing it here would re-arm
            # the warning for the next cross-repo cd in the same session.
            rm -f "$STATE_DIR/$session_id.cd_target" 2>/dev/null || true
        fi
    fi
    rm -f "$STATE_DIR/$session_id.ewt_pre"
fi
# PostToolUseFailure: EnterWorktree failed — clean up the pre-switch cwd snapshot
# so a stale ewt_pre from a failed call doesn't corrupt the next successful one.
if [[ "$tool_name" == "EnterWorktree" && "$event" == "PostToolUseFailure" ]]; then
    rm -f "$STATE_DIR/$session_id.ewt_pre"
fi
# ExitWorktree PostToolUse: clear .wt so the badge reverts to the actual cwd
# branch instead of holding the stale worktree pointer until the 12h TTL.
# PostToolUseFailure is intentionally excluded — a failed exit leaves the session
# still inside the worktree.
if [[ "$tool_name" == "ExitWorktree" && "$event" == "PostToolUse" ]]; then
    rm -f "$STATE_DIR/$session_id.wt" "$STATE_DIR/$session_id.wt_prev" 2>/dev/null || true
fi
if [[ "$tool_name" == "Bash" ]]; then
    # Match the WHOLE payload, not tool_input.command: that value is JSON-escaped,
    # so an earlier `"` would truncate a `"command":"([^"]*)"` capture before the
    # path. Two conventions: `.claude/worktrees/<task>` (own-repo, workspace-governance
    # SKILL.md § Worktrees) and `.worktrees/<task>` (foreign-repo isolation).
    # Two patterns keep BASH_REMATCH indices stable: cd/pushd → prefix [3] kind [4]
    # slug [5]; -C → prefix [2] kind [3] slug [4]. The leading boundary group stops
    # a substring match (`abcd`, a token ending in `-C` like `--no-C`).
    _wt_prefix=""; _wt_task=""; _wt_kind=""
    if [[ "$INPUT" =~ (^|[^A-Za-z0-9_])(cd|pushd)[[:space:]]+([^[:space:]\"]*/)?(\.claude/worktrees/|\.worktrees/)([A-Za-z0-9._-]+) ]]; then
        _wt_prefix="${BASH_REMATCH[3]}"; _wt_kind="${BASH_REMATCH[4]}"; _wt_task="${BASH_REMATCH[5]}"
    elif [[ "$INPUT" =~ (^|[^A-Za-z0-9_-])-C[[:space:]]+([^[:space:]\"]*/)?(\.claude/worktrees/|\.worktrees/)([A-Za-z0-9._-]+) ]]; then
        _wt_prefix="${BASH_REMATCH[2]}"; _wt_kind="${BASH_REMATCH[3]}"; _wt_task="${BASH_REMATCH[4]}"
    fi
    if [[ -n "$_wt_task" ]]; then
        # Absolute prefix → the real target dir; relative/empty → resolve against
        # the session cwd, preserving the prefix so a nested worktree still resolves.
        if [[ "$_wt_prefix" == /* ]]; then
            _wt_dir="${_wt_prefix}${_wt_kind}$_wt_task"
        else
            _wt_dir="$cwd/${_wt_prefix}${_wt_kind}$_wt_task"
        fi
        # Only record a worktree that actually exists — a torn-down task or a
        # slug from an unexpected context shouldn't repoint the badge at a dead dir.
        if [[ -d "$_wt_dir" ]]; then
            [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
            # Before overwriting .wt, save the displaced path to .wt_prev so the
            # renderer can fall back to the previous worktree's PR number.
            # Skip if .wt is already expired — copying a stale pointer resets its mtime
            # and would let the renderer treat it as fresh for another 12h.
            if [[ -r "$STATE_DIR/$session_id.wt" ]]; then
                _bash_wt_mtime=$(_mtime "$STATE_DIR/$session_id.wt")
                [[ "$_bash_wt_mtime" =~ ^[0-9]+$ ]] || _bash_wt_mtime=0
                _bash_now=$(date +%s)
                if (( _bash_now - _bash_wt_mtime < WT_POINTER_TTL_SEC )); then
                    _bash_old_wt=""
                    read -r _bash_old_wt < "$STATE_DIR/$session_id.wt" || true
                    if [[ -n "$_bash_old_wt" && "$_bash_old_wt" != "$_wt_dir" ]]; then
                        printf '%s' "$_bash_old_wt" > "$STATE_DIR/$session_id.wt_prev"
                    fi
                fi
            fi
            printf '%s' "$_wt_dir" > "$STATE_DIR/$session_id.wt"
        fi
    fi
fi

# #1269 cwd fallback: fires on any PostToolUse event (not just Bash) so sessions
# that use only Edit/Write/Read/MCP tools while already in a foreign linked worktree
# still get .wt written. Gated on PostToolUse so it doesn't fire on PreToolUse or
# UserPromptSubmit (cwd is authoritative only after a tool completes).
# Skips when the Bash command-string matcher already wrote .wt this turn (_wt_task set).
if [[ "$event" == "PostToolUse" && -n "$cwd" && -f "$cwd/.git" \
      && ( -z "${_wt_task:-}" || ! -d "${_wt_dir:-}" ) ]]; then
    _cwd_gitdir=""
    read -r _cwd_gitdir < "$cwd/.git" 2>/dev/null || true
    # Strip the "gitdir: " prefix git writes to the .git file
    _cwd_gitdir="${_cwd_gitdir#gitdir: }"
    case "$_cwd_gitdir" in
        */.git/worktrees/*/modules/*)
            ;;  # submodule nested inside a linked worktree — not a session worktree; skip
        */.git/worktrees/*)
            [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
            # Honour the same TTL / .wt_prev pattern as the command-string writer.
            if [[ -r "$STATE_DIR/$session_id.wt" ]]; then
                _cwd_wt_mtime=$(_mtime "$STATE_DIR/$session_id.wt")
                [[ "$_cwd_wt_mtime" =~ ^[0-9]+$ ]] || _cwd_wt_mtime=0
                _cwd_now=$(date +%s)
                if (( _cwd_now - _cwd_wt_mtime < WT_POINTER_TTL_SEC )); then
                    _cwd_old_wt=""
                    read -r _cwd_old_wt < "$STATE_DIR/$session_id.wt" || true
                    if [[ -n "$_cwd_old_wt" && "$_cwd_old_wt" != "$cwd" ]]; then
                        printf '%s' "$_cwd_old_wt" > "$STATE_DIR/$session_id.wt_prev"
                    fi
                fi
            fi
            printf '%s' "$cwd" > "$STATE_DIR/$session_id.wt"
            ;;
    esac
fi

# ── Background-task deferred-idle helpers ───────────────────────────────────
# Since Claude Code v2.1.145, Stop/StopFailure payloads include a
# background_tasks array. Two helpers, one per task type.
# Pure bash regex — no jq dependency. Called from Stop/StopFailure/idle_prompt.
_has_shell_bg_tasks() {
    local _inp="$1"
    # Quick bail: no background_tasks key at all.
    [[ "$_inp" =~ \"background_tasks\" ]] || return 1
    # Check for at least one {"type":"shell"} entry. Require the opening quote to
    # be unescaped (not preceded by \) so an embedded \"type\":\"shell\" inside a
    # command string — which JSON encodes with backslash-escaped quotes — does not
    # false-match. The status field could be "running", "pending", etc. — any
    # shell entry means work is still in flight (Claude Code only populates the
    # array with active tasks at Stop time).
    [[ "$_inp" =~ (^|[^\\])\"type\"[[:space:]]*:[[:space:]]*\"shell\" ]] && return 0
    return 1
}
_has_agent_bg_tasks() {
    # Returns 0 (true) if background_tasks contains at least one subagent entry.
    # Belt-and-suspenders alongside the .agents counter: some agent dispatch paths
    # (e.g. remote/workflow agents) may not fire PreToolUse(Agent), leaving the
    # counter at 0 while an agent is still running. background_tasks[type=subagent]
    # is the authoritative payload signal in that case — defer idle just like shell.
    local _inp="$1"
    [[ "$_inp" =~ \"background_tasks\" ]] || return 1
    [[ "$_inp" =~ (^|[^\\])\"type\"[[:space:]]*:[[:space:]]*\"subagent\" ]] && return 0
    return 1
}
_cron_wake_stale() {
    # Returns 0 (true) if the .cron_pending marker is stale — i.e. its stamped turn
    # number is strictly less than the current .turns value, meaning at least one
    # full UserPromptSubmit→Stop cycle elapsed since the CronCreate that armed it.
    # When true the one-shot wake has already driven a turn and the runtime auto-
    # deleted the cron; draining the marker lets Stop reach idle.
    # Returns 1 (false, do not drain) when:
    #   - the marker doesn't exist
    #   - the body is empty or unparseable (stampless/legacy marker treated as current)
    #   - stamp >= current turn (wake not yet driven)
    local _sid="$1"
    [[ -f "$STATE_DIR/$_sid.cron_pending" ]] || return 1
    local _stamp='' _cur=0
    read -r _stamp < "$STATE_DIR/$_sid.cron_pending" 2>/dev/null || true
    [[ "$_stamp" =~ ^[0-9]+$ ]] || return 1   # stampless/garbage — treat as current
    [[ -r "$STATE_DIR/$_sid.turns" ]] && read -r _cur < "$STATE_DIR/$_sid.turns"
    [[ "$_cur" =~ ^[0-9]+$ ]] || _cur=0
    (( 10#$_stamp < 10#$_cur ))
}

case "$event" in
    UserPromptSubmit)   state="running"
        # Turn counter: the statusline payload carries no turn count, so we
        # persist our own — one increment per user prompt (the turn unit). The
        # renderer reads $session_id.turns and shows it as a plain session-length
        # gauge. Resets naturally: /clear starts a new session_id → a fresh
        # counter file → back to 0, matching the proxy cost meter's reset.
        # Fork-free: bash arithmetic, no wc/expr. A missing/garbage file reads
        # as 0 (the regex guard rejects non-digits; 10#-radix stops a
        # leading-zero value from being parsed as octal).
        [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
        _turns=0
        [[ -r "$STATE_DIR/$session_id.turns" ]] && read -r _turns < "$STATE_DIR/$session_id.turns"
        [[ "$_turns" =~ ^[0-9]+$ ]] || _turns=0
        printf '%s' "$(( 10#$_turns + 1 ))" > "$STATE_DIR/$session_id.turns"
        # Clear stop_pending so a deferred idle from the previous turn doesn't fire
        # as agents from the new turn complete. Do NOT clear .agents: background
        # agents dispatched in a prior turn may still be running when the user sends
        # a new prompt. Clearing their counter would let a late SubagentStop
        # decrement a new turn's in-flight count, firing premature 🟢. Leaving the
        # counter intact lets old and new agents self-drain to a shared zero, which
        # is the correct idle condition for the session.
        rm -f "$STATE_DIR/$session_id.stop_pending" "$STATE_DIR/$session_id.stop_pending_shell" \
              "$STATE_DIR/$session_id.cron_pending_new" \
              "$STATE_DIR/$session_id.subagent_drained" \
              "$STATE_DIR/$session_id.ask_pending" 2>/dev/null || true
        # TTL reaper: clear .cron_pending when the marker is older than 2h (cron
        # interval ceiling). A live one-shot wake cannot exceed that TTL, so any
        # marker older than 2h must be orphaned (cron cancelled externally, session
        # resumed without a CronDelete). Clears here so the next Stop can reach idle.
        if [[ -f "$STATE_DIR/$session_id.cron_pending" ]]; then
            _cp_mtime=$(_mtime "$STATE_DIR/$session_id.cron_pending")
            _now=$(date +%s)
            if [[ -n "$_cp_mtime" ]] && (( _now - _cp_mtime > 7200 )); then
                rm -f "$STATE_DIR/$session_id.cron_pending" 2>/dev/null || true
            fi
        fi
        if [[ -f "$STATE_DIR/$session_id.thrash" ]]; then
            _compacts_line=""
            [[ -r "$STATE_DIR/$session_id.compacts" ]] && read -r _compacts_line < "$STATE_DIR/$session_id.compacts"
            set -- $_compacts_line
            _newest="${1:-}"
            while (( $# > 1 )); do shift; done
            [[ $# -ge 1 ]] && _newest="$1"
            _gap_now=$(date +%s)
            if [[ -z "$_newest" ]] || (( _gap_now - _newest > THRASH_WINDOW_SEC )); then
                rm -f "$STATE_DIR/$session_id.thrash" "$STATE_DIR/$session_id.compacts" 2>/dev/null || true
            fi
        fi
        ;;
    PreToolUse)         state="running"   # flicker guard — clears a premature 🟢
        # A new tool dispatch means the lead is still active — clear the subagent_drained
        # marker so a pending Stop from before this tool fires idle, not running.
        # Guard: only clear when no Agent dispatch is in flight; otherwise this may
        # be a sibling tool in the same parallel batch as an Agent, and clearing here
        # would erase the marker before the Agent's SubagentStop + Stop path needs it.
        # Exception: AskUserQuestion — see WHY block in header.
        if [[ "$tool_name" == "AskUserQuestion" ]]; then
            # Fast 🔴: question is now pending, tab needs user. Write "pending" into
            # the .ask_pending marker so a late Notification:agent_needs_input backstop
            # can distinguish three states: absent (no question this turn → fire normally),
            # "pending" (question live → reinforce waiting), "answered" (already resolved
            # → no-op, prevents re-painting 🔴 while Claude is crafting).
            # Do NOT touch .agents or .subagent_drained — AskUserQuestion is a lead-session
            # tool, not an Agent dispatch.
            [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
            printf '%s' "pending" > "$STATE_DIR/$session_id.ask_pending"
            state="waiting"
        else
            _ptu_agents=0
            [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _ptu_agents < "$STATE_DIR/$session_id.agents"
            [[ "$_ptu_agents" =~ ^[0-9]+$ ]] || _ptu_agents=0
            if (( _ptu_agents == 0 )); then
                rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
            fi
            # Track in-flight Agent dispatches. Each Agent PreToolUse increments the
            # per-session counter so Stop/idle_prompt can defer idle until all agents
            # complete. Only the "Agent" tool is counted; other tools are fire-and-
            # forget from the statusline's perspective (they complete within the turn).
            if [[ "$tool_name" == "Agent" ]]; then
                [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
                _agents=0
                [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
                [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
                printf '%s' "$(( 10#$_agents + 1 ))" > "$STATE_DIR/$session_id.agents"
                # Token counter for the timing-race guard: one token per Agent dispatch.
                # Stop decrements; while tokens > 0 Stop stays running; last token
                # consumed → file removed → next Stop writes idle. See header (A1).
                _sd=0
                [[ -r "$STATE_DIR/$session_id.subagent_drained" ]] \
                    && read -r _sd < "$STATE_DIR/$session_id.subagent_drained"
                [[ "$_sd" =~ ^[0-9]+$ ]] || _sd=0
                printf '%s' "$(( 10#$_sd + 1 ))" > "$STATE_DIR/$session_id.subagent_drained"
            elif [[ "$tool_name" == "CronCreate" ]]; then
                # A one-shot (recurring:false) cron wake is being scheduled — mark it
                # pending so Stop defers idle until the wake fires or is deleted.
                # Recurring crons have no natural completion event and are not treated
                # as bounded background work; only arm the marker for recurring:false.
                # Anchor on an unescaped leading quote to avoid false-matching this key
                # inside an escaped prompt string (e.g. a CronCreate prompt that mentions
                # the literal text "recurring": false). Store the pattern in a variable
                # so the backslash-and-quote sequence is not misread by the shell parser.
                _re_recurring='(^|[^\\])"recurring"[[:space:]]*:[[:space:]]*false'
                if [[ "$INPUT" =~ $_re_recurring ]]; then
                    [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
                    # Track whether this PreToolUse is creating the marker from scratch
                    # (no prior queued wake) so PostToolUseFailure/PermissionDenied can
                    # distinguish "new marker, wake never registered" from "pre-existing
                    # marker, prior wake still queued". Only set .cron_pending_new when
                    # .cron_pending does not yet exist.
                    if [[ ! -f "$STATE_DIR/$session_id.cron_pending" ]]; then
                        touch "$STATE_DIR/$session_id.cron_pending_new"
                        # Stamp the current turn number into the new marker. Stop uses this
                        # to drain stale markers via turn-age: if stamped-turn < current-turn
                        # the wake has driven at least one full turn and the cron auto-deleted.
                        # Only stamp when creating from scratch — a pre-existing marker's
                        # stamp must not be refreshed here, because a failed/denied call
                        # leaves the old marker intact (no .cron_pending_new → no rollback),
                        # and refreshing would disguise a stale stamp as current. The successful
                        # PostToolUse(CronCreate) re-stamp handles the refresh for re-arms.
                        _cp_turns=0
                        [[ -r "$STATE_DIR/$session_id.turns" ]] && read -r _cp_turns < "$STATE_DIR/$session_id.turns"
                        [[ "$_cp_turns" =~ ^[0-9]+$ ]] || _cp_turns=0
                        printf '%s' "$_cp_turns" > "$STATE_DIR/$session_id.cron_pending"
                    fi
                fi
            elif [[ "$tool_name" == "CronDelete" ]]; then
                # CronDelete not yet confirmed — keep cron_pending until PostToolUse
                # confirms success. A failed or denied delete means the wake is still
                # queued; clearing here would let Stop paint idle incorrectly.
                :
            fi
        fi
        ;;
    PostToolUse)
        # Flicker guard + clears 🔴 after approval. Also clear cron_pending when
        # CronDelete succeeds.
        # subagent_drained is NOT cleared here: PostToolUse fires for every tool
        # in a parallel batch, including non-Agent tools that run alongside an Agent.
        # In a mixed batch, a sibling PostToolUse(Bash) can arrive after SubagentStop
        # arms the marker but before PostToolBatch/Stop — clearing here reopens the
        # premature-idle race. Only PreToolUse (new dispatch) reliably proves the
        # lead is active and clears the marker safely.
        if [[ "$tool_name" == "CronDelete" ]]; then
            rm -f "$STATE_DIR/$session_id.cron_pending" \
                  "$STATE_DIR/$session_id.cron_pending_new" 2>/dev/null || true
        elif [[ "$tool_name" == "CronCreate" ]]; then
            # Successful CronCreate: re-assert .cron_pending for a registered
            # one-shot wake, then consume .cron_pending_new. Both ops are scoped
            # to recurring:false — a recurring create never sets .cron_pending_new
            # in PreToolUse, so clearing it here for a recurring success would
            # steal the bit from a concurrent one-shot call whose failure hasn't
            # arrived yet. Re-asserting .cron_pending handles the overlap case
            # where a concurrent failed CronCreate's PostToolUseFailure already
            # removed .cron_pending before this success event arrived.
            _re_recurring='(^|[^\\])"recurring"[[:space:]]*:[[:space:]]*false'
            if [[ "$INPUT" =~ $_re_recurring ]]; then
                [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
                # Re-stamp with current turn so the turn-age drain knows the loop
                # rescheduled and the wake is still live (not yet stale).
                _cp_turns=0
                [[ -r "$STATE_DIR/$session_id.turns" ]] && read -r _cp_turns < "$STATE_DIR/$session_id.turns"
                [[ "$_cp_turns" =~ ^[0-9]+$ ]] || _cp_turns=0
                printf '%s' "$_cp_turns" > "$STATE_DIR/$session_id.cron_pending"
                rm -f "$STATE_DIR/$session_id.cron_pending_new" 2>/dev/null || true
            fi
        fi
        # Mark question answered so a late Notification:agent_needs_input is a no-op.
        # "answered" (vs removing the file) lets the guard distinguish "answered this turn"
        # from "never asked" — both absent-marker states would otherwise look the same.
        if [[ "$tool_name" == "AskUserQuestion" ]]; then
            printf '%s' "answered" > "$STATE_DIR/$session_id.ask_pending" 2>/dev/null || true
        fi
        state="running"
        ;;
    PostToolBatch)      # 🔴 clear after a parallel tool batch; lead is active
        # Do NOT clear subagent_drained here — a batch can be the completion batch
        # for a set of parallel Agents. SubagentStop fires before PostToolBatch for
        # each agent in the batch, so the drain marker may be armed at this point.
        # Clearing it here would let the subsequent Stop fire idle prematurely.
        # The marker is consumed by Stop/StopFailure/idle_prompt or cleared on a
        # genuinely new dispatch (PreToolUse) or new turn (UserPromptSubmit).
        state="running" ;;
    PostToolUseFailure)
        # Clears 🔴 when an approved tool failed. Also decrement the in-flight
        # agent counter for a failed Agent dispatch (PostToolUse never fires for
        # a tool failure, and neither SubagentStop nor agent_completed arrives for
        # an Agent call that never launched a subagent successfully).
        state="running"
        if [[ "$tool_name" == "Agent" ]]; then
            _agents=0
            [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
            [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
            if (( _agents > 0 )); then
                _agents=$(( _agents - 1 ))
                printf '%s' "$_agents" > "$STATE_DIR/$session_id.agents"
                # A failed dispatch has no SubagentStop. When this failure drains
                # agents to 0, all in-flight agents are resolved — clear the entire
                # counter. This differs from Stop's per-token decrement: Stop fires
                # once per turn-end event; failure clears because no Stop-based
                # deferral remains possible once agents==0 (SubagentStop already ran
                # for any successful siblings, leaving their tokens consumed).
                # Guard: only when agents actually reached 0 — a non-zero remainder
                # means a sibling is still running; leave the counter intact.
                (( _agents == 0 )) && rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
                # If Stop already ran while this agent was in flight (stop_pending
                # set) and this failure is the final drain, complete the deferred
                # idle now — no SubagentStop will arrive to do it. Honor shell and
                # cron blockers (same guard as SubagentStop's stop_pending branch).
                if (( _agents == 0 )) && [[ -f "$STATE_DIR/$session_id.stop_pending" ]] \
                    && [[ ! -f "$STATE_DIR/$session_id.stop_pending_shell" ]] \
                    && [[ ! -f "$STATE_DIR/$session_id.cron_pending" ]]; then
                    rm -f "$STATE_DIR/$session_id.stop_pending" 2>/dev/null || true
                    state="idle"
                fi
            fi
        elif [[ "$tool_name" == "CronCreate" ]]; then
            # A failed CronCreate added no new wake. Only clear .cron_pending when
            # this PreToolUse was the one that created it (signalled by
            # .cron_pending_new); if the marker pre-existed, a prior successful wake
            # is still queued and clearing it would re-expose the original bug.
            if [[ -f "$STATE_DIR/$session_id.cron_pending_new" ]]; then
                rm -f "$STATE_DIR/$session_id.cron_pending" \
                      "$STATE_DIR/$session_id.cron_pending_new" 2>/dev/null || true
            fi
        elif [[ "$tool_name" == "AskUserQuestion" ]]; then
            # Failed question: mark answered so a late agent_needs_input backstop is
            # a no-op — same guard as PostToolUse(AskUserQuestion).
            printf '%s' "answered" > "$STATE_DIR/$session_id.ask_pending" 2>/dev/null || true
        fi
        ;;
    PermissionRequest)  state="waiting" ;;   # fast 🔴 — see header
    PermissionDenied)
        # Decrement the in-flight agent counter for a hook-blocked Agent dispatch.
        # PreToolUse(Agent) incremented it; a PreToolUse-blocked call (guard hook
        # exits 2) fires PermissionDenied instead of SubagentStop or
        # PostToolUseFailure, so this is the only event that can drain the counter.
        # Without this decrement the counter strands > 0 and Stop never reaches idle.
        state="running"   # auto-deny: clear any lingering 🔴 immediately
        if [[ "$tool_name" == "Agent" ]]; then
            _agents=0
            [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
            [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
            if (( _agents > 0 )); then
                _agents=$(( _agents - 1 ))
                printf '%s' "$_agents" > "$STATE_DIR/$session_id.agents"
                # A denied dispatch has no SubagentStop. Same clear-whole-when-zero
                # logic as PostToolUseFailure(Agent): once agents reaches 0, no more
                # Stop-based deferrals can occur, so the entire counter is consumed.
                (( _agents == 0 )) && rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
                # If Stop ran while this agent was in flight (stop_pending set)
                # and this denial is the final drain, complete the deferred idle
                # now — no SubagentStop will arrive. Honor shell and cron blockers.
                if (( _agents == 0 )) && [[ -f "$STATE_DIR/$session_id.stop_pending" ]] \
                    && [[ ! -f "$STATE_DIR/$session_id.stop_pending_shell" ]] \
                    && [[ ! -f "$STATE_DIR/$session_id.cron_pending" ]]; then
                    rm -f "$STATE_DIR/$session_id.stop_pending" 2>/dev/null || true
                    state="idle"
                fi
            fi
        elif [[ "$tool_name" == "CronCreate" ]]; then
            # A denied CronCreate added no new wake; same logic as
            # PostToolUseFailure — clear only a marker this turn created from scratch.
            if [[ -f "$STATE_DIR/$session_id.cron_pending_new" ]]; then
                rm -f "$STATE_DIR/$session_id.cron_pending" \
                      "$STATE_DIR/$session_id.cron_pending_new" 2>/dev/null || true
            fi
        elif [[ "$tool_name" == "AskUserQuestion" ]]; then
            # Denied question: mark answered so a late agent_needs_input backstop is
            # a no-op — same guard as PostToolUse/PostToolUseFailure(AskUserQuestion).
            printf '%s' "answered" > "$STATE_DIR/$session_id.ask_pending" 2>/dev/null || true
        fi
        ;;
    Elicitation)        state="waiting" ;;   # MCP server needs user input — 🔴
    ElicitationResult)
        # User answered an MCP elicitation — clear 🔴 and resume running.
        # Guard: only clear the drain marker when no Agent is in flight;
        # an elicitation resolving while a parallel Agent runs must not erase
        # the dispatch-time marker or Stop will write idle prematurely.
        _er_agents=0
        [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _er_agents < "$STATE_DIR/$session_id.agents"
        [[ "$_er_agents" =~ ^[0-9]+$ ]] || _er_agents=0
        (( _er_agents == 0 )) && rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
        state="running" ;;   # user answered elicitation — clear 🔴
    Stop)
        # 🟢 authoritative turn-end — but only when no background work is still
        # running. Three sources of in-flight background work are checked:
        #   (A) .agents counter > 0: a background Agent dispatch is still running.
        #   (B) background_tasks payload has a "shell" entry: a run_in_background
        #       Bash task is still running (available since Claude Code v2.1.145;
        #       probe-verified 2026-10-08: type:"shell", id, status, description,
        #       command fields present; both run_in_background:true and foreground-
        #       timeout paths produce identical {"type":"shell"} entries).
        #   (C) .cron_pending marker: a CronCreate one-shot wake is still queued
        #       (set by PreToolUse(CronCreate)); drained by PostToolUse(CronDelete)
        #       success, the turn-age drain below, or the cross-session orphan reaper.
        #       UserPromptSubmit does NOT clear this marker. .cron_pending_new is a
        #       same-turn discriminator and IS cleared by UserPromptSubmit.
        # Any of these triggers the same deferred-idle: set stop_pending, stay running.
        # The completion signals differ: agents fire SubagentStop (decrements
        # counter to 0 → idle); background bash fires UserPromptSubmit on re-
        # invocation (already sets running + clears stop_pending → next Stop
        # with empty background_tasks fires idle normally); cron wakes also arrive
        # as UserPromptSubmit (.cron_pending survives; if the loop reschedules
        # CronCreate the marker stays armed with the current turn stamp, otherwise
        # the turn-age drain fires here so the next Stop can reach idle).
        # When BOTH shell and agents are in flight, a separate stop_pending_shell
        # marker guards against SubagentStop firing idle while a shell task is
        # still running: SubagentStop has no background_tasks payload, so without
        # this marker it cannot tell whether a shell task is still outstanding.
        #
        # Turn-age drain: if .cron_pending's stamped turn is older than the current
        # turn the wake already fired and the runtime auto-deleted the cron — drain
        # the marker now so the blocker check below sees no pending cron.
        _cron_wake_stale "$session_id" && rm -f "$STATE_DIR/$session_id.cron_pending" \
            "$STATE_DIR/$session_id.cron_pending_new" 2>/dev/null || true
        _agents=0
        [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
        [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
        if (( _agents > 0 )) || _has_shell_bg_tasks "$INPUT" || _has_agent_bg_tasks "$INPUT" \
            || [[ -f "$STATE_DIR/$session_id.cron_pending" ]]; then
            [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
            touch "$STATE_DIR/$session_id.stop_pending"
            _has_shell_bg_tasks "$INPUT" && touch "$STATE_DIR/$session_id.stop_pending_shell"
            # stop_pending covers the deferral; the drain marker is redundant here
            # and would cause a spurious extra deferral when the last blocker clears.
            rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
            state="running"
        elif [[ -f "$STATE_DIR/$session_id.subagent_drained" ]]; then
            # Consume one drain token. While tokens remain, another Stop is expected
            # (a background agent is still live) → stay running. When the last token
            # is consumed, remove the file so the next Stop hits the else-idle branch.
            _sd=0
            read -r _sd < "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
            [[ "$_sd" =~ ^[0-9]+$ ]] || _sd=1
            if (( 10#$_sd > 1 )); then
                printf '%s' "$(( 10#$_sd - 1 ))" > "$STATE_DIR/$session_id.subagent_drained"
            else
                rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
            fi
            state="running"
        else
            rm -f "$STATE_DIR/$session_id.stop_pending_shell" 2>/dev/null || true
            state="idle"
        fi
        ;;
    StopFailure)
        # Turn ended in error — still done (prevent tab stuck at 🔴/running),
        # but apply the same deferred-idle check as Stop.
        # Turn-age drain: same as Stop — drain a stale .cron_pending before the check.
        _cron_wake_stale "$session_id" && rm -f "$STATE_DIR/$session_id.cron_pending" \
            "$STATE_DIR/$session_id.cron_pending_new" 2>/dev/null || true
        _agents=0
        [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
        [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
        if (( _agents > 0 )) || _has_shell_bg_tasks "$INPUT" || _has_agent_bg_tasks "$INPUT" \
            || [[ -f "$STATE_DIR/$session_id.cron_pending" ]]; then
            [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
            touch "$STATE_DIR/$session_id.stop_pending"
            _has_shell_bg_tasks "$INPUT" && touch "$STATE_DIR/$session_id.stop_pending_shell"
            # stop_pending covers the deferral; clear the drain marker so it
            # doesn't cause a spurious extra deferral when the last blocker clears.
            rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
            state="running"
        elif [[ -f "$STATE_DIR/$session_id.subagent_drained" ]]; then
            # Drain counter is the only blocker. StopFailure is an abnormal turn-end
            # (the tool call errored out), so any backgrounded agents are effectively
            # dead — clear all remaining tokens in one shot and write idle directly.
            # This differs intentionally from Stop's per-token decrement, which
            # preserves tokens for subsequent Stops in a normal multi-dispatch run.
            rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
            state="idle"
        else
            rm -f "$STATE_DIR/$session_id.stop_pending_shell" 2>/dev/null || true
            state="idle"
        fi
        ;;
    SubagentStop)
        # Guard: do NOT downgrade waiting → running, or idle → running.
        # A subagent finishing is not proof the parent turn is idle; a pending
        # 🔴 from a subagent's PermissionRequest must never be cleared by its own
        # SubagentStop, and a late SubagentStop after Stop must not erase the 🟢.
        # Resolve to running (no-icon) only when the current state is active (running
        # or absent) — never overwrite a terminal state (waiting or idle).
        #
        # Deferred-idle: decrement the in-flight agent counter FIRST (before the
        # terminal-state guard), so a completion that arrives while waiting/idle
        # does not leave a stale positive count that blocks a future Stop → idle.
        # If the count reaches 0 and stop_pending is set (Stop fired while agents
        # were still running), fire idle now — the parent turn already finished
        # and this was the last agent.
        # Note: subagent_drained is armed at PreToolUse(Agent), not here —
        # SubagentStop has no per-agent identity and cannot reliably distinguish
        # current-turn from prior-turn completions. SubagentStop only decrements
        # the counter; Stop/idle_prompt check the marker that PreToolUse armed.
        # Claude Code fires hooks serially per session, so concurrent RMW on
        # .agents within the same session_id is not possible in practice.
        _agents=0
        [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
        [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
        _decremented=0
        if (( _agents > 0 )); then
            _agents=$(( _agents - 1 ))
            printf '%s' "$_agents" > "$STATE_DIR/$session_id.agents"
            _decremented=1
        fi
        _cur_state=""
        [[ -r "$STATE_DIR/$session_id" ]] && read -r _cur_state < "$STATE_DIR/$session_id"
        # subagent_drained is armed at PreToolUse(Agent) dispatch time, not here.
        # SubagentStop only decrements the counter; the marker is already set if
        # a current-turn Agent was dispatched this turn.
        if [[ "$_cur_state" == "waiting" || "$_cur_state" == "thrashing" || "$_cur_state" == "idle" ]]; then
            # Terminal state: preserve visual. Counter was decremented above.
            # When the counter drains to 0 in a terminal state, the drain-race
            # cannot occur: Stop will write idle directly (or already did for
            # idle). Clear the marker so Stop is not spuriously deferred.
            (( _agents == 0 )) && rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
            exit 0
        fi
        if (( _agents == 0 )) && [[ -f "$STATE_DIR/$session_id.stop_pending" ]] \
            && [[ ! -f "$STATE_DIR/$session_id.stop_pending_shell" ]] \
            && [[ ! -f "$STATE_DIR/$session_id.cron_pending" ]]; then
            rm -f "$STATE_DIR/$session_id.stop_pending" 2>/dev/null || true
            state="idle"
        else
            state="running"
        fi
        ;;
    Notification)
        # 🔴 triggers: permission_prompt (slow backstop for PermissionRequest;
        # measured ~6s late, so PermissionRequest drives the fast path),
        # agent_needs_input (subagent/parallel turn needs user action; guarded — see
        # below), and elicitation_dialog / elicitation_url_dialog (MCP elicitation backstop).
        # 🟢 triggers: idle_prompt (done, awaiting next input). agent_completed is
        # guarded — must not paint 🟢 over a pending 🔴 (same rationale as
        # SubagentStop above), and resolves to running (no-icon) not idle: the
        # parent lead may still be working. Counter decrement is NOT done here —
        # SubagentStop is the sole counter owner (Claude Code fires both events
        # for the same agent; decrementing in both would double-count).
        # running (🔴 clear): elicitation_complete / elicitation_response —
        # Notification-channel equivalents of ElicitationResult (user answered).
        # auth_success, quota types, and unknown future types: no-op. An unknown type
        # must never paint 🟢 over a real 🔴 — safer to stay silent than to guess.
        case "$notif_type" in
            permission_prompt|\
            elicitation_dialog|\
            elicitation_url_dialog)
                state="waiting"
                ;;
            agent_needs_input)
                # Guarded: check .ask_pending content + in-flight agent counter.
                #   absent   → no AskUserQuestion this turn; fire normally (genuine subagent need).
                #   "pending" → question is still live; reinforce waiting.
                #   "answered" + agents==0 → stale late backstop after answer; skip so 🔴 is not
                #                re-painted while Claude is crafting.
                #   "answered" + agents>0  → Agent is in flight and may have its own genuine input
                #                request; don't suppress it (the late AskUserQuestion backstop is
                #                stale but the Agent's need is real).
                _ask_state=""
                [[ -r "$STATE_DIR/$session_id.ask_pending" ]] \
                    && read -r _ask_state < "$STATE_DIR/$session_id.ask_pending"
                if [[ "$_ask_state" == "answered" ]]; then
                    _ask_agents=0
                    [[ -r "$STATE_DIR/$session_id.agents" ]] \
                        && read -r _ask_agents < "$STATE_DIR/$session_id.agents"
                    [[ "$_ask_agents" =~ ^[0-9]+$ ]] || _ask_agents=0
                    if (( _ask_agents == 0 )); then
                        exit 0
                    fi
                fi
                state="waiting"
                ;;
            idle_prompt)
                # Same deferred-idle check as Stop for background agents (counter)
                # and shell tasks (stop_pending_shell marker). idle_prompt does NOT
                # receive background_tasks, but a prior Stop may have left
                # stop_pending and/or stop_pending_shell while background work is
                # still running. Check both to cover both task types.
                # Also check subagent_drained: in the inline-subagent timing race
                # (A1 above), PreToolUse(Agent) arms the marker at dispatch time
                # so Stop/idle_prompt know to defer until after the agent drains.
                # Claude Code fires Stop before idle_prompt in the turn-end sequence,
                # so Stop ordinarily consumes the marker first. This check guards the
                # edge where idle_prompt arrives before Stop (or instead of Stop if
                # the runtime skips it); in that case idle_prompt writes idle
                # directly rather than deferring by one more event.
                #
                # Turn-age drain: same as Stop — drain a stale .cron_pending so the
                # blocker check below does not defer idle for an already-fired cron.
                _cron_wake_stale "$session_id" && rm -f "$STATE_DIR/$session_id.cron_pending" \
                    "$STATE_DIR/$session_id.cron_pending_new" 2>/dev/null || true
                _agents=0
                [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
                [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
                if (( _agents > 0 )) || [[ -f "$STATE_DIR/$session_id.stop_pending_shell" ]] \
                    || [[ -f "$STATE_DIR/$session_id.stop_pending" ]] \
                    || [[ -f "$STATE_DIR/$session_id.cron_pending" ]]; then
                    [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
                    touch "$STATE_DIR/$session_id.stop_pending"
                    rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
                    state="running"
                elif [[ -f "$STATE_DIR/$session_id.subagent_drained" ]]; then
                    # Drain counter is the only blocker. idle_prompt is the definitive
                    # fall-through when Stop is skipped; no further Stop is expected, so
                    # clear all remaining tokens wholesale (not per-token) and write idle.
                    # If Stop already consumed some tokens (partial decrement), those are
                    # gone; idle_prompt clears whatever remains.
                    rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
                    rm -f "$STATE_DIR/$session_id.stop_pending_shell" 2>/dev/null || true
                    state="idle"
                else
                    rm -f "$STATE_DIR/$session_id.stop_pending_shell" 2>/dev/null || true
                    state="idle"
                fi
                ;;
            elicitation_complete|\
            elicitation_response)
                # Guard: only clear when no Agent is in flight — same race as
                # ElicitationResult: resolving an elicitation while a parallel Agent
                # runs must not erase the dispatch-time marker.
                _elicn_agents=0
                [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _elicn_agents < "$STATE_DIR/$session_id.agents"
                [[ "$_elicn_agents" =~ ^[0-9]+$ ]] || _elicn_agents=0
                (( _elicn_agents == 0 )) && rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
                state="running"   # user answered elicitation — clear 🔴
                ;;
            agent_completed)
                # Guarded running — same logic as SubagentStop: a completing subagent
                # is not proof the parent turn is done. Preserve terminal states
                # (waiting and idle) so a late agent_completed never erases 🟢.
                # NOTE: counter decrement intentionally omitted here. Claude Code fires
                # BOTH SubagentStop and Notification+agent_completed for the same agent
                # completion. SubagentStop is the canonical hook event and owns the
                # counter decrement; agent_completed must not decrement again or a
                # two-agent turn loses two counts per completion instead of one.
                # subagent_drained: armed by PreToolUse(Agent) at dispatch time, before
                # either completion event. SubagentStop decrements the counter before
                # agent_completed runs, but neither event clears the dispatch-time
                # marker while the session is active. This handler resolves to running
                # in both counter>0 and counter=0 cases — stop_pending not yet set —
                # so it correctly leaves the marker intact for Stop/idle_prompt.
                _cur_state=""
                [[ -r "$STATE_DIR/$session_id" ]] && read -r _cur_state < "$STATE_DIR/$session_id"
                if [[ "$_cur_state" == "waiting" || "$_cur_state" == "thrashing" || "$_cur_state" == "idle" ]]; then
                    exit 0
                fi
                _agents=0
                [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
                [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
                if (( _agents == 0 )) && [[ -f "$STATE_DIR/$session_id.stop_pending" ]] \
                    && [[ ! -f "$STATE_DIR/$session_id.stop_pending_shell" ]] \
                    && [[ ! -f "$STATE_DIR/$session_id.cron_pending" ]]; then
                    rm -f "$STATE_DIR/$session_id.stop_pending" 2>/dev/null || true
                    state="idle"
                else
                    state="running"
                fi
                ;;
            *)
                # auth_success, quota_* and any future type: no-op (do not overwrite state).
                exit 0
                ;;
        esac
        ;;
    PreCompact)
        # Compaction is starting — clear any stale 🟢 by going running.
        # Fires before manual /compact and auto-compact alike (matcher "*").
        # Guard: only clear the drain marker when no Agent is in flight.
        # Compaction can overlap a running Agent; clearing the marker here
        # would let the following Stop write idle before the Agent drains.
        _pc_agents=0
        [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _pc_agents < "$STATE_DIR/$session_id.agents"
        [[ "$_pc_agents" =~ ^[0-9]+$ ]] || _pc_agents=0
        (( _pc_agents == 0 )) && rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
        # If already thrashing when this compaction starts, mark it as a remedy candidate:
        # the user ran /compact deliberately to relieve context pressure. The paired
        # PostCompact will clear thrashing only when this marker is present.
        if [[ -f "$STATE_DIR/$session_id.thrash" ]]; then
            touch "$STATE_DIR/$session_id.thrash_remedy"
        else
            rm -f "$STATE_DIR/$session_id.thrash_remedy" 2>/dev/null || true
        fi
        # Cadence thrash detector: record epoch, trim to last THRASH_COUNT, check window.
        _compacts=""
        [[ -r "$STATE_DIR/$session_id.compacts" ]] && read -r _compacts < "$STATE_DIR/$session_id.compacts"
        _now=$(date +%s)
        set -- $_compacts "$_now"
        while (( $# > THRASH_COUNT )); do shift; done
        printf '%s' "$*" > "$STATE_DIR/$session_id.compacts"
        _oldest="$1"
        if (( $# >= THRASH_COUNT )) && [[ "$_oldest" =~ ^[0-9]+$ ]] && (( _now - _oldest <= THRASH_WINDOW_SEC )); then
            touch "$STATE_DIR/$session_id.thrash"
            state="thrashing"
        else
            rm -f "$STATE_DIR/$session_id.thrash" 2>/dev/null || true
            state="running"
        fi
        ;;
    PostCompact)
        # Compaction finished — the model resumes working, so stay running.
        # Guarded like agent_completed: never paint over a real 🔴 (waiting)
        # or erase a 🟢 (idle) set by a concurrent Stop, and honour deferred-idle
        # markers left by a prior Stop.
        # Exception: thrashing is cleared when this compaction was a remedy —
        # i.e., the session was already thrashing when PreCompact fired (.thrash_remedy
        # marker present). This ensures the alert persists past the threshold-crossing
        # compaction and only clears on the subsequent deliberate /compact.
        _cur_state=""
        [[ -r "$STATE_DIR/$session_id" ]] && read -r _cur_state < "$STATE_DIR/$session_id"
        if [[ "$_cur_state" == "waiting" || "$_cur_state" == "idle" ]]; then
            if [[ -f "$STATE_DIR/$session_id.thrash_remedy" ]]; then
                rm -f "$STATE_DIR/$session_id.thrash" "$STATE_DIR/$session_id.compacts" \
                      "$STATE_DIR/$session_id.thrash_remedy" 2>/dev/null || true
            fi
            exit 0
        fi
        if [[ "$_cur_state" == "thrashing" ]] && [[ -f "$STATE_DIR/$session_id.thrash_remedy" ]]; then
            rm -f "$STATE_DIR/$session_id.thrash" "$STATE_DIR/$session_id.compacts" \
                  "$STATE_DIR/$session_id.thrash_remedy" 2>/dev/null || true
        else
            rm -f "$STATE_DIR/$session_id.thrash_remedy" 2>/dev/null || true
        fi
        _agents=0
        [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _agents < "$STATE_DIR/$session_id.agents"
        [[ "$_agents" =~ ^[0-9]+$ ]] || _agents=0
        # If an Agent drained between PreCompact and PostCompact, the marker was
        # preserved by PreCompact's guard but is now stale. Clear it here so the
        # next Stop is not unnecessarily consumed by the drain-race deferral.
        (( _agents == 0 )) && rm -f "$STATE_DIR/$session_id.subagent_drained" 2>/dev/null || true
        if (( _agents == 0 )) && [[ -f "$STATE_DIR/$session_id.stop_pending" ]] \
            && [[ ! -f "$STATE_DIR/$session_id.stop_pending_shell" ]] \
            && [[ ! -f "$STATE_DIR/$session_id.cron_pending" ]]; then
            rm -f "$STATE_DIR/$session_id.stop_pending" 2>/dev/null || true
            state="idle"
        else
            state="running"
        fi
        ;;
    *) exit 0 ;;
esac

[[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
# Capture pre-guard state so the turn-end cleanup block can distinguish an idle
# transition (safe to clean up) from a running event that the guard upgrades to
# thrashing (live background work — do NOT clean up lifecycle markers).
pre_guard_state="$state"
# Thrash guard: if .thrash exists and the resolved state is running or idle, restore
# thrashing so the red alert persists until the gap-reset path clears it
# (UserPromptSubmit gap or /clear). Both running and idle are overridden — idle
# fires at turn-end when the user can act, so hiding the alert there is exactly
# the wrong time to drop it. .thrash is cleared by the UserPromptSubmit or PreCompact gap checks.
if [[ ( "$state" == "running" || "$state" == "idle" ) && -f "$STATE_DIR/$session_id.thrash" ]]; then
    state="thrashing"
fi
printf '%s' "$state" > "$STATE_DIR/$session_id"

# Persist a genuine user-set name as a sticky fallback so background events
# keep showing the specific name rather than reverting to the git-derived
# label. Write only when the name passed derived-rejection (session_name non-empty
# means nameSource was not "derived"). STATE_DIR is guaranteed above.
if [[ -n "$session_name" ]]; then
    # Mark this sticky as non-derived provenance so it survives a later derived
    # rewrite. Covers any nameSource-absent name: explicit /rename, --name flag,
    # and AI-assigned titles — all are non-derived and should survive /compact.
    # Write the marker only when the sticky write succeeds; an orphaned .name.user
    # with no backing .name would cause the fallback read to return empty.
    if printf '%s' "$session_name" > "$STATE_DIR/$session_id.name" 2>/dev/null; then
        touch "$STATE_DIR/$session_id.name.user" 2>/dev/null || true
    fi
elif [[ "$_session_index_derived" -eq 1 ]]; then
    # Index found the session but nameSource was "derived". Clear the sticky only
    # when it carries no user-provenance marker (.name.user absent). If the marker
    # exists, the sticky was written from a genuine user rename and must survive
    # the derived rewrite (this is the /compact-revert bug path).
    if [[ ! -f "$STATE_DIR/$session_id.name.user" ]]; then
        rm -f "$STATE_DIR/$session_id.name" 2>/dev/null || true
    fi
fi

# Turn-end sweep: runs once per idle transition, keeping state dir lean.
# Cleans:
#   • This session's own cross-repo pointer + ack + ewt_pre (turn freshness;
#     a new cd_target in the next turn gets a fresh commit_guard warning).
#   • Other sessions' *.cd_target older than STATE_RETENTION_SEC.
#   • Orphan bare session files (no accompanying .wt or .cd_target,
#     older than 7x STATE_RETENTION_SEC). These accumulate from sessions that
#     ended without an explicit clean-up turn. Matching .turns files are retained
#     to avoid resetting the turn gauge for live idle sessions.
#   • Orphan *.wt beyond the TTL (lazy-on-read doesn't catch all, e.g. a
#     session that never re-entered the worktree after the TTL expired).
#   • pr-cache entries older than STATE_RETENTION_SEC.
# Every `find`/`rm` is guarded with `2>/dev/null || true` — bash 3.2,
# set -uo pipefail (no -e), and the dir may not exist yet.
if [[ "$pre_guard_state" == "idle" ]]; then
    rm -f "$STATE_DIR/$session_id.cd_target" "$STATE_DIR/$session_id.cd_ack" \
          "$STATE_DIR/$session_id.ewt_pre" \
          "$STATE_DIR/$session_id.stop_pending" \
          "$STATE_DIR/$session_id.stop_pending_shell" \
          "$STATE_DIR/$session_id.cron_pending" "$STATE_DIR/$session_id.cron_pending_new" \
          "$STATE_DIR/$session_id.subagent_drained" \
          2>/dev/null || true
    # .agents is cross-turn state: UserPromptSubmit preserves it across turns so a
    # prior-turn background/fork agent can still be running when the user sends a new
    # prompt. Only sweep it when it reads 0 / unparseable / absent. Deleting a live
    # positive counter here is the issue #1322 race: a prior-turn fork drains+idles
    # before the next prompt while another fork is live → next Stop reads 0 from the
    # absent file → premature 🟢. A positive counter is left intact to survive into
    # the next turn and self-drain to a shared zero via SubagentStop.
    _sweep_agents=0
    [[ -r "$STATE_DIR/$session_id.agents" ]] && read -r _sweep_agents < "$STATE_DIR/$session_id.agents"
    [[ "$_sweep_agents" =~ ^[0-9]+$ ]] || _sweep_agents=0
    (( _sweep_agents == 0 )) && rm -f "$STATE_DIR/$session_id.agents" 2>/dev/null || true

    # Other sessions' stale .cd_target files.
    find "$STATE_DIR" -maxdepth 1 -name '*.cd_target' \
        -not -name "$session_id.cd_target" \
        -mmin +"$((STATE_RETENTION_SEC / 60))" \
        -delete 2>/dev/null || true

    # Orphan bare session files (UUID-shaped, no extension) whose .wt and
    # .cd_target are both absent and which are older than 7x the retention window.
    # These are left-behind "running"/"idle" state files from ended sessions.
    # Match with -name '*-*-*-*-*' (UUID shape; 5 segments of hex with dashes)
    # plus a bash [[ =~ ]] guard for the exact hexadecimal UUID pattern --
    # avoiding -regextype which is not portable across BSD find (macOS) and GNU.
    # Threshold is 7x the base retention (7 days at the default 1-day base) so a
    # session idle over a long weekend is not swept while still open. The .turns
    # file is excluded from deletion: losing the turn counter on a live idle
    # session would silently reset the up-arrow gauge; it is small and safe to keep.
    #
    # Note: same-session .agents leak recovery (a counter stuck >0 because a fork
    # was killed before SubagentStop fired) is intentionally NOT done here. The
    # background_tasks payload signal cannot safely distinguish "no agent running"
    # from "this runtime/dispatch path does not populate background_tasks" — a
    # reconciliation that zeroed a live counter would re-introduce the #1322 race.
    # A stale same-session counter self-heals on the next real SubagentStop or
    # when the user runs /clear (starting a fresh session_id). That "tab stuck at
    # running" is strictly better than a silent false-idle.
    find "$STATE_DIR" -maxdepth 1 -name '*-*-*-*-*' \
        -not -name "$session_id" \
        -mmin +"$(( (STATE_RETENTION_SEC * 7) / 60 ))" \
        2>/dev/null | while IFS= read -r _sf; do
        _sid="${_sf##*/}"
        # Exact UUID check: 8hex-4hex-4hex-4hex-12hex, lowercase only.
        [[ "$_sid" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || continue
        if [[ ! -f "$STATE_DIR/$_sid.wt" && ! -f "$STATE_DIR/$_sid.cd_target" ]]; then
            # Dead session: unconditional delete — no live counter to preserve (cf. same-session guard above).
            rm -f "$_sf" "$STATE_DIR/$_sid.cd_ack" \
                  "$STATE_DIR/$_sid.ewt_pre" \
                  "$STATE_DIR/$_sid.active" \
                  "$STATE_DIR/$_sid.active.prev" \
                  "$STATE_DIR/$_sid.wt_prev" \
                  "$STATE_DIR/$_sid.name" \
                  "$STATE_DIR/$_sid.name.user" \
                  "$STATE_DIR/$_sid.agents" \
                  "$STATE_DIR/$_sid.stop_pending" \
                  "$STATE_DIR/$_sid.stop_pending_shell" \
                  "$STATE_DIR/$_sid.cron_pending" \
                  "$STATE_DIR/$_sid.cron_pending_new" \
                  "$STATE_DIR/$_sid.fires" \
                  "$STATE_DIR/$_sid.subagent_drained" \
                  "$STATE_DIR/$_sid.ask_pending" \
                  "$STATE_DIR/$_sid.compacts" "$STATE_DIR/$_sid.thrash" \
                  2>/dev/null || true
        fi
    done

    # Reap fire-only counters left by invocations that exited before writing
    # a bare session-state file (e.g. session_id guard rejected). These are
    # never found by the bare-file sweep above. Remove after the same 7x window.
    find "$STATE_DIR" -maxdepth 1 -name '*.fires' \
        -not -name "$session_id.fires" \
        -mmin +"$(( (STATE_RETENTION_SEC * 7) / 60 ))" \
        2>/dev/null | while IFS= read -r _ff; do
        [[ -f "${_ff%.fires}" ]] || rm -f "$_ff" 2>/dev/null || true
    done

    # Orphan .wt files past the retention window (not the current session's — it
    # may still be valid within the same turn batch). -mmin gives minute-level
    # precision so STATE_RETENTION_SEC (1 day = 1440 min) matches the documented
    # 1-day window; -mtime +1 would sweep only files >48h old.
    find "$STATE_DIR" -maxdepth 1 -name '*.wt' \
        -not -name "$session_id.wt" \
        -mmin +"$((STATE_RETENTION_SEC / 60))" \
        -delete 2>/dev/null || true

    # Orphan .wt_prev files (same retention window).
    find "$STATE_DIR" -maxdepth 1 -name '*.wt_prev' \
        -not -name "$session_id.wt_prev" \
        -mmin +"$((STATE_RETENTION_SEC / 60))" \
        -delete 2>/dev/null || true

    # pr-cache entries older than the retention window.
    if [[ -d "$STATE_DIR/pr-cache" ]]; then
        find "$STATE_DIR/pr-cache" -maxdepth 1 -type f \
            -mmin +"$((STATE_RETENTION_SEC / 60))" \
            -delete 2>/dev/null || true
    fi
fi
# 🔴 waiting (needs you) · 🟢 idle (done, ready — a passive "don't forget me") ·
# no icon on running. We ALWAYS emit a title: the running case resets to the bare
# label, which (a) clears a stale 🔴 after ESC/decline and (b) is the flicker
# guard that erases a premature 🟢 when Stop fired mid-turn. A tab title persists
# until overwritten, so we must actively reset it, not just stop emitting.
# Emitted as JSON with the OSC-0 set-title sequence as literal escapes (a JSON
# parser decodes them; Claude Code relays it to the tab).
# Tab label: a user-set/AI session name wins when present (resolved above from
# the on-disk session index); otherwise a git-derived label. The base dir is the
# LAST worktree this session entered (recorded to <session_id>.wt above) when it
# still exists, else the payload cwd. This is the fix for the tab reverting to
# "main · <repo>" mid-session: the session cwd stays pinned at the repo root while
# Claude works a PR inside `cd .claude/worktrees/<task>` subshells, and no hook
# payload carries that subshell cwd — so without the .wt indirection the render
# resolves root→main during any stretch with no fresh `cd` (compaction, a long
# background agent, pure thinking), then only "comes back" when the next Bash `cd`
# re-stamps .wt. Reading .wt here makes the worktree label persist across those
# stretches. For a MAIN working tree we disambiguate to "<branch-last-component> ·
# <repo-basename>" — branch FIRST because tabs truncate from the right, and the
# branch is what tells same-repo tabs apart (repo:branch lost the branch on narrow
# tabs). A worktree's dir basename is already unique, so it stays bare. Fork-free:
# parse HEAD directly for the main checkout (a git fork on every hook event is the
# discipline this avoids).
# Sticky fallback: if the live index lookup returned empty (e.g. background
# events where index resolution races), recover the last good user-set name from
# the side-channel file. Never overrides a live name.
# Fires in two cases:
#   1. Index had NO hit (_session_index_hit=0) — standard race-recovery path.
#   2. Index hit but name was derived (_session_index_hit=1, _session_index_derived=1)
#      AND the sticky carries a user-provenance marker (.name.user). This recovers
#      the user-set name when /compact or a skill-restore rewrites the index entry
#      to nameSource:"derived" — the clobber branch above preserves the sticky in
#      this case; the widened gate here reads it back. Without the marker requirement
#      an unmarked stale sticky from a purely-derived session would substitute, which
#      is incorrect.
if [[ -z "$session_name" && -r "$STATE_DIR/$session_id.name" ]] && {
    [[ "$_session_index_hit" -eq 0 ]] || \
    [[ "$_session_index_hit" -eq 1 && "$_session_index_derived" -eq 1 && -f "$STATE_DIR/$session_id.name.user" ]]
}; then
    IFS= read -r session_name < "$STATE_DIR/$session_id.name" 2>/dev/null; session_name="${session_name:-}"
fi

if [[ -n "$session_name" ]]; then
    label="$session_name"
else
    # Resolve the label dir. Priority (PRECEDENCE: git_worktree > cwd(moved) > .wt > .cd_target):
    #   1. The payload cwd itself, when it IS a linked worktree (its .git is a
    #      file). This is authoritative: the session is running inside this
    #      worktree, so the branch from its HEAD is exactly right. A stale .wt
    #      pointer from a *different* worktree must NOT override it — that would
    #      show the old worktree's label when you've moved on. (This fixes the
    #      bug: start Claude in worktree A, later move to worktree B or another
    #      repo; the label must follow the real cwd, not the sticky .wt.)
    #   2. The payload cwd when it IS a main git checkout AND has moved from the
    #      launch dir (cwd != CLAUDE_PROJECT_DIR). Same principle: cwd is
    #      authoritative; a stale .wt/.cd_target must not override it. When cwd
    #      == launch dir the session is still at root (root+cd-subshell case) and
    #      we fall through to .wt/.cd_target as before.
    #   3. The recorded .wt dir, when it's still live. Needed for the
    #      root-with-subshells case: session cwd stays at the repo root while
    #      Claude works a PR inside `cd .claude/worktrees/<task>` subshells —
    #      no hook payload carries that subshell cwd, so the .wt indirection
    #      keeps the right worktree label across stretches with no fresh cd.
    #   4. The payload cwd (main checkout or unrecognized dir). Falls through to
    #      the branch · repo label for a main checkout.
    _label_dir="$cwd"
    _is_worktree=0
    _is_wt_live=0  # set to 1 only when the .wt pointer resolves to a live dir

    # Step 1: cwd is a linked worktree? Its .git is a FILE with a gitdir: line.
    # Resolve its HEAD and derive the worktree branch label. Fork-free, same
    # gitdir-resolution logic as statusline.sh's _read_gitdir_head.
    _cwd_gitdir_head=""
    _cwd_is_repo=0
    _label_from_active=0
    if [[ -n "$cwd" && -f "$cwd/.git" ]]; then
        _cwd_gitfile_line=""
        read -r _cwd_gitfile_line < "$cwd/.git"
        if [[ "$_cwd_gitfile_line" == "gitdir: "* ]]; then
            _cwd_gitdir="${_cwd_gitfile_line#gitdir: }"
            [[ -n "$_cwd_gitdir" && "$_cwd_gitdir" != /* ]] && _cwd_gitdir="$cwd/$_cwd_gitdir"
            [[ -n "$_cwd_gitdir" && -f "$_cwd_gitdir/HEAD" ]] && read -r _cwd_gitdir_head < "$_cwd_gitdir/HEAD"
        fi
    fi
    if [[ -n "$_cwd_gitdir_head" ]]; then
        # cwd is a worktree — it's authoritative. Use it directly; do NOT look at .wt.
        _label_dir="$cwd"; _is_worktree=1; _cwd_is_repo=1
    else
        # Step 2: cwd is a main checkout that has moved from the launch dir?
        # Authoritative for the same reason as the worktree case above.
        _cwd_moved=0
        if [[ -n "$cwd" && -f "$cwd/.git/HEAD" ]]; then
            _cwd_is_repo=1
            [[ -n "$launch_dir" && "$cwd" != "$launch_dir" ]] && _cwd_moved=1
        fi
        if [[ "$_cwd_is_repo" -eq 1 && "$_cwd_moved" -eq 1 ]]; then
            # cwd is a moved main checkout — authoritative. Skip .wt/.cd_target.
            _label_dir="$cwd"
            # Read the main HEAD for the label.
            read -r _cwd_main_head < "$cwd/.git/HEAD" 2>/dev/null || true
            _cwd_gitdir_head="$_cwd_main_head"
            # _is_worktree stays 0; label assembly below renders "branch · repo".
        else
        # cwd is not a worktree .git file. Fall back to the recorded .wt dir.
        _wt_file="$STATE_DIR/$session_id.wt"
        # TTL gate: expire the pointer before reading so both the hook and the
        # renderer agree on the 12h window. Split from the read block so the
        # read stays `read -r < file` (no `||` that would swallow a no-newline exit).
        if [[ -r "$_wt_file" ]]; then
            _wt_mtime=$(_mtime "$_wt_file"); [[ "$_wt_mtime" =~ ^[0-9]+$ ]] || _wt_mtime=0
            _hook_now=$(date +%s)
            if (( _hook_now - _wt_mtime >= WT_POINTER_TTL_SEC )); then
                rm -f "$_wt_file" 2>/dev/null || true
            fi
        fi
        if [[ -r "$_wt_file" ]]; then
            read -r _wt_recorded < "$_wt_file"
            if [[ -n "$_wt_recorded" && -d "$_wt_recorded" ]]; then
                _label_dir="$_wt_recorded"; _is_worktree=1; _is_wt_live=1
                # Read HEAD so the label block can render branch (and "branch · repo"
                # for cross-repo worktrees). Same gitdir-resolution as the cwd block.
                if [[ -f "$_wt_recorded/.git" ]]; then
                    _wt_gitfile_line=""
                    read -r _wt_gitfile_line < "$_wt_recorded/.git" 2>/dev/null || true
                    if [[ "$_wt_gitfile_line" == "gitdir: "* ]]; then
                        _wt_gitdir="${_wt_gitfile_line#gitdir: }"
                        [[ -n "$_wt_gitdir" && "$_wt_gitdir" != /* ]] && _wt_gitdir="$_wt_recorded/$_wt_gitdir"
                        [[ -n "$_wt_gitdir" && -f "$_wt_gitdir/HEAD" ]] && read -r _cwd_gitdir_head < "$_wt_gitdir/HEAD"
                    fi
                fi
                # Cross-repo flag: the .wt worktree is in a different repo than the
                # session cwd. Detected by a non-matching git common-dir (two git -C
                # forks; fired only when HEAD was successfully read above).
                # git rev-parse --git-common-dir returns "." (relative) from the
                # primary worktree root but an absolute path from a linked worktree.
                # Canonicalize both before comparing to avoid false cross-repo hits
                # when cwd is the repo root.
                _wt_cross_repo=0
                if [[ -n "$_cwd_gitdir_head" && -n "$cwd" ]]; then
                    _cwd_common=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null) || true
                    _wt_common=$(git -C "$_wt_recorded" rev-parse --git-common-dir 2>/dev/null) || true
                    # Make relative paths absolute (relative to their respective base dirs).
                    [[ -n "$_cwd_common" && "$_cwd_common" != /* ]] && _cwd_common="$cwd/$_cwd_common"
                    [[ -n "$_wt_common" && "$_wt_common" != /* ]] && _wt_common="$_wt_recorded/$_wt_common"
                    [[ -n "$_cwd_common" && -n "$_wt_common" && "$_cwd_common" != "$_wt_common" ]] && _wt_cross_repo=1
                fi
            else
                # Stale pointer — worktree torn down. Clear so future events don't
                # fall through to cwd and show the wrong repo's branch label.
                rm -f "$_wt_file" 2>/dev/null || true
            fi
        fi
        # Fall back to cd_target: driving a different repo via bare cd.
        # Lower priority than .wt (a worktree pointer is more specific).
        if [[ "$_is_worktree" -eq 0 ]]; then
            _ct_file="$STATE_DIR/$session_id.cd_target"
            if [[ -r "$_ct_file" ]]; then
                read -r _ct_recorded < "$_ct_file"
                if [[ -n "$_ct_recorded" && -d "$_ct_recorded" ]]; then
                    _label_dir="$_ct_recorded"
                    # If the cd_target dir is itself a linked worktree (.git is a file),
                    # resolve its HEAD via the gitdir pointer so the branch shows in the
                    # label — same pattern as the cwd-is-worktree block above.
                    if [[ -f "$_ct_recorded/.git" ]]; then
                        _ct_gitfile_line=""
                        read -r _ct_gitfile_line < "$_ct_recorded/.git" 2>/dev/null || true
                        if [[ "$_ct_gitfile_line" == "gitdir: "* ]]; then
                            _ct_gitdir="${_ct_gitfile_line#gitdir: }"
                            [[ -n "$_ct_gitdir" && "$_ct_gitdir" != /* ]] && _ct_gitdir="$_ct_recorded/$_ct_gitdir"
                            if [[ -n "$_ct_gitdir" && -f "$_ct_gitdir/HEAD" ]]; then
                                read -r _cwd_gitdir_head < "$_ct_gitdir/HEAD"
                                _is_worktree=1
                            fi
                        fi
                    fi
                fi
            fi
        fi
        # Fall back to .active (intent pointer from active_repo_tracker.sh).
        # Covers the key gap: gh-only or git -C work with no physical cd/worktree.
        # Lower priority than .wt and .cd_target — physical moves win.
        # No turn-delta freshness guard: the tracker explicitly removes .active on
        # return-home, so a file that exists is a live pointer by definition.
        # Caveat: the tracker fires only on Bash/Edit/Write tool calls — an MCP-only
        # return-home leaves .active set until the next Bash/Edit fires.
        if [[ "$_is_worktree" -eq 0 && "$_label_dir" == "$cwd" ]]; then
            _act_file="$STATE_DIR/$session_id.active"
            if [[ -r "$_act_file" ]]; then
                _h_act_dir=""; _h_act_slug=""; _h_act_branch=""; _h_act_pr=""
                { read -r _h_act_dir; read -r _; read -r _h_act_slug
                  read -r _h_act_branch; read -r _h_act_pr; } < "$_act_file" 2>/dev/null || true
                if [[ -n "$_h_act_dir" && -d "$_h_act_dir" ]]; then
                    # Read HEAD from the intent dir (may be a worktree or main).
                    if [[ -f "$_h_act_dir/.git" ]]; then
                        _h_gitfile=""
                        read -r _h_gitfile < "$_h_act_dir/.git" 2>/dev/null || true
                        if [[ "$_h_gitfile" == "gitdir: "* ]]; then
                            _h_gitdir="${_h_gitfile#gitdir: }"
                            [[ "$_h_gitdir" != /* ]] && _h_gitdir="$_h_act_dir/$_h_gitdir"
                            if [[ -f "$_h_gitdir/HEAD" ]]; then
                                read -r _cwd_gitdir_head < "$_h_gitdir/HEAD"
                                _label_dir="$_h_act_dir"
                                _is_worktree=1
                            fi
                        fi
                    elif [[ -f "$_h_act_dir/.git/HEAD" ]]; then
                        read -r _cwd_gitdir_head < "$_h_act_dir/.git/HEAD" 2>/dev/null || true
                        _label_dir="$_h_act_dir"
                        # Main checkout: _is_worktree stays 0; label block renders "branch · repo".
                    fi
                elif [[ -z "$_h_act_dir" && -n "$_h_act_slug" ]]; then
                    # gh-only: no local dir. Render "slug[  #PR]" as the label.
                    _act_repo_name="${_h_act_slug##*/}"
                    if [[ -n "$_h_act_pr" ]]; then
                        label="$_act_repo_name  #$_h_act_pr"
                    else
                        label="$_act_repo_name"
                    fi
                    # Override _label_dir for idle-reduction so it doesn't clobber to cwd.
                    _label_dir="$cwd"   # keep cwd as anchor; label is already set
                    # Signal that label is intent-derived; idle-reduction must preserve it.
                    _label_from_active=1
                fi
            fi
        fi
    fi
    fi  # end: if [[ -n "$_cwd_gitdir_head" ]] worktree-or-fallback block

    [[ "$_label_from_active" -eq 0 ]] && label="${_label_dir##*/}"
    # A worktree dir basename (the <task> slug) is already unique across tabs, so it
    # stays BARE — no "branch · repo" suffix (it would read redundantly, e.g.
    # "feat/tab-session-name · tab-session-name"). Only a MAIN checkout needs the
    # branch to disambiguate same-repo tabs, so HEAD is parsed for main only.
    # Exception: when cwd IS a linked worktree, show its branch (last path
    # component) as the tab label rather than the bare dir slug — branch names
    # are more recognisable than task slugs. Dir basename is the fallback.
    if [[ "$_is_worktree" -eq 1 && -n "$_cwd_gitdir_head" ]]; then
        # cwd or .wt worktree: extract branch from HEAD.
        if [[ "$_cwd_gitdir_head" == ref:* ]]; then
            _hook_ref="${_cwd_gitdir_head##*/}"
        else
            _hook_ref="${_cwd_gitdir_head:0:7}"
        fi
        if [[ -n "$_hook_ref" ]]; then
            # Cross-repo .wt worktree: append repo basename so the tab is
            # distinguishable from a same-repo worktree on a same-named branch.
            if [[ "${_wt_cross_repo:-0}" -eq 1 ]]; then
                label="$_hook_ref · ${_label_dir##*/}"
                # _label_dir is the worktree dir; its parent's basename is the repo.
                # e.g. ~/src/other-repo/.claude/worktrees/feat-x → feat-x
                # That's already the right disambiguator (unique task slug + repo implied
                # by the branch). But the repo basename is more recognisable cross-tab,
                # so walk up to the repo root: strip the worktree suffix for either
                # convention (.claude/worktrees/<task> own-repo, .worktrees/<task> foreign).
                _wt_repo_root="${_label_dir%/.claude/worktrees/*}"
                [[ "$_wt_repo_root" == "$_label_dir" ]] && _wt_repo_root="${_label_dir%/.worktrees/*}"
                [[ "$_wt_repo_root" != "$_label_dir" ]] && label="$_hook_ref · ${_wt_repo_root##*/}"
            else
                label="$_hook_ref"
            fi
        fi
        # label falls back to the dir basename set above if _hook_ref is empty.
    elif [[ "$_is_worktree" -eq 0 ]]; then
        # Main checkout: `.git` is a dir with HEAD inside.
        _head_file=""
        [[ -n "$_label_dir" && -d "$_label_dir/.git" && -f "$_label_dir/.git/HEAD" ]] && _head_file="$_label_dir/.git/HEAD"
        if [[ -n "$_head_file" ]]; then
            read -r _hook_head < "$_head_file"
            if [[ "$_hook_head" == ref:* ]]; then
                # Symbolic ref (branch/tag/remote): show the last path component only
                # — feat/x → x, docs/foo → foo, refs/tags/v1 → v1. Keeps long slashed
                # branch names from eating the tab and dropping the repo suffix.
                _hook_ref="${_hook_head##*/}"
            else
                # Detached to a bare SHA.
                _hook_ref="${_hook_head:0:7}"
            fi
            # A truncated/malformed HEAD (e.g. "ref:/" written mid-git-op) can leave
            # _hook_ref empty — fall back to the bare basename rather than emit a
            # dangling " · <repo>".
            [[ -n "$_hook_ref" ]] && label="$_hook_ref · ${_label_dir##*/}"
        fi
    fi
    # _is_worktree=1 but _cwd_gitdir_head empty: .wt dir exists but HEAD unreadable
    # (gitdir pointer missing or dir removed mid-session). Bare dir basename suffices.
fi
# Last-resort fallback: no session name, .wt missing/dead, AND cwd absent from
# the payload (regex at top leaves it "") or an unparseable HEAD — any of which
# leaves label "". Emit "claude" rather than a blank tab title.
[[ -z "$label" ]] && label="claude"
# On idle: reduce to repo basename — new tabs inherit the parent tab's title, so
# a stale "feat/branch · repo" propagates to every tab opened after this session.
# Running/waiting keep the full label. User-set session names are exempt.
# Intent-derived (gh-only) labels are also exempt — clobbering them to cwd
# basename would drop the "other-repo  #713" label during idle.
# Live linked worktrees (_is_wt_live=1, set only when the .wt pointer resolves to a
# live dir) are also exempt: the managed worktree still exists on disk (teardown
# not complete), so the label is current and specific. Collapse fires for main
# checkouts, submodules, and after teardown (_is_wt_live=0 in all those cases).
if [[ "$state" == "idle" && -n "$session_name" ]]; then
    : # user-set session name is already specific; keep it
elif [[ "$state" == "idle" && "$_label_from_active" -eq 1 ]]; then
    : # intent-derived label (gh-only .active); keep it — don't reduce to bare cwd
elif [[ "$state" == "idle" && "$_is_wt_live" -eq 1 ]]; then
    : # live linked worktree on disk (teardown not complete); keep the descriptive label
elif [[ "$state" == "idle" ]]; then
    # _label_dir is always set here: this arm is only reachable when session_name
    # is empty, which means the else block above (which sets _label_dir) ran.
    _repo_base="${_label_dir:-$cwd}"
    # Strip .claude/worktrees/<task> or .worktrees/<task> to reach the repo root.
    _repo_base="${_repo_base%/.claude/worktrees/*}"
    _repo_base="${_repo_base%/.worktrees/*}"
    label="${_repo_base##*/}"
    [[ -z "$label" ]] && label="claude"
fi
# JSON-safe the label (a dir basename may legally contain any of these): escape
# backslash first (so we don't double-escape), then double-quote, then strip C0
# control chars (tr handles the range portably; a bash-3.2 glob guard was tried
# but the [\001-\037] range doesn't match reliably there, so the strip is
# unconditional — one tr fork per event, on the hook path, is immaterial).
label="${label//\\/\\\\}"
label="${label//\"/\\\"}"
label=$(printf '%s' "$label" | tr -d '\000-\037')
case "$state" in
    waiting)   icon="🔴 " ;;
    thrashing) icon="🔴 " ;;
    idle)      icon="🟢 " ;;
    *)         icon="" ;;   # running → bare label (clears any prior icon)
esac
printf '%s\n' "{\"terminalSequence\":\"\\u001b]0;$icon$label\\u0007\"}"

exit 0

