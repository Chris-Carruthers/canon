---
type: reference
status: active
updated: TODO
---

# Choosing a Document

Which document to write, at which stage. **Pick the cheapest one that still works.**

<!--
WHY THIS NOTE EXISTS

The commonest documentation failure here is not writing badly. It is reaching for the
heavyweight document when a cheap one would have done, discovering halfway through that
the idea does not survive contact, and having burned an afternoon to find out. The
second commonest is the reverse: a decision worth a permanent record left in a chat
thread.

A ladder fixes both, because it makes the cheap rung visible and gives the expensive one
an entry condition.

Add a section per template pack you install. Delete rungs you do not use — an aspirational
ladder is worse than a short one, because people stop reading at the first rung that
obviously does not apply to them.
-->

## The ladder

| Stage | Document | Cost | Write it when |
|---|---|---|---|
| An idea worth ten minutes | A message, or a `Sessions/` note | minutes | You want a record that you thought about it |
| A choice being made now | `Decisions/` | ~30 min | Somebody will ask "why is it like this" |
| Work about to start | `Specs/<slug>.product-spec.md` | hours | It is funded, or it needs acceptance criteria |
| Work in flight | `Handoffs/<slug>.handoff.md` | ~30 min, ongoing | Anyone but you might have to pick it up |
| Work finished for today | `Sessions/` | 5 min | Every session. This is the one that must stay cheap |

## Rungs from optional packs

Present only if the pack is installed — `canon-pack list` says which are.

| Stage | Document | Cost | Pack |
|---|---|---|---|
| An idea worth a decision, not yet a plan | One-pager | ~30 min | `product-ladder` |
| Will anybody care? | PR-FAQ | ~2 hours | `product-ladder` |
| The problem is agreed; what fits the appetite? | Shape Up Pitch | ~2 hours | `product-ladder` |
| A real decision, and the room must reason | Six-pager | ~half a day | `product-ladder` |
| A change that needs agreement before it is built | RFC | hours–days | `engineering` |
| A newcomer needs the whole shape | Architecture Overview | hours | `engineering` |
| A procedure will be run again, possibly at 3am | Runbook | ~1 hour | `engineering` |
| Something broke | Postmortem | ~2 hours | `engineering` |
| You talked to people | Research Findings | ~1 hour | `research-craft` |
| A design was reviewed | Design Critique | ~20 min | `research-craft` |
| Interface text is argued about more than once | Content & UX Copy Guide | ~half a day | `research-craft` |

**An RFC and a Decision are both, not either.** The RFC is the argument and changes
under review; the ADR is the immutable record of what it settled. They are read at
different times by different people.

## The two questions that decide it

**Will somebody ask "why is it like this?"** → a `Decisions/` note, now, while the
constraints are still true. The context is what perishes; the decision itself is
recoverable from the code.

**Could somebody else have to pick this up cold?** → a `Handoffs/` note. Including —
especially — the half-finished branch and the manual step.

If the answer to both is no, a session note is enough. Most work is most work.

## Intent and state are two documents, deliberately

A spec is **intent**: what and why. A handoff is **state**: where the code is, what is
merged, what is unapplied, what is broken.

They are separate because they change at different rates and are read by different
people at different moments. Merging them produces a document that is either stale on
intent or unusable in an incident. The handoff cites its spec by path rather than
restating it — restated intent drifts silently while reading as authoritative.

## Do not open with the expensive rung

A full spec is the wrong first artefact for an unproven idea. It takes long enough that
finishing it feels like progress, and it produces acceptance criteria for something
nobody has yet agreed is worth building. Write the cheap rung, find out, then escalate.

The inverse failure is real too and it is worse: a decision that reshapes a system,
recorded nowhere, rediscovered eighteen months later by somebody re-deriving it from the
code. Cheap is the default, not the rule.

---
Related: [[House Voice]] · [[How We Work]] · [[Agent Router]]
