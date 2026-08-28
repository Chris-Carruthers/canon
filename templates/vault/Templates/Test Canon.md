---
type: test-canon
title: "<Team or Product Name>"
status: active           # active | proposed | absent
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
File as: Reference/Testing/<Name> — Current State.md

WHY THIS SHAPE. Tests are code, and code stays out of the vault. So this note
holds the part that is NOT code: what is tested, what deliberately is not, what
the floor is, who owns the gate, and who is able to make that gate binding. A
reader — human or agent — should leave knowing whether a green tick means
anything here.

"Nothing is tested and nobody owns it" is a valid and valuable first line. An
honest absence is a finding; a hopeful blank is a lie that costs somebody an
afternoon and, eventually, a production incident.

THE RULE THAT MATTERS MOST:
  A FLOOR IS A RATCHET, NOT A TARGET.
  Set each floor to the coverage the branch ALREADY has, rounded down. It only
  ever goes up. A floor set to where you wish you were fails from day one, gets
  muted within a week, and then measures nothing at all — while still looking
  like a control to anyone reading the config.

THE SECOND RULE:
  A GATE NOBODY MADE REQUIRED IS A DECORATION.
  A workflow that runs, reports, and cannot block a merge is advice. Record that
  honestly in `required:` rather than assuming, because the difference is
  invisible from the repo and is the single most common reason a team believes it
  is gated when it is not.

Delete sections that do not apply. Keep this file under 200 lines: it is an index
note, and index notes are read in full.
-->

## What this covers

One paragraph. Which repos and which layers (unit, integration, end-to-end), and
what is deliberately out of scope. Out-of-scope-on-purpose is information; silence
is not.

## Ownership

**Decide this before anything else here is worth writing.** These are
placeholders. Nobody outside your team can fill them in.

| Role | Who | Evidence |
|---|---|---|
| Owns the suite | `<name>` | |
| Owns the CI gate | `<name>` | |
| **Can make a check required** | `<name>` | |
| Accountable if it stalls | `<name>` | |

<!--
HOW TO DECIDE THIS, if it is not obvious.

  Owns the suite       whoever decides what is worth testing, and says no to a
                       test that asserts the mock. Usually a senior engineer.
  Owns the CI gate     whoever keeps the workflow green and honest — including
                       noticing when it silently stopped running.
  Can make a check     THE ONE PEOPLE FORGET, and the reason this row is bold.
  required             Branch protection needs repo-admin rights, which most
                       engineers do not have. A team can merge a dozen PRs
                       building gates and still be ungated because nobody with
                       admin ever flipped the switch — and a normal member's
                       token cannot even tell the difference between "not
                       required" and "you may not look". Name the person with the
                       rights, not the person who wants it done.
  Accountable          who unblocks the other three when they disagree.

One person can hold several roles. Nobody holding a role is also an answer.

WRITE "unowned" IF THAT IS TRUE, along with what you checked to conclude it.
Evidence means how you know — a ticket, a decision note, the person's own
confirmation. "We assumed" is not evidence, and is the same as none.
-->

## What a green tick means here

Two sentences, plainly. Which of the gates below can actually block a merge, and
which only report. If the answer is "none of them can block", say so here — it is
the most important line in the note.

## Reading a percentage

The number lies in a predictable direction: **a test that merely imports a module
takes it from 0% to 100%.** An app-boot test importing the router does verify that
routes register — and it is not a thousand lines of tested behaviour, though it
moves the percentage as if it were. Put effort into the seams that have actually
caused incidents, which in practice are wiring rather than logic, and treat a jump
in the number as a question rather than an achievement.

## Adherence

*How to measure*, never a measurement:

- `canon-test-audit <repo>…` — derives findings from this canon plus the coverage
  reports your suites already wrote, every run
- `canon-test-audit --ratchet <repo>…` — prints the floor each suite could claim
  today. Copy it in yourself; the tool never edits this note
- Latest report: the newest `Outputs/<date> — Test Canon Audit.md`

**No percentage is written in this note.** Numbers go stale the day after you type
them, and a stale number in a note that reads as authoritative is worse than no
number at all.

## Open Questions

