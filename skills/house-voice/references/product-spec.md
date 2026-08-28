# Voice: Product Spec

## Write it like

**Primary — the Shape Up pitch** (Ryan Singer, *Shape Up*). Five parts, in order:
Problem, Appetite, Solution, Rabbit Holes, No-gos.

**Supporting — the Amazon PR-FAQ** (Bryar & Carr, *Working Backwards*) for the
discipline of writing the outcome before the build, and **Shreyas Doshi** for how to
state a bet so that it can be wrong.

## Why them

The Shape Up pitch is the only widely-published product format that treats **time as an
input**. The appetite — "six weeks, and if it does not fit we cut scope, not extend" —
is fixed before the solution is described, which forces the solution to be shaped to
the budget instead of the budget being estimated from the solution. Everything
downstream in a spec depends on that being settled.

Its second gift is **Rabbit Holes and No-gos as first-class sections**. Most specs
record what is in scope and leave the reader to infer the rest. Naming the specific
places the work could sink, and the things you have decided *not* to do, is what makes
a spec survive contact with an engineer who has a better idea on day three.

The PR-FAQ adds one thing the pitch does not: it makes you write the outcome as though
it already happened, in the customer's language, before any implementation exists. If
that paragraph is boring, the feature is boring, and you have learned it for the price
of a paragraph.

## Do not write it like

**Simon Sinek.** The Golden Circle is a keynote structure — start with why, build
emotional assent, arrive at the what. It is genuinely good at making a room care.

In a spec it produces a stirring opening paragraph with nothing falsifiable underneath
it. "We believe people deserve better tools" is not a problem statement: nobody can
disagree with it, no acceptance criterion follows from it, and it survives being true
whether or not the feature ships. A spec's job is the opposite of a keynote's — it must
be **possible to be wrong about**, in a way a reader can check in six weeks.

Sinek's move does have a home. It is the opening frame of a *vision* document, where
the job is to make somebody care before you make them decide. That is
[strategy-narrative.md](strategy-narrative.md), and it must not leak downstream.

The second anti-pattern, worth naming because it is the more common one: **the
solution-shaped problem**. "Users need a bulk-export button" is a solution wearing a
problem's clothes. The test is whether the sentence survives someone proposing a
completely different implementation. If it does not, it is not a problem statement.

## The moves

**Fix the appetite before describing the solution.** Write the time budget as a
constraint, in its own line, before the Solution section — not as an estimate derived
from it. This is the move that most changes what gets written after it.

**Name the rabbit holes explicitly.** The two or three places this work could quietly
consume a month: an unclear data model, an integration nobody has tested, a migration.
Naming them is not pessimism; an unnamed rabbit hole is discovered mid-build, when it
is a crisis rather than a scoping decision.

**Write No-gos, not just Out-of-scope.** Out-of-scope is a list. A No-go carries the
reason — "not doing per-tenant theming, because it forces a token indirection we would
have to unwind." The reason is what stops the same suggestion arriving four times.

**Make the problem section longer than the solution section.** If the reader is not
convinced the problem is real and precisely shaped, they read the solution while
arguing with the premise, and nothing you wrote lands.

**State the counterargument at its strongest.** The best version of "we should not
build this", then the specific reason it loses. A strawman signals you have not
considered it seriously.

**Every acceptance criterion must be checkable by someone who did not write it.**
If verifying it requires asking you what you meant, it is prose, not a criterion.

## Go read

- Ryan Singer, *Shape Up*, chapter 6 "Write the Pitch" — <https://basecamp.com/shapeup/1.5-chapter-06>
- Colin Bryar & Bill Carr, *Working Backwards* — the PR-FAQ chapter
- Jeff Bezos, 2015 letter to shareholders — <https://www.aboutamazon.com/news/company-news/2015-letter-to-shareholders>
- Shreyas Doshi on product bets and pre-mortems — <https://shreyasdoshi.substack.com>

## Before saving

1. Does the Problem section survive somebody proposing a completely different solution?
2. Is the appetite stated as a constraint, before the solution, rather than estimated after it?
3. Is there at least one named rabbit hole and one No-go with a reason attached?
4. Can every acceptance criterion be checked by someone who did not write the spec?
5. Could this document turn out to be **wrong**, in a way a reader could point at in six weeks?
