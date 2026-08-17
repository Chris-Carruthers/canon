---
type: vision
status: active
updated: TODO
---

# How We Work

Conventions that keep this vault coherent across many people and many agent
sessions. [[Agent Router]] is the short version that agents load; this is the
reference humans come back to.

## The session loop

1. **Start** — the agent reads [[Agent Router]] and the relevant
   `Projects/` / `Clients/` note before non-trivial work.
2. **Work** — happens in the code repos, outside this vault.
3. **End** — the agent writes a dated note to `Sessions/`: goal, what changed
   with `repo-path:line` refs, decisions, open follow-ups, linked to its
   project. Real choices also get a `Decisions/` note.

This is wired up by a `CLAUDE.md` and a `SessionStart` hook committed in each
code repo, so it applies wherever the team works — not only when someone
remembers to ask.

## The three layers

Never mix raw material with compiled knowledge.

| Layer | Folder | Who writes it |
|---|---|---|
| **Raw** | `Sources/` | Humans drop files in; never hand-edited |
| **Wiki** | `Reference/` `Projects/` `Clients/` `Decisions/` | Agents compile it from raw, maintained in place |
| **Outputs** | `Outputs/` | Agents generate from the wiki, filed back so it stays searchable |

The loop is: drop a source → compile it → ask questions → file the output back.
Each pass makes the next answer better. Nobody writes the wiki layer by hand.

**Binary assets split by the same rule, stated so it is never a judgement call:**
if a note cites the path in its frontmatter, the file lives in `Attachments/`. If
the ingest loop reads it once and compiles it away, it lives in `Sources/`. So a
whole exported Figma page goes to `Sources/Design/`; the one canonical screenshot a
component note points at goes to `Attachments/Design/`.

## Note conventions

- **Link generously** with `[[wikilinks]]`; links to not-yet-written notes are
  useful placeholders.
- **Tag** for filtering (`#client/…`, `#project/…`, `#type/…`).
- **One concept per note.**
- **Frontmatter** `type:` / `status:` / `updated:` so notes can be tabled
  automatically.
- **Code stays out.** Link to repo paths.
- **Values stay out too.** A design token's *name* is API surface and belongs in
  the vault; its *value* is source. `--primary`, never `222 47% 11%`.

## Specs and handoffs

Two documents per significant piece of work, kept separate on purpose:

- **`Specs/<slug>.product-spec.md`** — *intent*: what and why. Five sections in a
  fixed order (Problem → Hypothesis → Scope → Acceptance Criteria → Success
  Metrics), with machine-checkable fenced blocks and sequential IDs. The spec is
  the **single source of truth**; tickets and PRs point back to it by path rather
  than restating it, because restated intent drifts out of sync silently.
- **`Handoffs/<slug>.handoff.md`** — *state*: how and where. Branch, PR, unmerged
  work, migrations, environment prerequisites, live incidents. It cites its spec
  by path and mirrors the acceptance-criteria checklist with evidence.

The rule of thumb: intent goes in the spec, and everything a person needs to pick
the work up cold goes in the handoff. The handoff is the one that saves you when
someone leaves — so write down the half-finished branch and the manual step, not
just the clean parts.

If you want machine validation of the fenced blocks, write a small validator
against **your own frozen schema** rather than depending on an external standard
that ships breaking changes. Templates are in `Templates/`.

## The design canon

`Reference/Design/` is where the design system lives — and the reason it can live
in a vault at all is that it holds **names, intent and pointers, never values**. A
token name is API surface, like a schema field name. A token value is source: it
has a format, it belongs to a cascade, and any tool can read it from the repo on
demand. Copy values in and you have made a second source of truth that drifts
silently while reading as authoritative.

Two tiers, so the common case stays cheap:

- **A row** in the `design-components` block covers most components.
- **A note** — from the Design Component template — only when a reader would ask
  *why*: a design decision, a drift story, a real accessibility contract. Thirty
  notes for thirty primitives is boilerplate, not knowledge. The note's
  frontmatter is deliberately the same field set as one row, so promoting costs
  nothing and duplicates nothing.

**A component resolves in three rungs**, and every rung's absence is detectable:
an exported image under `Attachments/Design/` (cheapest — no network, no auth), a
Figma `{ file, node }`, then `impl: repo/path`. Omit a key you do not have rather
than writing `TODO` — absence is the signal, and coverage is *derived* from it.

Unlike the spec blocks above, these **do** ship with a validator:
`canon-design-audit` parses them, and its key list is frozen against the template.
It also scans the code repos and reports what has drifted. It measures; it does not
enforce. Enforcement is CODEOWNERS on the token files plus branch protection.

**Where new designs come from** is the third block, `design-tools`: what is approved
for making or fixing UI, and — for anything that writes UI — which vocabulary it
must target. That key is required because a generator given no target does not
abstain from choosing one, it invents one, and the extra `--primary` surfaces months
later in a diff that looked fine. Whatever the tool produces comes back the same way
everything else does: **names in the vault, values in the repo**, with names landing
as `status: proposed` rows. Generated markup is a structural draft and does not get
pasted into a repo as-is. An empty block is a fine answer — it says nobody has
agreed on a tool yet, which stops an agent adopting one on your behalf. Details and
worked entries: `docs/DESIGN-TOOLS.md`.

## Size budgets

Index notes ≤200 lines / 25 KB · detail notes <500 lines · references one level
deep · table of contents on anything over 100 lines. These exist because agents
retrieve by structure, and because index files are loaded in full.

## Why the vault is not the wiki tool you already have

Both have a place. A published wiki (Confluence, Notion) is for finished
artifacts and a wide audience. This vault is the working knowledge layer: plain
markdown in git, so it is greppable, diffable, reviewable in a PR, and readable
by an agent as context. Context and work logs live here; things the wider
organisation needs get published outward and link back.

## What never goes in

PHI or personal data · secrets, keys, tokens, `.env` contents · source code ·
anything you could not defend showing a customer's security team. Git history is
permanent.

## Vault vs. agent memory

Agent memory files are terse, machine-local notes for the next session. This
vault is the durable, linked, **team-readable** narrative. When a memory fact
matures into something the team should see, promote it into a vault note.

---
Related: [[Agent Router]]
