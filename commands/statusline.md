---
description: Install, remove, or check the Staksmith status line (repo, branch, context gauge, model, 7-day limit)
disable-model-invocation: true
---

# Status Line Setup

Wire the Staksmith status line into your Claude Code `settings.json`. It renders the stoplight bar —
repo, branch, PR, session state, context gauge, model, and the 7-day token limit — from the payload
Claude Code pipes to a `statusLine` command.

Nothing runs it until it is wired into settings, and installing the plugin does **not** do that for
you (a status line is personal), so this is the opt-in step.

## Usage

```bash
# Install for your user account (~/.claude/settings.json) — the default scope
node scripts/statusline-setup.js --install

# Install for this project only (./.claude/settings.json)
node scripts/statusline-setup.js --install --project

# Replace a statusLine you already had configured
node scripts/statusline-setup.js --install --force

# Check what's currently configured
node scripts/statusline-setup.js --status

# Remove it (only removes the Staksmith one; a statusLine you set is left alone)
node scripts/statusline-setup.js --uninstall
```

## Behavior

- **Idempotent** — re-running `--install` is a no-op once configured; if the script path changed,
  it refreshes it. An install that still points at the retired `statusline.js` is refreshed too.
- **Non-destructive** — a `statusLine` you set yourself is never overwritten without `--force`, and
  every other key in `settings.json` is preserved.
- **Path-correct** — the command points at wherever `scripts/statusline-stoplight/statusline.sh`
  actually lives (dev repo or installed plugin cache), resolved from the setup script's own location.
- **Refresh** — the installed block sets `refreshInterval: 1`. After any change, restart Claude Code;
  already-open sessions keep the line they loaded at startup.

Session state (`⏳ working` / `✏️ ready`) and the tab icons need `statusline-hook.sh` wired to
Claude Code lifecycle events. `--install` wires the bar only.

## Pi

Pi does not run a `statusLine` command. Load `scripts/statusline-stoplight/pi-statusline.ts`
as an extension (`~/.pi/agent/extensions/` or `pi -e` that file). It draws the same bar. The
7-day gauge counts tokens this extension has seen, divided by `PI_WEEKLY_TOKEN_BUDGET`, and
stays hidden when that variable is unset. Restart Pi after changing the extension.
