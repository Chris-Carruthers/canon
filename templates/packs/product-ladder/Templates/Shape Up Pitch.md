---
type: pitch
status: draft            # draft | betted | passed | shipped
appetite: <e.g. 6 weeks | 2 weeks>
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/shape-up-pitch.md — your own map wins: Reference/Writing/House Voice.md
File as: Specs/<slug>.pitch.md

THE APPETITE IS AN INPUT, NOT AN ESTIMATE. Fix the time first, then shape the
solution to fit it. This inverts the usual order and it is the entire mechanic:
"how long will this take" produces a number nobody believes, while "what is worth
six weeks" produces a decision.

If the work does not fit the appetite, the scope is cut. Not the appetite extended.
Write that down here so nobody has to relitigate it in week five.

RABBIT HOLES AND NO-GOS ARE NOT OPTIONAL SECTIONS. They are why this format
survives contact with an engineer who has a better idea on day three.

A PITCH IS NOT A SPEC. Deliberately under-specified in the middle — shaped enough
to be bettable, loose enough that the people building it still get to design. If
you are writing acceptance criteria, you want Product Spec.
-->

# <Title>

## Problem

The raw idea, a use case, or something that went wrong. Specific enough that somebody
could disagree about whether it matters.

## Appetite

**<n> weeks.** How much this is worth, decided before the solution below. If the
solution does not fit, the solution changes.

## Solution

The shaped approach. Enough for somebody to picture building it; not so much that
there is nothing left to decide. Rough sketches beat precise ones — a precise mock
gets implemented literally.

## Rabbit holes

The specific places this could quietly consume a month. An unclear data model, an
untested integration, a migration nobody has scoped. Naming them is not pessimism; an
unnamed rabbit hole is discovered mid-build, when it is a crisis instead of a scoping
decision.

## No-gos

What we are explicitly **not** doing, **and why**. Out-of-scope is a list; a no-go
carries the reason, and the reason is what stops the same suggestion arriving four
times.

---
Related: Project [[ ]] · Escalates to [[<slug>.product-spec]]
