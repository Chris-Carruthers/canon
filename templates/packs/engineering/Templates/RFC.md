---
type: rfc
rfc: <nnnn>
status: draft            # draft | discussion | accepted | rejected | withdrawn | superseded
authors: ["<name>"]
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/rfc.md — your own map wins: Reference/Writing/House Voice.md
File as: Decisions/RFC-<nnnn> — <Title>.md

AN RFC ARGUES; AN ADR RECORDS. This is the distinction the pack exists for. A
Decision note is written after the choosing and is immutable. An RFC is written
before, is expected to change under review, and its job is to persuade. Writing an
ADR pre-emptively — recording a decision the team has not actually had yet — is the
commonest way to lose the argument while appearing to document it.

An accepted RFC usually produces a Decisions/ note. The RFC is the argument; the
ADR is the durable record of what it settled. Keep both.

NUMBERED AND NEVER DELETED. A rejected RFC is the most useful kind: it is the
written answer to "why don't we just…", and without it the same proposal returns
every eight months.

STATUS IS THE ONE FIELD PEOPLE FORGET. An RFC in `draft` for four months is a
decision nobody made. Say so, or withdraw it.
-->

# RFC-<nnnn>: <Title>

## Summary

Three sentences. What changes, for whom, and what it costs. A reader who stops here
should know whether they need to read on.

## Motivation

The problem, at length, with evidence. **Make this longer than the proposal.** A
reader who is not yet convinced the problem is real spends the whole design section
arguing with the premise, and nothing you wrote lands.

What breaks today. What it costs. Who has hit it, and when.

## Proposal

The design. Concrete enough to be criticised — an unimplementable proposal is
usually one nobody could find the flaw in.

## Alternatives considered

Each stated **at its strongest**, then rejected for a specific reason. Not "too
complex" — what complexity, and why it mattered more than what the alternative would
have bought. A strawman here signals you have not taken the space seriously, and it
is the most reliable way to lose a reviewer.

Include "do nothing". It is sometimes right, and a proposal that has not priced it
has not been tested.

## What this costs

Migration, operational burden, the thing that gets worse. Every real change makes
something worse; naming it is how a reader knows it was priced rather than missed.

## Open questions

The parts you have not resolved, stated as questions rather than smoothed over.
Marking uncertainty as uncertainty is the single largest credibility move available
here.

- [ ] ...

## Unresolved / rejected in review

What came up, and how it was answered. This is what stops the same objection
returning after acceptance.

---
Related: Decision [[ ]] · Project [[ ]] · Supersedes [[ ]]
