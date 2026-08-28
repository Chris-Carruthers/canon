# Voice: Project

## Write it like

**Primary — the Amazon six-pager narrative.** Prose, not bullets. Numbers, not
adjectives. Everything a reader needs in the document rather than in the meeting.

## Why them

The six-pager was invented to solve exactly the problem a project note has: a reader
arrives with no context and must leave able to reason about the work, without the author
present. Amazon's answer was to ban the deck, because **bullets let you skip the
connective tissue** — the sentence that explains why the second point follows from the
first. Forced into prose, gaps in reasoning become visible to the writer as they write,
which is most of the value.

The second property worth stealing is that the narrative is read in silence at the start
of the meeting. That is a brutal test: the document has to work with nobody there to
gloss it. A project note has the same audience — an agent or a colleague reading it cold
to find out where something stands.

## Do not write it like

**A Jira epic.** Status colours, percent-complete, a bullet list of child tickets, and a
"Description" field with one line in it.

The failure is that percentages and RAG statuses are **adjectives wearing numbers'
clothes**. "70% complete" is not measurable, is never revised downward, and hides which
70% — the easy 70 or the 70 that includes the migration. Meanwhile the field that would
actually help, "what is currently blocking this and who owns it", is either absent or
buried in a comment thread.

The second failing register: **the changelog**. A project note that is a reverse
chronological list of everything that happened has made the reader do the synthesis.
The current state is the deliverable; history belongs in the linked session notes.

## The moves

**Open with current state in one paragraph of prose.** What works, what does not, what
is blocking. Somebody should be able to stop after that paragraph and be correctly
oriented.

**Prose over bullets wherever a "because" is involved.** Bullets are fine for
enumerations — paths, environments, owners. They are not fine for reasoning, because
they let you omit the link between items.

**Numbers, not adjectives.** Not "performance is a concern" but "1.9s p95 against a 900ms
target". Not "mostly migrated" but "nine of fourteen regions".

**Say what is blocked and who owns unblocking it.** A named person. "Waiting on infra"
is a state nobody is accountable for and it will persist for a quarter.

**Link, do not restate.** Decisions, specs and session notes are one hop away by design.
Restated intent drifts out of sync silently and reads as authoritative while doing it.

**No history in the body.** The newest linked session note is the history. A project note
that grows monotonically has stopped being an index.

## Go read

- Colin Bryar & Bill Carr, *Working Backwards* — the narrative and six-pager chapters
- Jeff Bezos, 2004 internal note banning PowerPoint — widely reproduced; the reasoning is the useful part
- Any Amazon shareholder letter, for the register at length — <https://www.aboutamazon.com/news/company-news>

## Before saving

1. Can a reader stop after the first paragraph and be correctly oriented?
2. Is every claim about progress a number rather than a percentage or a colour?
3. Is each blocker attached to a named person?
4. Does the note restate anything that a linked spec or decision already says?
5. Is the body free of history — with the chronology left to the session notes?
