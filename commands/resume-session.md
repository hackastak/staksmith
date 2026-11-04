---
description: "Load a saved session, catch the user up on this chat, or reconstruct where work left off across recent chats. Saved files in ~/.claude/sessions/ stay the high-fidelity path. In-chat catch-up and cross-session reconstruction are enhancements of this command, not new skills. Use for /resume-session, catch me up, what changed since I last spoke, where did I leave off, and what have I been working on."
---

# Resume Session Command

Load the last saved session state, or catch the user up when no saved file covers the gap, and orient fully before doing any work.
This command is the counterpart to `/save-session`. It is also the home for in-chat catch-up and cross-session reconstruction. Those are not separate skills. Do not look for `ketchup` or `recall`.

## When to Use

- Starting a new session to continue work from a previous day
- After starting a fresh session due to context limits
- When handing off a session file from another source (just provide the file path)
- Any time you have a session file and want Claude to fully absorb it before proceeding

## Usage

```
/resume-session                                                      # loads most recent file in ~/.claude/sessions/
/resume-session 2024-01-15                                           # loads most recent session for that date
/resume-session ~/.claude/sessions/2024-01-15-session.tmp           # loads a specific legacy-format file
/resume-session ~/.claude/sessions/2024-01-15-abc123de-session.tmp  # loads a current short-id session file
/resume-session here                                                 # in-chat catch-up; do not load a file
/resume-session <topic>                                              # reconstruct that topic across recent chats
```

## Route first

Do not load a session file until you know which route this request is. `/handoff` writes a document when the session is ending. This command catches the user up. Do not write a handoff from here.

