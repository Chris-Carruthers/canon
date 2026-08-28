# Voice: Test Canon

## Write it like

**Primary — the SRE Workbook's SLO and error-budget chapters.** A number set to what is
already true, owned by a named person, with a stated consequence when it is missed.

**Supporting — *Software Engineering at Google*** (Winters, Manshreck, Wright) on
testing culture, for writing about coverage without pretending it is quality.

## Why them

The SLO chapters are the right model because an SLO and a coverage floor are the same
object: **a number that only means something if somebody is accountable when it is
breached.** The SRE material is unusually disciplined about this. It insists the target
be derived from measured reality rather than aspiration, it names the owner, and it
states what happens when the budget is spent. Remove any one of the three and you have a
dashboard.

*Software Engineering at Google* supplies the honesty about what coverage is. It is a
measure of what is *executed*, not what is *verified* — a distinction most writing about
testing elides, and eliding it is how a repository ends up with a high number and no
confidence.

## Do not write it like

**A coverage badge.** A percentage presented as a quality claim, with no statement of
what is excluded, who set the number, or what happens when it drops.

The specific failure this register enables is the **inflated denominator**: a module that
jumps from 0% to 100% because an import executed its top level, dragging the repository
number up while nothing was tested. A badge cannot express that. A sentence can, and
must.

The second failing register is **the aspiration**: a floor set to where the team wishes
it were. It fails from day one, gets muted within a week, and then measures nothing at
all — while still looking like a control to anyone reading the config. That is worse
than no floor, because it consumes the credibility a real one would have needed.

## The moves

**Set the floor to what the branch already has, rounded down.** A ratchet, not a target.
Write it that way, and say so, because the next person's instinct will be to raise it
aspirationally.

**Say what is deliberately not tested, and why.** An honest exclusion is a finding.
Silence reads as coverage.

**Name who can make the gate binding, separately from who owns the tests.** These are
usually different people, and the second is often an administrator nobody has asked. A
gate nobody made required is a decoration, and the note should say plainly whether this
one is.

**Distinguish executed from verified.** Say which the number measures. If a jump came
from an import rather than a test, write that down — it is the most misleading artefact
in the whole discipline.

**Report the gate's actual run history, not its configuration.** A workflow that is
configured correctly and has never fired is not a gate. Branch filters are
case-sensitive; the config is not the evidence.

**"Nothing is tested and nobody owns it" is a valid first line.** An honest absence is a
finding; a hopeful blank costs somebody a production incident.

## Go read

- The Site Reliability Workbook, "Implementing SLOs" — <https://sre.google/workbook/implementing-slos/>
- Google SRE Book, "Service Level Objectives" — <https://sre.google/sre-book/service-level-objectives/>
- Winters, Manshreck & Wright, *Software Engineering at Google* — the testing chapters

## Before saving

1. Is every floor set to measured reality rather than to an aspiration?
2. Does the note say what is deliberately **not** tested?
3. Does it state whether the gate is actually required, and name who can make it so?
4. Does it distinguish code that is executed from code that is verified?
5. Is the gate's real run history recorded, rather than its configuration?
