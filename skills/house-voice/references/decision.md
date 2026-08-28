# Voice: Decision

## Write it like

**Primary — Michael Nygard**, "Documenting Architecture Decisions" (2011). The original
ADR: Context, Decision, Status, Consequences. Short, dated, immutable.

**Supporting — Russ Cox's** Go design documents, for a *Why* section that survives
hostile review.

## Why them

Nygard's format is built around one insight: **the valuable part is the context, not
the decision.** Anybody can read the code and see what was chosen. What is unrecoverable
six months later is the set of constraints that made it the right call — the deadline,
the missing library, the thing that was true about the team that year. An ADR that
records only the choice has preserved the least perishable half.

The second insight is that an ADR is **immutable and dated**. You do not edit a decision
when it turns out badly; you write a new one that supersedes it. That is what makes the
folder a history rather than a snapshot, and it is why "we tried X and it failed" stays
visible instead of being quietly overwritten.

Cox supplies what Nygard's terse format leaves to the writer: how to argue. Read any Go
proposal and notice that the alternatives are stated so well you could almost be
persuaded by them, and then rejected for a specific, checkable reason. That is what
makes the decision hold when somebody re-litigates it.

## Do not write it like

**Meeting minutes.** The register that records who was present, what was raised, and
that a decision was reached — without stating what was chosen, what it costs, or what
was given up.

The failure is diagnostic: a minutes-voice decision note answers "did we discuss this?"
when the only question a future reader has is "why is it like this, and what breaks if
I change it?" It is also the register that produces the passive voice — "it was decided
that" — which conveniently removes the one fact that makes a decision accountable.

The second failing register is **the announcement**: a decision written as though it
were always obvious, with no alternatives section. If nothing was seriously considered
and rejected, either the note is hiding the argument or there was no decision to record.

## The moves

**Write the context so a stranger could re-derive the decision.** Constraints, deadline,
what was and was not known at the time. Include the constraints that have since
disappeared — those are the ones that make a past decision look stupid in hindsight,
and recording them is the whole point.

**State each alternative at its strongest, then reject it specifically.** Not "we
considered X but it was too complex" — *what* complexity, and why that mattered more
than what X would have bought.

**Consequences includes what got worse.** A decision with only upsides in its
consequences section was not a decision, it was a preference. Name the cost you accepted,
so the next person knows it was priced rather than missed.

**Separate what you knew from what you believed.** "we measured 1.9s at p95" and "we
expect this to be latency-bound" are different claims. Marking the second as a belief is
what lets a future reader check whether it turned out to be true.

**Never edit a decision. Supersede it.** New note, new date, a line in the old one
pointing forward. The failed attempt is the most useful thing in the folder.

## Go read

- Michael Nygard, "Documenting Architecture Decisions" — <https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions>
- The ADR pattern collection — <https://adr.github.io/>
- Go design documents — <https://go.dev/design/>
- Russ Cox, "Our Software Dependency Problem" — <https://research.swtch.com/deps>

## Before saving

1. Could a stranger re-derive this decision from the Context section alone?
2. Is every rejected alternative stated well enough that it sounds tempting?
3. Does Consequences name something that got **worse**?
4. Is anything you believed but did not verify marked as such?
5. If this decision is reversed next year, does the note say what evidence would justify that?
