---
name: story-ideas
description: Generate ranked, documented story ideas for the "Stories You Won't Believe" TikTok channel — unbelievable-but-true historical events. Use when you need fresh ideas for the content pipeline, grounded in real sources and filtered through the channel's pillars.
origin: Hackastak
---

# Story Ideas Generator

Mine history and documented true events for "Stories You Won't Believe" — TikTok-ready ideas that make viewers think *"there's no way that actually happened."*

## When to Activate

- planning the story content calendar
- the ready/idea buffer is running thin
- want a batch of ideas concentrated in a specific pillar
- looking for documented stories with high viral potential
- need to counterweight an over-used pillar (Survival tends to dominate)

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
STORY_PATH=1. Projects/Clipping/Unbelievable_Stories
```

Optional input: a pillar name (e.g. "Survival Stories", "Scams & Cons") or theme to focus the batch. Empty = balanced across all pillars, weighted toward gaps.

## Step 1: Load Strategy

Read the pipeline strategy first — it defines what belongs on the channel:

```bash
cat "$VAULT_PATH/$STORY_PATH/PIPELINE.md"
```

Internalize: the channel promise, the 8 content pillars, viral scoring, the documented-sources rule, and the 70/20/10 content mix.

## Step 2: Inventory What Already Exists

Avoid generating duplicates of ideas already logged or already written:

```bash
cat "$VAULT_PATH/$STORY_PATH/IDEAS.md"
ls "$VAULT_PATH/$STORY_PATH/SCRIPTS/"
grep -h "^pillar:" "$VAULT_PATH/$STORY_PATH/SCRIPTS/"*.md | sort | uniq -c
```

Note which pillars are over- and under-represented and actively counterweight the heavy ones.

## Step 3: Generate 20 Ranked Ideas

Produce **at least 20** ideas, ranked strongest to weakest by viral potential. Favor:
- High curiosity and a strong hook
- Strong emotional impact or a genuine twist
- **Documented** historical sources or well-known accounts (hard requirement — no internet myths unless labeled as legend)
- Pillars currently thin in the backlog/scripts
- The 70/20/10 mix (70% proven-winner pillars, 20% adjacent, 10% wild card)

Each idea uses this exact format (matches existing `IDEAS.md`):

```markdown
## [N]. [Idea Title]

**Hook:** "[The scroll-stopping first line. Intrigue only — no names, dates, or context.]"

**Summary:** [One sentence on what actually happened.]

**Pillar:** [One of the 8 pillars]

**Why People Will Watch:** [The psychological pull — curiosity gap, debate bait, emotional stakes.]

**Viral Potential:** [N]/10
```

## Step 4: Append to IDEAS.md

Append the new batch under a dated heading so old batches are preserved:

```markdown
---

# New Ideas — [today's date]
*Focus: [pillar/theme or "balanced"]*
```

Do not overwrite existing ideas. Use ISO date format (YYYY-MM-DD).

## Step 5: Summarize

Report: how many ideas added, the top 3 by score, which pillars they fill, and a one-line nudge on what to script next:

> "Added [N] ideas. Top picks: [titles]. These fill your [pillar] gap. Run `/story-script [title]` to draft one."

## Rules

- Never use em dashes (use comma + conjunction, colon, or a sentence split).
- Every idea must be a real, documented event — flag anything that's legend/unverified explicitly.
- Hooks open with intrigue, never with a name, date, or location.
- Keep the channel promise sacred: if it isn't shocking, bizarre, mysterious, or emotionally powerful, leave it out.

## Notes

- Mirrors the `/story-ideas` slash command in the vault's `.claude/commands/`.
- Pairs with `story-script` (drafts an idea) and `story-pipeline` (manages the calendar).
