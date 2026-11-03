---
name: technical-writing
description: "Layered technical-writing standard: Diátaxis structure, Google developer style sentences, STE instruction rules, and Global English syntax. Use for /technical-writing, or when writing or reviewing docs, RFCs, READMEs, PR descriptions, or commit messages."
category: "Writing & Content"
origin: community
disable-model-invocation: true
---

# Technical writing

Write so a tired engineer understands on the first read. Apply all four layers.

This is not `article-writing`, `blog-draft`, or `polish`. Those own brand voice, the blog pipeline, and the publish checklist. This skill owns structure and sentence rules for technical docs. It is not `unslop`. That skill owns the AI-tell catalog. Run it on every doc this skill touches. Do not edit it.

You do not need another plugin's setup skill to run this.

## When to use it

Use it when the user invokes `/technical-writing`, or when they ask you to write or review docs, RFCs, READMEs, vault technical notes, PR descriptions, or commit messages.

Do not use it for product UI strings. Use the product's copy guidelines for those.

If a blog draft also needs this standard, apply it after the voice pass. Do not flatten a brand voice into reference dryness.

## How to run it

1. Read the target. If none is named, ask which file or paste to edit.
2. Name the Diátaxis mode before you rewrite. If the doc mixes modes, split and link.
3. Rewrite to the four layers. Use the real symbol, file, flag, and command names from the codebase.
4. Apply `unslop` to the result. If you find a new abstract-metaphor offender, propose it as an addition to that skill's abstract-metaphor rule in the reply, with the diff. Do not edit that skill.
5. Reply with the mode, the rewrite or the file diff, and any rule you left broken because following it made the sentence worse.

**Done when:** the mode is named, every layer has been applied or a broken rule is named, and `unslop` has been applied.

## Three rules above the layers

- **Cut every word that does no work.** If the sentence survives without a word, the word goes. "In order to" is "to". "It is important to note that" is nothing.
- **Use the short, everyday word.** "Use", not "utilize". "Help", not "facilitate". "Do", not "perform". A long word has to buy its length with precision.
- **When a rule makes a sentence worse, fix the sentence another way or leave it alone.** A sentence that follows every rule and sounds like a machine wrote it has failed.

The codebase is the word list. Write the real symbol, file, flag, or command name, not a synonym or a description of it.

Don't invent jargon. Use the words a developer would say out loud: "move", "delete", "a budget that only decreases", not "evacuate", "ratchet", or "endgame". A named pattern is fine when the doc says what it means the first time.

## Vary the rhythm

A doc can obey every layer and still read machine-written. Every sentence is clipped short. There is no view anywhere. Nothing is specific.

- Mix sentence lengths on purpose. Short sentences land a point. Longer ones carry a fact with its condition or consequence.
- One thought per sentence does not mean one length per sentence. Split the sentence that carries two thoughts. Keep the long sentence that carries one.
- Have a view where the mode allows it. Explanation weighs trade-offs, so say what you make of them instead of listing pros and cons. Reference stays dry.
- Be specific over sterile. Not "schema changes can cause issues" but "a column rename fails the build".

## Pick the mode first (Diátaxis)

One document, one mode. Two questions pick it. Does the content inform action (doing) or understanding (thinking)? Does it serve learning or work?

- Action and learning: **tutorial**.
- Action and work: **how-to**.
- Understanding and work: **reference**.
- Understanding and learning: **explanation**.

Use the compass on a whole document or on one sentence.

**Tutorial: learning by doing.** The learner's success is your job, not theirs. Open by saying what the learner will build, not what they will "learn". Every step produces a visible result, early and often. Tell them what they should see: the expected output, the prompt change, the log line. Cut explanation to one clause and a link. Stay concrete. Write as "we", in commands: "First, do x. Now, do y."

**How-to: steps to a goal.** Solve a problem a person has, not an operation the machine can perform. Assume competence and skip teaching. Action only. No digressions, no background, no completeness for its own sake. Link those instead. Allow forks and judgment: "If you want x, do y." Name the guide by the task: "How to calibrate the radar array", not "Radar array calibration".

**Reference: facts for lookup.** Only describe. No instruction, no persuasion, no opinion. Be dry, complete, and sure. State facts, options, limits, and errors with no hedging. Mirror the structure of the thing described, so code and docs can be navigated together. Put material where readers expect it. Generate from code where possible.

