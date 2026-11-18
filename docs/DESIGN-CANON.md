# The design canon: names and pointers, never values

A design system is mostly code, and code stays out of the vault. So
`Reference/Design/` holds the part that isn't code — and the split is sharper than
it first looks:

> A token **name** is API surface, like a schema field name, and `Reference/` is for
> schemas. A token **value** is source. It has a format, it belongs to a cascade, and
> any tool can read it from the repo when asked.

Copy values into the vault and you have built a second source of truth that drifts
silently while reading as authoritative.

**For coding agents, the useful part is that assets resolve deterministically.** Two
frozen fenced blocks — `design-tokens` and `design-components` — give a three-rung
ladder, and *every rung's absence is detectable*:

| Rung | Field | Needs |
|---|---|---|
| Exported image | `image: Attachments/Design/<slug>--<variant>--<state>@<theme>.png` | nothing |
| Figma node | `figma: { file: <key>, node: <dash-form-id> }` | Figma MCP or an authed fetch |
| Implementation | `impl: repo/path[:line]` | the repo |

Filenames are **constructible**, so an agent derives the expected path from the slug
and checks whether it exists rather than guessing. **Omit a key you do not have —
never `TODO`.** Absence is the signal, and coverage is derived from it. `status:
absent` is a legitimate row: *"there is no shared `PageHeader`"* stops an agent
hunting for one and stops it silently inventing a fourth.

## What you are allowed to build UI *with*

A third block, `design-tools`, records the tools approved for making or fixing UI.
It exists because the other two blocks answer *what exists* and leave *what do I
build one with* to whoever is guessing that day.

Any tool whose `roles:` write UI must name the vocabularies it targets, and the
audit checks each one exists. That rule is the whole point: **a generator given no
target vocabulary does not abstain from choosing one — it invents one**, and you
find out months later when a fifth `--primary` appears in a diff that looked fine.
Which vocabulary applies in a given repo needs no key, because every vocabulary's
`source` is repo-prefixed: the one whose source lives in the repo you are editing is
the one to use.

`install.sh --design` writes the `DESIGN.md` that tells a tool which that is. It is
off by default — a stray `CLAUDE.md` costs nothing, but a stray `DESIGN.md` in a
repo with no UI points a design tool at an unrelated vocabulary. Once you fill in
the slug it is your file: never overwritten, and left in place by `--uninstall`.

Rows also carry `status: approved | trial | rejected`. A **rejected** row is the
useful one — it says somebody evaluated this and said no, where silence says nobody
has looked. Full contract and two worked entries:
**[`docs/DESIGN-TOOLS.md`](DESIGN-TOOLS.md)**.

## Reading the canon back out

The blocks are easy to write and were, for a while, hard to read. Two flags fix
that, and both derive everything on the spot:

**`--export`** prints the canon as JSON — every token name with the value read out
of the repo *at call time*, which rungs each component resolves to, the registered
tools with their targets joined per repo, and the names more than one vocabulary
claims. An agent reads one document instead of re-implementing the subtree walk and
the fence parsing. Where a repo was not scanned, values come back `unverifiable`
rather than absent: unscanned is unknown, not empty.

**`--view`** writes the same model to `Outputs/<date> — Design System View.md`.
Plain markdown, so an agent can grep it and a person can read it in Obsidian, with a
colour chip beside every value. Colours are emitted as the CSS function their
declared format implies and left for the renderer to resolve — the same reason the
audit never compares two values itself.

The section people actually open it for is **the tokens more than one vocabulary
declares**, flagged where they also differ in colour space. That is where "I assumed
they matched" starts, and before this it could only be asserted in prose.

Values appear in both outputs and are still not stored: each is dated, derived and
regenerated, exactly like the audit report. Do not hand-edit either — change the
canon or change the code and re-run.

## `canon-design-audit`

```
$ canon-design-audit ~/code/web-app
canon-design-audit 0.3.0
  scanned 695 file(s) in 1 repo(s)
  canon: 3 vocabular(ies), 12 component(s)

  VIOLATION DS-PALETTE-UTILITY     1204
              web-app/src/Page.tsx:31  bg-blue-500
              … and 1199 more
  VIOLATION DS-COLOR-LITERAL       88
  GAP       DS-FORMAT-SPLIT        4
              --primary  declared in web-app, design-system, mobile across
                         formats hsl-triplet, oklch

  coverage: image 0/12 · figma 3/12 · impl 9/12 · absent 2
```

*Illustrative figures from a made-up repo.* Your first run against an existing
codebase will report a far larger `DS-PALETTE-UTILITY` count, which is the point of
`--baseline-write`.

Two claims worth being precise about, because they are why the thing is usable:

**Derived, never stored.** It reads the contract from the vault and the facts from
the code and recomputes on every run. No frontmatter caches a verdict, no note holds
a score, and there is no scorecard to keep current. `--report` writes one dated
`Outputs/` note carrying `stale_after: +30d`, so `canon-trust --strict` fails on an
audit nobody re-ran.

**It never compares two token values.** Deciding whether `var(--foreground)` equals
`222 47% 11%` is a CSS resolution problem — aliases, `calc()`, colour spaces, the
cascade, shadow-root scoping — and a regex cannot solve it. So it compares **name
sets and format labels** and leaves value equivalence to the browser. This is a
direct lesson from a token-parity script whose false results meant nobody read it.

Everything else follows from the same instinct: **VIOLATION** is a fact you can check
by opening the cited line, **GAP** is a judgement call and can never fail a build,
the Tailwind rule uses a **closed list** of the default palette so `bg-primary` is
structurally unmatchable, the skip-list is **learned from the canon** so declaring a
vocabulary silences its own false positives, and `--strict` compares against a
`.canon-design-baseline` rather than zero — on a repo with thousands of existing
violations the only useful signal is *did it get worse*.

It is **read-only in every repo it scans**, asserted by a test. And it is not in any
pre-commit hook: it scans code repos, not the vault. It measures. Enforcement is
CODEOWNERS on the token files plus branch protection, in the repos where those files
live.
