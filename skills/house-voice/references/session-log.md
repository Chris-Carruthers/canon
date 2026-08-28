# Voice: Session Log

## Write it like

**Primary — a good git commit message body.** Tim Pope's convention and the Linux kernel
discipline: what changed, where, and why it needed to change. Written for the person who
runs `git blame` in two years.

**Supporting — the blameless postmortem register**, for the parts where something went
wrong.

## Why them

A session note is a commit message for a work session. The audience is identical — a
stranger, later, who has found this and wants to know why the world is the way it is —
and so is the discipline: **state the change and the reason, not the activity.**

The commit-message convention is also the right model for length. It is short because it
is written for retrieval, not for reading; nobody reads a commit log for pleasure, they
grep it. A session note that takes ten minutes to write will not be written next time,
and an unwritten note is the only real failure mode here.

The postmortem register handles the awkward half. When the session went badly — the
migration was never applied, the fix broke something else — a blameless factual register
makes recording it cheap. That matters because the sessions worth reading later are
disproportionately the ones that went wrong.

## Do not write it like

**A standup update.** "Worked on the connector, then looked at the auth bug, then picked
up the PR feedback."

The register records **activity rather than change**, which is exactly inverted. Nobody
reading this later cares what you spent the afternoon on; they need to know what is now
true that was not true before. A standup update also has no locations in it, so a reader
who wants to see the change has to go find it.

The second failing register is **the diary**: narrating the sequence of discoveries in
the order they happened, including the wrong turns, at length. The wrong turn is worth
one line if it is a trap the next person would also fall into. Otherwise it is noise
that buries the outcome.

## The moves

**Every change carries a location.** `repo/path:line`. A change without a path is not
retrievable, which means it is not written down.

**Write what is now true, not what you did.** "Added tenant scoping to the roster
endpoint" over "worked on the roster endpoint". The first is checkable.

**Record the wrong turn only if it is a trap.** One line, stating the trap: "the ledger
keys on the four-digit prefix alone, so a duplicate number is silently skipped." Trap,
not narrative.

**Promote real choices out.** A decision belongs in a dated `Decisions/` note; the
session note links to it. Decisions buried in a session log are unfindable within a
month.

**State what is unfinished, plainly.** The half-rebased branch, the unapplied migration,
the test you skipped. This is the highest-value content in the note and the easiest to
omit at the end of a long day.

**Keep it short enough that you will write the next one.** Complete beats thorough. The
note that does not get written costs more than the one that is terse.

## Go read

- Tim Pope, "A Note About Git Commit Messages" — <https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html>
- Linux kernel submitting-patches, on describing the change — <https://www.kernel.org/doc/html/latest/process/submitting-patches.html>
- Google SRE Book, "Postmortem Culture" — <https://sre.google/sre-book/postmortem-culture/>

## Before saving

1. Does every change carry a `repo/path:line`?
2. Does the note say what is now **true**, rather than what you worked on?
3. Is every wrong turn either cut or reduced to the trap it represents?
4. Is anything unfinished, unapplied or unmerged stated explicitly?
5. Was this quick enough to write that you will write one next session?
