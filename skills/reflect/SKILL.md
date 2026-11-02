---
name: reflect
description: Hold a mirror to the second brain — read the vault's stated goals, the attention it actually spends, and the beliefs it keeps returning to, then report how the thinking reflects the person, what it reveals about how they reason, and where behavior pulls toward or away from their goals. Tracks drift across reruns. Use for a periodic self-review of the vault's direction.
category: "Second Brain & Vault"
origin: Hackastak
---

# Reflect — Second-Brain Mirror

Read the whole vault as a portrait of a mind: not "what's on my todo list" but *how do I think, what do I keep thinking about, what do I actually believe, and is any of it moving me toward the goals I wrote down?* Produce a grounded reflection report, and save a snapshot so each rerun can show how the picture has drifted.

This skill is **read-and-reflect**. It reads notes and writes exactly one artifact: a dated reflection report (plus its machine-readable snapshot). It never edits project notes, goals, or tasks.

## When to Activate

- a periodic self-review — "what is my vault telling me about me right now?"
- checking whether daily attention matches stated goals (goal vs. behavior drift)
- before a planning cycle, a performance review, or a big direction decision
- the user invokes `/reflect`, or asks for a "mirror," "reflection," or "how am I thinking" read
- **Not** for: finding tasks (`what-next`), surfacing new ideas (`ideas`), pressure-testing one belief (`challenge`), or writing in the user's voice (`ghost`). Reflect sits above those — it reads the shape of the whole mind. Reach for it when the question is introspective, not operational.

## Vault Configuration

```
VAULT_PATH=~/Developer/My_Notes
GOALS_PATH=2. Areas/Core_Goals
REFLECTIONS_PATH=2. Areas/Core_Goals/Reflections
DURABLE_NOTES_PATH=5. Notes
```

Paths below are relative to the vault root. If `$GOALS_PATH` or `$REFLECTIONS_PATH` doesn't exist, note it in the report and fall back to scanning `2. Areas/` broadly for goal-shaped notes; create `$REFLECTIONS_PATH` only when saving the snapshot (Step 8).

## Arguments

`/reflect [horizon] [focus]` — both optional.

- **horizon** — how far back the *attention* scan reaches. Accepts `4w`, `8w`, `90d`, `6mo`, etc. Default: **last 6 weekly notes**. Goals and durable notes are always read in full regardless of horizon.
- **focus** — narrow the mirror to one domain (e.g. `/reflect 90d Lorien_AI` or `/reflect Hackastak`). When set, weight the attention scan and alignment toward that project/area, but still read all goals so alignment stays honest.

## Instructions

Work the four layers in order — **goals → attention → beliefs → thinking** — then compare them. The whole point is the comparison; don't stop at describing each layer.

### Step 1: Load the Goal Layer (what you *said* you want)

Read every note in `$GOALS_PATH` in full:

```bash
ls -1 "$GOALS_PATH"/ 2>/dev/null
```

Extract, verbatim where possible:
- **Explicit goals** and their success criteria / KPIs.
- **Stated tensions or risks the person named themselves** (these are gold — e.g. a note that says "my biggest risk is starting over finishing"). A goal the person has already diagnosed is a goal you can hold them to.
- **Target ratios or behaviors** (e.g. "shift from 90% building / 10% leading toward 60/40", "one article per month", "pause everything else").
- Any goals that live *outside* the career/work frame (family, health, hobbies, habits) — note them explicitly; they are the ones most likely to go silent later.

### Step 2: Measure the Attention Layer (what you *actually* did)

This is the evidentiary half. Read, don't guess.

**Recent weekly notes (the horizon window):**
```bash
ls -t "_Weekly"/**/*.md 2>/dev/null | head -8   # widen to match a longer horizon
```

**The project roster (breadth signal):**
```bash
ls -d "1. Projects"/*/ 2>/dev/null | wc -l
ls -d "1. Projects"/*/ 2>/dev/null
```

