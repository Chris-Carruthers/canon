---
name: house-voice
description: This skill should be used before writing or revising any vault document — a product spec, one-pager, PR-FAQ, six-pager or Shape Up pitch, decision note or RFC, handoff, runbook, postmortem, architecture overview, design system or component note, design critique, research findings, content style guide, project or client note, session note, or a strategy memo or vision document. Also use it when the user asks how a document should read, asks for a rewrite, says a draft "reads wrong", or asks which writer to imitate. Maps each document type to a named exemplar with a real corpus, the moves to imitate, and the anti-model to avoid.
version: 0.1.0
---

# House Voice

Every document type has a register that works and several that fail. This says which,
per type, by pointing at somebody who already writes it well.

## Why this exists

The templates in `Templates/` specify **what sections a document has**. Nothing
specifies **how it should read**. So the structure is enforced and the prose is
improvised, and improvised prose defaults to whatever register the writer last saw:

- A Decision note becomes meeting minutes — who attended, what was discussed, no
  statement of what was chosen or what it cost.
- A Handoff becomes a status report — the unmerged branch marked "in progress", which
  is an adjective standing where a fact should be.
- A Design System note becomes reverent adjectives about craft, with no rule anybody
  can apply.

Each of those documents passes its template check. Each is useless to the next person.

## The selection criterion

**A retrievable corpus of that exact document type. Not fame.**

This is the whole trick, and it is why the reference files name some people you would
not expect and refuse some you would.

An agent cannot imitate a sensibility it has never read. It can imitate a corpus. Ask
for "write it like Jony Ive" and you get reverent adjectives about materials, because
Ive spoke in product films and left almost nothing written — there is no corpus behind
the name, so the model fills the gap with the *idea* of him. Ask for "write it like a
GOV.UK Design System component page" and you get *when to use this / when not to use
this / how it works / research on this component*, because ten thousand pages of
exactly that exist and the model has read them.

Fame tells you whose taste was influential. It does not tell you whose prose is
imitable. Those are different questions and only the second one helps here.

## The failure mode to avoid

**Costume.** Copying a writer's mannerisms instead of their moves.

Mannerisms are the em-dashes, the short punchy fragment, the rhetorical question. They
transfer instantly and buy nothing. Moves are structural: *the problem section is
longer than the solution section*; *the counterargument is stated at its strongest
before it is rejected*. They are what make the document work, and they survive being
copied because they are about what the document contains, not how it sounds.

If a rewrite changed the rhythm and not the content, it failed. Check that first.

The second failure is **genre collision** — applying one type's register to another.
A vision document that reads like a spec commits to numbers it cannot defend. A spec
that reads like a vision document has a stirring opening and nothing falsifiable under
it. The reference files are split by genre for this reason; picking the right file
matters more than executing it well.

## Procedure

### 1. Identify the document type

From the template being used, the target folder, or the ask. If it is genuinely
ambiguous — someone wants "a doc about X" — read
`Reference/Writing/Choosing a Document.md` in the vault, which is the escalation ladder:
which document at which stage, and the cheapest one that still works.

Do not guess between two types. The register differs more between genres than within
one, so a wrong pick costs more than a mediocre execution.

### 2. Check for a local override, then read the reference file

`Reference/Writing/House Voice.md` in the vault is the team's own map, and **it wins**.
The files here are canon's defaults; a team that has named its own exemplars has done
the more valuable thing and their choice governs.

Otherwise, open the matching file:

| Document | Reference |
|---|---|
| Product Spec | [references/product-spec.md](references/product-spec.md) |
| Decision | [references/decision.md](references/decision.md) |
| Handoff | [references/handoff.md](references/handoff.md) |
| Design System | [references/design-system.md](references/design-system.md) |
| Design Component | [references/design-component.md](references/design-component.md) |
| Project | [references/project.md](references/project.md) |
| Client | [references/client.md](references/client.md) |
| Session Log | [references/session-log.md](references/session-log.md) |
| Test Canon | [references/test-canon.md](references/test-canon.md) |
| Cognitive Coverage | [references/cognitive-coverage.md](references/cognitive-coverage.md) |
| Vision, strategy memo | [references/strategy-narrative.md](references/strategy-narrative.md) |

