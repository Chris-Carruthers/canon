# Voice: Cognitive Coverage

## Write it like

**Primary — the skill's own register**, in `skills/cognitive-coverage/SKILL.md`. It is
already the exemplar; this file exists to keep it from drifting.

**Supporting — formative assessment writing**, which is diagnostic rather than
evaluative: it reports which specific thing is not yet understood, and what to read.

## Why them

The cognitive-coverage register was built around a single constraint that determines
everything else about it: **the subject has to be willing to do it again.** A coverage
report that reads as a verdict on a colleague gets run once, and the people who most
need it stop volunteering first.

So the register is diagnostic. It reports bands rather than a score, it says which
specific thing was not accounted for, and it points at the line where the answer lives.
Formative assessment is the discipline that gets this right in the field it came from,
and the transferable rule is the same: **a result that does not tell you what to do next
is not a result.**

The second constraint is that it must be honest, which pulls against the first. A quiz
everybody passes converts an unknown gap into a false belief and burns the one moment
somebody was willing to be tested. The register holds both by being unsparing about the
finding and neutral about the person.

## Do not write it like

**A performance review.** Any construction that grades the person rather than the
coverage: a headline percentage, a comparison to a peer, a trend line on an individual,
language about readiness or capability.

This is the register that kills the practice. It converts a diagnostic into a record
that could be used against somebody, at which point the rational response is to prepare
for it or avoid it — and both destroy the measurement. The distinction is not cosmetic:
the subject of the report is **the system**, and the person is the best-placed party to
close the gaps in it.

The second failure is **the softened result**: "good understanding overall, with some
room to grow on failure modes." That is a gap, described so as not to sting, and it
leaves nobody with anything to do.

## The moves

**Report bands, never a single score.** Solid on shape and blank on failure modes is a
specific, actionable problem. One averaged number hides it, and averaging is the main
thing that turns a diagnostic into a grade.

**Every gap comes with where to read the answer.** `repo/path:line`. The teaching is the
point; the score is only the record.

**"I don't know" is recorded as a gap, plainly.** Not softened, not editorialised. It is
a data point, and treating it as a social failure is what teaches people to bluff.

**Say which kind of gap it is.** A decision-band gap usually means the reasoning was
never written down — that is a missing `Decisions/` note, not a personal failing.
Missing documentation and missing understanding are fixed by different people.

**Date everything and prepend.** This is provenance of understanding, only meaningful
with a date. Never overwrite an earlier entry; the history is whether understanding
improved or quietly decayed.

**Record the questions asked.** A re-test with the same questions measures memory.

## Go read

- `skills/cognitive-coverage/SKILL.md` — the register in full
- Google SRE Book, "Postmortem Culture" — <https://sre.google/sre-book/postmortem-culture/> — for blameless without being vague

## Before saving

1. Are results reported per band, with no single averaged score anywhere?
2. Does every gap point at where the answer can be read?
3. Is the subject of the report the **system**, with the person as the party who can fix it?
4. Is each gap classified — missing understanding, or missing documentation?
5. Is the entry dated and prepended, with the earlier entries untouched?
