---
type: design-system
title: "<Design System Name>"
status: active           # active | proposed | absent
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/design-system.md — your own map wins: Reference/Writing/House Voice.md
File as: Reference/Design/<Name> — Current State.md
Companion detail notes, one hop away, each under 500 lines:
  Reference/Design/<Name> — Token Vocabularies.md    the design-tokens block
  Reference/Design/<Name> — Component Index.md       the design-components block
  Reference/Design/<Name> — Design Assets.md         Figma register, image convention

WHY THIS SHAPE. A design system is mostly code, and code stays out of the vault.
So this note holds the part that is NOT code: what the system is for, who owns it,
which names are API surface, and where the real thing lives. A reader — human or
agent — should leave knowing where to look, never having read a value they could
have read from the repo.

"There is no design system yet" is a valid and valuable first line. So is
"unowned". An honest absence is a finding; a hopeful blank is a lie that costs
somebody an afternoon.

THE RULE THAT MATTERS MOST:
  A token NAME is API surface, like a schema field name, and Reference/ is for
  schemas. A token VALUE is source. It rots, it has a format, it belongs to a
  cascade — and any tool can read it from the repo whenever it is asked.
  Names in the vault. Values in the repo. Always.

Delete sections that do not apply. Keep this file under 200 lines: it is an index
note, and index notes are read in full.
-->

## What this is

One paragraph. What the system covers, which surfaces it governs, and what it
deliberately does not govern.

## Ownership

**Decide this before anything else here is worth writing.** These are placeholders.
Nobody outside your team can fill them in.

| Role | Who | Evidence |
|---|---|---|
| Owns the token contract | `<name>` | |
| Owns component review | `<name>` | |
| Owns accessibility | `<name>` | |
| Accountable if it stalls | `<name>` | |

<!--
HOW TO DECIDE THIS, if it is not obvious.

A design system needs three different kinds of authority and they are usually three
different people. Splitting them is not bureaucracy — it is what stops the system
being blocked on one person's calendar:

  Token contract     normally a designer. They decide which names exist and what
                     each one means. This is the role that must NOT be a committee.
  Component review   whoever says yes to a new shared component, and no to the
                     fourth button. Often an engineer or design-systems lead.
  Accessibility      whoever is accountable for the standard being MET, not merely
                     aspired to. Name someone even if no audit has run — an
                     unowned WCAG claim in a spec is worse than no claim, because
                     it reads as done.
  Accountable        the person who unblocks the other three when the disciplines
                     disagree. Usually a product or engineering lead.

One person can hold several roles. Nobody holding a role is also an answer.

WRITE "unowned" IF THAT IS TRUE, along with what you checked to conclude it. It is
the most important line in this note when it is true. An unowned design system does
not converge, and a reader needs to know that before filing a request nobody will
read.

Evidence means how you know — a ticket, a decision note, the person's own
confirmation. "We assumed" is not evidence, and assumed ownership is the same as
none.
-->

## Source of truth

Three pointers an agent needs, and nothing else:

- **Token values live in** — `repo/path/to/tokens.css`
- **Design source lives in** — Figma file key + node (see the Design Assets note)
- **Live style guide** — `repo/path/to/route` or a URL, if one is rendered

"None — see the Open Question" is a valid answer for any of the three.

## Token vocabularies

Summary only; the full `design-tokens` block lives in the companion note.

| Vocabulary | Source | Format | Status |
|---|---|---|---|
| `<slug>` | `repo/path` | hsl-triplet | canonical |

`status` is one of `canonical`, `transcribed-copy`, `divergent`, `prototype`.
If nothing is `canonical`, say so here — that is the single most useful fact in
the note.

## Where the pieces live

A component resolves in three rungs, tried in order. Every rung's absence is
detectable, which is what makes the canon machine-readable:

| Rung | How | Needs |
|---|---|---|
| 1. Exported image | `Attachments/Design/<slug>--<variant>--<state>@<theme>.png` | nothing |
| 2. Figma node | `figma: { file: <key>, node: <dash-form-id> }` | Figma MCP or an authed fetch |
| 3. Implementation | `impl: repo/path[:line]` | the repo |

