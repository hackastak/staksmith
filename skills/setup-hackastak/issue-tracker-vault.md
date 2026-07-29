# Issue tracker: Obsidian Vault

Issues and specs (you may know a spec as a PRD) for this repo live as markdown notes in the
Obsidian vault, in the PARA project folder that corresponds to this repo.

This is the **default** backend. Use it unless this repo has been configured for `github` or
`local` instead.

## Locating the project folder

The vault root for projects is `~/Developer/My_Notes/1. Projects/`.

Match this repo to its project folder by fuzzy-matching the repo name against the folder names,
tolerating case, separators, and word order: `oms-athena` ↔ `OMS_Athena`, `billscribe-app` ↔
`BillScribe`, `smilestacklabs-site` ↔ `SmileStack Site`.

- **One clear match** — use it.
- **Ambiguous, or no match** — ask the user which project folder to use, or whether to create one.
  Never guess, and never create a project folder silently.

Everything below is relative to `1. Projects/<Project>/`.

## Conventions

- The spec is `spec.md`
- Implementation issues are one file per ticket at `issues/<NN>-<slug>.md`, numbered from `01` —
  never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file (see
  `triage-labels.md` for the role strings)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading
- `<NN>` is one number space per project. Never reuse a number, even after a ticket is resolved
  or dropped

## Vault conventions

These notes are part of a PARA vault and are read by a human in Obsidian, not only by agents.

- **Wikilinks over paths.** Reference other notes as `[[Note Name]]`, not as file paths, so
  Obsidian's graph and backlinks pick them up. An issue should wikilink its spec; the spec should
  wikilink the issues it spawned.
- **Link out to the repo by path**, since code files are not vault notes. A plain relative path
  or a `file://` link is fine.
- **Frontmatter** carries `status`, `tags`, and `created` where the project's other notes already
  use it. Match the surrounding notes rather than imposing a new scheme.
- **Don't reorganise the project folder.** Other notes live there that have nothing to do with
  tickets. Add `spec.md`, `issues/`, and `map.md`; leave everything else alone.

## Writing to the vault

Vault writes follow a **draft → confirm → write** gate. Show the user the note content you intend
to write and the exact path, get confirmation, then write. This applies to specs, issues, and the
map alike.

Editing a ticket you already created — appending a comment, changing `Status:`, recording an
answer — does not need a fresh confirmation; that is the normal running of the tracker.

## When a skill says "publish to the issue tracker"

Create a new note under `1. Projects/<Project>/`, creating the `issues/` directory if needed.

## When a skill says "fetch the relevant ticket"

Read the note at the referenced path. The user will normally pass the ticket number or the note
name directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a note with one **child** note per ticket.

- **Map**: `map.md` — the Notes / Decisions-so-far / Fog body.
- **Child ticket**: `issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A
  `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:`
  line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file
  it lists is `resolved`.
- **Frontier**: scan `issues/` for notes that are open, unblocked, and unclaimed; first by number
  wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append
  a context pointer (gist + wikilink) to the map's Decisions-so-far in `map.md`.

## Multiple concurrent efforts

One project normally has one `spec.md`, one `issues/`, and one `map.md`. When a project genuinely
has two efforts running at once, give the second its own subfolder —
`1. Projects/<Project>/<effort-slug>/` — with the same three shapes inside it and its own number
space. Ask before creating one; the flat layout is the default because it stays browsable.
