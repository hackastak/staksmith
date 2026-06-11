---
name: polish
description: Polish a blog draft against The HackaStak style guidelines — voice/structure/SEO audit, apply fixes, and generate a pre-publish checklist with meta description. Use after drafting, before scheduling.
origin: Hackastak
---

# Polish Article for Publishing

Polish a blog draft against The HackaStak style guidelines and generate a pre-publish checklist.

## When to Activate

- a draft is written and you want it publication-ready
- running a voice/structure/SEO audit before scheduling
- enforcing the no-em-dash and banned-phrase rules
- generating a pre-publish checklist and meta description

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

Paths below are relative to the vault root. Input: the article filename or title to polish. If empty, show articles in "ready" or "scheduled" status and ask which to polish.

## Instructions

### Step 1: Load Context

Read the blog strategy and identify the article:

```bash
cat "2. Areas/Hackastak_Brand/Medium_Blog/Blog_Strategy.md"
```

If no article was specified, list articles ready for polish:
```bash
ls "2. Areas/Hackastak_Brand/Medium_Blog/"*.md
```

Look for articles with `status: ready` or `status: scheduled` in frontmatter.

### Step 2: Read the Full Article

Read the target article completely. Note:
- Current frontmatter (status, pillar, tags, etc.)
- Word count and structure
- Voice and formatting patterns

### Step 3: Run Style Audit

Check the article against The HackaStak guidelines:

**Voice Check:**
| Criterion | Target | Status |
|-----------|--------|--------|
| Contractions | Always use (it's, you'll, don't) | ✓ or ✗ |
| Paragraphs | 1-3 sentences each | ✓ or ✗ |
| Product names | **Bold** on first mention | ✓ or ✗ |
| Emoji count | 2-3 total (🛠️ 💡 ✨) | ✓ or ✗ |
| Tone | Conversational, not corporate | ✓ or ✗ |
| No em dashes | Zero `—` in the body (see rule below) | ✓ or ✗ |
| No banned phrases | See list below | ✓ or ✗ |

**Structure Check:**
| Criterion | Target | Status |
|-----------|--------|--------|
| Hook | First 2 sentences grab attention | ✓ or ✗ |
| H2 frequency | Every 200-300 words | ✓ or ✗ |
| Scaffold (listicles) | Description → Features → Why You Should Use It | ✓ or ✗ |
| CTA | Direct question at end | ✓ or ✗ |
| Read time | 7-12 minutes (sweet spot) | ✓ or ✗ |

**SEO Check:**
| Criterion | Target | Status |
|-----------|--------|--------|
| Keywords in first 100 words | Target keyword appears early | ✓ or ✗ |
| Year-stamped if evergreen | "2026" in title or early text | ✓ or ✗ |
| Title pattern | "Topic: The Subtitle That Sells It" | ✓ or ✗ |

**Banned Phrases (flag if found):**
- "In today's rapidly evolving landscape"
- "Let's dive in" / "without further ado"
- "Game-changer" / "revolutionary" / "cutting-edge"
- "In conclusion" / "To summarize"
- "Moreover" / "Furthermore" / "Additionally"
- "Utilize" / "leverage" (corporate tone)
- Excessive exclamation points

**Em-Dash Rule (always flag and fix):**

No em dashes (`—`) in the article body. They read as AI-generated and aren't part of the voice. Treat every em dash as a Must Fix. Replace each one based on what it's doing:

- **Joining two independent clauses (most common):** use a comma + coordinating conjunction (and, but, or, so, for, nor, yet) to make a proper compound sentence.
  - Before: `Sessions aren't cheap — substantial work runs $3–$5 a pop.`
  - After: `Sessions aren't cheap, and substantial work runs $3–$5 a pop.`
- **Setting off an aside or appositive:** use a comma (or a pair of commas / parentheses).
  - Before: `Cline — the open-source option — is free.`
  - After: `Cline, the open-source option, is free.`
- **Introducing a list or elaboration:** use a colon.
  - Before: `It earns its slot in one context — complex, big, real.`
  - After: `It earns its slot in one context: complex, big, real.`
- **Sometimes the cleanest fix is two sentences.** If a comma-and-conjunction rewrite feels forced, split it with a period instead.

Only the em dash (`—`) is banned. Leave these alone:
- **Hyphens (`-`) in compound words and modifiers** stay (no-fluff, open-source, early-to-mid, terminal-native, ex-Microsoft). Never strip or rewrite these.
- **En dashes (`–`) in numeric ranges** stay (`$3–$5`, `7–12`).

### Step 4: Present Findings

Output the audit results:

```markdown
# Polish Report: [Article Title]

## Style Audit

### Voice ✓/✗
[Table of voice checks with status]

### Structure ✓/✗
[Table of structure checks with status]

### SEO ✓/✗
[Table of SEO checks with status]

## Issues Found

### Must Fix
1. [Critical issue] — [specific location]
2. [Critical issue] — [specific location]

### Should Fix
1. [Improvement] — [specific location]
2. [Improvement] — [specific location]

### Optional
1. [Nice-to-have] — [specific location]
```

### Step 5: Apply Fixes

For each issue, offer to fix it:

> "I found [X] issues. Would you like me to:
> 1. Fix all automatically
> 2. Fix one at a time (with approval)
> 3. Show me the suggested changes first
> 4. Skip fixes, just generate the checklist"

Apply fixes using the Edit tool, preserving the article's voice and intent.

### Step 6: Generate Pre-Publish Checklist

After polishing, append a checklist to the article:

```markdown

---

## Pre-Publish Checklist

**Article:** [Title]
**Scheduled:** [Date]
**Pillar:** [Pillar]

### Before Publishing
- [ ] Final read-through (read aloud for flow)
- [ ] Header image created (1200x800 recommended)
- [ ] Alt text added to all images
- [ ] Links verified (if any external links)
- [ ] Title finalized: [Current Title]
- [ ] Meta description written (140 chars max):
  > [Suggest a meta description here]

### Publishing
- [ ] Copy to Medium (paste markdown, verify formatting)
- [ ] Set tags: [list the 5 tags from frontmatter]
- [ ] Add to publication (if targeting one): [Better Programming / Level Up Coding / etc.]
- [ ] Schedule or publish

### After Publishing
- [ ] Cross-post to Dev.to (set canonical URL → Medium)
- [ ] Cross-post to Hashnode (set canonical URL → Medium)
- [ ] Update frontmatter: `status: published`, `published: [date]`
- [ ] Update `cross_posted` in frontmatter
- [ ] Share on social (if applicable)

### Notes
[Any article-specific notes, e.g., "Double-check OpenCode is still actively maintained"]
```

### Step 7: Save and Confirm

After adding the checklist:

1. Save the updated article
2. Confirm what was changed
3. Offer next steps:

> "Article polished and checklist added. Next steps:
> 1. Open in Obsidian to review
> 2. Polish another article
> 3. Check pipeline status (`/content`)
> 4. Generate a header image prompt"

## Meta Description Generator

When generating the meta description, follow these rules:
- 140 characters max
- Front-load the primary keyword
- Make it compelling (not just a summary)
- Include a hook or benefit

**Template:**
"[Primary keyword]: [Benefit or hook]. [Specific detail that differentiates]."

**Example:**
"My 2026 dev stack: 10 terminal-native tools that survived real projects. No fluff, just what I actually use daily."

## Notes

- Always preserve the article's authentic voice — polish, don't rewrite
- If an article has major structural issues, flag them but don't attempt full rewrites
- The checklist stays in the file for tracking but should be removed before copying to Medium
- Update frontmatter `word_count` and `read_time` if content changed significantly
