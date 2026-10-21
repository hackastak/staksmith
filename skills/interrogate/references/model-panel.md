# Reviewer panel

This file is the slice of pstack's model rule and subagent tuning that interrogate needs. It does not require poteto-mode or setup-pstack. If neither config exists, use the defaults below.

## Where the list comes from

Read the first source that exists and has an `interrogate reviewers:` line. Split on commas. Trim whitespace. Drop empty entries. Spawn one reviewer per entry, labeled Reviewer A, B, and so on, in that order.

1. `STAKSMITH_INTERROGATE_REVIEWERS` (comma-separated). If set, it wins. Do not also read a file.
2. `~/.staksmith/models.md`
3. `~/.claude/rules/pstack-models.md`
4. `~/.cursor/rules/pstack-models.mdc`

A file that exists but has no `interrogate reviewers:` line does not count. Keep going.

If none of those has the line, use the defaults:

| Label | Default slug |
| --- | --- |
| Reviewer A | `claude-opus-5-5-xhigh` |
| Reviewer B | `grok-4.7-xhigh-fast` |

`auto` and `inherit-parent` mean the parent session's model. Omit `model` for that seat.

To set a panel without pstack, write `~/.staksmith/models.md` with one line:

```text
interrogate reviewers: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
```

## Reasoning and speed

Start from the configured slug. Change only the effort level and whether the slug is fast. Keep the family, so a diverse panel stays diverse.

- Raise effort one step, up to the family's max, when the diff is large, subtle, or security-sensitive.
- Lower effort one step for a small, obvious diff.
- Use a `-fast` slug only when CI or trunk is red, or a person is blocked on the result right now. Otherwise use the same slug without `-fast`.
- A seat on `auto` or `inherit-parent` stays on the parent model. Do not retune it.
- If the family has no slug at the chosen level and speed, use its nearest slug.
- If the tool rejects the adjusted slug, do not try another adjustment. Use the seat's configured slug or table default, and say so.

## Rejected slugs

Families go by prefix: `claude-*`, and `grok-*` with `cursor-grok-*` and `composer-*`.

If the tool rejects a configured entry, run that reviewer on its family's table default and say so. A refused `composer-*` entry runs on Reviewer B's default. With no family match, use Reviewer A's default. If it rejects a table default, spawn with the closest equivalent from the valid slugs in its error (same family, same reasoning tier if possible), and tell the user the default table in this file needs an update. Do not block the review on the slug. Never treat `auto` or `inherit-parent` as a rejected slug.

## Harness mapping

Spawn every reviewer in one message, all readonly. Do not edit, commit, or apply their suggestions.

| Harness | Spawn |
| --- | --- |
| Cursor | `Task`, `subagent_type: generalPurpose`, `readonly: true`, `model` set to the slug. |
| Claude Code | `Agent`. Readonly maps to `subagent_type: "Explore"`. Also tell the reviewer not to edit files, and check `git status` after. A `claude-<family>-<version>-<effort>[-fast]` slug becomes `model` of `opus`, `sonnet`, or `haiku` (match the family token) and `effort` of the effort token. Drop `-fast`. `model` accepts only values the tool schema lists. |
| OpenCode | The session's task or subagent tool, readonly, `model` set when the schema allows it. |
| Pi, or any harness with no subagent tool | Stop. Say this harness cannot run a multi-model panel. Do not role-play the missing reviewers. |

Claude Code, and any harness that cannot set a non-Claude model: do not omit `model` and pretend that seat was a different vendor. Skip that seat, name the slug you could not run, and continue with the seats you can actually run. If that leaves fewer than two distinct models, say the panel is not diverse and that the verdict is weaker because of it. Still synthesize what you have. Do not invent a second model's findings.

Each reviewer prompt is built from `references/reviewer-prompt.md`, with the rubric and code-quality lens filled in. Use the same template for every seat. The adversarial signal is model diversity, not assigned personas. Do not give reviewers different personalities.
