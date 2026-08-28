# Pack: engineering

> RFC, architecture overview, runbook, postmortem — the documents a system needs.

## What this is for

canon's core can record a decision and hand work over. It cannot **argue** for a
decision before it is made, describe a system as a whole, tell somebody what to do at
3am, or account for an incident afterwards.

The gap that matters most is the first one. An ADR is retrospective by design: it
records what was chosen and why, after the choosing. There is no template for the
document that does the persuading — the Oxide RFD, the Go proposal, the design doc that
goes round for two weeks before anyone writes code. Teams that lack it either decide in
chat and lose the reasoning, or write an ADR pre-emptively and pretend the argument
already happened.

| Template | Write it when |
|---|---|
| RFC | A significant change needs agreement before it is built |
| Architecture Overview | A newcomer needs the whole shape, including the failure modes |
| Runbook | A procedure will be run again, possibly by somebody frightened |
| Postmortem | Something broke and the learning is worth more than the blame |

An RFC that is accepted usually produces a `Decisions/` note: the RFC is the argument,
the ADR is the durable record of what it settled. Keep both; they are read at different
times by different people.

## When not to install this

If your team runs nothing in production, Runbook and Postmortem are aspirational
paperwork. Install the pack and delete those two rather than leaving them empty — an
unused template still signals that somebody should be filling it in.

## Voice

`skills/house-voice/references/rfc.md`, `architecture-overview.md`, `runbook.md`,
`postmortem.md`. Overridable at `Reference/Writing/House Voice.md`.
