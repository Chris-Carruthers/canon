# Voice: Handoff

## Write it like

**Primary — the Google SRE Book's postmortem register.** Blameless, factual, and
specific about what is broken. State reality; let the reader draw the conclusion.

**Supporting — James Hamilton**, "On Designing and Deploying Internet-Scale Services"
(LISA '07), for operational density: every sentence carries something you would need at
3am.

## Why them

A handoff is read by somebody who has no context and a problem. The postmortem register
is built for exactly that reader: it assumes ignorance without condescending, states
what is true rather than what was intended, and treats an admission of breakage as
information rather than as a confession.

The reason it works is that it is **blameless by construction** — which is not
politeness, it is what makes honesty cheap. A writer who expects to be judged for the
half-finished branch writes "in progress". A writer who knows the document's job is
accuracy writes "rebased onto Dev, three of eleven files conflict, nobody has looked at
it since the 14th." Only the second one saves anybody time.

Hamilton adds the habit of writing every operational fact as something actionable. Not
"there are some environment prerequisites" but the variable name, where it is set, and
what happens when it is not.

## Do not write it like

**A status report.** The register where adjectives stand in for state: "mostly done",
"in progress", "nearly there", "some cleanup remaining".

Each of those is a feeling about a fact, and the fact is what the reader needs. "Mostly
done" is unactionable; "the migration is written and merged but has never been applied
to any environment" is a task. The status-report register is also optimistic by
default, because it evolved to be read by someone deciding whether to worry — which
means it systematically hides the thing a handoff exists to surface.

The specific failure to guard against: **a merged PR reported as a shipped feature.**
Merged, deployed, applied and verified are four different states. A handoff that
collapses them has lied about the only thing it was written to record.

## The moves

**Lead with what is broken or unfinished.** Not buried under what works. The reader who
needs this document is the one about to trip over the gap, and they will not read to
the bottom first.

**Every claim of "done" carries its evidence.** How it was verified, and by whom. "Tests
pass" is weaker than "ran against dev on the 19th, booked an appointment end to end."
Verified-by-nobody is a state worth naming.

**Distinguish merged, deployed, applied, verified.** Say which. Never let one imply
another. A migration in the ledger is not a migration that ran.

**Name the manual step nobody wrote down.** The env var set by hand, the row inserted in
prod, the branch that only exists on your laptop. These are the entire reason the
document exists; the clean parts are recoverable from git.

**Write for the reader who has no context and a problem.** Expand the acronym. Give the
full path. Say which environment. They are reading this at the worst possible moment.

**State absence in words.** "Not tested", "nobody owns this", "no rollback exists" —
never a blank cell. A blank reads as an oversight; a stated absence is a finding.

## Go read

- Google SRE Book, "Postmortem Culture" — <https://sre.google/sre-book/postmortem-culture/>
- Google SRE Book, example postmortem — <https://sre.google/sre-book/example-postmortem/>
- James Hamilton, "On Designing and Deploying Internet-Scale Services", LISA '07 — <https://www.usenix.org/legacy/events/lisa07/tech/full_papers/hamilton/hamilton.pdf>
- Perspectives — <https://perspectives.mvdirona.com/>

## Before saving

1. Does the first paragraph say what is **broken or missing**, not what works?
2. Is every "done" accompanied by how it was verified and when?
3. Are merged, deployed, applied and verified distinguished wherever they differ?
4. Is every manual step and hand-set value written down, including the embarrassing ones?
5. Could somebody with no context pick this up cold and know their first action?
