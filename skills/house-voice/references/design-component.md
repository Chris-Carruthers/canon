# Voice: Design Component

## Write it like

**Primary — a GOV.UK component page.** The four-part shape: when to use this · when not
to use this · how it works · research on this component.

**Supporting — Julie Zhuo** for the usage and drift sections, where a judgement has to
be defended, and **Don Norman** for the vocabulary to defend it in.

## Why them

The GOV.UK shape is the best-designed component document because of one section most
teams omit: **when not to use this.** It is the section that does the work. A component
page that only says what the thing is for gets applied everywhere the reader can
imagine, and the drift you spend the next year cataloguing was authored by your own
documentation.

Zhuo's contribution is how to write a design judgement so it reads as a judgement and
not as a decree. Her critique writing consistently separates the observation from the
principle from the preference, and says which is which — the move that lets a reader
disagree with you productively instead of either deferring or ignoring you.

Norman supplies the vocabulary. **Affordance, signifier, mapping, feedback, constraint,
the gulf of execution and the gulf of evaluation** are precise terms for things people
otherwise describe as "confusing". "The control affords dragging but signifies nothing"
is diagnosable. "It feels unclear" is not.

## Do not write it like

**A Storybook caption.** The register that documents the prop API — variants, sizes,
states, a table of booleans — and nothing about the decision.

The API is already in the code, typed, and it is more current there than it will ever be
in a note. Restating it produces a document that is simultaneously redundant and
out-of-date, and that crowds out the one thing the code cannot carry: why this exists,
when to reach for something else, and what broke last time somebody used it wrong.

The second failing register: **preference stated as principle.** "Buttons should be
uppercase" with no reason is a taste presented as a rule, and it will be relitigated
every quarter by whoever has the strongest opinion that month. Either attach the reason
or admit it is a convention chosen for consistency — both are defensible, pretending is
not.

## The moves

**Write "when not to use this" first.** Before the description. It is the section that
prevents drift, and writing it first tends to sharpen what the component actually is.

**Separate observation, principle and preference — and label which.** "The focus ring
is 2px" is an observation. "Focus must be visible at 3:1" is a principle with a source.
"I would rather it were a filled style" is a preference. Collapsing the three is what
makes design feedback feel arbitrary.

**Use the precise word.** Affordance, signifier, mapping, feedback. If you are about to
write "confusing", you have a diagnosis available and have not made it.

**Accessibility claims are checkable or absent.** Role, keyboard interaction, focus
behaviour, labelling requirement — stated as things somebody can verify. If nothing has
been audited, say that instead. An unaudited claim reads as done.

**Two or three rules people actually break.** Not a style essay. The approved-usage
section earns its length only from rules with a real violation history.

**Drift is a location, not a count.** `repo/path:line`. Counts go stale the day after
you write them; the current number belongs in a dated audit output.

## Go read

- GOV.UK Design System components — <https://design-system.service.gov.uk/components/>
- Julie Zhuo, "How to Do a Design Critique" — <https://medium.com/the-year-of-the-looking-glass/how-to-do-a-design-critique-3d64f1f2ac5e>
- Don Norman, *The Design of Everyday Things* — affordances, signifiers, mapping, feedback
- Nielsen Norman Group, ten usability heuristics — <https://www.nngroup.com/articles/ten-usability-heuristics/>

## Before saving

1. Is there a "when not to use this", and is it specific enough to refuse a real request?
2. Does the page restate anything already typed in the code?
3. Is every design judgement labelled as observation, principle or preference?
4. Is every accessibility claim checkable, or explicitly marked unaudited?
5. Is drift recorded as `repo/path:line` rather than as a number?
