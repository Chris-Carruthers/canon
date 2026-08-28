---
type: runbook
procedure: "<what this does>"
severity: routine        # routine | urgent | incident-only
owner: "<named person>"
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/runbook.md — your own map wins: Reference/Writing/House Voice.md
File as: Reference/Runbooks/<Procedure>.md

WRITTEN FOR SOMEBODY FRIGHTENED, AT 3AM, WHO HAS NOT DONE THIS BEFORE. Every
formatting decision follows from that. Numbered steps, one action each, exact
commands, expected output stated. No paragraphs — prose is unreadable under stress
and impossible to resume after an interruption.

STATE WHAT YOU EXPECT TO SEE. A step with no expected output cannot be checked, so
the reader cannot tell whether it worked, so they carry on regardless. That is how a
runbook makes an incident worse.

SAY WHAT IS DESTRUCTIVE, BEFORE THE STEP. Not after, not in a footnote.

AN UNTESTED RUNBOOK IS FICTION. Record when it was last actually run. A procedure
nobody has executed in a year is a hypothesis about your own system.
-->

# Runbook: <Procedure>

**Last actually run:** YYYY-MM-DD by `<name>` · **Takes:** ~<n> minutes

## When to run this

The trigger. And **when not to** — the near-miss situation where somebody reaches for
this and should not.

## Before you start

- Access you need, and who grants it if you do not have it
- What you should have open
- Anything that must be true first

## Steps

1. **<Action.>**
   ```
   <exact command>
   ```
   Expect: `<what you should see>`
   If instead you see `<X>`: <what that means, what to do>

2. **<Action.>**
   ⚠️ **Destructive** — this <what it does>. Confirm <what> before running it.
   ```
   <exact command>
   ```
   Expect: `<what you should see>`

## How to tell it worked

The specific check. Not "everything looks fine" — the query, the endpoint, the log
line.

## If it goes wrong

The rollback, as numbered steps. If there is no rollback, **say so here in those
words** — that is the most important sentence in the document and it must not be
discovered halfway through.

## Who to wake

Named person, then the fallback. A rota link is fine; a team name is not.

---
Related: Architecture [[ ]] · Postmortems [[ ]]
