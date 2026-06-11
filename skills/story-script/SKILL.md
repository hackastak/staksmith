---
name: story-script
description: Draft a publication-ready TikTok narration script for the "Stories You Won't Believe" channel, matching the owner's four canonical scripts for tone and structure. Use when turning a story idea into a finished, calm, documented script.
origin: Hackastak
---

# Story Script Writer

Turn an idea into a publication-ready TikTok narration script for "Stories You Won't Believe," following the channel's exact formula and the owner's canonical voice.

## When to Activate

- turning an idea from `IDEAS.md` into a finished script
- need a publication-ready narration with caption, on-screen text, and hashtags
- replenishing the ready-to-schedule buffer
- want a draft that matches the channel's established voice and seriousness

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
STORY_PATH=1. Projects/Clipping/Unbelievable_Stories
```

Optional input: the idea to script (a title from `IDEAS.md`, a free-text topic, or a pillar/score to auto-pick). If empty, recommend the highest-scoring unwritten idea and confirm before drafting.

## Step 1: Load Strategy & Source Idea

```bash
cat "$VAULT_PATH/$STORY_PATH/PIPELINE.md"
cat "$VAULT_PATH/$STORY_PATH/IDEAS.md"
ls "$VAULT_PATH/$STORY_PATH/SCRIPTS/"
```

Match the input to an idea. Internalize the Story Formula, retention techniques, writing style, and the quality checklist. Confirm the story is **documented history** — if you can't verify it, say so and recommend a different idea rather than inventing details.

## Step 2: Study the Voice (Canonical Examples)

These four scripts were written by the channel owner and are the **gold standard for voice, tone, and structure.** Always read all four before drafting — they, not this document's description, are the source of truth for how a script should sound. Match them.

```bash
cat "$VAULT_PATH/$STORY_PATH/SCRIPTS/The_Man_Who_Survived_Both_Atomic_Bombs.md"
cat "$VAULT_PATH/$STORY_PATH/SCRIPTS/The_Missing_Son_Imposter.md"
cat "$VAULT_PATH/$STORY_PATH/SCRIPTS/Titanic_Plus_Two_More.md"
cat "$VAULT_PATH/$STORY_PATH/SCRIPTS/Woman_Fell_33000_Feet.md"
```

What to absorb from them:
- **Cadence:** short standalone lines, usually one sentence each, blank line between. Sentences are plain and unadorned.
- **Restraint:** the tone is calm and sincere, never breathless or hyped. The facts carry the shock; the narration does not oversell them. Very few exclamation points and no "OMG you won't BELIEVE this" energy.
- **Gravity:** grim material (mass death, severe injury, exploited grief) is handled with respect, not glee. Stakes are stated plainly and left to land.
- **Understated payoff:** endings are quiet and reflective, not a hard sell ("Sometimes the most unbelievable stories aren't legends. They're documented history."), then a genuine question + "Like and follow for more unbelievable stories just like this one."
- **Honest hedging:** uncertain facts are softened ("reportedly," "by some accounts"), never inflated.

When this document's guidance and the four scripts seem to disagree, **the scripts win.**

## Step 3: Write the Script

Target 60-90 seconds, 180-300 words. Follow the five-beat formula:
1. **Hook (0-5s)** — scroll-stopping first line, intrigue only
2. **Setup (5-15s)** — who / what / why it matters, fast
3. **Escalation (15-40s)** — curiosity rising every 1-3 lines
4. **Twist (40-60s)** — the biggest reveal
5. **Payoff (5-15s)** — shocking close + engagement question + follow CTA

## Step 4: Produce the Full Output

Write the file with this structure (frontmatter + the channel's standard blocks):

```markdown
---
status: ready
pillar: [one of the 8 pillars]
hook: "[the opening line]"
scheduled:
published:
viral_score: [1-10]
platform: TikTok
---

**CAPTION**
` ` `
[1-2 sentence caption that teases without spoiling]

#StoriesYouWontBelieve #TrueStory [+ 6-8 relevant tags]
` ` `

**SCRIPT**
[Full narration, house style — short lines, blank line between]

**ON-SCREEN TEXT**
- [Key phrases to overlay at beats]

**THUMBNAIL TEXT**
[3-6 punchy words]

**ENDING QUESTION**
[The debate-bait question used to close]
```

(Use real triple-backticks around the caption, as in the existing scripts.)

## Step 5: Save & Quality-Check

Write to `$VAULT_PATH/$STORY_PATH/SCRIPTS/[Descriptive_Title].md` (Title_Case_With_Underscores, matching existing files).

Run the quality checklist before finishing:
1. Would someone stop scrolling for the hook?
2. Is something interesting happening every few seconds?
3. Are the stakes increasing?
4. Is there at least one major surprise?
5. Is the ending memorable?
6. Would viewers comment or share this?

Set `status: ready` only if all six pass; otherwise `status: scripted` and note what needs work. Then report:

> "Drafted **[title]** ([pillar], ~[N] words, score [N]/10). Status: [ready/scripted]. Run `/story-pipeline schedule [title] [date]` to slot it, or `/story-pipeline status` to see the calendar."

## Rules

- **Match the four canonical scripts' tone above all else.** Calm, sincere, restrained. Let the facts carry the shock — do not hype, exaggerate, or pile on adjectives. Treat tragedy with respect. If a draft feels breathless or salesy, it's wrong; rewrite it plainer.
- **Never use em dashes.** Use comma + conjunction, colon, or a sentence split.
- Documented events only. No invented quotes, stats, or details. If a fact is uncertain, soften it ("reportedly," "by some accounts") rather than fabricating.
- Open with intrigue, never a name/date/location.
- Don't overwrite an existing script file — pick a new filename or confirm replacement first.

## Notes

- Mirrors the `/story-script` slash command in the vault's `.claude/commands/`.
- The four canonical scripts are pinned by name on purpose — future generated scripts must never replace them as the voice reference.
