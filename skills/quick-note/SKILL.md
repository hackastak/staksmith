---
name: quick-note
description: Summarize the work done in this chat into one tight reference line and append it to the current week's weekly note, under today, in the right section (Hackastak or SAP Business Network) with a project label. Minimal reference points, not detailed notes. Use when work wraps up, when the user invokes /quick-note, or as the final logging step of /handoff.
category: "Second Brain & Vault"
origin: Hackastak
argument-hint: "Section/project hint, or nothing"
---

# Quick Note

Log the work from this session as a **single tight line** (two at most) in the current week's weekly note, under today's day, in the right section. These are minimal reference points a future you can scan, not detailed project notes. Distill hard, cut every unnecessary word.

## When to use

- Work in the session is complete and worth a one-line record.
- The user invokes `/quick-note`.
- As the final step of `/handoff` (see [[handoff]]), which chains this skill to log the thread before the session ends.

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

## The target note

The current week's note lives at:

```
$VAULT_PATH/_Weekly/$(date +%G)/$(date +%G)-W$(date +%V).md
```

`date +%G` is the ISO year, `date +%V` the ISO week — always compute them, never hardcode. Today's day line is `date +%A` (e.g. `Tuesday`).

If that note does not exist, **stop and tell the user** — do not invent the weekly structure. Offer to run `weekly-momentum-report` or create it, but wait for the yes.

## Note structure you are writing into

Each weekly note has top-level sections (`# Hackastak`, `# SAP Business Network`), each with a `#### Daily Journal` and plain day-name lines (`Monday`, `Tuesday`, ...). Bullets sit under the day line; sub-points are tab-indented. Example:

```markdown
# Hackastak
#### Daily Journal
Monday
- Staksmith: built out the setup-hackastak skill
Tuesday
- <your new line goes here, after any existing Tuesday bullets>
```

## How it works

1. **Distill the work.** Read what this session actually accomplished and compress it to one line (two only if the work genuinely split). Concrete and terse: what shipped, not the play-by-play. If nothing was really completed, say so and do not write a filler entry.

2. **Pick the section and label — infer, then confirm.** Infer from the cwd / repo and the nature of the work:
   - SAP work (repos under `~/Developer/SBN/`, SAP CAP / Jira / `NEXTGEN-*` tickets, `oms-*` repos) → `# SAP Business Network`.
   - Everything else (personal projects, job search, blog, this Staksmith repo) → `# Hackastak`.
   - Derive a project label from the repo/project for the Hackastak style prefix: `Staksmith`, `Hackafolio`, `RepoG`, `Blog`, etc. For SAP, match the existing style (`[[supplier-reliability-index]] (NEXTGEN-51072): ...`).
   - If `$ARGUMENTS` names a section/project, let it override the inference. If the work clearly spans both sections, confirm and write a line to each.

3. **Format the line** to blend with the surrounding bullets:
   - Hackastak: `- <Project>: <tight summary>`
   - SAP Business Network: `- <tight summary>` (or `- [[project]] (TICKET): <tight summary>`)

4. **Place it under today.** Locate the chosen section, its `#### Daily Journal`, then today's day line. Append the new bullet as the **last** bullet for that day, immediately before the blank line preceding the next day heading. If today's day line has no bullets yet, add it directly beneath the day line.

5. **Write it.** Apply the edit directly — don't ask for approval first. In manual mode the harness already stops for approval before the edit lands, so an explicit confirmation step just adds a redundant round-trip. Report the resolved section + day, the note path, and the line written.

## Writing style

- **No em dashes.** Use a comma plus a conjunction, a colon, or split the sentence. This matches the user's vault-writing preference.
- **Minimal.** These are reference points. Fewest words that still say what happened. No preamble, no "worked on", no hedging.
- Match the voice of the existing daily-journal bullets in the same note.

## Guardrails

- **Only edits the current weekly note.** No other vault file, no code, no new project folders.
- Compute the week and day from `date`; never assume last session's week.
- If the weekly note is missing, stop and ask — do not scaffold it silently.
- Never write a filler entry when nothing was completed.
- Write the entry directly rather than asking for approval first; manual mode already gates the edit itself.

## Related skills

- **`handoff`** — chains this skill as its final logging step; handoff captures the full thread state, quick-note leaves the one-line breadcrumb in the weekly note.
- **`weekly-momentum-report`** — narrates the whole week from these daily entries; quick-note is what feeds it.
- **`backlog-review`** — also reads/writes the vault, reconciling backlogs rather than logging daily work.
