---
name: blog-ideas
description: Generate blog post ideas for The HackaStak by mining your Obsidian vault for expertise, filtered through the blog strategy, pillars, and audience. Use when planning the content calendar or deciding what to write next.
category: "Writing & Content"
origin: Hackastak
---

# Generate Blog Post Ideas

Mine the vault for blog-worthy topics grounded in your actual expertise and learning, filtered through The HackaStak's strategy and audience.

## When to Activate

- planning your content calendar
- stuck on what to write next
- want to turn scattered learning into publishable content
- looking for topics where you have a unique angle
- need to identify your strongest content opportunities

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

## Step 1: Load Blog Strategy

Read the strategy document first — it defines what belongs on The HackaStak:

```bash
cat "$VAULT_PATH/$BLOG_PATH/Blog_Strategy.md"
```

Key filters to internalize before generating ideas:
- **Target reader:** Early-to-mid career devs (18–35) looking to level up their toolkit
- **Content pillars:** (1) Developer Tooling Roundups, (2) Engineering Best Practices, (3) Career & Growth, (4) AI x Developer Workflow, (5) Personal Knowledge Systems (PKM)
- **Off-limits:** Generic marketing content, doom-and-gloom takes, enterprise-only tools, abstract AI think-pieces, career-advice essays with no concrete tool or system attached
- **Current priority (from July 2026 data):** Concrete tools and personal-system pieces, first-person and actionable, win by a wide margin. Tool-specific roundups (esp. CLI) and PKM / second-brain content are the proven veins. AI content only works when it's personal and tool-specific, never as commentary.

## Step 2: Inventory Your Knowledge Base

Scan the vault to understand where expertise lives:

**Active projects (deep hands-on experience):**
```bash
ls -d "$VAULT_PATH/1. Projects"/*/ 2>/dev/null
```

**Areas of ongoing focus:**
```bash
ls -d "$VAULT_PATH/2. Areas"/*/ 2>/dev/null
```

**Resources being collected (emerging interests):**
```bash
ls -d "$VAULT_PATH/3. Resources"/*/ 2>/dev/null
```

