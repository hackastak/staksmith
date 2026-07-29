---
name: resolving-merge-conflicts
description: "Resolve an in-progress git merge or rebase conflict — read the intent behind each side, resolve the hunks, run the project's checks, then hand back for the final commit. Use when a merge or rebase has stopped with conflicts."
origin: Hackastak
---

# Resolving Merge Conflicts

1. **See the current state** of the merge or rebase. Check `git status`, the history on both sides (`git log --oneline --left-right HEAD...MERGE_HEAD`), and the conflicting files. Know which operation you're in — a rebase replays commits one at a time and will stop again; a merge stops once.

2. **Find the primary sources for each conflict.** Understand deeply why each change was made and what the original intent was. Read the commit messages, check the PRs, check the original issues or tickets. A conflict is two intents colliding; you cannot resolve it correctly until you know both. If `CONTEXT.md` or `docs/adr/` covers the area, read them too — a conflict that touches a settled decision resolves toward the decision.

3. **Resolve each hunk.** Preserve both intents where possible. Where they're genuinely incompatible, pick the one matching the merge's stated goal and note the trade-off out loud. Do **not** invent new behaviour — a resolution that is neither side is a change smuggled in under a merge, and nobody will review it.

   **Resolve by default.** Don't abort to dodge the work. Abort only if the merge itself is wrong — wrong branch, wrong direction, shouldn't be happening at all — and when you do, say why before you do it.

4. **Run the project's automated checks.** Discover them first (`package.json` scripts, `Makefile`, `justfile`, CI config), then run them in the usual order: typecheck, then tests, then format. Fix anything the merge broke. A conflict resolved to something that compiles is not the same as a conflict resolved correctly — the tests are what tell you which one you did.

5. **Stage everything, then hand back.** Stage the resolved files and summarise: what conflicted, how you resolved each one, any trade-off you took, and what the checks said. **Do not commit and do not run `git rebase --continue`** — the final merge commit and each rebase step are the user's to make. Tell them the exact command they'll want (`git commit` or `git rebase --continue`) and stop there.

   If you're mid-rebase and more commits remain, say so — the user will hit the next conflict after continuing, and this skill runs again.

## Related skills

- **`review-changes`** — worth running over a large or surprising resolution before the commit.
- **`draft-commit`** — drafts the message when the merge commit needs one written.
- **`git-guardrails`** — the hooks that keep an automated `--abort` or `reset --hard` from happening by accident here.
