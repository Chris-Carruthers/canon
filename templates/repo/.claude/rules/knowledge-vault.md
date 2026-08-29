---
description: Conventions for writing notes into the shared knowledge vault
---

# Writing to the knowledge vault

These rules apply whenever you create or edit a markdown note inside the shared
vault. They exist so the corpus stays findable as it grows — an agent retrieves
by filename and structure long before it reads content.

## Never

- **PHI, personal data, patient/customer identifiers** — including
  de-identified-*looking* samples, screenshots containing names, or query
  results from a production database.
- **Secrets** — API keys, tokens, connection strings, `.env` contents.
- **Source code.** Link `repo/path.ts:42` instead. Code rots inside documents.
- **Design-token values.** A token *name* is API surface and belongs in the vault;
  its *value* is source. Write `--primary`, never `222 47% 11%`. Copying values in
  creates a second source of truth that drifts silently and reads as authoritative.

Git history is permanent. If you are unsure whether something belongs, leave it
out and say so.

## Governed paths — propose, do not edit

Some notes are owned. `Vision/` in particular is direction set by leadership, not
documentation anyone tidies. Check the vault's `.canon-owners` file before editing
outside the working folders.

If a change to a governed note seems right, **do not just make it.** Either:

- write a `Decisions/` note arguing for it and link the note you'd change, or
- make the edit on a branch and say clearly that it needs the owner's review.

This matters specifically for agents: improving a document that is slightly untidy
is a reasonable instinct almost everywhere else, and it is the wrong instinct
here. A vision statement's phrasing is often the deliberate output of an argument
you cannot see from the file.

Freely writable without asking: `Sessions/`, `Projects/`, `Clients/`,
`Reference/`, `Outputs/`, `Sources/`, `_Inbox/`.

## Structure

- **One concept per note.** Big topics get their own note; other notes link to
  them rather than restating them.
- **Name notes for their concept**, because filenames are the primary retrieval
  signal. Sessions and dated artifacts: `YYYY-MM-DD — <short title> (<initials>).md`.
  The initials are the author's, and they are not decoration: two people writing
  about the same thing on the same day produce two files instead of a collision.
  Take them from the git `user.email` local part if nobody has told you otherwise.
- **Frontmatter** on Project / Client / Decision / Reference notes:
  `type:`, `status:`, `updated:`.
- **Link generously** with `[[wikilinks]]`. A link to a note that does not exist
  yet is a feature — it marks something worth writing.
- **The design canon lives in `Reference/Design/`.** Its machine-readable half is
  three fenced blocks with frozen key sets — `design-tokens`,
  `design-components` and `design-tools` — whose contract is documented in the
  Design System template. A component resolves in three rungs: an exported image
  under `Attachments/Design/`, a Figma `{ file, node }`, then `impl: repo/path`.
  **Omit a key you do not have** rather than writing `TODO`; absence is what the
  tooling reads, and coverage is derived from it. Write a per-component note only
  when a reader would ask *why* — a decision, a drift story, an a11y contract.
  Otherwise add a row.
- **Before running a design tool, read the `design-tools` block** and target the
  vocabulary its row names. Whatever the tool emits comes back as *names in the
  vault, values in the repo*: names become a `design-tokens` row with
  `status: proposed`, values land in the repo's tokens file. Generated markup is a
  structural draft — do not paste it in as-is, which is how a codebase acquires
  thousands of hardcoded colour utilities.
- **The testing canon lives in `Reference/Testing/`.** Its machine-readable half is
  two fenced blocks with frozen key sets — `test-suites` and `test-gates` — whose
  contract is documented in the Test Canon template. **A floor is a ratchet, not a
  target**: it is the coverage that already exists, rounded down, and it only rises.
  `branches:` is **case-sensitive and verbatim** — a workflow filtered on `dev`
  against a branch named `Dev` runs on nothing and still looks green. Never infer
  `required:`; whether a check can block a merge is server-side state that no
  checkout can see, so it is a human attestation. Percentages live in the coverage
  report and in dated `Outputs/` audits, never in the note.
- **Use `Templates/` rather than inventing a shape.** Beyond the core set a vault
  may have installed optional packs — the product ladder (one-pager, PR-FAQ,
  six-pager, pitch), engineering (RFC, architecture overview, runbook, postmortem)
  or research craft (findings, design critique, content guide). Every template's
  header says where the note is filed and which reference file governs its voice.
  An RFC and a Decision are both, not either: the RFC argues and changes under
  review, the decision note is the immutable record of what it settled.
- **Before writing a vault document, check how that type should read.**
  `Reference/Writing/House Voice.md` maps each document type to a writer worth
  imitating and, more usefully, to the register it must **not** land in — a Decision
  note that reads like meeting minutes records what was discussed rather than what
  was chosen. `Reference/Writing/Choosing a Document.md` says which document to write
  at which stage; pick the cheapest rung that still works. canon's defaults are in
  the `house-voice` skill, and the vault note overrides them.
- **`Reference/Cognitive Coverage/` records whether a person can explain a feature**,
  as dated assessments, newest first. Never overwrite an entry — the history is the
  point. One person per entry, and record the questions asked so a re-test can be
  harder rather than identical. Stored rather than derived on purpose: it is a fact
  about a person on a date, which nothing can recompute.

## Stamp what you write

Any note you create or meaningfully rewrite gets provenance in its frontmatter, so
a reader can tell an agent draft from something a human checked:

```yaml
generated: { by: <your-model-id>, at: <ISO 8601 UTC> }
```

Use `human:<id>` for people and `process:<id>` for automation. **Do not add a
`verified:` entry for yourself** — that field means *a human confirmed this*, and
it is theirs to add with `canon-verify`. Writing it on your own behalf produces
exactly the false confidence the field exists to prevent.

Optional, when they apply: `status: draft|stable|deprecated`, and `stale_after:
YYYY-MM-DD` for anything with a known shelf life (a quarterly plan, a pricing
sheet, a dependency version). Absolute dates, not durations.

## Size budgets

Mirroring the limits real agent runtimes impose on index files:

| Note kind | Budget |
|---|---|
| Index / router notes | **200 lines or 25 KB** — overflow may be silently dropped |
| Detail notes | under **500 lines** |
| Reference chains | **one level deep** — do not build deep link ladders |
| Any note over 100 lines | add a table of contents |

If a note outgrows its budget, split it and link — do not let it sprawl.

## Session notes

At the end of meaningful work, write `Sessions/YYYY-MM-DD — <title> (<initials>).md`:

- **Goal** — what we set out to do
- **What changed** — `repo-path:line` references and why
- **Decisions** — anything worth remembering; significant ones also get a
  `Decisions/` note
- **Open / next** — checkboxes for follow-ups
- **Links** — its `[[Project]]` and any `[[Client]]`

Write what a teammate would need to pick the work up cold in three months.
Record what was surprising, not what is already obvious from the code.