1. **In-chat catch-up** when the user asks what changed in this chat, what is waiting on them, or passes `here`. Notifications and subagent results are not their messages. Follow [In-chat catch-up](#in-chat-catch-up). Do not read other chats. Do not start work.
2. **Cross-session reconstruction** when no saved session file exists, the argument is a topic rather than a date or a file path, or the user asks where they left off, what they have been working on, or to catch up across sessions. A date, a file path, or an explicit request to load the saved session stays on the saved-file route. Follow [Cross-session reconstruction](#cross-session-reconstruction). Do not start work until they say to continue.
3. **Saved session file** otherwise. Continue at Step 1. A file they asked you to load still wins over reconstruction.

If they already handed you a full state capsule (paths, branch, and the change), use that capsule and skip mining.

## Process

### Step 1: Find the session file

Only the saved-file route reaches this step. In-chat catch-up and cross-session reconstruction stop in their own sections.

If no argument provided:

1. Check `~/.claude/sessions/`
2. Pick the most recently modified `*-session.tmp` file
3. If the folder does not exist or has no matching files, say that no saved session file was found and that `/save-session` is still the high-fidelity path. Then run [Cross-session reconstruction](#cross-session-reconstruction) for the active workspace. Do not stop, and do not invent a session file.

If an argument is provided:

- If it looks like a date (`YYYY-MM-DD`), search `~/.claude/sessions/` for files matching
  `YYYY-MM-DD-session.tmp` (legacy format) or `YYYY-MM-DD-<shortid>-session.tmp` (current format)
  and load the most recently modified variant for that date
- If it looks like a file path, read that file directly
- If not found, report clearly and stop

### Step 2: Read the entire session file

Read the complete file. Do not summarize yet.

### Step 3: Confirm understanding

Respond with a structured briefing in this exact format:

```
SESSION LOADED: [actual resolved path to the file]
════════════════════════════════════════════════

PROJECT: [project name / topic from file]

WHAT WE'RE BUILDING:
[2-3 sentence summary in your own words]

CURRENT STATE:
✅ Working: [count] items confirmed
🔄 In Progress: [list files that are in progress]
🗒️ Not Started: [list planned but untouched]

WHAT NOT TO RETRY:
[list every failed approach with its reason — this is critical]

OPEN QUESTIONS / BLOCKERS:
[list any blockers or unanswered questions]

NEXT STEP:
[exact next step if defined in the file]
[if not defined: "No next step defined — recommend reviewing 'What Has NOT Been Tried Yet' together before starting"]

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

### Step 4: Wait for the user

Do NOT start working automatically. Do NOT touch any files. Wait for the user to say what to do next.

If the next step is clearly defined in the session file and the user says "continue" or "yes" or similar, proceed with that exact next step.

If no next step is defined, ask the user where to start, and optionally suggest an approach from the "What Has NOT Been Tried Yet" section. This step is only for the saved-file route. The catch-up routes stop on their own contracts.

## In-chat catch-up

Catch the user up on what changed in this chat since the last message they wrote before this request. Help them understand each change, not only where it stands. Then lay out every call waiting on them so they can decide from the reply alone. Assume they remember that last message and nothing after it.

Keep this turn read-only. Do not change code, start an app or a job, post anything, or write a handoff. Make visuals only from artifacts you already have.

Use plain words and short sentences. Say what changed for the user, not how you did it. Leave out hashes, file paths, commands, build numbers, and test counts unless they need one to act. Call each PR, branch, or agent by a name they would know. If a fact needs context to make sense, give the context or leave the fact out.

Collect your own work since that message, reports from subagents, and messages from anyone else in this chat. Check the current state of each PR, CI run, or agent this chat touched. Check each number you will show against the facts it comes from, and say so when you correct one.

An action item is a call or step only the user can take, such as a product choice, an approval, an irreversible action, or access you lack. Include any still waiting on the user, even one raised before their last message. Work you can still do yourself is not an action item. Never invent a call to fill the reply. A step they did not ask for and the work does not need is not an action item, unless it is irreversible and waiting on them: give it one line and no visual.

One call can cover many items. For each item, collect its link, what it changes for users, the evidence behind your pick, its risk, and your pick. Write "unknown" for a fact the call needs that you do not know. Leave out a link you do not have.

Spend words on the calls, not on the story. Keep what happened under 100 words, not counting pictures, and shorter when less happened. Leave out work that changed nothing for the user. Give each item about 30 words. Never cut items or shrink them to stay under a word count: no count in place of a list, and no link in place of an item. A link can add depth, but the reply alone must be enough to decide.

Open with one short sentence that names what waits on the user, or says nothing does. If nothing happened and nothing waits, say so and stop.

Then show what happened, pictures first, when you already have them. Then one short line per thing the user asked for: what came of it, and whether it is done, still running, failed, or not checked. Write each line the way you would say it out loud. Each line must stay true when read alone. Never mark something done that still waits on the user, and leave out anything the action items say. Under the summary, give at most three short lines that change what the user knows or must do. Then name in one line any work left that you can do yourself.

Then list the action items. Ask the call the user owns, and give your pick. A step you would take first goes in your pick. So does anything that must happen first, and anything that cannot be undone. Give the number or link of each PR, issue, or agent a call is about.

A call about one item is one bullet: the call, your pick, what it changes for users, the evidence behind your pick, and its risk, with the item named once. When items share a call, write the call and your pick once, then give each item its own bullet, riskiest first. Name an item's pick only where it differs. Give each item's risk even when it is low. Say what waiting costs only when it is more than a delay, such as a deadline or lost data.

For a call between options, give every option the work weighed, each with what it gets the user and what it costs, and the current state when there is one. Those costs are the call's risk, so add no separate risk line.

A visual is a screenshot, a video, a Mermaid diagram, or another picture you already have. A Markdown table is not a visual. Draw a picture only when it is easier to grasp than sentences: how a design works, a PR stack with each PR's state, a before and after, or options side by side. Never draw a status list, a list of action items, or boxes with nothing connecting them. Never give a fact twice. Keep each visual small enough to read at a glance: at most six boxes, with at most eight words in each. Embed screenshots and videos inline when the change is visible and you captured them. If a visible change has none, mark its summary line "No screenshot yet," and say there what changed on screen. Never invent a number, and never draw or generate a picture of a screen you did not capture.

Then stop. Do not start the work.

## Cross-session reconstruction

Rebuild recent working context from this workspace's chats, live state, and the shared record, then hand back a tight brief. Read only what the in-scope threads need, then stop.

This is the fallback when a context clear dropped the thread and nobody ran `/save-session`, or when the user named a topic across chats. It is not a substitute for a saved session file they asked you to load. One named session file is the saved-file route. Writing a handoff is `/handoff`.

Lock the scope before searching. Pin the window ("recent" is a real range, default the last 7 days), the topic if named, and the workspace (default the active one). State the scope back. Never quietly turn "all" into "recent N". Never read another project's transcripts unless they asked.

Search only the active workspace's transcript root. Order candidates by modification time, never by UUID or filename. Grep the topic first, then read only the matching chats and only their relevant regions. Skip the current chat and obvious noise (subagent, eval, and test chats). For one or two chats, search directly. For more, fan out only if this harness can spawn subagents. Otherwise search yourself and say the sweep was single-agent. Do not role-play other agents. The raw transcripts stay out of the reply. Cite each finding by chat id.

Known roots, skip any that are not there:

- Claude Code: `~/.claude/projects/<slug>/*.jsonl`. `<slug>` is the workspace path with the leading slash removed and each `/` turned into `-`, so `/Users/you/proj` becomes `-Users-you-proj`.
- Pi: `~/.pi/agent/sessions/<slug>/*.jsonl`. `<slug>` is the same path wrapped in `--`, so `/Users/you/proj` becomes `--Users-you-proj--`. The timestamp is in the filename. Still order by modification time.
- Cursor, when that directory exists: `~/.cursor/projects/<slug>/agent-transcripts/<uuid>/<uuid>.jsonl`, with the leading slash dropped and each `/` turned into `-` (no leading hyphen).
- Codex: `~/.codex/sessions/`, in dated folders. Order by modification time.
- If the harness names a transcript path for this run, use that path. Do not invent a root you cannot see.

When the topic names a feature, file, subsystem, area, or bug, also sweep the shared record. That sweep is the default, not a judgment call. "My work on X" does not exempt it. Hand it to the `why` skill (`skills/why/SKILL.md`), and steer the question from design rationale to current state, what was tried and did not hold, and what users are still reporting. Reuse its source playbooks. Run that sweep in parallel with the chat search when you can spawn. If this harness cannot spawn, do the searches yourself and say so. Skip an unavailable source and say so. Do not invent findings. Skip the sweep only for pure activity recall with no named target ("what did I do this week"), where your own history and live state are the entire answer.

Verify the PRs, branches, and tickets that mining surfaced with `git` and `gh`. When the answer hinges on what an agent actually did, read the full transcript, not a trimmed copy. Live state wins over the transcript when they disagree. Say so.

Write the brief through the `unslop` skill (`skills/unslop/SKILL.md`). Sanitize private context and secrets before any output. Group by thread. Stay on the named topic. An adjacent feature or ticket stays out unless it blocks this one.

Lead with the capsule, then the threads, then the problems, then the next move.

- **Capsule.** At most 5 bullets. What this work is and where it stands overall.
- **Threads.** One line each, prefixed with exactly one status tag: `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`. A thread with no tag is not done yet, so tag it.
- **Problems.** At most 5, the recurring ones. Include symptoms users keep reporting and any fix that shipped and was reverted.
- **Next move.** The single most useful next action, concrete.

Cite chat findings by chat id and shared-record findings by source (PR number, ticket id, chat permalink, error-tracker issue). When the capsule and thread lines outgrow a screen, cut detail before you cut threads.

Then wait. Do not start work until the user says to continue.

## Edge Cases

**Multiple sessions for the same date** (`2024-01-15-session.tmp`, `2024-01-15-abc123de-session.tmp`):
Load the most recently modified matching file for that date, regardless of whether it uses the legacy no-id format or the current short-id format.

**Session file references files that no longer exist:**
Note this during the briefing — "⚠️ `path/to/file.ts` referenced in session but not found on disk."

**Session file is from more than 7 days ago:**
Note the gap — "⚠️ This session is from N days ago (threshold: 7 days). Things may have changed." — then proceed normally.

**User provides a file path directly (e.g., forwarded from a teammate):**
Read it and follow the same briefing process — the format is the same regardless of source.

**Session file is empty or malformed:**
Report: "Session file found but appears empty or unreadable. You may need to create a new one with /save-session."

---

## Example Output

```
SESSION LOADED: /Users/you/.claude/sessions/2024-01-15-abc123de-session.tmp
════════════════════════════════════════════════

PROJECT: my-app — JWT Authentication

WHAT WE'RE BUILDING:
User authentication with JWT tokens stored in httpOnly cookies.
Register and login endpoints are partially done. Route protection
via middleware hasn't been started yet.

CURRENT STATE:
✅ Working: 3 items (register endpoint, JWT generation, password hashing)
🔄 In Progress: app/api/auth/login/route.ts (token works, cookie not set yet)
🗒️ Not Started: middleware.ts, app/login/page.tsx

WHAT NOT TO RETRY:
❌ Next-Auth — conflicts with custom Prisma adapter, threw adapter error on every request
❌ localStorage for JWT — causes SSR hydration mismatch, incompatible with Next.js

OPEN QUESTIONS / BLOCKERS:
- Does cookies().set() work inside a Route Handler or only Server Actions?

NEXT STEP:
In app/api/auth/login/route.ts — set the JWT as an httpOnly cookie using
cookies().set('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' })
then test with Postman for a Set-Cookie header in the response.

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

---

## Notes

- Never modify the session file when loading it — it's a read-only historical record
- The briefing format is fixed — do not skip sections even if they are empty
- "What Not To Retry" must always be shown, even if it just says "None" — it's too important to miss
- After resuming, the user may want to run `/save-session` again at the end of the new session to create a new dated file
- In-chat catch-up and cross-session reconstruction do not use the saved-file briefing format. Each has its own contract above. Reconstruction uses `why` and `unslop`, which already ship here
