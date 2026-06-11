---
name: content
description: Manage The HackaStak content calendar and publishing pipeline — buffer health, pillar balance, scheduling, and publish tracking. Use to see status or move articles through the pipeline.
origin: Hackastak
---

# Content Pipeline Manager

Manage The HackaStak content calendar and publishing pipeline.

## When to Activate

- checking blog pipeline status and buffer health
- deciding what to write or publish next
- scheduling an article to a publish date
- marking an article published and tracking cross-posts

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

Paths below are relative to the vault root. Input: "status", "schedule [article] [date]", "publish [article]", "next", or an article name to update.

## Instructions

### Step 1: Load Current Pipeline State

Scan all blog content to understand current state:

```bash
ls -la "2. Areas/Hackastak_Brand/Medium_Blog/"*.md 2>/dev/null
```

Read frontmatter from each file to extract status, pillar, scheduled dates, etc.

Key files to always check:
- `Blog_Strategy.md` — strategy context
- `Content_Calendar.md` — calendar view (Dataview-powered)

### Step 2: Route Based on Arguments

**If input is empty or "status":**
Generate a full pipeline report (see Step 3).

**If input is "next":**
Recommend what to work on next based on:
1. Buffer health (is it thin?)
2. Pillar balance (which pillar is underrepresented?)
3. What's closest to ready

**If input is "schedule [article] [date]":**
Update the article's frontmatter:
- Set `status: scheduled`
- Set `scheduled: [date]`
Confirm the change.

**If input is "publish [article]":**
Update the article's frontmatter:
- Set `status: published`
- Set `published: [today's date]`
- Remind about cross-posting to Dev.to and Hashnode
Confirm the change.

**If input matches an article name:**
Show that article's current status and offer to update it.

### Step 3: Generate Pipeline Report

Present the pipeline status in this format:

```markdown
# Content Pipeline Status
*Generated: [date]*

---

## Buffer Health

**Ready/Scheduled:** [X] articles
**Target:** 3-4 articles
**Status:** [Healthy ✅ | Low ⚠️ | Critical 🚨]

---

## Pipeline

### Scheduled ([X])
| Article | Publish Date | Pillar |
|---------|--------------|--------|
| [title] | [date]       | [pillar] |

### Ready to Schedule ([X])
| Article | Pillar | Read Time |
|---------|--------|-----------|
| [title] | [pillar] | [X] min |

### In Progress ([X])
| Article | Status | Pillar |
|---------|--------|--------|
| [title] | [drafting/outline] | [pillar] |

### Ideas ([X])
| Article | Pillar | Seed Idea |
|---------|--------|-----------|
| [title] | [pillar] | [idea] |

---

## Pillar Balance

| Pillar | Ready/Scheduled | Published |
|--------|-----------------|-----------|
| Tooling | [X] | [X] |
| Best Practices | [X] | [X] |
| Career | [X] | [X] |
| AI x Dev | [X] | [X] |

**Gap:** [Identify underrepresented pillar]

---

## Recommendations

1. **Publish next:** [Article] — [reason]
2. **Work on next:** [Article or pillar] — [reason]
3. **Idea to develop:** [Topic] — [reason]
```

### Step 4: Handle Status Updates

When updating an article's status:

1. Read the current file
2. Update the YAML frontmatter
3. Write the file back
4. Confirm the change

**Status progression:**
```
idea → outline → drafting → ready → scheduled → published
```

**When scheduling:**
- Suggest dates based on desired posting frequency (e.g., weekly)
- Check for conflicts with already-scheduled articles

**When publishing:**
- Set `published` to today's date
- Remind about cross-posting checklist:
  - [ ] Published to Medium
  - [ ] Cross-posted to Dev.to (canonical URL to Medium)
  - [ ] Cross-posted to Hashnode (canonical URL to Medium)
  - [ ] Update `cross_posted` frontmatter

### Step 5: Offer Follow-Up Actions

After any operation, offer relevant next steps:

> "What would you like to do next?
> 1. Schedule an article
> 2. Mark an article as published
> 3. Generate new blog ideas (`/blog-ideas`)
> 4. Draft an article (`/blog-draft [topic]`)
> 5. View the full calendar in Obsidian"

## Status Definitions

| Status | Description |
|--------|-------------|
| `idea` | Topic identified, no content yet |
| `outline` | Structure planned, not written |
| `drafting` | Actively being written |
| `ready` | Draft complete, needs polish/scheduling |
| `scheduled` | Publish date set |
| `published` | Live on Medium |

## Notes

- Always preserve existing frontmatter fields when updating
- Use ISO date format: YYYY-MM-DD
- The Content_Calendar.md file uses Dataview — it auto-updates based on frontmatter
- Strategy reminder: Consistency > topic selection. Ship regularly.
- Target buffer: 3-4 articles in ready/scheduled state
