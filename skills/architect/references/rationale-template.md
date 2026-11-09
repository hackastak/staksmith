# Rationale template

The prose that ships alongside the type sketch. One page. Sentence-case headings. Replace the italic notes with the actual design.

## Problem

*One paragraph. What we are trying to do, and what about the existing system makes the shape non-obvious. Name the Phase A constraints the design must honor: types to interoperate with, callers that cannot break, invariants that crossed a boundary.*

## Usage (caller's view)

*Write this first, before the type sketch. Show the README or quickstart the caller reads, plus two or three realistic call sites. What they import, what they call, what comes back. The Shape section is derived from this. When they diverge, reconcile the sketch to the usage.*

## Shape

*Data structures first, then how data flows through the signatures. Name the load-bearing decisions. State which invariants are encoded in types, where validation lives, and what the system deliberately does not do. State what complexity the public surface hides, what remains exposed, and why the interface is no larger than needed. Cite the rule behind each decision, for example `per boundary validation`. Do not restate the rule.*

## Synthesis decision

*Filled in by arena, or by the same-model comparison when the harness cannot spawn. Which candidate became the base and why, what was adapted from each of the others, and what was rejected and why. If the multi-model pass did not run, say so here.*

## Tradeoffs accepted

*One bullet per tradeoff. Form: "we accept X in exchange for Y." Name anything a later reader might mistake for an oversight.*

## Alternatives considered

*Required. At least one concrete alternative shape, with one line on why it lost, judged on interface depth. Two or three when the design space had real contenders. One is fine when the constraints forced the answer: "this was the only viable shape because...". Do not list flavors of the same shape. This section is design alternatives, not other runner candidates. Those belong in Synthesis decision.*

## Open questions and risks

*Questions the human still has to answer, and risks worth flagging before implementation. Phrase as questions.*

## Next implementation step

*The first thing to build against the sketch. One sentence.*
