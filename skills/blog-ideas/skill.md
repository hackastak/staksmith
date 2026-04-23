---
name: blog-ideas
description: Generate blog post ideas by mining your Obsidian vault for topics where you have expertise, opinions, or unique experiences. Use when you want content ideas grounded in what you actually know and are learning.
origin: custom
---

# Blog Ideas Generator

Surface blog-worthy topics from your vault—ideas grounded in real expertise, not generic content farming.

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

## Step 1: Inventory Your Knowledge Base

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

## Step 2: Identify Blog-Worthy Patterns

Look for signals that indicate strong content potential:

### Strong Signals (High Priority)
- **Lessons learned the hard way**: Problems you solved after struggle
- **Contrarian opinions**: Views that differ from mainstream
- **Frameworks you've developed**: Mental models or processes you use
- **Before/after transformations**: Skills or approaches that changed
- **Repeated explanations**: Concepts you explain to others often
- **Unique combinations**: Intersections of your different interests

### Medium Signals (Worth Exploring)
- **Questions you've answered deeply**: Topics with multiple related notes
- **Tools or workflows you've built**: Things that work for you
- **Industry observations**: Patterns you've noticed others miss
- **Beginner perspective preserved**: Notes from when you were learning

### Weak Signals (Skip Unless Compelling)
- Topics with only surface-level notes
- Areas where you're still mostly consuming, not creating
- Subjects already saturated with similar content

## Step 3: Cross-Reference with Existing Blog Content

Check what's already been written or drafted:

**Published posts:**
```bash
ls "$VAULT_PATH/$BLOG_PATH/PUBLISHED/" 2>/dev/null
```

**Current drafts and backlog:**
```bash
find "$VAULT_PATH/$BLOG_PATH" -name "*.md" -type f ! -path "*/PUBLISHED/*" 2>/dev/null
```

Read these to understand:
- Topics already covered (avoid repetition unless expanding)
- Gaps in coverage relative to expertise
- Successful formats and angles

## Step 4: Evaluate Audience Value

For each potential topic, assess:

1. **Specificity**: Is this a concrete problem or vague theme?
2. **Stakes**: Why would someone care about this?
3. **Differentiation**: What's your unique angle?
4. **Evidence**: Can you support claims with real experience?
5. **Actionability**: Can readers do something with this?

Prioritize topics where you score high on all five.

## Step 5: Generate the Ideas Report

Present findings in this format:

```
# Blog Post Ideas
*Generated: [current date]*
*Based on: [X] vault areas analyzed*

---

## Ready to Write

Ideas with strong expertise and clear angle—could start drafting today.

### 1. [Working Title]
**Core Argument:** [One sentence thesis]
**Your Angle:** [Why you specifically can write this]
**Evidence Available:** [[Note 1]], [[Note 2]], [[Note 3]]
**Target Reader:** [Who benefits most]
**Format:** [Listicle / Deep dive / How-to / Opinion piece]

### 2. [Working Title]
[Same format...]

### 3. [Working Title]
[Same format...]

---

## Needs Development

Strong potential but requires more research or thinking.

### 4. [Working Title]
**Seed Idea:** [The kernel of the argument]
**Found In:** [[Note]]
**Missing:** [What you'd need to develop]
**Research Required:** [Specific questions to answer]

### 5. [Working Title]
[Same format...]

---

## Contrarian Takes

Opinions that go against consensus—higher risk, higher engagement.

### 6. [Working Title]
**The Mainstream View:** [What most people think]
**Your Position:** [Your contrarian argument]
**Why You're Right:** [Evidence from experience]
**Risk Level:** [How controversial this is]

---

## Series Opportunities

Topics deep enough for multi-part coverage.

### 7. [Series Title]
**Part 1:** [First post focus]
**Part 2:** [Second post focus]
**Part 3:** [Third post focus]
**Connecting Thread:** [What ties them together]

---

## Quick Hits

Smaller ideas for shorter posts or Twitter threads.

- [Idea 1]: [One line description]
- [Idea 2]: [One line description]
- [Idea 3]: [One line description]

---

## Recommended Next Steps

1. **Start this week:** [Highest-value, most ready idea]
2. **Develop this month:** [Strong idea needing work]
3. **Keep simmering:** [Idea worth tracking but not urgent]
```

## Step 6: Offer Follow-Up Options

After presenting the report, ask:

> "Which idea interests you most? I can:
> 1. Generate a detailed outline for any of these
> 2. Draft the full post using `/blog-draft [topic]`
> 3. Find more evidence in the vault for a specific idea
> 4. Develop the contrarian angle more fully"

## Quality Criteria

**Strong ideas have:**
- Clear thesis you can state in one sentence
- Evidence from your actual experience
- A reader who has this specific problem
- Something they can do after reading

**Weak ideas have:**
- Vague themes without a point
- Topics you're interested in but haven't practiced
- "Me too" content without differentiation
- No clear takeaway for the reader

## Notes

- Quality over quantity: 5 strong ideas beat 15 mediocre ones
- Your best content comes from problems you've actually solved
- Contrarian takes work when backed by real experience, not just hot takes
- Check recent weekly notes—freshest insights often live there
- Projects and Areas notes are richer than Resources for content
- When in doubt, start with "What did I learn that I wish I knew earlier?"
