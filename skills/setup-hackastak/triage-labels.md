# Triage labels

The label strings this repo uses for the triage state machine. `triage` and the rest of the
ticketing flow read this file to learn what to call each role. Canonical role names live in the
`triage` skill; this file records how they are spelled and applied **here**.

The roles are fixed — two categories and five states, one of each per issue. What varies per repo
is the string each role maps to and, on the vault and local backends, the fact that the role is a
`Status:` line rather than a label.

## Category roles

| Role | Label string |
|------|--------------|
| `bug` | `bug` |
| `enhancement` | `enhancement` |

## State roles

| Role | Label string |
|------|--------------|
| `needs-triage` | `needs-triage` |
| `needs-info` | `needs-info` |
| `ready-for-agent` | `ready-for-agent` |
| `ready-for-human` | `ready-for-human` |
| `wontfix` | `wontfix` |

## How the role is recorded

Depends on the backend configured in `issue-tracker.md`:

- **vault** and **local** — there are no labels. The role is a `Status:` line near the top of the
  ticket file, e.g. `Status: ready-for-agent`. An issue carries its one category and one state on
  that line (`Status: bug, needs-triage`).
- **github** — the role is a real GitHub label. Create the labels once with `gh label create`
  before the first triage pass; `triage` will `gh issue edit --add-label` / `--remove-label` from
  then on.

## Customising the strings

Change the right-hand column if this repo's team already uses different words (`feature` instead
of `enhancement`, `blocked` instead of `needs-info`). Keep the left column exactly as written —
the skills key off the canonical role, and only the string it resolves to may change.

Do not add or remove roles. The state machine is fixed; a repo that needs a sixth state wants a
change to the `triage` skill, not a local relabel that the machine won't understand.
