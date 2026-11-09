# Model panel

This file is the slice of model selection `architect` needs for Phase B. It does not require another plugin. If no config exists, use the defaults below.

Candidates write only inside the output path arena gave them.

## Where the list comes from

One line. Split on commas. Trim whitespace. Drop empty entries.

| Role | Config line | Env override | Default |
| --- | --- | --- | --- |
| Runners | `architect runners:` | `STAKSMITH_ARCHITECT_RUNNERS` | the `arena runners:` line, else `claude-opus-5-5-xhigh`, `grok-4.7-xhigh-fast` |

If the env var is set, it wins. Do not also read a file.

Otherwise read the first file that exists and has `architect runners:`:

1. `~/.staksmith/models.md`
2. `~/.claude/rules/pstack-models.md`
3. `~/.cursor/rules/pstack-models.mdc`

A file that exists but has no `architect runners:` line does not count. Keep going. If none has the line, use the `arena runners:` line from the same search. If that is also missing, use the default.

An `auto` or `inherit-parent` entry means the parent model. Omit `model` for that seat.

To set this without another plugin, write `~/.staksmith/models.md`:

```text
architect runners: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
```

Alias and rejected entries follow the runner rules in the `arena` skill. Do not invent a runner you cannot spawn. If this harness cannot spawn subagents, do not use this list to role-play them. Follow the same-model fallback in the architect skill.
