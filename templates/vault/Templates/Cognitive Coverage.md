---
type: cognitive-coverage
feature: <slug>
subject: <who was quizzed>
latest_assessment: YYYY-MM-DD
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
File as: Reference/Cognitive Coverage/<feature-slug>.md

WHY THIS EXISTS. Code review asks "is this correct". Tests ask "does it work".
Neither asks the question that decides whether a team can operate what it ships:
can a person explain it without reading it again?

Agent-built code fails that quietly, because it passes review — it IS correct. The
gap surfaces later, when someone has to change it and finds they are reading it for
the first time.

NEWEST ENTRY FIRST, and never overwrite an old one. The history is the value: it
shows whether understanding improved after somebody went and read the code, or
quietly decayed. One note per feature, one dated section per assessment.

ONE PERSON PER ENTRY. Two people means two entries. A merged result tells you
nothing about either of them.

RECORD THE QUESTIONS. A re-test that asks the same questions measures memory rather
than understanding, so the next round needs to know what was already asked.

THIS IS NOT A PERFORMANCE REVIEW. It is a coverage report for a system, and the
subject is whoever is best placed to close the gaps. If it reads as a scorecard on a
colleague, people stop asking for it — and the ones who need it stop first.

Keep this file under 500 lines. When it outgrows that, keep the newest three
assessments and summarise the rest in one line each.
-->

# Cognitive Coverage — <Feature>

Implementation: `repo/path` · Built: YYYY-MM-DD · Spec: [[ ]] · Project: [[ ]]

## YYYY-MM-DD — <subject>

| Band | Result | Note |
|---|---|---|
| Shape — the pieces and how data moves | solid \| partial \| gap | |
| State — what is stored, and who else changes it | | |
| Failure — what breaks, and would you find out | | |
| Boundary — what is deliberately out of scope | | |
| Decision — why this and not the obvious alternative | | |
| Change — where the next feature goes, and what it breaks | | |

<!-- "I don't know" is a gap, never a partial. An answer that would equally fit a
     different implementation is partial at best. Do not average the bands into one
     percentage — a person solid on shape and blank on failure modes has a specific
     and actionable problem, and a single number hides it. -->

**Gaps worth closing**

- The specific thing, and `repo/path:line` where it can be read.

**Not a coverage gap**

- Anything that turned out to be missing documentation rather than missing
  understanding. Different problem, different fix, usually a different person.

**Questions asked**

1. …

## Related

Project: [[ ]] · Spec: [[ ]] · Decisions: [[ ]]
