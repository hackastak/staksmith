---
name: git-guardrails
description: Set up a Claude Code hook that blocks dangerous git commands (push, reset --hard, clean -f, branch -D, checkout .) before they execute. Use when the user wants to prevent destructive git operations or add git safety hooks.
category: "Build, Debug & Merge"
origin: Hackastak
---

# Git Guardrails

Install a `PreToolUse` hook that intercepts dangerous git commands and blocks them **before** Claude runs them. It greps the Bash tool's `command` string and exits 2 with a BLOCKED message, which the agent sees as a refusal.

This enforces the manual-git-control posture the rest of Staksmith assumes: no auto-commit, `draft-commit` never commits, `implement` and `prototype` stage and hand back. Those are instructions an agent can drift from; this is a hook it can't.

## Why a hook and not just `permissions.deny`

Native `permissions.deny` matches on command **prefixes**. This hook greps **substrings**, so it catches the variants a prefix rule misses — `cd foo && git push`, `git push --force-with-lease`, a `git reset --hard` buried in a compound command. Different mechanism, complementary rather than redundant; run both.

It's also distinct from the reminder hook Staksmith already ships (`pre-bash-git-push-reminder.js`), which *warns* before a push. This one **blocks**.

## What gets blocked

The default list in [scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh):

- `git push` (all variants, including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

Keep it **git-scoped**. Don't fold in `rm -rf` or other destructive non-git commands — the skill's name and purpose are git, and a blocklist that grows past its name becomes one nobody trusts or audits.

## Two install modes

### Mode 1 — opt-in setup (default)

Install into one project, or globally for the user. This is the default; do this unless the user asks for mode 2.

**Step 1 — ask scope.** This project only (`.claude/settings.json`) or all projects (`~/.claude/settings.json`)?

**Step 2 — copy the script.**

- **Project:** `.claude/hooks/block-dangerous-git.sh`
- **Global:** `~/.claude/hooks/block-dangerous-git.sh`

Then `chmod +x` it.

**Step 3 — add the hook to settings.**

Project (`.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

Global (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

**Merge, never overwrite.** If the settings file exists, add this entry to the existing `hooks.PreToolUse` array and leave every other setting alone. Read the file, merge, write back — a clobbered `settings.json` costs the user more than the hook saves. The `update-config` skill owns this file too; coordinate rather than racing it.

**Step 4 — ask about customisation.** Does the user want patterns added or removed? Edit the copied script, not the one in this skill.

**Step 5 — verify.** This step is not optional; an unverified hook is indistinguishable from no hook.

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>
```

Expect exit code 2 and a BLOCKED message on stderr. Also confirm a safe command passes:

```bash
echo '{"tool_input":{"command":"git status"}}' | <path-to-script>
```

Expect exit code 0 and no output.

### Mode 2 — default-on across every repo

Offer this only if the user wants the guardrail always active wherever the Staksmith plugin loads: wire the script into the plugin's own `hooks/hooks.json` instead of a per-project settings file.

Two things to settle before doing it:

- **Flag gating.** Staksmith's other hooks run through `scripts/hooks/run-with-flags.js`, which gates them on hook-profile flags (`standard`, `strict`). Decide with the user whether this hook should be flag-gated the same way — a guardrail that a profile can silently switch off is a weaker guarantee, so ungated is the defensible default here.
- **Blast radius.** Default-on means every repo the plugin touches, including ones where the user does want an agent pushing. Confirm that's genuinely what they want.

The script depends on `jq`. Check it's present before promising the hook works.

## Portability note

The mechanism is Claude-Code-specific — `PreToolUse` hooks have no OpenAI-compatible equivalent, so `agents/openai.yaml` here is a stub kept for consistency across the skill collection. This skill genuinely does not port; the closest equivalent on another harness is whatever command-approval layer it offers.

## Related skills

- **`update-config`** — owns `settings.json` generally, including `permissions.deny`. Use it for the prefix-match layer that complements this hook.
- **`draft-commit`** — the intended path for commits: stage, draft a message, let the user run it.
- **`resolving-merge-conflicts`** — the hook is what keeps an automated `--abort` or `reset --hard` from happening mid-conflict.
