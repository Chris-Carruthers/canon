# Voice: Six-pager

## Write it like

**Primary — the Amazon six-pager.** A narrative memo, read in silence at the start of
the meeting, then discussed.

**Supporting — Russ Cox's** Go design documents, for how to hold an argument together
across six pages without losing the reader.

## Why them

The six-pager exists because of one observation: **bullets let you omit the sentence
that explains why the second point follows from the first, and the omission is
invisible to the writer.** Prose does not permit that. You discover the gap in your own
reasoning while writing, which is where most of the value is created — before anybody
else reads it.

The silent-reading ritual is the other half, and it is a brutal test. The document must
work with nobody there to gloss it, no verbal framing, no answering questions as they
arise. Anything ambiguous will be read wrong by somebody in the room, and you will find
out immediately.

Cox is the model for sustaining an argument at length. Six pages is long enough to lose
structure; his design documents show how to keep a thread visible across that distance —
recapitulate briefly, signpost, and never make the reader hold two open questions at
once.

## Do not write it like

**A deck reformatted into sentences.** Bullets converted to prose by adding "and" —
same skeleton, more words.

The test is mechanical: if you can restore the bullets by deleting connective words,
you have not written a narrative. What is missing is the *because*. A narrative earns
six pages by carrying reasoning that would not survive compression; one that is a deck
in disguise carries the same content at four times the length, which is worse than the
deck was.

The second failure is **burying the ask**. A six-pager whose request appears on page
five has spent the reader's whole attention budget before telling them what it was for,
and they will re-read the earlier pages with different eyes and resent it.

## The moves

**State the decision in the first three sentences.** Then earn it. A reader who knows
what is being asked reads the evidence properly.

**Prose everywhere the word "because" belongs.** Bullets are fine for enumerations —
environments, owners, paths — and nowhere else.

**Alternatives stated at their strongest, then rejected specifically.** This is the
section that decides whether the room trusts the rest of the document.

**Price what you are stopping.** A proposal that adds without subtracting has not been
costed, and everybody in the room knows it.

**Put the data in an appendix and the argument in the body.** If an appendix item is
load-bearing, it is not an appendix item.

**Read it aloud before you send it.** Six pages of prose hides bad sentences that a
deck would have exposed. This is the only reliable way to find them.

## Go read

- Colin Bryar & Bill Carr, *Working Backwards* — the narrative chapters
- Go design documents — <https://go.dev/design/>
- Russ Cox, the vgo series — <https://research.swtch.com/vgo> — a sustained argument across many pages

## Before saving

1. Is the decision being asked for stated in the first three sentences?
2. Could you restore bullets by deleting connective words? (If yes, rewrite.)
3. Is every rejected alternative stated well enough to sound tempting?
4. Does it say what gets stopped, not only what starts?
5. Have you read it aloud?
