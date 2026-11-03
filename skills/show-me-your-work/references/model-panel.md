# Trail reviewer

This file is the model rule for the cross-model review in `show-me-your-work`. It does not require another plugin. If no config exists, use the defaults below.

Spawn one reviewer. It is readonly. It does not edit the log, the repo, or the transcript. Self-review is not a substitute.

## Where the reviewer comes from

Read the first source that exists and names a slug. Trim whitespace.

1. `STAKSMITH_SHOW_ME_YOUR_WORK_REVIEWER`. If set, it wins. Do not also read a file.
2. `~/.staksmith/models.md`, the `show-me-your-work reviewer:` line.
3. `~/.claude/rules/pstack-models.md`, the same line.
4. `~/.cursor/rules/pstack-models.mdc`, the same line.

A file that exists but has no `show-me-your-work reviewer:` line does not count. Keep going.

If none of those names a slug, pick the default from a different family than the parent:

| Parent family | Default slug |
| --- | --- |
| `claude-*` | `grok-4.7-xhigh-fast` |
| `grok-*`, `cursor-grok-*`, `composer-*` | `claude-opus-5-5-xhigh` |
| anything else | `claude-opus-5-5-xhigh` |

`auto` and `inherit-parent` mean the parent session's model. That seat is the same family as the parent, so it is not a cross-model review. Treat it as unset and use the table instead.

To set a reviewer without another plugin, write `~/.staksmith/models.md` with one line:

```text
show-me-your-work reviewer: grok-4.7-xhigh-fast
```

## Reasoning and speed

Start from the configured slug. Change only the effort level and whether the slug is fast. Keep the family.

- Raise effort one step, up to the family's max, when the trail is long, the work touched security or data, or a revert is in the log.
- Lower effort one step for a short trail with a few rows.
- Use a `-fast` slug only when a person is blocked on the result right now. Otherwise use the same slug without `-fast`.
- If the family has no slug at the chosen level and speed, use its nearest slug.
- If the tool rejects the adjusted slug, do not try another adjustment. Use the configured slug or table default, and say so.

## Rejected slugs

Families go by prefix: `claude-*`, and `grok-*` with `cursor-grok-*` and `composer-*`.

If the tool rejects a configured entry, run the reviewer on its family's table default and say so. A refused `composer-*` entry runs on `grok-4.7-xhigh-fast`. With no family match, use `claude-opus-5-5-xhigh`. If it rejects a table default, spawn with the closest equivalent from the valid slugs in its error (same family, same reasoning tier if possible), and tell the user the default table in this file needs an update. Do not block the hand-back on the slug.

If the only slug you can run is the same family as the parent, do not pretend it was a different vendor. The Attention section says the cross-model review did not run, names the slug you could not run, and does not invent flags.

## Harness mapping

| Harness | Spawn |
| --- | --- |
| Cursor | `Task`, `subagent_type: generalPurpose`, `readonly: true`, `model` set to the slug. |
| Claude Code | `Agent`. Readonly maps to `subagent_type: "Explore"`. Also tell the reviewer not to edit files, and check `git status` after. A `claude-<family>-<version>-<effort>[-fast]` slug becomes `model` of `opus`, `sonnet`, or `haiku` (match the family token) and `effort` of the effort token. Drop `-fast`. `model` accepts only values the tool schema lists. |
| OpenCode | The session's task or subagent tool, readonly, `model` set when the schema allows it. |
| Pi, or any harness with no subagent tool | Stop. Say this harness cannot spawn a different model. Do not role-play the missing reviewer. Do not invent flags. |

The reviewer prompt is: read the decision log and this run's transcript only. Flag weak or missing evidence, verification claimed but not shown, risky choices, and gaps a casual skim would miss. Point at specific rows. Do not redo the work. Do not edit anything.
