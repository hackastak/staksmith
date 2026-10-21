# Model panel

This file is the slice of model selection and subagent tuning that `why` needs. If no config exists, use the defaults below.

Investigators and the synthesizer need tool access. Do not spawn them readonly, in Ask mode, or as an Explore agent. Readonly mode strips MCP access. Tell each one not to write, commit, or change external state, and check `git status` after.

## Where the slugs come from

Two lines, read independently:

| Role | Config line | Env override | Default |
| --- | --- | --- | --- |
| Investigators | `why investigators:` | `STAKSMITH_WHY_INVESTIGATORS` | `grok-4.7-xhigh-fast` |
| Synthesizer | `why synthesizer:` | `STAKSMITH_WHY_SYNTHESIZER` | `claude-opus-5-5-xhigh` |

If the env var is set, it wins for that role. Do not also read a file for that role.

Otherwise read the first file that exists and has the line:

1. `~/.staksmith/models.md`
2. `~/.claude/rules/pstack-models.md`
3. `~/.cursor/rules/pstack-models.mdc`

A file that exists but has no matching line does not count for that role. Keep going. If none has the line, use the default.

`auto` and `inherit-parent` mean the parent session's model. Omit `model` for that seat.

To set this without another plugin, write `~/.staksmith/models.md`:

```text
why investigators: grok-4.7-xhigh-fast
why synthesizer: claude-opus-5-5-xhigh
```

## Reasoning and speed

Start from the configured slug. Change only the effort level and whether the slug is fast. Keep the family.

- Raise effort one step, up to the family's max, when the history is long, contradictory, or the question is a regression or postmortem.
- Lower effort one step for a single obvious commit whose PR body already states the reason.
- Use a `-fast` slug only when CI or trunk is red, or a person is blocked on the result right now. Otherwise use the same slug without `-fast`.
- A seat on `auto` or `inherit-parent` stays on the parent model. Do not retune it.
- If the family has no slug at the chosen level and speed, use its nearest slug.
- If the tool rejects the adjusted slug, do not try another adjustment. Use the configured slug or the table default, and say so.

## Rejected slugs

Families go by prefix: `claude-*`, and `grok-*` with `cursor-grok-*` and `composer-*`.

If the tool rejects a configured entry, run that seat on its family's table default and say so. A refused `composer-*` entry runs on `grok-4.7-xhigh-fast`. With no family match, use `claude-opus-5-5-xhigh`. If it rejects a table default, spawn with the closest equivalent from the valid slugs in its error (same family, same reasoning tier if possible), and tell the user the default table in this file needs an update. Do not block the investigation on the slug. Never treat `auto` or `inherit-parent` as a rejected slug.

## Harness mapping

Spawn every investigator in one message. Spawn the synthesizer only after they return.

| Harness | Spawn |
| --- | --- |
| Cursor | `Task`, `subagent_type: generalPurpose`, `readonly: false`, `model` set to the slug. |
| Claude Code | `Agent`, not `Explore`. `Explore` is readonly and can strip MCP. Tell the agent not to edit files, and check `git status` after. A `claude-<family>-<version>-<effort>[-fast]` slug becomes `model` of `opus`, `sonnet`, or `haiku` (match the family token) and `effort` of the effort token. Drop `-fast`. `model` accepts only values the tool schema lists. |
| OpenCode | The session's task or subagent tool, `model` set when the schema allows it. |
| Pi, or any harness with no subagent tool | Do the category searches in this session. Say the panel was single-agent. Do not role-play the missing investigators. Do not invent a second model's findings. |

Claude Code, and any harness that cannot set a non-Claude model: do not omit `model` and pretend that seat was a different vendor. Skip that seat, name the slug you could not run, and continue with the seats you can actually run. Source control still runs in this session, because git and `gh` do not need a subagent. If the synthesizer slug cannot run, write the synthesis yourself and say so.
