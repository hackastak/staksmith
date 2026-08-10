---
name: ideas
description: Scan the vault for emerging patterns and generate an ideas report — tools to build, people to reach out to, topics to investigate, and things to write. Use when seeking grounded inspiration.
category: "Second Brain & Vault"
origin: Hackastak
---

# Generate Ideas Report

Scan the vault for emerging patterns and generate fresh ideas grounded in actual interests and activity. Use this when seeking inspiration that's rooted in your existing knowledge and curiosities.

## When to Activate

- seeking inspiration grounded in your actual interests
- looking for tools to build, people to contact, or topics to explore
- turning recent activity into a prioritized action list
- periodic review of emerging themes in your work

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

Paths below are relative to the vault root. `$BLOG_PATH` is the shared blog location used by every writing skill — always reference it as `$VAULT_PATH/$BLOG_PATH`, never as a literal path.

## Instructions

### Step 1: Scan for Patterns Across the Vault

Analyze multiple sources to understand current interests and emerging themes:

**Recent Activity (last 30 days):**
```bash
find . -name "*.md" -mtime -30 -type f ! -path "./.obsidian/*" ! -path "./.claude/*"
```

**Weekly Notes:**
```bash
ls -t "_Weekly"/**/*.md 2>/dev/null | head -8
```

**Active Projects:**
```bash
ls -d "1. Projects"/*/ 2>/dev/null
```

**Areas of Focus:**
```bash
ls -d "2. Areas"/*/ 2>/dev/null
```

**Resources Being Collected:**
```bash
ls -d "3. Resources"/*/ 2>/dev/null
```

**Recent Inbox Items:**
```bash
find "0. Inbox" -name "*.md" -type f
```

Read a representative sample of notes from each category.

### Step 2: Identify Emerging Themes

Look for:
- **Recurring topics**: Subjects mentioned across multiple notes
- **Questions asked**: Unanswered questions or curiosities expressed
- **Frustrations noted**: Pain points or problems mentioned
- **Interests declared**: Topics marked as interesting or worth exploring
- **Skills being developed**: Technologies, frameworks, concepts being learned
- **Gaps identified**: Missing knowledge or capabilities noted

### Step 3: Find People Mentioned

Search for names and contacts:
```bash
grep -r -h "reach out\|connect with\|talk to\|meet with\|@\|contact" --include="*.md" . 2>/dev/null
```

Also check:
- `2. Areas/` for any contacts or relationship notes
- Notes mentioning authors, speakers, or experts
- People referenced positively in article notes

Identify:
- People mentioned but not yet contacted
- Experts in areas you're actively exploring
- Potential collaborators based on overlapping interests

### Step 4: Identify Tool Opportunities

Look for signals that suggest tools to build:
- Manual processes described repeatedly
- Complaints about existing tools
- "I wish there was..." statements
- Workflows that could be automated
- Problems you've solved manually multiple times
- Gaps between tools you use

Cross-reference with:
- Your technical skills (from project notes)
- Technologies you're learning
- Side project ideas already captured

### Step 5: Find Investigation-Worthy Topics

Identify subjects worth deeper exploration:
- Topics mentioned but not fully explored
- Questions without answers in the vault
- Concepts referenced but not understood
- Areas where notes are shallow but interest is high
- Connections between domains not yet mapped
- Contrarian views encountered but not evaluated

### Step 6: Surface Writing Opportunities

Find potential content to create:
- Topics you have strong opinions on (from `/ghost` patterns)
- Areas where you have unique experience
- Explanations you've written informally that could be polished
- Connections between ideas others might not see
- Lessons learned from projects
- Frameworks or mental models you've developed

Check existing blog drafts and backlog:
```bash
find "$VAULT_PATH/$BLOG_PATH" -name "*.md" -type f 2>/dev/null
```

### Step 7: Generate the Ideas Report

Present findings in this format:

