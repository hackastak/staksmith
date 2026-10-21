# Model panel

This file is the slice of model selection and subagent tuning that `arena` needs. If no config exists, use the defaults below.

Candidates write only inside the output path Phase A gave them. The cross-judge is readonly.

## Where the lists come from

Two lines, read independently. Split on commas. Trim whitespace. Drop empty entries.

| Role | Config line | Env override | Default |
| --- | --- | --- | --- |
| Runners | `arena runners:` | `STAKSMITH_ARENA_RUNNERS` | `claude-opus-5-5-xhigh`, `grok-4.7-xhigh-fast` |
| Cross-judge pool | `arena cross-judge pool:` | `STAKSMITH_ARENA_CROSS_JUDGE` | `claude-opus-5-5-xhigh`, `grok-4.7-xhigh-fast` |

If the env var is set, it wins for that role. Do not also read a file for that role.

Otherwise read the first file that exists and has the line:

1. `~/.staksmith/models.md`
2. `~/.claude/rules/pstack-models.md`
3. `~/.cursor/rules/pstack-models.mdc`

A file that exists but has no matching line does not count for that role. Keep going. If none has the line, use the default.

An `auto` or `inherit-parent` entry means the parent model. Omit `model` for that seat.

To set this without another plugin, write `~/.staksmith/models.md`:

```text
arena runners: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
arena cross-judge pool: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
```

Pick the cross-judge from the pool after candidates finish. Prefer a different model family from the parent's.

## Reasoning and speed

Start from the configured slug. Change only the effort level and whether the slug is fast. Keep the family, so a diverse panel stays diverse.

- Raise effort one step, up to the family's max, when the artifact is a design, a migration, or a wide blast-radius question.
- Lower effort one step for a small generation task.
- Use a `-fast` slug only when CI or trunk is red, or a person is blocked on the result right now. Otherwise use the same slug without `-fast`.
- A seat on `auto` or `inherit-parent` stays on the parent model. Do not retune it.
- If the family has no slug at the chosen level and speed, use its nearest slug.
- If the tool rejects the adjusted slug, do not try another adjustment. Use the seat's configured slug or table default, and say so.

## Rejected slugs

Families go by prefix: `claude-*`, and `grok-*` with `cursor-grok-*` and `composer-*`.

If the tool rejects a configured entry, run that seat on its family's table default and say so. A refused `composer-*` entry runs on `grok-4.7-xhigh-fast`. With no family match, use `claude-opus-5-5-xhigh`. If it rejects a table default, spawn with the closest equivalent from the valid slugs in its error (same family, same reasoning tier if possible), and tell the user the default table in this file needs an update. Do not block the arena on the slug. Never treat `auto` or `inherit-parent` as a rejected slug.

## Harness mapping

Spawn every runner in one message. Spawn the cross-judge only after every runner has finished writing.

| Harness | Spawn |
| --- | --- |
| Cursor | `Task`, `subagent_type: generalPurpose`, `readonly: false` for runners and `readonly: true` for the judge, `model` set to the slug. Background when the tool allows it. |
| Claude Code | `Agent`. The judge may use `subagent_type: "Explore"`. Runners must not. Tell runners not to edit files outside their output path, and check `git status` after. A `claude-<family>-<version>-<effort>[-fast]` slug becomes `model` of `opus`, `sonnet`, or `haiku` (match the family token) and `effort` of the effort token. Drop `-fast`. `model` accepts only values the tool schema lists. |
| OpenCode | The session's task or subagent tool, `model` set when the schema allows it. |
| Pi, or any harness with no subagent tool | Stop. Say this harness cannot run an arena. Do not role-play the missing candidates. Do not invent a second model's artifact. |

Claude Code, and any harness that cannot set a non-Claude model: do not omit `model` and pretend that seat was a different vendor. Skip that seat, name the slug you could not run, and continue with the seats you can actually run. If that leaves fewer than two distinct models, stop the arena and say the panel was not diverse. Do not invent the missing candidate.
