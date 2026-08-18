# Design tools

The design canon answers *what exists, and does the code conform?* This is the
other half: **what do I use to make or fix one, and what stops it going its own
way.**

The `design-tools` block in `Reference/Design/` is that registry. Its contract is
frozen in `templates/vault/Templates/Design System.md` and validated by
`bin/canon-design-audit`.

**Both tools named below are example entries, not dependencies.** canon works with
the block empty or absent, and a vault that registers no tools produces
byte-identical audit output to a build without this feature. An unused registry
should be invisible, not a row of zeroes.

## The one-way ingest rule

This is the whole point of registering a tool rather than just using one:

> A generated or refactored design enters the canon as **names in the vault, values
> in the repo.** Token *names* become a `design-tokens` row with
> `status: proposed`. Token *values* land in the repo's tokens file. Screens become
> `Attachments/Design/` images.
>
> **Generated markup does not enter a repo as-is.** It is a structural draft.
> Pasting it is how a codebase acquires hardcoded colour utilities in bulk, and
> `DS-PALETTE-UTILITY` is usually the largest count in an audit of a codebase that
> has been generated into. Run `canon-design-audit` before and after if you want
> your own number rather than this claim.

One-way on purpose. The canon does not round-trip back into a generator: these
tools have no API, and their output is not reproducible from the same input.

## Why a row carries no paths at all

Same reasoning as the Figma rule (rule 3): a vendor URL is rename-fragile the moment
the product is renamed or folded into something else. An install path is worse — a
skill sits at a different absolute path on every machine, so a committed one is
somebody else's machine. The `slug` and `kind` identify it; how to reach it belongs
in the prose note, where being wrong costs nothing instead of failing a build.

**Where a tool writes values carries no key either — it is derived.** A tool writes
into the tokens file of whichever vocabulary it is targeting, and every vocabulary
already declares that file as its `source`. An earlier draft of this block had a
`values-to` key, and in practice it was a verbatim copy of one vocabulary's
`source` — which is exactly how it ended up holding a single path for a tool used
across three repos.

That removal also answers the question the key was there to answer. Every
vocabulary's `source` is repo-prefixed, so **the vocabulary whose source lives in
the repo you are editing is the one to target.** "Vocabulary X for surface Y" is
fully expressed by the two blocks together; the tool row only has to list which
vocabularies it is allowed near. `--export` renders the join for you:

```json
"targets": [
  { "repo": "web-app", "vocabulary": "web-shadcn-hsl",
    "format": "hsl-triplet",
    "values_in": "web-app/src/styles/tokens.css" }
]
```

## Recording a tool you turned down

`status:` is `approved`, `trial`, or `rejected`, and `owner` is who decided. A
rejected row is the most useful kind: it says somebody evaluated this and said no,
where silence says nobody has looked. It is the same idea as a component row with
`status: absent`, which stops an agent both hunting for a shared `PageHeader` and
quietly building a fourth one. A `rejected` tool is exempt from needing a
`vocabulary` — it is not going to be pointed at anything.

## Why `checked:` is mandatory

Third-party capability rots faster than anything else in this canon. Features ship,
limits change, export paths break, free tiers get metered. A capability claim with
no date is one somebody acts on a year after it stopped being true.

`canon-design-audit` reports a row older than 180 days as a **GAP** — never a
violation, because a rule that can fail a build through the mere passage of time is
a rule someone switches off. So an unchecked claim decays into a visible absence
instead of a quiet lie.

## Why `vocabulary:` is mandatory for anything that writes UI

A tool told to build or refactor UI, given no target vocabulary, does not decline
to choose one. **It invents one.** You find out months later when a fifth
`--primary` shows up, in a diff that looked fine and a test suite that stayed
green.

So any row whose `roles:` include `generator` or `implementer` must name a
vocabulary, and the audit cross-checks that the vocabulary actually exists in a
`design-tokens` block. This is the enforcement arm of *names in the vault, values
in the repo*: the tool is told which names to use, and reads the values from the
repo itself.

---

## Entry: Google Stitch

`kind: vendor` · `roles: [generator]` · checked 2026-08-15

Prompt or image → UI screens, in a browser canvas.

| | |
|---|---|
| Inputs | text prompt; image reference (experimental mode) |
| Theme controls | light/dark, accent colour, corner radius, font |
| Outputs | HTML/CSS in a `.zip`; `design.md`; "Copy to Figma" |

**Limits, as of the checked date.** Cannot define or enforce component libraries,
tokens or brand guidelines across projects — brand colours must be re-stated as hex
in every prompt. Non-deterministic: the same prompt produces a different result
each time, which suits exploration and fights production. Code export is HTML/CSS
only. Figma export is unavailable on some agents and in image-reference mode.
Roughly 350 generations a month. **No API** — copy-paste only.

### `design.md` → the canon

Stitch's `design.md` is a near-exact counterpart to this canon, which is why it is
worth naming rather than merely mentioning. It is the artifact canon is the
governed version of:

