---
name: blog-draft
description: Draft a complete blog post for The HackaStak by mining the vault for evidence and writing in the established brand voice. Use when you have a topic ready and want a full first draft.
category: "Writing & Content"
origin: Hackastak
---

# Draft a Blog Post

Draft a complete blog post for The HackaStak by mining the vault for evidence and writing in the established brand voice.

## When to Activate

- you have a topic or idea ready to develop
- you want to turn vault notes into a polished article
- you need a first draft to edit rather than starting from a blank page
- you're expanding on an idea from `/blog-ideas`

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

Input: the topic, title, or idea to draft a post about. If empty, ask what topic to write about.

## Step 1: Load Blog Strategy

Read the strategy document first — it defines voice, format, and audience:

```bash
cat "$VAULT_PATH/$BLOG_PATH/Blog_Strategy.md"
```

Key constraints to apply throughout drafting:
- **Reader:** Early-to-mid career devs (18–35) leveling up their toolkit
- **Voice:** Conversational, practical, encouraging, opinionated-but-fair, no-fluff
- **Format:** Concrete tools or a personal system, first-person and actionable, is what wins (format is secondary). For roundups, use the item scaffold: Description → Key Features → Why You Should Use It
- **Emoji budget:** 2–3 per piece (🚀 💡 🛠️ ✨)
- **Headline pattern:** "Topic: The Subtitle That Sells It"

## Step 2: Clarify the Topic

If no topic was provided, ask:
> "What topic should I draft a post about?"

Otherwise, proceed with the provided topic.

## Step 3: Gather Source Material

Search the vault for relevant content:

**Direct topic matches:**
```bash
grep -r -l "[topic keywords]" "$VAULT_PATH" --include="*.md" 2>/dev/null | grep -v ".obsidian" | grep -v ".claude" | head -20
```

**Check key content areas:**
```bash
find "$VAULT_PATH/1. Projects" "$VAULT_PATH/2. Areas" "$VAULT_PATH/3. Resources" -name "*.md" -type f 2>/dev/null | head -30
```

Read relevant notes and extract:
- Key arguments and opinions
- Specific examples and experiences
- Data points or evidence
- Related concepts to weave in

## Step 4: Analyze Voice and Style

Read published posts to match the voice:

```bash
cat "$VAULT_PATH/$BLOG_PATH/PUBLISHED"/*.md 2>/dev/null | head -200
```

**The HackaStak voice patterns:**
- **Tone**: Conversational, practical, encouraging, opinionated-but-fair
- **Paragraphs**: Short (1–3 sentences) with white space
- **Contractions**: Always — *it's*, *you'll*, *don't*
- **Transitions**: Rhetorical questions ("Sound familiar?")
- **Product names**: **Bold** on first mention
- **Emojis**: 2–3 per piece, sparingly (🚀 💡 🛠️ ✨)
- **Openings**: Hook in first two sentences (Medium preview shows ~200 chars)
- **Endings**: Direct CTA ("Which one are you trying first?")

## Step 5: Develop the Thesis

Before writing, crystallize:

1. **One-sentence thesis**: What's the main argument?
2. **Reader problem**: What pain does this address for early-to-mid career devs?
3. **Promise**: What will the reader gain? (Can they install/do something today?)
4. **Filtration value**: Why does this earn a spot on The HackaStak?

If thesis isn't clear, propose 2-3 angles and ask which direction.

## Step 6: Create the Structure

**For listicles (the winning format):**

```
## Hook (1-2 short paragraphs)
- Hook in first two sentences — Medium preview shows ~200 chars
- Establish stakes: why this matters to devs leveling up

## Brief Context (1 paragraph)
- What problem this list solves
- "Here's what I learned after testing X tools..."

## The List (10 items is the sweet spot)
For each item, use the scaffold:

### 1. **Tool Name** 🛠️
**Description:** What it is and does (1-2 sentences)

**Key Features:**
- Feature 1
- Feature 2
- Feature 3

**Why You Should Use It:** The honest take on when/why this earns its spot (2-3 sentences)

## Quick Decision Guide (optional)
- Summary table or "choose X if you need Y" format

## CTA (1 paragraph)
- Direct question: "Which one are you trying first?"
- Invitation to comment
```

