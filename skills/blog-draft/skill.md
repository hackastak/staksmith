---
name: blog-draft
description: Draft a complete blog post based on a topic or idea, mining your vault for supporting evidence and writing in your established voice. Use when you have a topic ready and want a full first draft.
origin: custom
---

# Blog Post Drafter

Turn a topic into a complete draft by pulling from your vault and writing in your voice.

## When to Activate

- you have a topic or idea ready to develop
- you want to turn vault notes into a polished article
- you need a first draft to edit rather than starting from blank page
- you're expanding on an idea from `/blog-ideas`

## Input

The user provides:
- **Topic or title**: What the post is about
- **Optional**: Target audience, desired length, specific angle, or notes to reference

If no topic is provided, ask: "What topic should I draft a post about?"

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

## Step 1: Gather Source Material

Search the vault for relevant content:

**Direct topic matches:**
```bash
grep -r -l "[topic keywords]" "$VAULT_PATH" --include="*.md" 2>/dev/null | head -20
```

**Related notes in key areas:**
```bash
find "$VAULT_PATH/1. Projects" "$VAULT_PATH/2. Areas" "$VAULT_PATH/3. Resources" -name "*.md" -type f 2>/dev/null | xargs grep -l "[topic]" 2>/dev/null | head -15
```

**Recent thinking on the topic:**
```bash
find "$VAULT_PATH/_Weekly" -name "*.md" -type f | xargs grep -l "[topic]" 2>/dev/null | head -5
```

Read relevant notes and extract:
- Key arguments and opinions
- Specific examples and experiences
- Data points or evidence
- Quotes or references to cite
- Related concepts to weave in

## Step 2: Analyze Voice and Style

Read published posts to match the voice:

```bash
ls "$VAULT_PATH/$BLOG_PATH/PUBLISHED/"
```

Extract patterns from existing work:
- **Sentence structure**: Direct, medium-length, varied rhythm
- **Tone**: Practical, confident but not preachy, occasionally dry
- **Openings**: Lead with tension, stakes, or a concrete observation
- **Evidence style**: Real examples over hypotheticals
- **Formatting**: Headers, numbered lists, clear sections
- **Endings**: Actionable takeaway, no fluffy summary

## Step 3: Develop the Thesis

Before writing, crystallize:

1. **One-sentence thesis**: What's the main argument?
2. **Reader problem**: What pain does this address?
3. **Promise**: What will the reader gain?
4. **Unique angle**: Why can you write this specifically?

If the thesis isn't clear from the topic, propose 2-3 angles and ask which direction to take.

## Step 4: Create the Structure

Build a skeletal outline:

```
## Hook (1-2 paragraphs)
- Open with tension, problem, or surprising observation
- Establish stakes: why this matters now
- Thesis statement (can be implicit)

## Context/Why This Matters (1-2 paragraphs)
- Background needed to understand the rest
- Connect to reader's experience

## Main Content (bulk of the post)
- For listicles: each item is a section
- For arguments: build through evidence
- For how-tos: sequential steps
- Each section: lead with example, explain after

## Synthesis/Implications (1-2 paragraphs)
- What this means for the reader
- Connect back to the opening tension

## Call to Action (1 paragraph)
- One concrete thing to do next
- Optional: invitation to engage
```

## Step 5: Write the Draft

Follow these rules while drafting:

### Voice Rules
- Write in first person when sharing experience
- Be direct—avoid hedging and qualifiers
- Use "you" to address the reader directly
- Vary sentence length but favor shorter
- One idea per paragraph

### Structure Rules
- Lead each section with the concrete thing: example, number, anecdote
- Explain after showing, not before
- Headers should be informative, not clever
- Use numbered lists for sequences, bullets for unordered items

### Evidence Rules
- Reference specific vault notes as sources (but don't include wikilinks in final draft)
- Prefer real examples over hypothetical scenarios
- Include specific numbers when available
- Cite any external sources properly

### Banned Patterns
Delete and rewrite any of these:
- "In today's rapidly evolving landscape"
- "Let's dive in" or "without further ado"
- "Game-changer," "revolutionary," "cutting-edge"
- "In conclusion" or "To summarize"
- Rhetorical questions as section openers
- Filler transitions: "Moreover," "Furthermore," "Additionally"

## Step 6: Add Supporting Elements

Include where appropriate:

**FAQ Section** (if post warrants it):
- 2-4 common questions
- Direct, practical answers
- Address objections

**Callouts or Pull Quotes**:
- Highlight key insights
- Break up long sections

**Code Blocks** (for technical posts):
- Working, runnable examples
- Minimal but complete

## Step 7: Quality Check

Before delivering, verify:

- [ ] Hook grabs attention in first two sentences
- [ ] Thesis is clear by end of intro
- [ ] Every section adds new information
- [ ] Examples are specific and real (or clearly hypothetical)
- [ ] No banned phrases or generic language
- [ ] Ending has clear takeaway
- [ ] Length matches topic depth (typically 1000-2500 words)
- [ ] Headers enable skimming

## Step 8: Deliver the Draft

Output format:

```markdown
# [Title]

[Full draft content here...]

---

## Draft Notes

**Word count:** [X] words
**Estimated read time:** [X] minutes
**Vault sources used:**
- [[Note 1]] - [how it was used]
- [[Note 2]] - [how it was used]

**Suggested next steps:**
1. [Specific edit recommendation]
2. [Section that might need expansion]
3. [Fact to verify before publishing]

**Alternative titles:**
- [Option 1]
- [Option 2]
```

## Step 9: Offer Iteration

After delivering, ask:

> "Here's your draft. Would you like me to:
> 1. Strengthen a specific section?
> 2. Add more examples from your vault?
> 3. Adjust the tone or length?
> 4. Generate social posts to promote it?"

## Output Formats

Adjust based on request:

- **Full draft** (default): Complete post ready for editing
- **Outline only**: Detailed structure without full prose
- **Section expansion**: Develop one specific section deeply
- **Multiple angles**: 2-3 different openings to choose from

## Notes

- First drafts are meant to be edited—aim for 80% quality, not perfect
- Better to include too much evidence than too little (easier to cut)
- If vault sources are thin, acknowledge gaps and suggest research
- Match length to topic: not everything needs to be 2000+ words
- When in doubt, start with the most concrete example you have
