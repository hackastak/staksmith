# Architect runner prompt

The orchestrator passes this file to every parallel candidate during Phase B, with the task, the Phase A grounding, the isolated working directory, and the output path. The working directory is a git worktree when available, otherwise a per-runner subdirectory. Candidates must not write the same file.

You are producing one candidate design. Read the architect skill in full first. Output a type sketch, function signatures, a module map, and a rationale shaped per `rationale-template.md`. Leave the Synthesis decision section empty. Arena fills that in.

Apply this discipline. The orchestrator compares candidates on these axes.

- Caller's usage first. Write the README-style usage and two or three real call sites before the types, then derive the type sketch from them. The usage is the spec. When they diverge, reconcile the sketch to the usage, not the reverse.
- Data structures first. Trace each dominant access pattern through the proposed structure. If the answer is "we'll add a map later," the structure is wrong. That bar is Foundational Thinking in `rules/common/coding-style.md`.
- Interface depth. Prefer a simple interface that pulls complexity into the callee. Do not put transport or wire types on the public API. Parse into domain types behind the interface. Vocabulary is `codebase-design`.
- Shared state. If two actors might both write, ask what happens. If the answer is not "nothing," default to per-actor state with a merge at the read boundary. That check is Separate Before Serializing Shared State in `rules/common/coding-style.md`.
- Make boundaries visible. `not implemented` for bodies, pseudocode comments for tricky logic, doc comments for intent and invariants. A reader should trace data from input to output by reading types and signatures alone.
- Encode invariants in types: hard-to-misuse types, then runtime checks, then prose. That order is Type System Discipline in `rules/common/coding-style.md`.
- Validate at boundaries, trust types inside. Business logic as pure functions. The shell stays thin. That is Input Validation in `rules/common/coding-style.md`.
- One source of truth per invariant. Derive instead of syncing a second list.
- Idempotent transitions where a retry or a crash halfway is plausible. Say what the second run does.
- Short call chains. If tracing the flow needs more than three files, flatten the hierarchy.

You are one runner. Produce the best design you can. Do not hedge toward a safe middle. Differences between candidates are the signal used to pick a base and graft.
