# Voice: Design System

## Write it like

**Primary — the GOV.UK Design System.** Plain, testable, evidence-backed. Every claim
is either a rule you can apply or a finding you can check.

**Supporting — Dieter Rams'** ten principles as the review checklist, and the **Apple
HIG** / **Material** for how to write a rule that scales to people you will never meet.

## Why them

GOV.UK is the best-written design-system documentation that exists, and the reason is
structural rather than stylistic: it was written for a readership that **cannot be
trained**. Thousands of teams across hundreds of organisations use it, none of whom can
be brought into a room. So every page has to work with no context, no relationship and
no follow-up question. That constraint produces the register you want — no in-jokes, no
appeal to taste, no "we felt" — because none of those survive a reader who has never
met you.

Its second property is that it **publishes its evidence**. Component pages carry a
"research on this component" section, and where the research is thin the page says so.
A design system that cannot say why a rule exists is a set of preferences with a
changelog, and preferences do not survive their author leaving.

Rams earns his place for a reason worth stating plainly: the ten principles are
**written down**, and they are checkable. "Good design is as little design as possible"
is a review question you can put to a component. That is what a principle is for.

## Do not write it like

**Jony Ive.** He is the taste most people mean when they say they want a beautifully
designed system, and he left almost nothing written — his medium was the product film
and the spoken introduction. There is no corpus to imitate.

So the imitation reaches for the *idea* of him and produces reverent adjectives:
considered, honest, crafted, inevitable. None of those is a rule. A reader cannot apply
them, a reviewer cannot fail a component against them, and a new team member cannot
tell whether their button qualifies. The document reads beautifully and governs nothing.

Rams is the written ancestor of that same taste, and unlike Ive he produced ten
sentences you can check work against. When you want the Ive register, use Rams.

The second failing register is **the manifesto** — a page of values with no component
on it. Values are cheap and every design system has the same five. The specific rule
about when not to use the thing is what is scarce.

## The moves

**Write for a reader you will never meet.** No shared history, no "as we discussed",
no team in-joke. If the page needs a conversation to work, it does not work.

**Every rule carries its evidence or admits it has none.** "Research on this component"
with an honest "we have not tested this" is worth more than a confident assertion. An
unaudited claim reads as settled and is worse than silence.

**Name what the system does *not* govern.** The surfaces it does not cover, the
decisions it deliberately leaves open. A system that claims everything is trusted for
nothing, because the first exception discredits the rest.

**Ownership is a name, not a team.** "Design owns tokens" is nobody. Write the person,
and where they can be reached, and what they are accountable for. This is the single
most common blank in a design-system note and the one that most reliably kills the
system.

**Names, never values.** A token name is API surface and belongs here; a token value is
source and belongs in the repo. Copying values in creates a second source of truth that
drifts silently while reading as authoritative.

**An honest absence is a finding.** "There is no design system yet" and "this is
unowned" are valuable first lines. A hopeful blank costs somebody an afternoon.

## Go read

- GOV.UK Design System — <https://design-system.service.gov.uk/>
- GOV.UK, how they write component guidance — <https://design-system.service.gov.uk/components/>
- Dieter Rams, ten principles for good design — <https://www.vitsoe.com/us/about/good-design>
- Apple Human Interface Guidelines — <https://developer.apple.com/design/human-interface-guidelines>
- Material Design 3 — <https://m3.material.io/>

## Before saving

1. Would this page work for somebody who has never spoken to anyone on the team?
2. Does every rule carry evidence, or explicitly say that it has none?
3. Is what the system does **not** govern stated as clearly as what it does?
4. Is every ownership row a named person rather than a team or a role?
5. Are there any token **values** on the page? (There should be none.)
