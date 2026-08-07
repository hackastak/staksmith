# statusLine stdin schema (pinned)

Reference for `scripts/statusline.js`. Claude Code invokes a `statusLine` command of type
`command` and pipes a single JSON object to it on **stdin**; the command prints one line to
**stdout**. This file pins the field names so the parser can't silently drift when Claude Code
changes its payload.

- **Verified against:** Claude Code `2.1.223` (2026-08-06)
- **Source:** <https://code.claude.com/docs/en/statusline.md> — "Available data" / "Full JSON schema"

## Fields this status line consumes

Everything below is confirmed present at 2.1.223. Treat every field as possibly-absent and guard
before use — Claude Code marks many as conditional, and a status line must never crash the render.

| Field | Type | Used for |
|-------|------|----------|
| `model.display_name` | string | Model segment (e.g. `Opus`) |
| `model.id` | string | Model segment fallback / disambiguation |
| `workspace.current_dir` | string | Directory segment (preferred over top-level `cwd`) |
| `cwd` | string | Directory segment fallback |
| `workspace.repo.name` | string | Repo/branch segment (absent outside a git repo) |
| `workspace.git_worktree` | string | Worktree marker (absent in the main working tree) |
| `context_window.used_percentage` | number \| null | Context segment — **pre-computed**, no transcript read needed |
| `context_window.total_input_tokens` | number | Context segment — current (not cumulative) input tokens |
| `context_window.context_window_size` | number | Context segment — window size (200000, or 1000000 extended) |
| `exceeds_200k_tokens` | boolean | Available; not currently rendered (the meter shows fill level instead) |
| `cost.total_cost_usd` | number | Cost segment (resets to $0 on `/clear`) |
| `cost.total_duration_ms` | number | Duration segment (wall clock) |
| `cost.total_api_duration_ms` | number | Duration segment (API wait) |
| `cost.total_lines_added` | number | Activity segment |
| `cost.total_lines_removed` | number | Activity segment |
| `rate_limits.seven_day.used_percentage` | number | Usage segment (`7D:n%`); absent before the first API response / non-subscription |

### Key finding — context usage is handed to us directly

As of the versions past 2.1.132, `context_window` carries the current context usage in the payload:
`used_percentage` / `remaining_percentage` (pre-computed, may be `null` early in a session or after
`/compact`) plus `total_input_tokens`, `context_window_size`, and a `current_usage` breakdown
(`input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`).

**A status line does not need to read `transcript_path` to show context usage.** Reading the
transcript was the pre-2.1.132 fallback and is dropped from this feature's plan. `transcript_path`
remains available if a future segment wants per-message detail that isn't in the payload.

## Optional fields available at 2.1.223 (candidate future segments)

Present on this version, not consumed by the initial cut — listed so later segments don't
re-discover them:

- `effort.level` — `low` | `medium` | `high` | `xhigh` | `max` (absent if the model has no effort param)
- `fast_mode` — boolean
- `thinking.enabled` — boolean
- `rate_limits.five_hour` — `{ used_percentage, resets_at }` (Claude.ai subscribers; absent before the first API response). The 7-day counterpart is now consumed by the `usage` segment; `five_hour` and both `resets_at` timestamps remain available for a future segment.
- `output_style.name`, `vim.mode`, `agent.name`, `pr.{number,url,review_state}`, `session_name`, `prompt_id`, `version`

## Version dependencies to remember

- **2.1.132+** — `context_window.total_input_tokens` / `total_output_tokens` are **current** context,
  not cumulative session totals. Below that they were cumulative. This feature targets current-context
  semantics and does not support pre-2.1.132.
- **2.1.196+** — `prompt_id` added.
- **2.1.205+** — per-task `model` / `contextWindowSize` in subagent status lines.
- `exceeds_200k_tokens` is a **fixed** 200k threshold on the most recent response's total tokens —
  independent of the actual `context_window_size` (which can be 1M on extended-context models). Use
  `context_window.used_percentage` for the real fill level; treat `exceeds_200k_tokens` only as the
  named threshold flag.
