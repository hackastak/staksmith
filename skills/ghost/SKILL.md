---
name: ghost
description: Answer a question in the user's own voice, drawn from their writing style and stated beliefs in the vault. Use to externalize thinking or draft authentic responses.
origin: Hackastak
---

# Ghost Writer

Answer a question the way the user would, based on their writing style and stated beliefs in the vault. Use this to externalize thinking or draft responses that sound authentic.

## When to Activate

- you want an answer drafted in your own voice
- externalizing your likely take on a question before writing
- drafting a response grounded in your stated beliefs
- continuing a piece in a voice consistent with your other writing

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Paths below are relative to the vault root. Input: the question to answer (required).

## Instructions

### Step 1: Understand the Question

Parse the question from the input. Identify:
- The domain/topic (software engineering, productivity, life, career, etc.)
- The type of question (opinion, advice, explanation, decision)
- Key concepts that need to be addressed

### Step 2: Find Relevant Notes

Search the vault for notes related to the question's topic:

```bash
# Search for topic-related content
grep -r -l "[key terms]" --include="*.md" . 2>/dev/null
```

Prioritize searching in:
1. `2. Areas/` - Personal opinions, ongoing work, reflections
2. `3. Resources/` - Curated knowledge, article notes with commentary
3. `1. Projects/` - Applied experience, decisions made
4. `0. Inbox/` - Recent thoughts, fresh perspectives
5. `_Weekly/` - Reflections, lessons learned

Look for:
- Direct statements of opinion ("I think...", "I believe...", "My take is...")
- Decisions made and reasoning behind them
- Highlighted passages with personal commentary
- Recurring themes or principles
- Strong reactions (positive or negative) to ideas

### Step 3: Analyze Writing Style

Read several notes to understand the user's voice:

**Tone indicators:**
- Formal vs. casual language
- Use of humor or directness
- Technical depth preference
- Sentence structure patterns
- Common phrases or expressions

**Argument style:**
- Does the user lead with examples or principles?
- Do they acknowledge nuance or take firm stances?
- Do they reference personal experience?
- Do they cite sources or speak from intuition?

**Values and principles:**
- What does the user optimize for? (simplicity, performance, maintainability, etc.)
- What do they consistently criticize?
- What do they consistently praise?
- What trade-offs do they prefer?

### Step 4: Extract Relevant Beliefs

From the notes found, extract:
- Direct opinions on the topic
- Related principles that would apply
- Past experiences that inform the view
- Influences (books, articles, people) that shaped thinking

Document each belief with its source:
```
Belief: [statement]
Source: [[Note Name]]
Context: [relevant excerpt]
```

### Step 5: Synthesize the Answer

Construct an answer that:
1. **Opens like the user would** - Match their typical opening style
2. **Uses their reasoning patterns** - If they typically give context first, do that
3. **Incorporates their vocabulary** - Use phrases they actually use
4. **References their experiences** - Draw on specific examples from their notes
5. **Arrives at their likely conclusion** - Based on their stated values and principles

### Step 6: Add Source References

Weave in references to specific notes naturally:
- "As I noted in [[Note Name]]..."
- "This connects to my thinking on [[Topic]]..."
- "I've written about this before in [[Note Name]]..."

Or add a references section at the end.

### Step 7: Output the Response

Present the ghostwritten answer in this format:

```
# How I Would Answer: "[Question]"

---

[The answer, written in the user's voice, 2-5 paragraphs depending on complexity]

---

## Sources Used
- [[Note 1]] - [what belief/style was drawn from this]
- [[Note 2]] - [what belief/style was drawn from this]
- [[Note 3]] - [what belief/style was drawn from this]

## Voice Notes
- **Tone**: [how the tone was calibrated]
- **Key principles applied**: [values that shaped the answer]
- **Confidence level**: [high/medium/low - based on how much relevant content was found]
```

### Step 8: Offer Refinement

After presenting the answer, ask:

> "Does this sound like you? I can adjust the tone, add more nuance, or take a stronger/softer stance if needed."

## Special Handling

**If topic has no direct coverage:**
- Look for adjacent topics and extrapolate
- Identify the user's general principles that would apply
- Be transparent: "I didn't find notes directly on this, but based on your views on [related topic]..."

**If the user has conflicting views:**
- Acknowledge the tension
- Present the most recent view as primary
- Note the evolution: "Your thinking on this seems to have evolved..."

**If the question is personal/sensitive:**
- Draw only from what's explicitly written
- Don't extrapolate into areas without evidence
- Focus on stated beliefs, not inferred ones

**For Medium blog drafts** (check `2. Areas/Hackastak_Brand/Medium_Blog/`):
- Match the style of existing published or drafted articles
- Use similar structure and formatting
- Maintain consistent voice with other blog content

## Notes
- The goal is authenticity, not perfection
- When uncertain, err toward the user's more considered, written views over casual mentions
- Weekly notes may contain raw thoughts; Areas/Resources contain more refined views
- Recent notes may reflect evolved thinking - weight them appropriately
- If the vault lacks coverage on a topic, say so rather than inventing a position
- Never use em dashes in the drafted response (use a comma + conjunction, a colon, or split into two sentences)
