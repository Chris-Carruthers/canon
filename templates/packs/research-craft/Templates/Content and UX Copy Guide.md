---
type: content-guide
surface: "<product or surface this governs>"
status: active           # active | proposed | absent
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/content-style-guide.md — your own map wins: Reference/Writing/House Voice.md
File as: Reference/Design/<Surface> — Content Guide.md

WHY THIS EXISTS: without it, interface text is negotiated per string. Everybody has
opinions about copy, nobody has written a rule, so the same argument recurs and
whoever cares most that day wins.

EVERY RULE NEEDS A PAIR — the thing to write and the thing not to. A rule with no
counter-example is unenforceable, because two people will read it as endorsing
opposite strings and both will be sincere.

BAN THE ADJECTIVE LIST. "Friendly, human, clear, confident" describes every product
ever shipped, tells a writer nothing, and cannot fail a string in review. If your
voice section contains only adjectives, delete it and write five before/after pairs
instead.

ERROR MESSAGES ARE THE HIGHEST-VALUE SECTION AND THE ONE MOST OFTEN OMITTED. They
are read at the worst moment, by the most frustrated reader, and they are where
generic guidance does the most damage.
-->

# <Surface> — Content Guide

## What this governs

Which surfaces, and which it deliberately does not.

## Voice, in pairs

Not adjectives. Show the string.

| Write | Not | Why |
|---|---|---|
| "Save changes" | "Submit" | Names what happens, not the mechanism |

## Rules

Numbered, each with a counter-example. Only rules people actually break — this is a
short list or it is ignored.

**1. <Rule.>**
✅ `<good string>`
❌ `<bad string>`
Why: <reason>

## Error messages

The highest-value section. Each error says what happened, why, and what to do next —
in that order, in the reader's terms, without blaming them.

| Situation | Write | Not |
|---|---|---|
| Upload too large | "That file is over 10 MB. Try a smaller one." | "Validation error: size exceeded" |

## Terminology

The words we use, and the ones we have decided against. Includes the internal term
that must never reach the interface.

| Use | Never | Note |
|---|---|---|

## Capitalisation, punctuation, numbers

The mechanical rules. Sentence case or title case, the Oxford comma, dates, times,
currency, how numbers are written. Boring, and the reason reviews stop being about
commas.

## Accessibility and plain language

Reading level target, what to do with jargon that cannot be removed, how link text is
written (never "click here" — the text must make sense read alone by a screen
reader).

## Not yet decided

Honest gaps. Better than a confident rule nobody agreed to.

---
Related: Design System [[ ]] · Component [[ ]]
