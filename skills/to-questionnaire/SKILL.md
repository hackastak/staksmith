---
name: to-questionnaire
description: Turn a decision you can't answer alone into a questionnaire for someone else to fill in — async or over a meeting. Use when the user needs knowledge a third party holds, or invokes /to-questionnaire.
category: "Workflow & Meta"
origin: Hackastak
disable-model-invocation: true
---

# To Questionnaire

Turn something the user can't answer alone into a **questionnaire** — a Markdown document they hand to one person to fill in async, or fill out together over a meeting. The recipient holds knowledge the user lacks; the questionnaire pulls it out of them.

This is the outbound inverse of the `grill-me` family. Those skills grill the *user*; this one packages questions so the user can grill a *third party*.

**Grill the send, not the subject.** Interview the user only about the *send*, which they can always answer: who it goes to, and what they need back. The questions in the document then target the **gap** between what the recipient knows and what the user needs. Interviewing the user about the subject is the failure mode here — if they could answer those questions, there'd be no questionnaire.

## Process

1. **Who is it going to?** Ask, in one exchange, the recipient's role, expertise, and relationship to the user. This fixes the questionnaire's tone and how much context it must carry. Done when you know who the recipient is and what they know that the user doesn't.

2. **What do you need back?** Ask, in one exchange, the specific decisions or facts the user can't resolve alone and needs from this person. Done when you have a concrete list of what the user must walk away able to do or decide.

3. **Write the questionnaire.** Draft questions aimed at the gap from steps 1–2, following the document structure below. Done when the file exists and every item the user named in step 2 is covered by a question.

## Where it goes

**The vault, by default.** A questionnaire is a send-and-returned artifact worth keeping — the answers come back onto it.

- **`~/Developer/My_Notes/1. Projects/<Project>/Questionnaire_<slug>.md`** when the topic fuzzy-matches a project folder (same matching as the other vault skills — ask if it's ambiguous, never create a project folder silently).
- **`~/Developer/My_Notes/0. Inbox/Questionnaire_<slug>.md`** when it doesn't match anything yet.

**The cwd instead** when the questionnaire is genuinely about a code repo and belongs beside it — then use `to-questionnaire-<slug>.md`.

Follow the vault's draft → confirm → write gate: show the user the document and the exact path before writing it. Report the path when you're done.

## Document structure

Frame the document as a **discovery questionnaire**: the user lacks context, the recipient holds it. Order questions **most-important-first** — async means you may only get one pass — and group them under `##` headings by theme once there are more than a handful.

<questionnaire-template>

# <Questionnaire title>

**Purpose:** why this questionnaire exists and the decision riding on it.

**From:** <the user> — **To:** <the recipient> — **How your answers will be used:** <where they go>

## Context

One paragraph orienting a recipient who wasn't in the user's head. Enough to answer well, not a page.

## How to answer

Deadline and rough effort. Partial answers and "I don't know" are useful — flag anything you're unsure of rather than skipping it.

## <Theme heading>

One `##` section per theme. Under each, its questions, most-important-first. Every question is one idea — **never compound** — with an answer stub directly beneath, and a one-line _why this matters_ only where the question could be misread or invite a throwaway answer.

<question-example>
### What load is the system expected to handle at launch?

_Why this matters: it decides whether we provision for burst traffic now or defer it._

>
</question-example>

## Anything else?

A closing catch-all: anything we didn't ask that we should know?

</questionnaire-template>

## Related skills

- **`grill-me` / `batch-grill-me`** — the inbound direction: the agent grills the user.
- **`to-spec` / `to-tickets`** — the same conversation-to-durable-Markdown family. A returned questionnaire often feeds `to-spec`.
