---
type: postmortem
incident: "<short name>"
date: YYYY-MM-DD
severity: <sev level>
duration: "<detection to resolution>"
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/postmortem.md — your own map wins: Reference/Writing/House Voice.md
File as: Reference/Postmortems/YYYY-MM-DD — <Incident>.md

BLAMELESS, AND THAT IS A MECHANISM RATHER THAN A COURTESY. A writer who expects to
be judged writes a vaguer document, and the vagueness is the actual loss. Blameless
is what makes accuracy cheap.

"HUMAN ERROR" IS NEVER A ROOT CAUSE. If a person could take the system down by
doing a reasonable-looking thing, the finding is that the system allowed it. Every
"they should have known" is a missing runbook, a missing guard, or a missing alert —
name which.

WRITE THE TIMELINE IN UTC AND IN THE ORDER IT HAPPENED, including the wrong
diagnoses. The time spent chasing the wrong cause is usually the largest number in
the incident and it is the one most often edited out.

ACTIONS WITH NO NAMED OWNER DO NOT HAPPEN. This is the only section anybody checks
again in three months.
-->

# Postmortem: <Incident>

**Impact:** who was affected, how many, for how long, and what they could not do.
**Detected by:** an alert, or a customer. Say which — it is a finding either way.

## Timeline

All times UTC. Include the wrong turns.

| Time | What happened |
|---|---|
| HH:MM | |

## What happened

The narrative, in prose, once. What was true about the system that allowed this.

## Why it happened

The chain of causes, not a single one. Keep going past the first plausible stopping
point — the first answer is usually the last change, which is rarely the reason the
change was dangerous.

## Why it took as long as it did to detect

Frequently the biggest finding in the whole document, and the easiest to skip.

## Why it took as long as it did to fix

Missing access, missing runbook, missing knowledge, wrong first diagnosis. Say which.

## What went well

Not a formality. The thing that limited the blast radius is worth knowing about, and
it is usually something somebody built deliberately and never got told about.

## Actions

Every one owned by a **named person** with a date. An action with no owner is a wish.

| Action | Owner | By | Prevents recurrence, or reduces impact? |
|---|---|---|---|

## Where the gap really was

If the answer is "somebody should have known", the gap is a missing runbook, guard or
alert. Name which one, and put it in the table above.

---
Related: Runbook [[ ]] · Architecture [[ ]] · Project [[ ]]
