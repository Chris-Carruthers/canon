# Voice: RFC / Design Proposal

## Write it like

**Primary — the Oxide Computer RFDs** and **Russ Cox's Go design documents**. Both are
public, both are real proposals that had to survive hostile review before anything was
built.

**Supporting — the Rust RFC process**, for how to write the parts that are unresolved.

## Why them

These are the best publicly readable corpus of real engineering proposals in existence —
not papers written after the fact, not blog posts, but documents that had to persuade
sceptical colleagues and then get implemented. That distinction matters, because a
retrospective write-up can quietly omit the objection it never answered.

Two properties transfer directly. **The motivation is longer than the proposal.** Cox
will spend more than half a document establishing that the problem is real and
precisely shaped, with named examples and numbers, before proposing anything. A reader
who is not convinced of the problem argues with the premise all the way through your
design, and nothing you wrote lands.

**Alternatives are stated better than their advocates would state them.** Read any Go
proposal and notice you could almost be persuaded by the rejected options — then notice
the specific, checkable reason each one loses. That is what makes a decision hold
instead of returning every eight months.

The Oxide RFDs add discipline about status. An RFD is numbered, dated, never deleted,
and carries a lifecycle. A rejected RFD is the most useful kind: it is the written
answer to "why don't we just…".

## Do not write it like

**An ADR.** The register that records a decision as already made — Context, Decision,
Consequences — applied to a decision the team has not actually had yet.

This is the specific failure the RFC template exists to prevent, and it is seductive
because the ADR format is shorter and canon already ships it. But an ADR is
retrospective by construction: it has no section for the argument, because the argument
is over. Writing one pre-emptively produces a document that *looks* like a settled
decision, which either forecloses the discussion or gets ignored once people notice the
sleight of hand. Either way the reasoning is lost.

The second failure is **the strawman alternatives section** — three options nobody
proposed, dismissed in a clause each. Reviewers read that section first to calibrate
how seriously to take you, and a weak one costs you the whole document.

## The moves

**Motivation longer than proposal.** With evidence: what breaks today, what it costs,
who has hit it and when.

**State each alternative at its strongest.** Including "do nothing", which is sometimes
right and is always worth pricing.

**Reject specifically.** Not "too complex" — what complexity, and why it outweighed
what the alternative bought.

**Name what gets worse.** Every real change makes something worse. Saying which is how
a reader knows it was priced rather than missed.

**Keep open questions open.** Marking uncertainty as uncertainty is the single largest
credibility move available. Smoothing over an unresolved question is discovered in
review anyway, at a much higher cost.

**Record what came up in review and how it was answered.** This is what stops the same
objection returning after acceptance.

## Go read

- Oxide Computer RFDs — <https://rfd.shared.oxide.computer/>
- RFD 1, on the RFD process itself — <https://rfd.shared.oxide.computer/rfd/0001>
- Go design documents — <https://go.dev/design/>
- Russ Cox, the vgo series — <https://research.swtch.com/vgo>
- The Rust RFC repository — <https://github.com/rust-lang/rfcs>

## Before saving

1. Is the motivation section longer than the proposal section?
2. Is every alternative — including "do nothing" — stated well enough to sound tempting?
3. Does the document name something that gets **worse** if this is accepted?
4. Are unresolved questions left visibly open rather than smoothed over?
5. Is this arguing for a decision, rather than recording one already made?