```
# Ideas Report
*Generated: [current date]*
*Based on: [X] notes analyzed, [Y] recent activity patterns*

---

## Tools to Build

### High Potential
Ideas with clear need and alignment with your skills

#### 1. [Tool Name]
**The Problem:** [Pain point identified from notes]
**Evidence:** Found in [[Note 1]], [[Note 2]]
**Your Advantage:** [Why you're positioned to build this]
**First Step:** [Concrete starting action]

#### 2. [Tool Name]
[Same format...]

### Worth Exploring
Ideas that need more validation

#### 3. [Tool Name]
**The Problem:** [Pain point]
**Evidence:** [Where this surfaced]
**Unknown:** [What you'd need to figure out]

---

## People to Reach Out To

### High Priority
People aligned with current focus areas

#### 1. [Name/Role]
**Why:** [Connection to your interests]
**Context:** Mentioned in [[Note]]
**Angle:** [How to approach/what to discuss]

#### 2. [Name/Role]
[Same format...]

### Worth Connecting With
People in adjacent areas

#### 3. [Name/Role]
**Why:** [Potential value]
**Found in:** [[Note]]

---

## Topics to Investigate

### Deep Dives Needed
Topics where you have surface knowledge but want depth

#### 1. [Topic]
**Current Understanding:** [What you know]
**Gap:** [What's missing]
**Why It Matters:** [Connection to projects/goals]
**Starting Point:** [Resource or action to begin]

#### 2. [Topic]
[Same format...]

### Curiosities to Explore
Interesting threads worth pulling

#### 3. [Topic]
**Sparked By:** [[Note]]
**Question:** [The driving question]

---

## Things to Write

### Ready to Write
Topics where you have enough material and opinions

#### 1. [Title/Topic]
**Core Argument:** [Your main point]
**Supporting Notes:** [[Note 1]], [[Note 2]], [[Note 3]]
**Unique Angle:** [What makes your perspective different]
**Format:** [Blog post / Twitter thread / Documentation / etc.]

#### 2. [Title/Topic]
[Same format...]

### Needs More Thinking
Topics that could become writing with more development

#### 3. [Title/Topic]
**Seed Idea:** [The kernel]
**Found In:** [[Note]]
**Missing:** [What you'd need to develop]

---

## Pattern Insights

### What You're Gravitating Toward
[Themes that appear repeatedly across recent notes]

### Potential Blind Spots
[Areas notably absent despite related activity]

### Unexpected Connections
[Surprising relationships between topics in your vault]

---

## Recommended Next Actions

1. **This Week:** [Most actionable high-impact item]
2. **This Month:** [Larger initiative worth starting]
3. **Explore When Ready:** [Interesting but not urgent]
```

### Step 8: Offer Follow-Up

After presenting the report, ask:

> "Would you like me to:
> 1. Dive deeper into any specific idea?
> 2. Draft an outline for one of the writing topics?
> 3. Research one of the investigation topics?
> 4. Create a project note for one of the tool ideas?"

## Idea Quality Criteria

Prioritize ideas that are:
- **Grounded**: Based on actual notes, not invented
- **Actionable**: Have a clear first step
- **Aligned**: Connect to existing projects or stated goals
- **Energizing**: Topics that show repeated interest/enthusiasm
- **Unique**: Leverage your specific combination of interests/skills

Deprioritize ideas that are:
- Generic (could apply to anyone)
- Disconnected from current focus
- Already well-covered in existing notes
- Mentioned once without follow-up interest

## Notes
- Focus on quality over quantity - 3-5 strong ideas per category is better than 10 weak ones
- Ideas should feel like "of course!" not "huh?"
- Cross-pollinate: best ideas often come from combining different areas
- Check `1. Projects/` for ideas that were started but abandoned - might be ready to revisit
- Recent weekly notes often contain the freshest sparks
- Frustrations are gold - they point to real problems worth solving
- When in doubt, favor ideas connected to active projects over new directions
