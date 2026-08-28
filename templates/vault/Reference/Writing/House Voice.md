---
type: reference
status: active
updated: TODO
---

# House Voice

Which writer each of our documents should read like, and who it must not.

**This file wins.** canon ships defaults in its `house-voice` skill so a new vault is not
blank; anything you write here overrides them. A team that has named its own exemplars
has done the more valuable thing.

<!--
HOW TO USE THIS NOTE

Replace the rows below with exemplars from your own world. The shipped ones are
defensible but generic — a regulator's published guidance, a predecessor's document
everybody already imitates, or a customer whose format you must match will beat them
every time, because they are the standard your readers are actually holding you to.

Keep all three columns when you override. "Write it like X" with no reason decays into a
preference nobody can argue with, and the anti-model column is doing more work than the
exemplar: it names the specific failure the writer is otherwise about to commit.

This is an index note — keep it under 200 lines. Depth goes in the skill's reference
files, one per document type, at skills/house-voice/references/<doctype>.md.
-->

## The rule behind the picks

**A retrievable corpus of that exact document type. Not fame.**

An agent cannot imitate a sensibility it has never read; it can imitate a corpus. Names
with enormous influence and almost nothing written — Jony Ive is the standing example —
produce reverent adjectives, because the model fills the gap with the *idea* of the
person. Names attached to ten thousand pages of the exact document you are writing
produce the document.

Fame tells you whose taste was influential. It does not tell you whose prose is
imitable.

## The map

| Document | Write it like | And not like |
|---|---|---|
| Product Spec | Shape Up pitch (Ryan Singer); Amazon PR-FAQ | Simon Sinek — a keynote frame with nothing falsifiable under it |
| Decision | Michael Nygard's ADR; Russ Cox for the argument | Meeting minutes — what was discussed, not what was chosen |
| Handoff | Google SRE postmortem register; James Hamilton | A status report — adjectives standing where facts belong |
| Design System | GOV.UK Design System; Dieter Rams as the checklist | Jony Ive — no written corpus, so imitation yields adjectives |
| Design Component | GOV.UK component pages; Julie Zhuo; Don Norman's vocabulary | A Storybook caption — the prop API, never the decision |
| Project | The Amazon six-pager narrative | A Jira epic — percentages and colours with nothing behind them |
| Client | Erika Hall, *Just Enough Research* | A CRM note — sentiment recorded as fact |
| Session Log | A good commit message body; blameless postmortem | A standup update — activity instead of change |
| Test Canon | SRE Workbook SLO chapters | A coverage badge — a percentage as a quality claim |
| Cognitive Coverage | Its own register — diagnostic, banded, dated | A performance review — the thing that kills the practice |
| Vision, strategy memo | Satya Nadella's reframe; Fidji Simo's commitment; Ravi Mehta's stack | Sundar Pichai's shareholder register — engineered not to create news |

Depth for each row — why them, the moves, what to read, the pre-save check — is in
`skills/house-voice/references/<doctype>.md`.

## The moves that hold everywhere

These are true for every document here. The per-type files add four to six more.

- **The problem is longer than the solution.** An unconvinced reader argues with the
  premise all the way through the answer.
- **State the counterargument at its strongest**, then reject it specifically. A
  strawman says you have not thought about it.
- **Mark belief separately from knowledge.** "We measured 1.9s at p95" and "I think this
  is latency-bound" must look different on the page.
- **Follow every abstract claim with a concrete instance**, adjacent, in that order.
- **Numbers, not adjectives.** "Slow" is a feeling.
- **State absence in words** — "not measured", "nobody owns this" — never a blank cell
  or a `TODO`. A blank reads as an oversight; a stated absence is a finding.
- **Cut the throat-clearing.** Delete the first paragraph and see whether anything went
  with it.

## Two things this does not do

**It does not make a document good.** It makes it the right *kind* of document. A
well-voiced spec with no evidence in it is still a bad spec — voice is the last layer,
applied to something that already has content.

**It is never announced.** A document that mentions which writer it is imitating has
failed at imitating them. None of them did that.

---
Related: [[Choosing a Document]] · [[How We Work]] · [[Agent Router]]
