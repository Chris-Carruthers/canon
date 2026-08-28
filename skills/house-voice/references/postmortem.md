# Voice: Postmortem

## Write it like

**Primary — the Google SRE Book's postmortem chapter and its worked example.** Blameless
by construction, timeline first, actions owned.

**Supporting — the NTSB accident-report register**, for how to hold "what happened" and
"why the system allowed it" apart across a long document.

## Why them

Blameless is not politeness — it is **a mechanism for accuracy**. A writer who expects
to be judged writes a vaguer document, and the vagueness is the actual loss. Remove the
threat and people write down the thing they were confused about at 02:14, which is
usually the finding.

The SRE example postmortem is the best single artefact to imitate because it does the
hard thing in public: it records the wrong diagnosis, the time spent chasing it, and
the moment somebody realised. Most postmortems edit that out, and the edit removes the
largest number in the incident.

The NTSB register supplies the discipline of separating the event chain from the
systemic finding. "The valve was closed" and "nothing prevented the valve from being
closed" are different sentences that appear in different sections, and conflating them
is how an investigation ends at a person.

## Do not write it like

**A blame narrative.** Anything that terminates in "human error", "they should have
known", or a named individual as the cause.

Beyond being unkind, it is **analytically wrong and it stops the investigation early**.
If a person could take the system down by doing a reasonable-looking thing, the finding
is that the system allowed it — the missing guard, the missing alert, the runbook that
did not exist, the confirmation prompt that was not there. Every "they should have
known" is a documentation gap wearing a person's name, and naming the person means
nobody fixes the gap.

The second failure is **the single root cause.** Real incidents have chains. Stopping
at the first plausible cause usually lands on the last change, which is rarely the
reason the change was dangerous — and the action item that follows is "be more careful
next time", which is not an action item.

## The moves

**Timeline in UTC, including the wrong turns.** The time spent chasing the wrong cause
is usually the biggest number in the incident and the most commonly edited out.

**Separate why it happened from why it took so long to detect** and **why it took so
long to fix.** They have different causes and different fixes, and the detection one is
frequently the largest finding in the document.

**Keep going past the first plausible cause.** Ask what allowed it, then what allowed
that.

**"Human error" is never a root cause.** Name the missing guard, alert or runbook
instead — and put it in the actions table.

**Every action has a named owner and a date.** This is the only section anybody checks
again in three months. An unowned action is a wish.

**Write what went well, and mean it.** The thing that limited the blast radius is
usually something somebody built deliberately and was never told about.

## Go read

- Google SRE Book, "Postmortem Culture" — <https://sre.google/sre-book/postmortem-culture/>
- Google SRE Book, example postmortem — <https://sre.google/sre-book/example-postmortem/>
- The Site Reliability Workbook, "Postmortem Culture in Practice" — <https://sre.google/workbook/postmortem-culture/>
- Any NTSB accident report, for the separation of event chain from systemic finding

## Before saving

1. Does the timeline include the wrong diagnoses and the time they cost?
2. Are "why it happened", "why detection was slow" and "why the fix was slow" separate?
3. Does the causal chain go past the first plausible stopping point?
4. Is "human error" absent — replaced by the missing guard, alert or runbook?
5. Does every action have a named owner and a date?
