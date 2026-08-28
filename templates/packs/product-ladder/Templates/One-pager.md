---
type: one-pager
status: draft            # draft | agreed | dropped | escalated
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/one-pager.md — your own map wins: Reference/Writing/House Voice.md
File as: Specs/<slug>.one-pager.md

THE CHEAPEST RUNG THAT STILL FORCES A DECISION. Thirty minutes, one page, and the
only question it has to answer is: is this worth more than thirty minutes?

The failure this exists to prevent is opening with a full spec — which takes long
enough that finishing it feels like progress, and produces acceptance criteria for
something nobody has agreed is worth building.

ONE PAGE IS THE CONSTRAINT, NOT A GUIDELINE. If it does not fit, the idea is not
yet clear enough to be worth somebody's decision. Escalate to a PR-FAQ or a Shape
Up Pitch when it is agreed, and record which in `status:`.

Delete a section rather than filling it with "TBD". An absent section is a signal;
a "TBD" is noise that reads like content.
-->

# <Title>

## The problem

Who has it, what it costs them, and why now. One paragraph.

Must survive somebody proposing a completely different solution — if it does not, it
is a solution wearing a problem's clothes.

## What we would do

One paragraph. Enough to picture it. **Not** a design.

## What it would cost

A rough order of magnitude, stated as a range, and what it is traded against. "Two
weeks, which is the connector work" beats a number with nothing beside it.

## Why it might be wrong

The strongest case against, stated properly. If you cannot write this section, you
have not thought about it long enough to ask anybody for a decision.

## What we want

The specific decision being asked for, and from whom. "Feedback" is not a decision.

---
Related: Project [[ ]] · Escalates to [[<slug>.pr-faq]] or [[<slug>.product-spec]]
