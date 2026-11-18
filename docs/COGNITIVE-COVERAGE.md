# Cognitive coverage: can you explain what your agent built?

Code review asks *is this correct*. Tests ask *does it work*. Neither asks the
question that decides whether a team can operate what it ships: **can a person
explain it without reading it again?**

Agent-built code fails that quietly, because it passes review — it *is* correct. The
gap surfaces later, when someone has to change it and realises they are reading it
for the first time.

```
/cognitive-coverage
```

The skill reads what you just built, writes six to ten questions across six bands —
shape, state, failure, boundary, decision, change — asks them one at a time, and
grades against the implementation rather than against your confidence. At least one
question is about something *surprising* in the code, because that is where
understanding actually lives and it is what nobody retains from watching an agent
work.

Then it records a dated entry in `Reference/Cognitive Coverage/<feature>.md`, newest
first, **appending rather than overwriting**. The history is the value: it shows
whether understanding improved after somebody went and read the code, or quietly
decayed. It records the questions too, so a re-test can be harder instead of
identical.

**The design is mostly about refusing to be nice.** A quiz everyone passes is worse
than no quiz — it converts an unknown gap into a false belief and burns the one
moment someone was willing to be tested. So: an answer that would equally fit a
different implementation is *partial* at best, "I don't know" is a *gap* and never a
partial, and the bands are never averaged into one number, because a person who is
solid on shape and blank on failure modes has a specific problem that a percentage
hides.

It is a coverage report for a system, not a performance review — and it says so,
because if it reads as a scorecard on a colleague then nobody asks for it twice and
the people who need it stop first.
