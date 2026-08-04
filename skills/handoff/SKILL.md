---
name: handoff
description: Write a durable handoff document so a fresh agent — or you in a new session — can continue this work: what was done, the current state, the next moves, and which skills to reach for, with secrets redacted. Save-only, never launches. Use at a session boundary, before /clear or /compact, when handing work to another agent, or when the user invokes /handoff.
origin: Hackastak
disable-model-invocation: true
argument-hint: "What the next session should focus on, or nothing"
---

# Handoff

Write a **handoff document**: a self-contained note that lets a fresh agent, or you in a new session, pick up exactly where this one left off. The skill produces the artifact and stops.

**Save-only. This skill never launches anything.** It does not spawn a background agent, does not open a new session, does not run `claude --bg`. It writes one document and hands the path back. Continuation is a separate, human-initiated step: someone opens a fresh session and points it at the document.

## Relationship to `strategic-compact`

`strategic-compact` suggests an in-place `/compact` at a logical boundary — it keeps you in the same session and produces no artifact. `handoff` is for the other kind of boundary: when the session is **ending** and the work must survive it. It writes the durable artifact that `/compact` throws away. They are complementary, not alternatives: compact to keep going, hand off to stop and let someone else (or a rested you) resume.

## When to use

- The session is approaching its context limit and you would rather stop cleanly than auto-compact through a task boundary.
- Work is in flight at the end of a session and the next session should continue it.
- You are handing the thread to another agent — an AFK run, a teammate, a fresh CLI session.
- The user invokes `/handoff`.

## What the document carries

A handoff is only useful if the next agent can act from it without re-reading this whole conversation. Include:

1. **The goal** — what this work is trying to achieve, in one or two sentences. Not the history; the destination.
2. **State of play** — what is done and verified, what is in flight, what is committed vs uncommitted. Name the branch, the last commit, and whether the tree is clean. Be honest about what is *not* done and what is uncertain.
3. **Next moves** — the concrete next actions, specific enough to start on: a file to open, a command to run, a decision that is waiting. Order them. If `$ARGUMENTS` named a focus, let it steer which next move leads.
4. **Suggested skills** — which skills the next session should reach for, and when (e.g. "run `/tdd-workflow` for the parser change", "`/review-changes` before committing"). This is what makes the handoff self-propelling rather than a passive summary.
5. **Watch-outs** — landmines the next agent would otherwise step on: a flaky test, a pre-existing failure that is not theirs, a decision that looks reopenable but was settled, an ADR that constrains the change.

### Reference artifacts, do not restate them

The conversation already produced durable things — a spec, a plan, ADRs, issues, commits, diffs, files on disk. **Point at them by path or URL; do not copy their contents into the handoff.** Restating a spec in the handoff creates a second copy that drifts from the first, and it bloats the document past the point of being read. Link `1. Projects/<Project>/spec.md`, `docs/adr/0007-*.md`, `#42`, a commit SHA, a `path/file.ts:120` anchor — and trust the next agent to open them.

The handoff's own value is the connective tissue the artifacts do not have: why the work is at this exact point, what to do next, and what to avoid.

### Redact secrets

The handoff is written to be **read back as a prompt** — a fresh session may be launched with its contents. So treat it like anything that leaves the session: no API keys, tokens, passwords, connection strings, or private URLs in the body. If a next step genuinely needs a credential, say *which* credential is needed and where it lives (`the STRIPE_KEY from .env`), never the value itself.

## Where it goes

Always save. Never launch.

- **`~/Developer/My_Notes/1. Projects/<Project>/Handoff_<slug>.md`** when the work fuzzy-matches a vault project folder — same matching as the other vault skills (`repog` ↔ `RepoG`). Ask if it is ambiguous; never create a project folder silently.
- **The scratchpad** (`Handoff_<slug>.md` in the session scratchpad directory) when nothing matches. A handoff may be picked up later, so this beats an OS temp dir that gets wiped — but note to the user that the scratchpad is session-scoped, and offer the cwd if the next session may not see it.
- **The cwd instead**, as `handoff-<slug>.md`, when the work is bound to a specific code repo and the handoff belongs beside it.

Follow the vault's **draft → confirm → write** gate: show the user the document and the exact path before writing. Report the path when done, and state plainly that nothing was launched — resuming is their next step.

## Log a weekly-note breadcrumb

After the handoff document is written, chain the `quick-note` skill (see [[quick-note]]) to drop a one-line record of this session's completed work into the current week's weekly note, under today, in the right section. Run it **silently** here — the handoff gate already covered the write, so do not prompt again. This leaves a scannable breadcrumb in the weekly note alongside the durable handoff. Skip it only if nothing was actually completed this session.

## Document structure

```markdown
# Handoff: <short title>

**Focus for next session:** <from $ARGUMENTS, or "continue the work below">
**As of:** <branch> @ <last commit sha> — <clean | N files uncommitted>

## Goal
<1–2 sentences: the destination, not the history.>

## State of play
- Done & verified: <...>
- In flight: <...>
- Not started: <...>

## Next moves
1. <concrete first action — a file, a command, a decision>
2. ...

## Suggested skills
- `/<skill>` — <when and why>

## Watch-outs
- <landmines, pre-existing failures, settled-but-reopenable decisions>

## Artifacts (open these; not restated here)
- Spec: <path/URL>
- ADRs: <docs/adr/...>
- Issues / PRs: <#nn / URL>
- Key files: <path:line>
```

## Guardrails

- **Never launch.** No `claude --bg`, no spawning an agent, no opening a session. Write and stop.
- **Never inline a secret.** Name the credential and its location; never its value.
- **Reference, don't restate.** Artifacts are linked by path/URL, not copied in.
- **Draft → confirm → write.** Show the path and content, get the yes, then write.

## Related skills

- **`strategic-compact`** — the in-place counterpart: compact to keep going; hand off to stop and resume elsewhere.
- **`weekly-momentum-report`** — narrates throughput across a week; `handoff` captures the state of one thread at a single moment.
- **`what-next`** — where the next session might start if the handoff's next moves have already been done.
