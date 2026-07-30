---
name: writing-shape
description: Writing, exploit — shape raw material into an argued article, paragraph by paragraph, with deliberate format choices. Use for technical or brand long-form where the piece argues a thesis.
origin: Hackastak
disable-model-invocation: true
---

# Writing Shape

The user has passed (or will pass) a markdown file of raw material. Treat it as the input pile — anything from a tidy list of fragments to a wall of unstructured prose to a transcript. The format doesn't matter. **Read it end-to-end before doing anything else.**

This is **exploit**: the exploring is done, the pile is fixed — commit to a structure and mine the pile to fill it. **Do not edit the raw material file — it is read-only to this skill.**

This is the **argued** exploit mode, best matched to technical and brand long-form. For a piece that's walked rather than argued, use `writing-beats`.

## Where it goes

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

The shared blog location used by every writing skill. Always reference it as `$VAULT_PATH/$BLOG_PATH`, never as a literal path. Write the article to `$VAULT_PATH/$BLOG_PATH/<Title>.md`. If the user names a different path, use theirs and remember it.

## The loop

1. **Read the pile.** In full. Form a sense of what's in it.
2. **Establish the prerequisites.** Settle with the user what the reader knows walking in — the concepts **grounded** from the start. See [Grounding](#grounding).
3. **Draft 2–3 candidate openings.** Each should imply a *different thesis or angle*. Show all of them. Force the user to pick or compose a hybrid. The chosen opening defines what the rest of the article must do.
4. **Grow block by block.** After the opening lands, ask "given this opening, what does the reader need to hear next?" Pull material from the pile to answer. The next block may only lean on grounded concepts, and grounds new ones as it lands. Argue about the *form* the block takes — see [Format arguments](#format-arguments-to-actually-have).
5. **Append to the article file as you go.** Don't batch. Write each agreed block immediately so the user watches the article take shape.
6. **Loop step 4** until the article is done. The user decides when that is.

## Grounding

The grounding system lives in the **`writing-grounding`** skill — the shared reference this skill and `writing-beats` both point at, so the rule reads the same whichever one you came from. Read it before establishing prerequisites. Its own word for a unit of the draft is a **move**; here that unit is a **block**.

The short version, in this mode's terms: every concept must be grounded before a block can lean on it, either as a **prerequisite** the reader brings or **introduced** by an earlier block. Keep a running list of what's grounded.

Here the graph decides **order**. When you ask "what does the reader need to hear next?" and the honest answer names a concept nothing has grounded, that concept **is** the answer — ground it first, here or earlier, or you can't make the move. This is gap-naming one level up from [Pulling from the pile](#pulling-from-the-pile): there the pile is missing material, here the article is missing a foundation.

## Conversational feel

This is a grilling session **inverted**. In ideation the question was "what are you actually noticing?" Here it's "what is this article actually arguing, and in what order does the reader need to hear it?" Push back. Refuse to let weak transitions slide. If a paragraph doesn't earn its place, cut it.

Moves to keep using:

- "What does this paragraph do for the reader that the previous one didn't?"
- "If I cut this, what breaks?"
- "Is this prose, or should it be a list? Why prose?"
- "This sentence is doing two jobs — split it or pick one."
- "The opening promised X. We've drifted to Y. Either re-thread it or change the opening."

## Pulling from the pile

Treat the raw material as a **quarry, not a script**. Pull a fragment, rework it to fit the surrounding paragraph, place it. A fragment may be split across paragraphs, merged with another, or paraphrased. The pile's job is to be mined; the article's job is to read as one voice.

If the pile lacks something the article needs, **name the gap explicitly**: "We need an example here and the pile doesn't have one — give me one now or we cut this section."

## Format arguments to actually have

When choosing how to render a block, weigh these out loud with the user, not silently:

- **Prose vs. list.** Prose carries argument; lists carry parallel items. If items aren't truly parallel, prose is better. If they are, a list is faster to scan.
- **Inline vs. callout.** Tips, warnings, and asides go in callouts (`> [!TIP]`, `> [!NOTE]`) — but only if they'd genuinely derail the main argument inline. Otherwise leave them inline.
- **Table vs. repeated structure.** If the same shape repeats 3+ times with the same fields, a table. Otherwise prose with bold leads.
- **Quote vs. paraphrase.** Quote when the original wording is the point. Paraphrase when only the idea matters.
- **Code block vs. inline code.** Multi-line, runnable, or illustrative → block. Single token or identifier → inline.

## Writing rhythm

Append to the article file as each block is agreed. **Re-read the file from disk before every write** — the user may have edited between turns. Never overwrite blindly. If the user wants a paragraph rewritten, edit that specific paragraph in place; leave the rest alone.

## Out of scope

- Mining for new fragments that aren't in the pile (handle gaps as in [Pulling from the pile](#pulling-from-the-pile)).
- Editing the raw material file.
- Publishing, formatting for a specific platform, or adding frontmatter the user didn't ask for.

## Related skills

- **`writing-grounding`** — the shared grounding reference. Not optional reading.
- **`writing-fragments`** — produces the pile this skill mines.
- **`writing-beats`** — the narrative exploit mode.
- **`article-writing`** — structure vs voice, not competitors. Compose: shape the argument here, then a voice pass there.
- **`polish`** — the publish pass.
