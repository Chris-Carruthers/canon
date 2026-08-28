---
type: handoff
status: active
implements: "Specs/<slug>.product-spec.md"
spec_revision: 1
project: "[[Project Name]]"
repo: path/to/repo
updated: YYYY-MM-DD
---

# Handoff: <title>

> Implements `Specs/<slug>.product-spec.md` (spec_revision 1). Intent lives in
> the spec and stays the source of truth; this is the **ops how and state** —
> what the next person or agent needs to pick this up cold.

<!--
Voice: skills/house-voice/references/handoff.md — your own map wins: Reference/Writing/House Voice.md
The test for this document: someone who has never seen the work reads only this
and can continue it without asking you anything. If you would have to explain
something out loud, it belongs here.

Write down the embarrassing things especially — the half-rebased branch, the
temporary route, the manual step you always forget. Those are exactly what is
lost when work changes hands, and nobody ever writes them because they feel like
admissions rather than documentation.
-->

## TL;DR state

One line: what is built, what is merged, what is blocking.

## Acceptance criteria status

Mirror the spec's criteria and mark each with evidence, so intent alignment is
checkable rather than assumed.

- [ ] AC-1 <criterion> — how and where verified

## Where the code lives

| Part | Branch / PR | Path | Merged? |
|---|---|---|---|
| | | | |

## What works

Done *and verified* — say how it was verified. "It should work" is not verified.

## What is NOT done

Unmerged branches, uncommitted work, temporary routes, stubbed behaviour,
anything that only works on one machine.

## Prerequisites to run or deploy

- **Migrations / schema:** ...
- **Environment / configuration:** ... *(names only — never paste secrets)*
- **Jobs / infrastructure:** ...
- **Manual steps:** the ones that are not automated yet

## Open incidents and risks

Live bugs, known failure modes, things that will break under load.

## Open Questions

- [ ] ...

## Next steps

- [ ] ...

---
Related: Spec: [[<slug>.product-spec]] · Project: [[ ]] · Decisions: [[ ]]