Link the `Decisions/` notes. Every team has at least one: the untested subsystem
everyone knows about, or the gate that cannot be made required yet.

## Related

One level deep. Do not build a link ladder.

<!--
================================================================================
BLOCK CONTRACTS — FROZEN. Must match bin/canon-test-audit exactly.
================================================================================
These two fenced blocks are the machine-readable half of the canon.
canon-test-audit GLOBS the Reference/Testing/ subtree for them rather than
reading a fixed filename, so a block can move to a sibling note freely.

The names are namespaced on purpose: `test-suites`, not `suites`. A generic fence
name collides with the next tool that wants one.

If you change a key here, change it in bin/canon-test-audit in the SAME commit.
The kit already has two scars from ignoring this. A Product Spec template whose
fence names never matched the validator written against it, so every file made
from the template failed the check. And an annotated block that its own validator
could not parse, which produced four errors from a copy-paste of the documented
example and silently disabled the rule being documented. Both blocks below are
therefore parsed as part of the test suite, comments and all.

```test-suites
- suite: <kebab-slug>                    # required, unique
  repo: <repo-name>                      # required, matches the directory name
  command: pytest -q                     # how a HUMAN runs it. never parsed
  report: coverage.xml                   # repo-relative path the suite writes
  format: cobertura                      # cobertura | lcov | json-summary
  metric: lines                          # lines | statements | branches | functions
  floor: 62                              # the ratchet. omit if not ratcheted yet
  status: enforced                       # enforced | advisory | absent
  note: "[[Decision — why 62]]"          # only if a note exists
```

```test-gates
- gate: <kebab-slug>                     # required, unique
  repo: <repo-name>                      # required
  workflow: .github/workflows/ci.yml     # required, repo-relative
  job: test                              # the job that must pass
  branches: [Dev]                        # CASE-SENSITIVE, verbatim
  required: false                        # can it block a merge? see rule 4
  verified: { by: human:<id>, at: <iso> } # who confirmed `required`, via canon-verify
  note: "[[Decision — gate scope]]"      # only if a note exists
```

SEVEN RULES. Each one exists because it is the thing that gets got wrong.

1. OMIT A KEY YOU DO NOT HAVE. Never TODO, TBD, ?, or an empty value. Absence is
   the machine-readable signal, and coverage is DERIVED from it. A row full of
   TODOs reports as complete-but-broken instead of honestly incomplete.

2. `branches:` IS CASE-SENSITIVE AND VERBATIM. This is the highest-value field in
   either block. A workflow filtered on `dev` against a branch named `Dev` runs on
   NOTHING: no run, no failure, no signal, and a PR list that looks clean. One
   real suite ran on zero of thirty-five pull requests this way while everyone
   involved believed it was gating. Write the branch exactly as git spells it.

3. `report:` MUST BE THE SUMMARY, NOT THE RAW DUMP. istanbul writes both:
   `coverage/coverage-summary.json` has the totals, `coverage-final.json` is
   per-file raw data and has no total at all. Naming the wrong one is the most
   common json-summary mistake, so the audit diagnoses it by name.

4. `required:` IS A HUMAN ATTESTATION, NOT AN OBSERVATION. Nothing in a checkout
   can see branch protection — it is server-side state. So the audit never infers
   it, and treats `required: true` without a `verified:` entry as unconfirmed.
   Record it with `canon-verify` once you have actually looked at the setting.

5. A FLOOR ONLY GOES UP. Set it to what you already have, rounded down. Use
   `--ratchet` to see what each suite could claim; it deliberately refuses to
   suggest a LOWER number, because lowering a floor is how a ratchet quietly
   becomes a target.

6. `status: absent` IS A LEGITIMATE, HIGH-VALUE ROW. "There is no frontend suite"
   stops an agent hunting for one, stops the audit reporting a gap that is really
   a decision, and tells a reader the truth. Absence recorded is cheaper than
   absence rediscovered.

7. `metric:` MUST BE ONE THE FORMAT CARRIES. cobertura has no statement counter;
   lcov has no statements either. Asking for one is not a rounding error, it is a
   different measurement wearing the label you asked for, so the audit refuses
   rather than substituting.
-->
