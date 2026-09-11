---
name: receiving-code-review
description: "Use when receiving code review feedback, before implementing suggestions — especially if feedback seems unclear or technically questionable. Requires technical rigor and verification, not performative agreement or blind implementation. The inbound counterpart to code-review / review-changes / review-github-pr."
category: "Code Review & Quality"
origin: community
---

# Receiving Code Review

Code review requires technical evaluation, not emotional performance. The rest of the review family (`code-review`, `review-changes`, `review-github-pr`) governs review you *give*; this governs review you *receive*.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ:      Complete feedback without reacting
2. UNDERSTAND: Restate the requirement in your own words (or ask)
3. VERIFY:    Check against codebase reality
4. EVALUATE:  Technically sound for THIS codebase?
5. RESPOND:   Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

**NEVER:**
- "You're absolutely right!"
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if it's wrong
- Just start working (actions > words)

## Handling Unclear Feedback

If any item is unclear, STOP — do not implement anything yet — and ask for clarification on the unclear items. Items may be related; partial understanding produces the wrong implementation.

**Example:** Feedback is "Fix 1-6." You understand 1, 2, 3, 6 but are unclear on 4, 5.
- ❌ Implement 1, 2, 3, 6 now, ask about 4, 5 later.
- ✅ "I understand items 1, 2, 3, 6. Need clarification on 4 and 5 before proceeding."

## Source-Specific Handling

**From the user:**
- Trusted — implement after understanding.
- Still ask if scope is unclear.
- No performative agreement; skip to action or a technical acknowledgment.

**From external reviewers — be skeptical, but check carefully.** Before implementing:
1. Technically correct for THIS codebase?
2. Does it break existing functionality?
3. Is there a reason for the current implementation?
4. Does it work on all supported platforms/versions?
5. Does the reviewer have the full context?

- If a suggestion seems wrong: push back with technical reasoning.
- If you can't easily verify: say so — "I can't verify this without [X]. Should I investigate / ask / proceed?"
- If it conflicts with the user's prior decisions: stop and discuss with the user first.

## YAGNI Check for "Professional" Features

If a reviewer suggests "implementing this properly," grep the codebase for actual usage first.
- If unused: "This endpoint isn't called anywhere. Remove it (YAGNI)?"
- If used: implement it properly.

## Implementation Order

For multi-item feedback:
1. Clarify anything unclear FIRST.
2. Then implement in order: blocking issues (breaks, security) → simple fixes (typos, imports) → complex fixes (refactoring, logic).
3. Test each fix individually.
4. Verify no regressions.

## When To Push Back

Push back when the suggestion:
- Breaks existing functionality
- Comes from a reviewer lacking full context
- Violates YAGNI (unused feature)
- Is technically incorrect for this stack
- Ignores legacy/compatibility reasons
- Conflicts with the user's architectural decisions

**How:** technical reasoning, not defensiveness. Ask specific questions. Reference working tests/code. Involve the user if the point is architectural. If you're uncomfortable pushing back out loud, name that tension and tell the user about the issue you've seen — honesty is the point.

## Acknowledging Correct Feedback

```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch — [specific issue]. Fixed in [location]."
✅ [Just fix it and show it in the code]

❌ "You're absolutely right!"   ❌ "Great point!"
❌ "Thanks for catching that!"  ❌ ANY gratitude expression
```

**Why no thanks:** actions speak. Just fix it — the code shows you heard the feedback. If you catch yourself about to write "Thanks," delete it and state the fix instead.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong, state the correction factually and move on:
```
✅ "You were right — I checked [X] and it does [Y]. Implementing now."
✅ "Verified this; you're correct. My initial understanding was wrong because [reason]. Fixing."

❌ Long apology   ❌ Defending why you pushed back   ❌ Over-explaining
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State the requirement or just act |
| Blind implementation | Verify against the codebase first |
| Batch without testing | One at a time, test each |
| Assuming the reviewer is right | Check whether it breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |
| Can't verify, proceed anyway | State the limitation, ask for direction |

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.
