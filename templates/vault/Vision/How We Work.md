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