Full inventory: the `design-components` block in the Component Index note.

## Accessibility contract

What is asserted, and by which tool. "Nothing is asserted" is a valid and
valuable answer — an unaudited WCAG claim in a spec is worse than no claim,
because it reads as done.

## Adherence

*How to measure*, never a measurement:

- `canon-design-audit <repo>…` — derives violations and coverage from this canon
  plus the code, every run
- Latest report: the newest `Outputs/<date> — Design System Audit.md`

**No score is written in this note.** Counts go stale the day after you type them.

## Open Questions

Link the `Decisions/` notes. A design system with no open questions is either
finished or not being used.

## Related

One level deep. Do not build a link ladder.

<!--
================================================================================
BLOCK CONTRACTS — FROZEN. Must match bin/canon-design-audit exactly.
================================================================================
These two fenced blocks are the machine-readable half of the canon. They live in
the companion detail notes, not here, because they outgrow an index note's 200
lines. canon-design-audit GLOBS the Reference/Design/ subtree for them rather
than reading a fixed filename, so a block can move to a sibling note freely.

The names are namespaced on purpose: `design-tokens`, not `tokens`. A generic
fence name collides with the next tool that wants one.

If you change a key here, change it in bin/canon-design-audit in the same commit.
The kit already has one scar from ignoring this: a Product Spec template whose
fence names never matched the validator written against it, so every file made
from the template failed the check.

```design-tokens
- vocabulary: <slug>                  # required, unique
  source: repo/path/to/tokens.css     # required — where the VALUES live
  format: hsl-triplet                 # hsl-triplet | oklch | hex | rgb-triplet | named
  scope: ":root"                      # the selector the declarations sit on
  catalog: repo/path/to/palette.md    # optional human-readable catalog
  names: [--background, --foreground] # the token NAMES. never values.
  status: canonical                   # canonical | transcribed-copy | divergent | prototype
  of: <vocabulary-slug>               # required when status is transcribed-copy
```

```design-components
- slug: <kebab-slug>                  # required, unique
  name: <Display Name>                # required
  vocabulary: <vocabulary-slug>
  figma: { file: <key>, node: <dash-form-id> }
  image: Attachments/Design/<slug>--<variant>--<state>@<theme>.png
  impl: repo/path/to/component.tsx
  tokens: [--primary, --primary-foreground]
  status: shipped                     # proposed | shipped | drifted | absent
  note: "[[Component — <Name>]]"      # only if a per-component note exists
```

SEVEN RULES. Each one exists because it is the thing that gets got wrong.

1. OMIT A KEY YOU DO NOT HAVE. Never TODO, TBD, ?, or an empty value. Absence is
   the machine-readable signal, and coverage is DERIVED from it. A row full of
   TODOs reports as complete-but-broken instead of honestly incomplete.

2. figma.node is DASH form — 2566-21359 — because that is what a Figma URL
   carries and copy-paste is how it gets here. The REST and MCP APIs want COLON
   form — 2566:21359. Convert dash to colon at the call site. This is the single
   most common mistake with Figma node IDs.

3. NEVER STORE A FIGMA URL. It carries a rename-fragile decorative slug, and
   often a `t=` session parameter that is credential-shaped and that the secret
   scanner will not catch. Store file + node; render the URL when you need it:
     https://www.figma.com/design/<file>/x?node-id=<node>&m=dev

4. impl / source / catalog are repo-prefixed and RELATIVE — repo/path.tsx:42 —
   matching the vault's existing convention for pointing at code. Never absolute,
   never a URL. Absolute paths are somebody else's machine.

5. NAMES IN THE VAULT, VALUES IN THE REPO. Stated again because it is the rule
   people break first and it is the whole reason this shape exists.

6. `status: absent` IS A LEGITIMATE, HIGH-VALUE ROW. A row saying there is no
   shared PageHeader stops an agent hunting for one AND stops it silently
   inventing a fourth one. Absence recorded is cheaper than absence rediscovered.

7. One image per component per theme, PNG, under 200 KB. Do not gitignore
   Attachments/ — a path that silently cannot resolve is worse than a declared
   absence, because the tool can report an absence.
-->

