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

## Note conventions

- **Link generously** with `[[wikilinks]]`; links to not-yet-written notes are
  useful placeholders.
- **Tag** for filtering (`#client/…`, `#project/…`, `#type/…`).
- **One concept per note.**
- **Frontmatter** `type:` / `status:` / `updated:` so notes can be tabled
  automatically.
- **Code stays out.** Link to repo paths.

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