**For best-practices / deep-dive pieces:**

```
## Hook (1-2 paragraphs)
## Context / The Problem
## Main Content (H2s every 200-300 words)
## Synthesis
## CTA
```

## Step 7: Write the Draft

**Voice Rules (The HackaStak style):**
- First person when sharing experience
- Contractions always — *it's*, *you'll*, *don't*
- Short paragraphs (1–3 sentences)
- Use "you" to address reader directly
- Rhetorical questions as transitions ("Sound familiar?")
- **Bold product names** on first mention
- Opinionated but fair, because readers trust your filter
- **No em dashes (`—`).** They read as AI-generated. Join two clauses with a comma + coordinating conjunction (and, but, or, so) to make a compound sentence, use commas (or parentheses) for an aside, a colon for an elaboration or list, or just split into two sentences. Only the em dash (`—`) is banned. Hyphens (`-`) in compound words and modifiers are fine and should stay (no-fluff, open-source, early-to-mid, terminal-native). En dashes (`–`) in numeric ranges (`7–12`, `$3–$5`) are also fine.
- **No reflexive antithesis.** Avoid the "It's not X, it's Y" negation-contrast construction and its variants ("That's not A, that's B," "not just X but Y," "X isn't about A, it's about B"). It's an AI-writing tell, the same family as em dashes. Used once it lands, but sprinkled through a piece it reads as a tic, so cap it at one per article and state the positive claim directly instead. Genuine factual either/or distinctions the reader needs (e.g., "`fc` edits the last command, not the current line") are fine and don't count.

**Structure Rules:**
- Lead each section with concrete thing: example, number, anecdote
- Headers should be informative, not clever
- H2s every 200–300 words for scannability
- One image minimum in first third (for Medium thumbnail)

**Evidence Rules:**
- Reference specific vault notes as sources
- Prefer real examples over hypotheticals
- Include specific numbers when available
- Mix well-known anchors with lesser-known finds

**Banned Patterns (delete and rewrite these):**
- "In today's rapidly evolving landscape"
- "Let's dive in" or "without further ado"
- "Game-changer," "revolutionary," "cutting-edge" (undermines trusted-filter positioning)
- "In conclusion" or "To summarize"
- "Moreover," "Furthermore," "Additionally"
- Corporate/formal tone ("utilize," "leverage")
- Doom-and-gloom framing (flip to opportunity angle)
- Excessive hype or exclamation points
- Em dashes (`—`), per the no-em-dash voice rule above
- Reflexive antithesis ("It's not X, it's Y," "not just X but Y," "X isn't about A, it's about B") used for rhythm, per the antithesis voice rule above; state the point directly, one per article max

**Emoji Usage:**
- Budget: 2–3 per article
- Preferred: 🚀 💡 🛠️ ✨
- Place in headers or key callouts, not every paragraph

## Step 8: Add Supporting Elements

**Quick Decision Guide** (for listicles):
- Summary table or "choose X if you need Y" format
- Helps readers who skim

**FAQ Section** (if warranted):
- 2-4 common questions
- Direct, practical answers

**Code Blocks** (for technical posts):
- Working, runnable examples
- Minimal but complete

## Step 9: Quality Check

Before delivering, verify against The HackaStak standards:

**Content:**
- [ ] Hook grabs attention in first two sentences (Medium preview = ~200 chars)
- [ ] Thesis clear by end of intro
- [ ] Every section adds new information
- [ ] Examples are specific and real
- [ ] Mix of known tools + lesser-known discoveries
- [ ] Ending has direct CTA ("Which one are you trying first?")

