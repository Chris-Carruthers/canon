---
type: vision
status: active
updated: TODO
---

# Agent Router

**This is the only vault file meant to enter an agent's context.** Everything
else is reached on demand. Keep it under 150 lines — it is paid for on every
request that loads it. Explanations belong in [[How We Work]]; this file is a
map, not a manual.

## Where things live

| Looking for | Search here |
|---|---|
| Why we chose something | `Decisions/` — dated, ADR-style |
| What a workstream is / where it stands | `Projects/<name>.md` |
| A client / customer / domain area | `Clients/<name>.md` |
| Durable facts, schemas, APIs, pricing | `Reference/` |
| Design system: tokens, components, design assets, approved design tools | `Reference/Design/` |
| Who can explain a feature, and when they were last checked | `Reference/Cognitive Coverage/` |
| What is tested, the floor, and whether the gate can block | `Reference/Testing/` |
| How a document of this type should read, and which to write | `Reference/Writing/` |
| Intent for a feature (what & why) | `Specs/` |
| Ops state to pick work up cold | `Handoffs/` |
| What happened in past sessions | `Sessions/YYYY-MM-DD — <title> (<initials>).md` |
| Generated reports and decks | `Outputs/` |
| Raw, un-compiled source material | `Sources/` |

<!-- Delete folders you do not use. Add ones you do. Keep the table short. -->

## How to search it

1. **Filenames first.** Notes are named for their concept — glob before you grep
   (`Projects/*auth*`, `Sessions/2026-07*`).
2. **Then grep** the vault for the term.
   <!-- List any large folder to exclude by default, e.g. a vendor doc mirror. -->
3. **Read the note, then follow its `[[wikilinks]]`** — related context is one
   hop away by design.
4. **For "where does X stand"**: read `Projects/<name>.md`, then its newest
   linked `Sessions/` note.

## Rules when writing here

- **`Vision/` is owned, not open.** It is direction, not documentation. Propose a
  change via a `Decisions/` note or a reviewed branch — do not edit it in place.
  See `.canon-owners` for who owns what. Freely writable: `Sessions/`,
  `Projects/`, `Clients/`, `Reference/`, `Outputs/`, `Sources/`, `_Inbox/`.
- **Name session notes with the author's initials:**
  `Sessions/YYYY-MM-DD — <title> (<initials>).md`. One file per person per session
  means two people writing about the same thing on the same day never collide.
- **Stamp what you write:** `generated: { by: <your-model-id>, at: <ISO 8601 UTC> }`.
  Never write a `verified:` entry for yourself — that means a *human* confirmed it,
  and it is theirs to add via `canon-verify`.
- **Never** PHI, personal data, secrets, keys, tokens, or `.env` contents. This
  is a git repo; history is permanent.
- **No source code** — link `repo/path.ts:42` instead. **No design-token values**
  either: token *names* are API surface and belong here, values live in the repo.
- **One concept per note**; frontmatter `type:` / `status:` / `updated:` on
  Project / Client / Decision / Reference notes.
- **Size budgets:** index notes ≤200 lines / 25 KB · detail notes <500 lines ·
  references one level deep · TOC over 100 lines.
- **End of meaningful work:** write `Sessions/YYYY-MM-DD — <title> (<initials>).md` with
  goal, what changed (`repo-path:line`), decisions, open follow-ups, and links
  to its `[[Project]]`.

Conventions in full: [[How We Work]]
