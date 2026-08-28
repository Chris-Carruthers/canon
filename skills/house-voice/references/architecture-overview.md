# Voice: Architecture Overview

## Write it like

**Primary — James Hamilton**, "On Designing and Deploying Internet-Scale Services", for
reasoning from constraints and failure rather than from structure.

**Supporting — the Google SRE Book's** service-description chapters, and **Martin
Kleppmann's** *Designing Data-Intensive Applications* for explaining a system's
properties rather than its parts.

## Why them

Hamilton's register is built on the observation that **the interesting facts about a
system are the ones that hold when something is broken.** His writing is dense with
failure rates, cost per unit, what happens at the tail — and almost empty of
box-and-arrow description, because structure is the cheap half and the code already
carries it.

Kleppmann is the model for explaining *why the boundary is where it is*. That is the
question a newcomer actually has and the one a diagram cannot answer: which splits are
load-bearing, which are historical accident, and what was tried before. A reader cannot
tell those apart from the code, so they treat all of them as sacred and route around
the ones that should have been fixed.

## Do not write it like

**A diagram with captions.** Boxes, arrows, a paragraph naming each component, and
nothing about what happens when an arrow stops working.

The failure is that this register documents the part that is already visible. Anybody
can read the repository and see that there is a queue between two services; what they
cannot see is that the queue exists because of a specific incident, that it silently
drops on overflow, and that nobody is alerted when it does. A diagram-with-captions
overview is reassuring to write, passes review because nothing in it is wrong, and
leaves the reader with exactly the knowledge they already had.

The second failure is **omitting the ugliness**. An overview that describes the
intended architecture rather than the real one costs the next person a week
rediscovering the difference, and a second week assuming it was deliberate.

## The moves

**Write the failure table before the component table.** Per dependency: what happens
when it is unavailable, whether we degrade or stop, whether anybody finds out. Name the
silent failures specifically — those are the ones the code will not tell you about.

**Say which boundaries are load-bearing and which are accident.** This single
distinction is the most useful thing in the document and it exists nowhere else.

**State what is stored, where, and who else can change it.** The question that decides
whether somebody can safely make a change.

**Name what the system deliberately does not do**, and what breaks if somebody assumes
otherwise.

**Record the known ugliness with `repo/path:line`.** The parts that are wrong and known
to be wrong. Writing them down is what converts a trap into a task.

**Prose before diagram, always.** A diagram cannot express "usually", "unless the cache
is cold", or "this arrow has never actually been tested".

## Go read

- James Hamilton, "On Designing and Deploying Internet-Scale Services" — <https://www.usenix.org/legacy/events/lisa07/tech/full_papers/hamilton/hamilton.pdf>
- Perspectives — <https://perspectives.mvdirona.com/>
- Martin Kleppmann, *Designing Data-Intensive Applications*
- Google SRE Book — <https://sre.google/sre-book/table-of-contents/>

## Before saving

1. Is there a failure mode listed for every dependency, including the silent ones?
2. Does the note say which boundaries are load-bearing and which are historical?
3. Is the known ugliness written down with paths, rather than tactfully omitted?
4. Would a newcomer learn anything they could not get from reading the repository?
5. Is there any prose that a diagram is standing in for?