**Voice:**
- [ ] Contractions used throughout
- [ ] Short paragraphs (1–3 sentences)
- [ ] No em dashes (`—`) anywhere in the body
- [ ] Reflexive antithesis ("It's not X, it's Y") kept to one per article, max
- [ ] No banned phrases
- [ ] No corporate/formal tone
- [ ] Opinionated but fair, not preachy

**Format:**
- [ ] Listicle items follow scaffold (Description → Features → Why You Should Use It)
- [ ] H2s every 200–300 words
- [ ] **Bold product names** on first mention
- [ ] 2–3 emojis max
- [ ] Length: 7–12 minute read (Medium sweet spot)

**SEO:**
- [ ] Target keywords in first 100 words
- [ ] Year-stamp if evergreen ("best tools 2026")

## Step 10: Deliver the Draft

Output format:

```markdown
# [Topic: The Subtitle That Sells It]

[Full draft content...]

---

## Draft Notes

**Word count:** [X] words
**Estimated read time:** [X] minutes
**Pillar:** [Tooling / Best Practices / Career / AI x Dev / PKM]

**Suggested Medium tags:**
- [Tag 1], [Tag 2], [Tag 3], [Tag 4], [Tag 5]

**Vault sources used:**
- [[Note 1]] - [how used]
- [[Note 2]] - [how used]

**Suggested edits:**
1. [Specific recommendation]
2. [Section that might need expansion]

**Alternative titles:**
- [Topic: Alternative Subtitle]
- [Different Angle: Subtitle]

**Cross-post reminder:** Publish to Dev.to and Hashnode with canonical URL pointing to Medium
```

## Step 11: Save Draft and Archive Outline

After the draft is complete, save it and clean up:

**1. Generate the filename from the topic:**
- Convert topic to filename: replace spaces with underscores, remove special characters
- Example: "Stop Writing Tests Before You Know What You're Building" → `Stop_Writing_Tests_Before_You_Know_What_Youre_Building`

**2. Save the draft:**
```bash
# Save to DRAFT file in the blog folder
# Path: $VAULT_PATH/$BLOG_PATH/[Topic_Name]_DRAFT.md
```

Include proper frontmatter:
```yaml
---
status: drafting
pillar: [Tooling / Best Practices / Career / AI x Dev / PKM]
read_time: [estimated minutes]
word_count: [approximate]
tags:
  - [Tag 1]
  - [Tag 2]
seed_idea: "[one-line summary]"
---
```

**3. Archive any existing outline:**
If an OUTLINE file exists for this topic, move it to archive:
```bash
# Check if outline exists
ls "$VAULT_PATH/$BLOG_PATH/[Topic_Name]_OUTLINE.md" 2>/dev/null

# If it exists, ensure archive folder exists and move it
mkdir -p "$VAULT_PATH/4. Archive/Blog_Outlines"
mv "$VAULT_PATH/$BLOG_PATH/[Topic_Name]_OUTLINE.md" "$VAULT_PATH/4. Archive/Blog_Outlines/"
```

This keeps the Content_Calendar clean — only the active DRAFT appears, while outlines are preserved in archive.

## Step 12: Offer Iteration

After delivering, ask:

> "Here's your draft. Would you like me to:
> 1. Strengthen a specific section?
> 2. Add more examples from your vault?
> 3. Adjust the tone or length?
> 4. Add a comparison table or decision guide?
> 5. Generate social posts to promote it?"

## Notes

- First drafts are meant to be edited, so aim for 80% quality
- Better to include too much evidence than too little
- If vault sources are thin, acknowledge gaps
- 7–12 minute read time is the Medium sweet spot
- When in doubt, start with the most concrete example you have
- Mix well-known tools (validation) with lesser-known finds (discovery)
- Remember: consistency matters more than topic selection right now — ship it
- Mirrors the `/blog-draft` invocation; pairs with `blog-ideas`.
