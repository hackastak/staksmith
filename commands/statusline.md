---
description: Install, remove, or check the Staksmith status line (model, context %, cost, git branch)
disable-model-invocation: true
---

# Status Line Setup

Wire the Staksmith status line into your Claude Code `settings.json`. It renders one line —
directory, git branch, package manager, model, context %, session cost, duration, and lines
changed — from the payload Claude Code pipes to a `statusLine` command.

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
  it refreshes it.
- **Non-destructive** — a `statusLine` you set yourself is never overwritten without `--force`, and
  every other key in `settings.json` is preserved.
- **Path-correct** — the command points at wherever `statusline.js` actually lives (dev repo or
  installed plugin cache), resolved from the setup script's own location.
- **Refresh** — after any change, the status line updates on the next activity, not instantly.

## Customizing which segments show

Order and visibility follow this precedence (highest first):

1. `STAKSMITH_STATUSLINE_SEGMENTS` env var — comma/space-separated segment names
2. `~/.claude/statusline.json` — `{ "segments": ["directory", "model", "context"] }`
3. Built-in default order

Segment names: `directory`, `branch`, `pm`, `model`, `context`, `cost`, `duration`, `activity`.

```bash
# Show only model, context %, and cost — in that order
export STAKSMITH_STATUSLINE_SEGMENTS="model,context,cost"
```
