# Model panel

This file is the slice of model selection and subagent tuning that `how` needs. If no config exists, use the defaults below.

Explorers and the explainer are readonly. They explain. They do not edit.

## Where the slugs come from

Two lines, read independently:

| Role | Config line | Env override | Default |
| --- | --- | --- | --- |
| Explorers | `how explorer:` | `STAKSMITH_HOW_EXPLORER` | `grok-4.7-xhigh-fast` |
| Explainer | `how explainer:` | `STAKSMITH_HOW_EXPLAINER` | `claude-opus-5-5-xhigh` |

If the env var is set, it wins for that role. Do not also read a file for that role.

Otherwise read the first file that exists and has the line:

1. `~/.staksmith/models.md`
2. `~/.claude/rules/pstack-models.md`
3. `~/.cursor/rules/pstack-models.mdc`

A file that exists but has no matching line does not count for that role. Keep going. If none has the line, use the default.

`auto` and `inherit-parent` mean the parent session's model. Omit `model` for that seat.

To set this without another plugin, write `~/.staksmith/models.md`:

```text
how explorer: grok-4.7-xhigh-fast
how explainer: claude-opus-5-5-xhigh
```

## Reasoning and speed

Start from the configured slug. Change only the effort level and whether the slug is fast. Keep the family.

- Raise effort one step, up to the family's max, when the subsystem spans services or the question is where a new piece should live.
- Lower effort one step for a single function.
- Use a `-fast` slug only when CI or trunk is red, or a person is blocked on the result right now. Otherwise use the same slug without `-fast`.
- A seat on `auto` or `inherit-parent` stays on the parent model. Do not retune it.
- If the family has no slug at the chosen level and speed, use its nearest slug.
- If the tool rejects the adjusted slug, do not try another adjustment. Use the configured slug or the table default, and say so.

## Rejected slugs

Families go by prefix: `claude-*`, and `grok-*` with `cursor-grok-*` and `composer-*`.

If the tool rejects a configured entry, run that seat on its family's table default and say so. A refused `composer-*` entry runs on `grok-4.7-xhigh-fast`. With no family match, use `claude-opus-5-5-xhigh`. If it rejects a table default, spawn with the closest equivalent from the valid slugs in its error (same family, same reasoning tier if possible), and tell the user the default table in this file needs an update. Do not block the walkthrough on the slug. Never treat `auto` or `inherit-parent` as a rejected slug.

## Harness mapping

Spawn every explorer in one message. Spawn the explainer only after they return. Simple questions spawn only the explainer.

| Harness | Spawn |
| --- | --- |
| Cursor | `Task`, `subagent_type: generalPurpose`, `readonly: true`, `model` set to the slug. |
| Claude Code | `Agent`. Readonly maps to `subagent_type: "Explore"`. Also tell the agent not to edit files, and check `git status` after. A `claude-<family>-<version>-<effort>[-fast]` slug becomes `model` of `opus`, `sonnet`, or `haiku` (match the family token) and `effort` of the effort token. Drop `-fast`. `model` accepts only values the tool schema lists. |
| OpenCode | The session's task or subagent tool, readonly, `model` set when the schema allows it. |
| Pi, or any harness with no subagent tool | Take the simple path in this session. Say the multi-explorer pass did not run. Do not role-play the missing explorers. |

Claude Code, and any harness that cannot set a non-Claude model: do not omit `model` and pretend that seat was a different vendor. Skip that seat, name the slug you could not run, and continue with the seats you can actually run. If that leaves no explainer, write the explanation yourself from the code you read and say so. Do not invent a second model's walkthrough.
