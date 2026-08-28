---
type: architecture
system: "<system or product name>"
status: active           # active | proposed | historical
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/architecture-overview.md — your own map wins: Reference/Writing/House Voice.md
File as: Reference/Architecture/<System>.md

WHAT THIS IS FOR: a newcomer needs the whole shape in twenty minutes, including the
parts that are ugly. Code shows structure; it does not show why the boundary is
where it is, or which component falls over first.

A DIAGRAM WITH NO FAILURE MODES IS DECORATION. The boxes and arrows are the cheap
half. What earns the note is what happens when one of the arrows stops working.

CODE STAYS OUT, AND SO DO VALUES. Link `repo/path:line`. A note that reproduces
configuration has created a second source of truth that drifts silently while
reading as authoritative.

Keep it under 500 lines and one level deep. If a component needs more, it gets its
own note and this one links to it.
-->

# <System> — Architecture

## What it does

One paragraph, in terms of what it is for rather than what it contains.

## The shape

The components and how data moves between them. Prose, then a diagram if it helps —
never a diagram instead of prose, because a diagram cannot express "usually".

| Component | Responsibility | Lives at |
|---|---|---|

## Boundaries, and why they are there

The interesting part. Why this split and not another. What was tried before. Which
boundaries are load-bearing and which are historical accident — say which; a reader
cannot tell from the code, and will otherwise treat both as sacred.

## State: what is stored, where, and who can change it

The question that decides whether somebody can safely make a change.

## How it fails

Per dependency: what happens when it is unavailable, whether we degrade or stop,
whether anybody finds out. **Name the silent failures specifically** — those are the
ones the code will not tell you about.

| Dependency | On failure | Detected by |
|---|---|---|

## What it deliberately does not do

And what breaks if somebody assumes otherwise.

## Known ugliness

The parts that are wrong and known to be wrong, with `repo/path:line`. Writing these
down is what stops the next person spending a week rediscovering them and a second
week assuming they were intentional.

---
Related: Project [[ ]] · Decisions [[ ]] · RFCs [[ ]]