Optional template packs (`canon-pack add <pack>`) bring more document types. Their
reference files ship here whether or not the pack is installed — a skill costs nothing
until it loads, and a template arriving without its voice is the worse failure:

| Document | Pack | Reference |
|---|---|---|
| One-pager | `product-ladder` | [references/one-pager.md](references/one-pager.md) |
| PR-FAQ | `product-ladder` | [references/pr-faq.md](references/pr-faq.md) |
| Six-pager | `product-ladder` | [references/six-pager.md](references/six-pager.md) |
| Shape Up Pitch | `product-ladder` | [references/shape-up-pitch.md](references/shape-up-pitch.md) |
| RFC / Design Proposal | `engineering` | [references/rfc.md](references/rfc.md) |
| Architecture Overview | `engineering` | [references/architecture-overview.md](references/architecture-overview.md) |
| Runbook | `engineering` | [references/runbook.md](references/runbook.md) |
| Postmortem | `engineering` | [references/postmortem.md](references/postmortem.md) |
| Research Findings | `research-craft` | [references/research-findings.md](references/research-findings.md) |
| Design Critique | `research-craft` | [references/design-critique.md](references/design-critique.md) |
| Content & UX Copy Guide | `research-craft` | [references/content-style-guide.md](references/content-style-guide.md) |

Each file is the same six parts: who to write like · why them · who **not** to write
like and what goes wrong · the moves · what to go read · the pre-save check.

### 3. Apply the moves that hold everywhere

These are true for every document type in the vault. The reference file adds four to
six more that are specific to its genre.

**The problem is longer than the solution.** If the reader is not convinced the problem
is real and precisely shaped, the solution is unreadable — they spend it arguing with
the premise. Most weak documents invert this ratio and fail for exactly that reason.

**State the counterargument at its strongest.** Then reject it for a specific reason.
A strawman tells the reader you have not thought about it; a fair statement followed by
a concrete rejection is the single largest credibility move available in a technical
document.

**Mark belief separately from knowledge.** "We measured 1.9s at p95" and "I think this
is latency-bound" are different claims and must look different on the page. Blurring
them is how a guess becomes a requirement three documents downstream.

**Follow every abstract claim with a concrete instance.** Rule, then example, in that
order, adjacent. A principle with no instance is unfalsifiable and gets ignored.

**Numbers, not adjectives.** "Slow" is a feeling. "1.9s p95 against a 900ms target" is a
fact somebody can act on, disagree with, or measure again next month.

**State absence in words.** "Not measured", "not designed", "nobody owns this" — never
a blank cell or a `TODO`. A blank is indistinguishable from an oversight; a stated
absence is a finding somebody can pick up. This is the same rule the design canon
applies to resolution rungs, for the same reason.

**Cut the throat-clearing.** Delete the first paragraph and check whether anything was
lost. Usually it was context the reader already has, or an announcement of what the
document is about, which the title did.

### 4. Run the pre-save check

Each reference file ends with five yes/no questions specific to its type. Answer them
literally, on the draft, before saving. A "no" is a rewrite, not a caveat to mention in
the summary.

## When to override, and how

Canon's defaults are opinionated so a new vault is not blank. They are not a house
style you inherited and cannot change.

A team should override when it has a **better exemplar for its own domain** — a
regulator's published guidance, a predecessor's document everybody already imitates, a
customer whose format you must match. Record it in
`Reference/Writing/House Voice.md`, with the same three fields the shipped files use:
who, why them, and what goes wrong without them. An override with no stated reason
decays into a preference nobody can argue with.

Do not override to remove the anti-model. The anti-model is doing more work than the
exemplar — it names the specific failure the writer is otherwise about to commit.

## Notes

**Cite, do not paste.** The reference files link to the real documents rather than
reproducing them. Go read the source when the summary is not enough; a paraphrase of a
paraphrase is how a distinctive corpus becomes generic advice.

**This does not make a document good.** It makes it the right *kind* of document. A
well-voiced spec with no evidence in it is still a bad spec — voice is the last layer,
applied to something that already has content.

**Do not announce it.** A document that mentions which writer it is imitating has
failed at imitating them. None of them did that.
