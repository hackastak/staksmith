---
name: source-research
description: Investigate a question against high-trust primary sources — official docs, source code, specs, first-party APIs — and capture the findings as a single cited Markdown file. Delegated to a background agent. Use when the user wants a technical topic researched, docs or API facts gathered, or reading legwork delegated.
origin: Hackastak
---

# Source Research

Spin up a **background agent** to do the research, so you keep working while it reads.

## The discipline

**Primary sources only.** Official documentation, the source code itself, specifications, RFCs, first-party API responses, changelogs from the project that owns the thing. Not a blog post about the docs, not a Stack Overflow answer, not an LLM's recollection.

**Follow every claim back to the source that owns it.** If the docs say "as of v4 this is the default" and you cite the docs, that's fine. If a blog post says it, go find where the project says it — or report that you couldn't, which is itself a finding. A claim you can't trace to an owner gets written down as unverified, not quietly asserted.

Never answer from parametric knowledge. The whole point of delegating this is that the agent goes and reads.

## The agent's job

1. **Investigate the question against primary sources**, following each claim back to the source that owns it.
2. **Write the findings to a single Markdown file**, citing the source for every claim — a URL, a file path and line, a spec section. One file, not a directory.
3. **Save it in the repo**, where the repo already keeps such notes. Match the existing convention; if there is none, put it somewhere sensible and say where.

The repo is the default output location because the note becomes a **primary source the code references** — it sits next to what it describes and gets read by whoever touches that code next. Use the vault instead when the investigation isn't tied to a codebase (evaluating a service before adopting it, a question spanning several projects), in which case it goes to the matching `1. Projects/<Project>/` folder, or `3. Resources/` if it's reference material rather than project work.

## Writing the brief

The background agent has none of this conversation's context. Its brief must carry:

- **The question**, stated precisely enough that a wrong answer would be recognisable as wrong.
- **Which sources count** for this question — name the project, the docs site, the repo, the spec if you know it.
- **The primary-source discipline above**, verbatim.
- **Where the file goes**, and what convention it should match.
- **What the answer will be used for**, in a line, so the agent knows what depth is enough.

Don't block on it. Keep working; the agent reports when it's done.

## Related skills

- **`wayfinder`** — research tickets on a map resolve through this skill, in parallel.
- **`grill-with-docs`** — the file this skill produces is what you take into the design conversation.
- **`deep-research`** — broad web synthesis including secondary sources. Different mode: that one surveys a landscape, this one nails a technical fact to its owner.
- **`documentation-lookup`** — Context7 library docs, when the question is "what's the API for X" and a lookup will do.
- **`search-first`** — for "does a library already do this?" rather than "how does this work?".