**Recent activity (what's top of mind):**
```bash
find "$VAULT_PATH" -name "*.md" -mtime -14 -type f ! -path "*/.obsidian/*" ! -path "*/.claude/*" | head -30
```

Read representative notes from each category to understand depth and angle.

## Step 3: Identify Blog-Worthy Patterns

Look for these signals in the notes:

**Strong Signals (High Priority):**
- Lessons learned the hard way—problems you solved after struggle
- Contrarian opinions—views that differ from mainstream
- Frameworks developed—mental models or processes you use
- Before/after transformations—skills or approaches that changed
- Repeated explanations—concepts explained to others often
- Unique combinations—intersections of different interests

**Medium Signals (Worth Exploring):**
- Questions answered deeply—topics with multiple related notes
- Tools or workflows built—things that work for you
- Industry observations—patterns others miss

**Skip Unless Compelling:**
- Topics with only surface-level notes
- Areas where you're mostly consuming, not creating
- Subjects already saturated with similar content

## Step 4: Cross-Reference with Existing Blog Content

Check what's already been written:

**Published posts:**
```bash
ls "$VAULT_PATH/$BLOG_PATH/PUBLISHED/" 2>/dev/null
```

**Current drafts and backlog:**
```bash
find "$VAULT_PATH/$BLOG_PATH" -name "*.md" -type f ! -path "*/PUBLISHED/*" 2>/dev/null
```

Read these to identify gaps and avoid repetition.

## Step 5: Evaluate Each Potential Topic

For each idea, assess against The HackaStak's criteria:

**Fit Check:**
1. **Pillar alignment**: Does it fit one of the five pillars? (Tooling, Best Practices, Career, AI x Dev, PKM)
2. **Reader match**: Would an early-to-mid career dev searching to level up care about this?
3. **Filtration value**: Does recommending this earn trust, or is it obvious/commodity info?

**Quality Check:**
4. **Specificity**: Concrete problem or vague theme?
5. **Evidence**: Can you support claims with real experience?
6. **Actionability**: Can readers install/do something today?

**Winning-pattern Check (the real driver — weight this heavily):**
7. **Concrete subject**: Is it about specific named tools or a specific personal system, not an abstract theme or opinion?
8. **First-person / lived**: Can it be written as "the tools/system I actually use," "how I built X"?
9. **Format fit**: If it's a roundup, can it follow Description → Key Features → Why You Should Use It? (Format is secondary — a listicle about an abstract topic still flops.)

**Priority Boost (from July 2026 data):** Give extra weight to (a) tool-specific roundups, especially CLI/terminal, and (b) PKM / second-brain / personal-workflow ideas — these are the proven top performers. Down-weight abstract AI think-pieces and standalone career-advice essays; they get throttled by Medium's distribution.

## Step 6: Generate the Ideas Report

Present findings in this format:

```
# Blog Post Ideas
*Generated: [current date]*
*Based on: [X] vault areas analyzed*

---

## Ready to Write

Ideas with strong expertise and clear angle.

### 1. [Working Title]
**Pillar:** [Tooling / Best Practices / Career / AI x Dev / PKM]
**Core Argument:** [One sentence thesis]
**Your Angle:** [Why you specifically can write this]
**Evidence Available:** [[Note 1]], [[Note 2]]
**Format:** [Listicle (10 items) / Deep dive / How-to]
**Suggested Tags:** [3-5 Medium tags from strategy]
**Headline Options:**
- [Topic: The Subtitle That Sells It]
- [Alternative]

### 2. [Working Title]
[Same format...]

---

## Needs Development

Strong potential but requires more research.

### 3. [Working Title]
**Seed Idea:** [The kernel]
**Found In:** [[Note]]
**Missing:** [What you'd need to develop]

---

## Contrarian Takes

Opinions against consensus—higher risk, higher engagement.

### 4. [Working Title]
**Mainstream View:** [What most people think]
**Your Position:** [Your contrarian argument]
**Why You're Right:** [Evidence from experience]

---

## Series Opportunities

Topics deep enough for multi-part coverage.

### 5. [Series Title]
**Part 1:** [First post]
**Part 2:** [Second post]
**Connecting Thread:** [What ties them together]

---

## Quick Hits

Smaller ideas for shorter posts.

- [Idea]: [One line description]
- [Idea]: [One line description]

---

## Recommended Next Steps

1. **Start this week:** [Highest-value idea]
2. **Develop this month:** [Strong idea needing work]
```

## Step 7: Offer Follow-Up

After presenting the report, ask:

> "Which idea interests you most? I can:
> 1. Generate a detailed outline
> 2. Draft the full post using `/blog-draft [topic]`
> 3. Find more evidence in the vault
> 4. Develop the contrarian angle further"

## Quality Criteria (The HackaStak Filter)

**Strong ideas have:**
- Clear thesis in one sentence
- Evidence from actual experience
- Fit within one of the five pillars
- Appeal to early-to-mid career devs leveling up
- Listicle potential with the scaffold (Description → Features → Why You Should Use It)
- Mix of well-known anchors + lesser-known finds

**Weak ideas have:**
- Vague themes without a point
- Topics you're interested in but haven't practiced
- Enterprise-only tools the average reader won't touch
- Doom-and-gloom framing (flip to opportunity angle)
- "Me too" content without the trusted-filter positioning

## Notes

- Quality over quantity: 5 strong ideas beat 15 mediocre ones
- Your best content comes from problems you've actually solved
- Check recent weekly notes—freshest insights live there
- When stuck, start with "What did I learn that I wish I knew earlier?"
- Mirrors the `/blog-ideas` invocation; pairs with `blog-draft`.