**Explanation: understanding and why.** One bounded topic, readable away from the product. Each title should tolerate an implicit "About..." in front. Anchor on a real why question. Give context: design decisions, history, constraints, alternatives. Opinion is allowed here and nowhere else.

Don't mix modes. No reference tables inside a tutorial. No tutorial hand-holding inside reference. No arguing inside a how-to. Split and link instead.

## Write sentences to the reader (Google developer style)

- Talk to the reader as "you", in the present tense. "Will" only for things that genuinely happen later.
- Say who does what: "the compiler checks", not "is checked". Passive is fine only when the actor is unknown or beside the point.
- Write instructions as commands: "Click Submit." State facts plainly. Never "should be done".
- Put the condition before the instruction: "To delete the document, click Delete."
- Put the common case first. Exceptions after.
- Sound like a knowledgeable friend. No buzzwords, no figurative language, no "please" in instructions, and never "simply", "easy", or "quickly" in a procedure. If it were simple, the reader would not be here.
- Don't pre-announce ("we will soon support...") and don't start consecutive sentences with the same phrase.
- Link with words that say where the link goes: the page title or a short description. Never "click here". Prefer a sentence of context on the page over a link off it.
- Headings carry the point, not just the topic ("Pick the mode first", not "Modes"). Sentence case. A task heading is a bare verb phrase ("Create an instance"). A concept heading is a noun phrase. One h1 per page, no skipped levels.
- Numbered lists for sequences, bullets for everything else. Introduce a list with a complete sentence. Keep items parallel.
- Code goes in code font. UI elements go in bold. Use serial commas. Drop "etc." and say up front that a list is partial.

## Make statements load one at a time (STE rules)

- One instruction per sentence. One thought per sentence everywhere else.
- Split instructions longer than about 20 words and other sentences longer than about 25.
- Put the warning or condition before the step it guards: "If hot oil touches your skin, injuries can occur."
- Keep "the" and "a": "Remove backup file" reads two ways. "Remove the backup file" reads one.
- Give each word one meaning and one job, then keep it. If "check" means inspect, don't also use it for restrain.
- Pick one word per action and stick to it: "start", not "start" here and "initiate" there.
- Write procedures as direct commands, never as narration and never in the passive: "Install the component", not "the component must be installed".
- Avoid "-ing" words where you can.

## Leave no sentence open to two readings (Global English)

- Keep words like "only" and "not" next to the word they change. "Only fails on growth" and "fails only on growth" say different things.
- Break up long noun strings. "The proto import budget check script" becomes "the script that checks the proto-import budget".
- Make every "it", "they", and "this" point at one obvious thing. Repeat the noun when in doubt. Never use "this" or "which" to point at a whole clause.
- Don't drop verbs. "Phase 1 moves the converters and Phase 2 the runtime" leaves Phase 2 without one. Give it one.
- Keep the small words that show structure, such as "that" in "Ensure that the switch is off". Never trade clarity for word count.
- Repeat the article in a series when it prevents a misread: "the client and the host", not "the client and host", when they are two things.
- Say which parts "and" or "or" joins when a sentence can group two ways. "Both...and", "either...or", and "if...then" are free disambiguators.
- Use periods, not semicolons. Replace an em dash with a new sentence.
- Make text in parentheses a full grammatical unit or its own sentence. Never form plurals with "(s)".
- No slashes. Write "a, b, or both" instead of "a/b" or "and/or".
- Call each thing by one name, everywhere. A doc that says "the gate", "the ratchet", and "the budget check" for one thing teaches three things. Don't churn what didn't change.
- Skip idioms, colloquialisms, Latin abbreviations, and metaphors.

## Voice and repo specifics

- Apply the **unslop** skill to every doc this skill touches. That skill owns the slop-pattern catalog: AI vocabulary, filler, hedging, formatting tells.
- PR descriptions and commit messages are writing too. Every layer except Diátaxis applies to them. A PR body is a briefing that a reviewer can read in under a minute. Do not paste swarm logs, SHA lists, or metric tables. Link them.
- Indent code snippets with tabs. Write real paths. Make every count or tree claim true at the commit that lands it, and include the command that regenerates it.

## Worked example

Before:

> Configuration of the proto import ratchet budget script parameters is performed via budget.json. Note that it's important to remember that running with --write, which updates the committed budget to reflect the current count, should only be done when lowering it. If exceeded, CI fails.

After:

> `budget.mjs` reads the committed budget from `budget.json` and counts the files that import protos. If the count exceeds the budget, CI fails. Run `budget.mjs --write` only to lower the budget.
