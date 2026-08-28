# Voice: Runbook

## Write it like

**Primary — the Google SRE Book's playbook material.** Numbered, imperative, one action
per step, expected output stated.

**Supporting — aviation checklists**, which are the mature version of this discipline:
terse, ordered, and designed for somebody whose judgement is degraded.

## Why them

Every formatting rule in a runbook follows from one fact about its reader: **they are
frightened, it is 3am, they have not done this before, and they may be interrupted
halfway through.** The SRE playbook register is built for that reader. Numbered steps
survive an interruption because you can find your place; prose does not. One action per
step means a partial completion is unambiguous. An expected output means the reader can
tell whether it worked rather than carrying on and hoping.

Aviation checklists are worth reading precisely because they are so austere. They
assume competence and reject prose entirely, and the reason is the same: under stress,
reading comprehension collapses long before procedural ability does.

## Do not write it like

**A tutorial.** Explanatory paragraphs, background on why the system works this way,
options presented for the reader to choose between.

Every one of those is actively harmful at 3am. Background reading costs time the reader
does not have. A paragraph cannot be resumed after an interruption because there is no
place-marker in it. And a choice presented to a frightened person who has not done this
before is not empowerment — it is the document declining to do its job, and they will
pick wrong.

The second failure is **the step with no expected output**. It cannot be checked, so
the reader cannot tell whether it worked, so they proceed regardless. That is the
mechanism by which a runbook makes an incident worse than having none, and it is
invisible until it happens.

## The moves

**Numbered steps, one action each.** No paragraphs anywhere in the procedure.

**State what you expect to see after every step**, and what it means if you see
something else.

**Exact commands, copy-pasteable.** Not "restart the service" — the command, with the
real flags.

**Mark destructive steps before the step, not after.** A warning underneath a command
is read second.

**If there is no rollback, say so in those words**, in its own section. That is the
most important sentence in the document and it must not be discovered halfway through.

**Record when it was last actually run, and by whom.** A procedure nobody has executed
in a year is a hypothesis about your own system, not a runbook.

**Name a person to wake, with a fallback.** A rota link is fine; a team name is not —
at 3am nobody knows who is on the team.

## Go read

- Google SRE Book, "Being On-Call" and "Emergency Response" — <https://sre.google/sre-book/table-of-contents/>
- The Site Reliability Workbook, on playbooks — <https://sre.google/workbook/table-of-contents/>
- Atul Gawande, *The Checklist Manifesto* — on why the austerity is the feature

## Before saving

1. Is every step numbered, imperative, and a single action?
2. Does every step state what you expect to see, and what a different result means?
3. Are destructive steps flagged **before** the command rather than after?
4. Does it say plainly whether a rollback exists — including when it does not?
5. Is the date it was last actually run recorded, and is it recent enough to trust?
