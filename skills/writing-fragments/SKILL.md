---
name: writing-fragments
description: Writing, explore — mine raw fragments for a piece, with no structure yet. Use when the user wants to gather material for something they're going to write, or invokes /writing-fragments.
origin: Hackastak
disable-model-invocation: true
---

# Writing Fragments

This is pure **explore**: widen the space of what could be written without committing to structure. Committing is *exploit* — that's `writing-beats` or `writing-shape`, not this skill.

Run a **`grill-me`** session that produces fragments, interviewing the user relentlessly about whatever they want to write about. `grill-me` carries the interview discipline; here it's aimed at producing *material* rather than a resolved plan. Imposing phases, outlines, or article structure is out of scope.

As fragments emerge from either side of the conversation, append them to a single markdown file.

Capture fragments from the very first thing the user says, **including the initial prompt**.

On first write, put a single H1 at the top with a working title (it can change later) and nothing else — no metadata, no TOC, no date.

## Where it goes

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

The shared blog location used by every writing skill, so the craft track and the brand track share one shelf. Always reference it as `$VAULT_PATH/$BLOG_PATH`, never as a literal path. Write to `$VAULT_PATH/$BLOG_PATH/<Working_Title>_FRAGMENTS.md`. If the user names a different path, use theirs and remember it for the rest of the session.

## What is a fragment

A fragment is any piece of text that might survive into the final article. It must be *readable by the author* — the author can tell what it means — but it does not need to define its terms or be comprehensible to a cold reader. The bar is "is this a piece of good writing?", not "is this a self-contained argument?"

Fragments are deliberately heterogeneous:

- A sharp sentence you'd want to deploy somewhere but don't yet know where.
- A claim with a one-line justification.
- A vignette: a thing that happened, a code snippet, a scenario, an analogy.
- A half-thought: "something about how X feels like Y, work this out later."
- A quote, a piece of dialogue, an overheard line.
- A list of related observations that hang together by feel.
- A complaint, a confession, a punchline.
- A **leading word** — a compact metaphor or coinage the whole piece can hang on.

**The leading word is the most valuable fragment to land.** It is load-bearing: name the right one in explore and it shapes the structure, the transitions, and the title later, paying dividends through the entire exploit phase. *Tracer bullets* names a whole pattern; *fog of war* names another. When the conversation circles a recurring idea, push to coin a word for it.

The novelist's diary is the model: years of unstructured noticings that later get mined for raw material. Fragments are noticings.

## File format

```markdown
# Working title

A first fragment lives here.

It can be multiple paragraphs. It can include lists, code, quotes — whatever
shape the fragment naturally takes.

---

A second fragment.

---

> A quoted line that the user wants to keep around.

A reaction to it.

---

- A cluster of related observations
- That hang together by feel
- And want to be near each other
```

Fragments are separated by a horizontal rule (`\n---\n`). No headings inside the body. No tags. No order beyond the order they were added.

## Writing rhythm

**Append silently.** Don't ask permission for each fragment. Mention what you added in passing ("adding that"), but don't interrupt the conversation with save dialogs.

**Re-read the file from disk before every write.** The user may have edited, reordered, or deleted fragments between turns — preserve their changes. Never overwrite the file; only append, or edit a specific fragment in place when asked.

The user can say "cut the last one", "rewrite that one sharper", "merge those two" at any time. Treat those as first-class instructions.

## Related skills

- **`writing-beats` / `writing-shape`** — the two exploit modes this feeds. Fragments has no grounding concerns; those begin when structure does.
- **`grill-me`** — the interview engine, repurposed here to produce material rather than a plan.
- **`blog-ideas`** — different altitude: that decides *what to write about*; this mines material for a piece already chosen.