**Recently touched notes (what's warm):**
```bash
find . -name "*.md" -mtime -30 -type f ! -path "./.obsidian/*" ! -path "./.claude/*"
```

Then **quantify attention**, don't just eyeball it:
- Tag each weekly-journal entry by theme/project. Produce an approximate **attention distribution** (which themes dominate, which barely appear).
- Where the goals named a ratio (e.g. build vs. lead), classify entries into those buckets and estimate the **actual ratio**. State your method so the number is checkable.
- Note **emotional valence** where it's clear — entries logged as frustration vs. as wins. A pattern of logging real progress *as* grievance is a finding in itself.

### Step 3: Extract the Belief Layer (what you *value*)

Read the durable/atomic notes and any manifesto-shaped notes:
```bash
ls -1 "$DURABLE_NOTES_PATH"/*.md 2>/dev/null
grep -rllE "I believe|my philosophy|the gist is|I've learned|principle" --include="*.md" "$DURABLE_NOTES_PATH" "2. Areas" 2>/dev/null
```

Pull out **stated values and operating principles** — decision frameworks, mental models, convictions the person has written in their own voice. Separate:
- **Codified beliefs** — written down deliberately as durable notes.
- **Emergent convictions** — the same opinion asserted unprompted across several weeklies (often more revealing than the codified ones, because they're live).

### Step 4: Detect Thinking Patterns (*how* you reason)

Across everything read, name the recurring *shape* of the reasoning — independent of topic. Look for signatures such as:
- how problems get framed (root-cause vs. symptom; systems vs. tasks)
- decision heuristics actually in use (reversibility, inversion, smallest-first, leverage)
- what the person reaches for when stuck, bored, or frustrated
- the gap between how they *describe* their level/role and the work the notes *show* them doing

Ground each pattern in at least one concrete, cited entry. A pattern with no evidence is a horoscope — cut it.

### Step 5: Compute Goal-vs-Behavior Alignment (the core of the report)

For each major goal from Step 1, hold it against the attention from Step 2 and mark it:
- **Aligned & moving** — stated and visibly worked on. Cite the evidence.
- **Aligned but silent** — stated, but near-zero attention in the window. Name the absence.
- **Diverging** — behavior actively contradicts the stated goal (e.g. "finish over start" vs. a growing project count). These are the highest-value findings; lead with them.
- **Emergent / unstated** — real, energized activity that serves a goal the person isn't crediting (e.g. doing the next level's work but logging it as complaint). Name it and connect it to the goal it secretly advances.

Where you can, attach a **number** to the divergence (project count vs. "pause everything else"; actual build/lead ratio vs. target). Numbers make drift trackable in Step 8.

### Step 6: Surface Blind Spots

- **Silent goals** — goals from Step 1 the vault votes against with its silence.
- **Comfortable avoidance** — a sophisticated-looking activity that competes for the same hours as the hard, stated priority (e.g. tooling that defers the actual ship).
- **Under-narrated wins** — inflection points logged in a single bullet that deserve more deliberate capture.
- **Unacknowledged heat** — a project or relationship accelerating faster than the notes treat it.

Say plainly when the vault *can't* answer something (e.g. a goal that may simply live in a different capture surface). Don't invent a verdict the evidence doesn't support — mark it `[Inference]` or `[Unverified]` per the vault's provenance habit.

### Step 7: Generate the Reflection Report

Present the report in chat using this structure (adapt depth to what the evidence supports):

```
# 🪞 Second-Brain Mirror — [date]
*Horizon: [window] · Focus: [all | focus area] · Based on: [N] goals, [M] weeklies, [K] durable notes*

## 1. How you think
[2–4 reasoning signatures, each with a cited example. End with the one-line "what this says" takeaway.]

## 2. What you think about
[Attention distribution table: theme | weight in window | pulling toward goals?]

## 3. What you believe
[Codified + emergent beliefs, each linked to [[the note]] or the week it recurs.]

## 4. Goal alignment — the central tension
[Per-goal verdict: Aligned & moving / Aligned but silent / Diverging / Emergent. Lead with divergences. Quote the person's own stated tension where it applies. Attach numbers.]

## 5. Blind spots the vault reveals
[Silent goals, comfortable avoidance, under-narrated wins, unacknowledged heat.]

## 6. Verdict
[2–4 sentences: the honest one-paragraph portrait. Where do the goals and the behavior agree, and where are the one or two real fault lines?]

## Drift since last reflection
[Only if a prior snapshot exists — see Step 8. Otherwise: "First reflection — this is the baseline."]
```

Keep it honest and specific. The report should feel like being *seen*, not flattered. Every claim traces to a note or a counted pattern.

### Step 8: Save the Snapshot (drift tracking)

So reruns can measure change, save the report to the vault **and** embed a small machine-readable snapshot in its frontmatter.

Write to `$REFLECTIONS_PATH/[YYYY-MM-DD]_Reflection.md` (create the folder if missing). Frontmatter carries the trackable metrics:

```yaml
---
date: 2026-11-01
horizon: 6 weeks
focus: all
metrics:
  active_project_count: 12
  build_lead_ratio_estimate: "85/15"   # vs target in goals
  dominant_themes: [SBN_SCM delivery, AI repositioning, Lorien AI]
  silent_goals: [family, fishing, reading, circadian]
  top_divergence: "12 active projects vs. stated 'finish over start / pause everything else'"
---
```

Before writing, read the most recent existing snapshot in `$REFLECTIONS_PATH` (if any) and compute the **Drift** section for Step 7: which metrics moved, which divergences closed or widened, which silent goals found their voice. This turns `reflect` from a one-off into a longitudinal mirror — the real reason the skill exists.

### Step 9: Offer Follow-Up

After presenting, offer concrete next moves, e.g.:

> "Want me to:
> 1. Turn the top divergence into a corrective plan (e.g. a project-pruning pass)?
> 2. Draft the promotion-case write-up from the under-narrated wins I found?
> 3. Re-run focused on one goal or project?
> 4. Set a reminder to reflect again next month so we can track the drift?"

## Quality Criteria

A good reflection is:
- **Evidentiary** — every claim cites a note or a counted pattern; nothing invented.
- **Comparative** — the value is in goals-vs-behavior, not in describing either alone.
- **Honest** — it names the fault lines, including the ones the person already half-knows and avoids.
- **Longitudinal** — it leaves a snapshot so the next run can measure movement.

Avoid:
- Horoscope language that could describe anyone.
- Flattery — "under-narrated wins" is fine; empty praise is not.
- Prescribing a life — reflect *mirrors*; it offers corrective action only as an opt-in in Step 9.
- Silently picking a winner when two notes disagree — surface both (vault provenance habit).

## Notes
- Goals and durable notes are read in full every run; only the attention scan respects the horizon.
- The person's own stated tensions (Step 1) are the sharpest tool here — holding someone to a risk they diagnosed themselves lands harder than any outside judgment.
- Silence is data. A stated goal with zero attention is a finding, not an omission.
- Pairs well with `ideas` (what to do next), `challenge` (stress-test one belief), and `ghost` (speak in the voice this skill profiles). `reflect` is the altitude read above all three.
