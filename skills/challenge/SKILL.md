---
name: challenge
description: Pressure-test a belief or decision by finding contradictions, hidden assumptions, weak reasoning, and missing perspectives across vault notes. Use before big decisions.
origin: Hackastak
---

# Challenge My Thinking

Pressure-test beliefs by finding contradictions, weak points, and unexamined assumptions. Use this to stress-test ideas before making big decisions.

## When to Activate

- before a big decision you want stress-tested
- auditing a belief or position for internal consistency
- looking for blind spots and counterarguments in your own thinking
- checking whether your stated views actually cohere

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Paths below are relative to the vault root. Input: the topic or belief to challenge (required).

## Instructions

### Step 1: Understand What to Challenge

Parse the input to identify:
- Is this a specific belief/claim to test?
- Is this a topic area to audit for consistency?
- Is this a decision being considered?

### Step 2: Gather All Relevant Notes

Search comprehensively for notes on the topic:

```bash
# Find all notes mentioning the topic
grep -r -l -i "[topic terms]" --include="*.md" . 2>/dev/null
```

Search in:
- `2. Areas/` - Ongoing thinking and stated positions
- `3. Resources/` - External influences and curated knowledge
- `1. Projects/` - Applied decisions and their rationale
- `_Weekly/` - Evolving thoughts over time
- `0. Inbox/` - Recent, unprocessed thinking

Read each relevant note fully to understand the complete picture.

### Step 3: Map the Belief System

Document all stated positions on the topic:

```
Position 1: [statement]
Source: [[Note Name]]
Date/Context: [when written, what prompted it]

Position 2: [statement]
Source: [[Note Name]]
Date/Context: [when written, what prompted it]
```

Also capture:
- Stated reasons and justifications
- Examples given as evidence
- Authorities or sources cited
- Emotional language indicating strong conviction

### Step 4: Find Internal Contradictions

Look for positions that conflict with each other:

**Direct contradictions:**
- Note A says X, Note B says not-X
- Different conclusions from similar situations
- Stated principles violated by stated preferences

**Tension points:**
- Positions that could both be true but create friction
- Trade-offs acknowledged in one place but ignored in another
- Values that compete (e.g., "move fast" vs. "be thorough")

**Evolution without resolution:**
- Old view and new view coexist without explicit update
- Changed position without examining why the old one was wrong

### Step 5: Identify Hidden Assumptions

Look for unstated premises that the beliefs depend on:

**Common assumption types:**
- **Permanence**: Assuming current conditions will continue
- **Universality**: Assuming what works for you works for everyone
- **Causation**: Assuming correlation implies causation
- **Authority**: Accepting something because of who said it
- **Experience**: Over-weighting personal experience vs. data
- **Recency**: Over-weighting recent events
- **Survivorship**: Only seeing successful examples

For each assumption found:
- State it explicitly
- Consider: What if this isn't true?
- Find evidence for and against in the vault

### Step 6: Test the Reasoning

Examine the logic behind stated beliefs:

**Check for:**
- Circular reasoning (conclusion assumed in premise)
- False dichotomies (presenting only two options when more exist)
- Slippery slopes (assuming one thing inevitably leads to another)
- Ad hominem (rejecting ideas based on source, not merit)
- Appeal to nature/tradition (assuming old/natural = good)
- Confirmation bias (only citing supporting evidence)

### Step 7: Find Missing Perspectives

Identify viewpoints not represented in the notes:

- What would someone who disagrees say?
- What counterexamples exist that aren't addressed?
- What contexts might this belief fail in?
- Who might be harmed by this view?
- What's the steelman of the opposing position?

### Step 8: Check Against Reality

If applicable:
- Has this belief been tested in practice?
- What were the results?
- Are there notes showing this belief succeeding or failing?

### Step 9: Output the Challenge Report

Present findings in this format:

```
# Belief Stress Test: [Topic]

## Your Current Position
[Summary of stated beliefs on this topic, synthesized from notes]

**Key sources:**
- [[Note 1]] - [core claim]
- [[Note 2]] - [core claim]

---

## Contradictions Found

### Contradiction 1: [Brief title]
**Position A:** "[Quote or paraphrase]"
- Source: [[Note Name]]

**Position B:** "[Quote or paraphrase]"
- Source: [[Note Name]]

**The tension:** [Explain why these conflict]

**Questions to resolve:**
- [Question that would help reconcile or choose]

### Contradiction 2: [Brief title]
[Same format...]

---

## Hidden Assumptions

### Assumption 1: [State the assumption]
**Found in:** [[Note Name]]
**You're assuming:** [Explicit statement of unstated premise]
**But what if:** [Alternative possibility]
**Evidence for:** [Supporting points from vault or logic]
**Evidence against:** [Challenging points]

### Assumption 2: [State the assumption]
[Same format...]

---

## Weak Points in Reasoning

### Weak Point 1: [Brief title]
**The claim:** "[Quote]"
**The issue:** [Logical flaw or unsupported leap]
**Strengthening it would require:** [What evidence or reasoning is missing]

### Weak Point 2: [Brief title]
[Same format...]

---

## Missing Perspectives

### Not considered: [Viewpoint]
**The opposing view:** [Steelman of disagreement]
**Why it might be right:** [Best case for this view]
**Notes that partially address this:** [[Note]] (or "None found")

---

## Questions Worth Sitting With

1. [Provocative question that challenges core assumption]
2. [Question that exposes a tension]
3. [Question that invites reconsideration]

---

## Overall Assessment

**Belief coherence:** [High/Medium/Low] - [brief explanation]
**Assumption risk:** [High/Medium/Low] - [which assumptions are most precarious]
**Recommended action:** [Suggestions for strengthening or revising thinking]
```

### Step 10: Offer to Go Deeper

After presenting the report, ask:

> "Would you like me to:
> 1. Dig deeper into any specific contradiction?
> 2. Steelman the opposing view more fully?
> 3. Search for external evidence that challenges your position?
> 4. Help you articulate a more robust version of your belief?"

## Notes
- Be rigorous but respectful - the goal is to strengthen thinking, not attack it
- Distinguish between contradictions (problems) and tensions (trade-offs that may be intentional)
- Weight recent notes more heavily as representing current thinking
- If a contradiction seems resolved by evolution of thought, note that
- Some assumptions are reasonable to hold even if unprovable - flag but don't condemn
- The user may have good reasons for positions that seem contradictory - invite explanation
- This is collaborative stress-testing, not adversarial debate
