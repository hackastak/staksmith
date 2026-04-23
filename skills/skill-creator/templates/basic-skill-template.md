---
name: your-skill-name
description: Brief description of what this skill does and when Claude should use it. Maximum 1024 characters.
---

# Your Skill Name

[Brief overview of what this skill does and its main purpose]

## Instructions

### Step 1: [First Action]

[Clear, specific instructions for the first step]

### Step 2: [Second Action]

[Clear, specific instructions for the second step]

### Step 3: [Third Action]

[Clear, specific instructions for the third step]

## Best Practices

- [Important guideline or consideration]
- [Another important guideline]
- [Key principle to follow]

## Examples

### Example 1: Minimal Happy Path

<!-- Example 1 format depends on skill type:

MINIMAL HAPPY PATH (under 15 lines) works best for:
- Procedural skills (do X → Y → Z)
- Transformation skills (input → output)
- Script-based skills (run command, get result)

REGULAR EXAMPLES work better for:
- Reference/lookup skills (show representative queries)
- Decision-based skills (show different branches)
- Reactive/contextual skills (show triggering conditions)

For procedural/transformation skills, keep this under 15 lines. -->

**Input/Request:**
```
[Simplest user request that triggers this skill]
```

**Output:**
```
[Expected output — the happy path result]
```

**Note:** This is the minimal case — everything works, no edge cases.

### Example 2: [Tricky Case or Edge Case]

<!-- Show a case that requires judgment — ambiguous input, edge case, or common mistake. This teaches when to deviate from the happy path. -->

**Input/Request:**
```
[Request that represents an edge case or tricky scenario]
```

**What makes this tricky:**
- [Why this case is different from the happy path]

**Output:**
```
[Expected result — how to handle this case correctly]
```

## When NOT to Use

<!-- Explicitly call out adjacent cases this skill is NOT for. This prevents the most common misfires. -->

- [Adjacent case this skill is NOT for] — use [alternative] instead.
- [Another near-miss case]

## Notes

- [Any additional context or edge cases]
- [Common pitfalls to avoid]
