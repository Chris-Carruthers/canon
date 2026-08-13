---
type: design-component
component: <kebab-slug>
system: "[[<Design System Name>]]"
status: shipped          # proposed | shipped | drifted | deprecated
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
figma: { file: <figma-file-key>, node: <dash-form-node-id> }
image: Attachments/Design/<slug>--<variant>--<state>@<theme>.png
impl: repo/path/to/component.tsx
tokens: [--token-name, --token-name]
---

<!--
File as: Reference/Design/Component — <Display Name>.md

WHEN TO WRITE ONE OF THESE — and mostly, do not.

Most components need a row in the `design-components` block and nothing more.
Write a note only when a reader would otherwise ask WHY:
  * a design decision somebody will want to reverse
  * a drift story — three versions exist and here is which one wins
  * an accessibility contract with real obligations
  * an approved-usage rule people keep breaking

A note per component for thirty shadcn primitives is thirty files of boilerplate
that all say "it is a button". That is a row pretending to be a concept.

THE FRONTMATTER ABOVE IS DELIBERATELY THE SAME FIELD SET AS ONE BLOCK ROW. One
schema, two carriers: canon-design-audit reads a row or a note indifferently, so
promoting a row to a note duplicates nothing. Keep them identical — if you add a
key here, add it to the block contract in the Design System template and to
bin/canon-design-audit in the same commit.

Omit any key you do not have. Never write TODO or leave it blank — absence is the
signal the tooling reads. Keep under 500 lines.
-->

## What it is

Intent and role, not implementation. What problem it solves and when to reach for
it. If a reader could get this from the source, cut it.

## Where it resolves

| Rung | Pointer |
|---|---|
| Exported image | `Attachments/Design/<slug>--<variant>--<state>@<theme>.png` |
| Figma node | file `<key>`, node `<dash-form-id>` |
| Implementation | `repo/path/to/component.tsx` |

<!--
A missing rung is stated IN WORDS — "not exported", "not designed", "not built" —
never left blank. A blank cell is indistinguishable from an oversight; "not
designed" is a fact somebody can act on.

Remember: dash form here, colon form when calling the Figma API.
-->

## Tokens it consumes

Names only, with a pointer to where the values live:

- `--primary` · `--primary-foreground` — values in `repo/path/to/tokens.css`

## Variants and states

The enumeration the image filenames derive from, so an agent can construct the
expected path rather than guess it:

| Variant | States | Themes |
|---|---|---|
| primary | default, hover, focus, disabled | light, dark |

## Accessibility contract

Checkable statements, not aspirations. Role, keyboard interaction, focus
behaviour, labelling requirement. If nothing has been audited, say that instead —
an unaudited claim reads as done and is worse than silence.

## Approved usage / do not

The two or three rules people actually break. Not a style essay.

## Known drift

Where other implementations of this exist, as `repo/path:line`.

**No counts here** — counts go stale the day after you write them. The current
number is in the newest `Outputs/<date> — Design System Audit.md`.

## Related

System: [[ ]] · Decisions: [[ ]]
