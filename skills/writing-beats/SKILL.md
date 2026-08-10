---
name: writing-beats
description: Writing, exploit — assemble raw material into a journey of beats, grounding each concept before a beat leans on it. Use for narrative, personal-essay, or discovery-style pieces whose structure isn't known up front.
category: "Writing & Content"
origin: Hackastak
disable-model-invocation: true
---

# Writing Beats

The user has passed (or will pass) a markdown file of raw material. This is **exploit**: the exploring is done, the pile is fixed — commit to a path through it and mine the pile to fill each beat.

This is the **narrative** exploit mode. Best for pieces where the structure isn't known up front and the shape emerges as you walk it — personal essays, discovery writing, anything told rather than argued. For a piece with a thesis to argue paragraph by paragraph, use `writing-shape` instead.

## Where it goes

```
VAULT_PATH=~/Developer/My_Notes
BLOG_PATH=2. Areas/Hackastak_Brand/Medium_Blog
```

The shared blog location used by every writing skill. Always reference it as `$VAULT_PATH/$BLOG_PATH`, never as a literal path. Write the article to `$VAULT_PATH/$BLOG_PATH/<Title>.md`. If the user names a different path, use theirs and remember it. The raw material file is **read-only** to this skill.

## The journey

1. **Establish the prerequisites.** Before any beats, settle with the user what the audience already knows walking in — the concepts **grounded** from the start. See [Grounding](#grounding).
2. **Write 2–3 candidate starting beats**, drawn from the raw material. Each is a different entry point into the article. Each may only lean on grounded concepts; note what new concepts each one grounds. Show the user the beats *before* writing anything to the article file. The user picks one. Preview what beats that pick unlocks — as if they're seeing a little way down the path.
3. **Write only that beat** to the article file. A beat may be one sentence or several paragraphs — whatever that beat naturally is. Stop there.
4. **Re-read the article file from disk.** Then offer 2–3 candidate **next beats** — different directions the journey could pivot to from where the article now stands. Each must be reachable from the current grounded set; note what each one grounds.
5. **Loop 3–4** until the article reaches a natural end.

## Grounding

The grounding system lives in the **`writing-grounding`** skill — the shared reference this skill and `writing-shape` both point at, so the rule reads the same whichever one you came from. Read it before establishing prerequisites. Its own word for a unit of the draft is a **move**; here that unit is a **beat**.

The short version, in this mode's terms: every concept must be grounded before a beat can lean on it, either as a **prerequisite** the audience brings or **introduced** by an earlier beat. Each beat both *requires* grounded concepts and *grounds* new ones, so keep a running list of what's grounded and update it as each beat lands.

That list is what drives the choose-your-own-adventure. A candidate beat is only reachable if everything it requires is already grounded; picking a beat that grounds concept X unlocks every beat that was waiting on X. When you offer next beats, they must all be reachable from the current grounded set — and say what each one grounds, so the user can see which paths it opens.

## What is a beat

A beat is **one move** in the journey. It does one thing — sets a scene, lands a point, asks a question, drops an aside, twists the angle — then stops, leaving the reader where the next beat can pivot.

A beat is sized by what it needs:

- A single sentence if that's all the move is ("And then nothing happened for three weeks.").
- A short paragraph if the move needs setup.
- Multiple paragraphs if the beat is a self-contained vignette, argument, or example.

If a "beat" needs five paragraphs and three subheadings, it's not a beat — it's two beats glued together. Split it.

## Pulling from the pile

Pull material from the raw pile to populate each beat. Paraphrase, split, recombine, or quote. The pile is a quarry.

## Ending the journey

The article ends when the **journey** is complete — not when the pile is empty. Most piles have leftover fragments that don't make it in. That's fine; that's the point of having more raw material than you need.

## Writing rhythm

- **Append one beat at a time. Never write ahead.**
- **Re-read the article file from disk before every write.** Preserve user edits absolutely.
- If the user edits a previous beat substantially, let it change what comes next.
- If the user says "rewrite that beat" or "go back and try a different beat 3", do it — edit in place, leave the rest alone.

## Related skills

- **`writing-grounding`** — the shared grounding reference. Not optional reading.
- **`writing-fragments`** — produces the pile this skill mines.
- **`writing-shape`** — the argued exploit mode, for pieces with a thesis rather than a journey.
- **`polish`** — the publish pass, once the journey is done.