| | Stitch `design.md` | canon design blocks |
|---|---|---|
| Token **values** | yes — hex, type scale, spacing scale | deliberately never |
| Token **names** as API surface | no | yes |
| Machine-enforceable | no | yes, via `canon-design-audit` |
| Resolution | static file, one-way, copy-paste | three-rung ladder |

Map it as follows:

- **Colour system** — the *names* you decide to keep become a `design-tokens` row
  with `status: proposed`. The hex values go to the repo's tokens file. Never both.
- **Component patterns, states, variants** — `design-components` rows, and the
  variant/state enumeration is what makes the image filenames constructible.
- **Radius** — maps to `--radius` where the vocabulary has it.
- **Typography and spacing scale** — *usually drop these on the floor.* If
  `Reference/Design/` does not record that a type scale or spacing scale exists,
  one is deferred deliberately, and importing Stitch's would create a further thing
  to reconcile rather than filling a gap. Import them only once a decision says to.

### Filling rung 1 of the resolution ladder

The audit's coverage line usually reports **0 components resolving to an exported
image**, because exporting them is manual work nobody has done. That is the one gap
a generator can actually close:

1. Generate the screen in Stitch, re-stating the repo's existing token values as
   explicit hex — it cannot hold a brand.
2. Export a PNG per variant/state/theme into the path the ladder already defines:
   `Attachments/Design/<slug>--<variant>--<state>@<theme>.png`
3. Add or update the `design-components` row with `image:` and `status: proposed`.
4. Run `canon-design-audit --report`. `DS-ASSET-MISSING` tells you whether the path
   resolves.

Rung 1 is the cheapest rung on purpose — no network, no auth, no vendor account —
so it is the one that keeps working when the others do not.

---

## Entry: impeccable

`kind: skill` · `roles: [critic, implementer]` · checked 2026-08-15

A Claude Code skill that critiques and builds production frontend UI. Apache 2.0,
so unlike a hosted vendor it can be pinned and read.

Sub-commands worth knowing: `audit` / `critique` (evaluate what exists),
`craft` / `shape` (build), `polish` / `harden` / `optimize`, `extract` /
`document`, `live`. It reads project context from `PRODUCT.md` and `DESIGN.md`,
writes critiques to `.impeccable/critique/`, and carries explicit WCAG contrast
rules (≥4.5:1 body text, ≥3:1 large).

### The hazard, and the wiring that removes it

Its setup has a reasonable default that is wrong here: **when it finds no committed
brand colours, its step 6 seeds a brand colour and has you compose an OKLCH palette
around it.** That step is skipped only if committed brand colours were found, so
"found" is the whole ballgame. Against a canon whose vocabularies
already disagree — and especially while a source-of-truth decision is open — that
is precisely how the next vocabulary gets created, by a well-behaved tool doing
what it was told.

Registering it does not fix that. **Wiring it does:**

1. Copy `templates/repo/DESIGN.md` to the repo root and fill in the vocabulary slug
   and the path to the tokens file.
2. **A `DESIGN.md` on its own is inert — you also need a `PRODUCT.md`.** The context
   loader returns early when no `PRODUCT.md` is present and never emits the
   `DESIGN.md` body, so the guardrail reaches nothing. This is not documented by the
   tool; it was found by running it, and it is the single most likely way to think
   you are wired up when you are not.
3. Confirm the tool actually reads it. The check is that the context step prints
   your `DESIGN.md`, not that the file exists.
4. Run `audit` on one component and confirm it cites the repo's existing tokens
   instead of proposing a palette.

> **Watch the filename.** impeccable's own `document` command writes a root
> `DESIGN.md` (and an `.impeccable/design.json` that *does* carry token values). So
> canon's values-free pointer file sits at a path a registered tool owns and will
> regenerate. Either do not run `document` in a repo wired this way, or move the
> pointer content somewhere the tool does not own. Recorded here rather than
> silently, because the collision is invisible until it overwrites you.

Step 3 is the acceptance test. Everything else here is documentation; that is the
part that either holds or does not.

### `extract`, and why it is not a shortcut

`extract` can derive a design system from existing code, which is tempting when the
canon records a missing spacing or type scale. Resist it while a source-of-truth
decision is open: extracting from one repo produces a vocabulary shaped by that
repo, and a scale invented to fill a gap is indistinguishable, six months later,
from a scale somebody decided on. Record what it finds as `status: proposed` and let
the owner decide.

---

## Adding your own entry

- Fill in every key you actually have, and **omit the rest.** Never `TODO` —
  absence is the machine-readable signal, and the audit reports a placeholder as
  malformed.
- `checked:` is the date **you** confirmed it, not the date you copied it from a
  blog post. It is deliberately not called `verified:` — that name is already load-
  bearing in this kit, where it means *a human confirmed this note*, drives
  `canon-trust`, and agents are told never to write it for themselves.
- If the tool writes UI, name every vocabulary it is allowed near. If you do not
  know which, that is the finding — write it up as an open question instead of
  registering the tool. Do not add a path for where values go; it is derived from
  the vocabulary's own `source`.
- `status: trial` is the honest default until somebody has actually used it here.
  `approved` claims a decision, so name the `owner` who made it.
- Then run `canon-design-audit --json <repo>` and read the `DS-TOOL-*` rules.
