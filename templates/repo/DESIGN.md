<!--
Copy to the ROOT of a repo that has UI, and fill in the four angle-bracket values.

WHAT THIS IS FOR. Design tools read a file like this to learn the project's design
context before they touch anything. impeccable reads `PRODUCT.md` and `DESIGN.md`;
other tools look for something similar. Without it a tool concludes the project has
no committed design language and generates one — which is how a codebase acquires a
second, plausible, entirely parallel set of tokens.

So this file has one job: point the tool at the canon and tell it what not to
invent. It is a POINTER FILE. It holds no token values — those live in the repo's
own tokens file, which the tool can read directly, and duplicating them here would
create a third source of truth that drifts silently while reading as authoritative.

Keep it short. A tool reads it in full, every run.
-->

# Design context — <repo-name>

## The canon is not in this repo

The design system's names, component inventory and approved tooling live in the
knowledge vault, under `Reference/Design/`. Resolve the vault path with
`canon-path`; do not hardcode it.

Read before changing any UI:

- `Reference/Design/<Name> — Token Vocabularies.md` — the token **names** that
  exist, per vocabulary
- `Reference/Design/<Name> — Component Index.md` — what already exists, and what
  is recorded as deliberately absent
- `Reference/Design/<Name> — Tooling.md` — what is approved for making or fixing
  UI here

## This repo's vocabulary

**`<vocabulary-slug>`.** Use these token names and no others.

**Values live in `<path/to/tokens.css>`** — read them from there. They are
deliberately not repeated in this file or in the vault.

## Do not invent

The three failure modes that actually happen, in order of how often:

1. **Do not add a new colour format.** If this repo's vocabulary is HSL triplets,
   do not introduce `oklch()` or hex, even where it would be tidier. Format splits
   are what make two vocabularies impossible to reconcile later.
2. **Do not generate a palette.** If you cannot find committed brand colours, that
   is a bug in this file or in your reading of it — not a licence to seed one. Stop
   and say so. A generated palette that looks right is worse than an error,
   because it ships.
3. **Do not invent a spacing scale or a type scale** unless
   `Reference/Design/` records that one exists. Where the vault says a scale is
   deferred, it is deferred on purpose, and adding one creates a further thing to
   reconcile.

## New components

Check the Component Index first. A `status: absent` row means the shared component
does **not** exist and that absence was recorded deliberately — it is there to stop
you hunting for one *and* to stop you quietly building the fourth. If you do build
it, add or update the row rather than leaving the canon behind.

## Accessibility

<State what is actually asserted here, and by which tool. "Nothing has been
audited" is a valid and more useful answer than an aspiration — an unaudited WCAG
claim reads as done, which is worse than no claim.>

## Checking your work

`canon-design-audit <this-repo>` reports what drifted. It compares name sets and
format labels; it never compares two token values. The count that matters is
whether it went **up** relative to `.canon-design-baseline`, not whether it is zero.
