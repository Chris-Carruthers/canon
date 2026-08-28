# Working in this repo

## Shared knowledge vault

This team keeps durable context — decisions, project status, client/domain
knowledge, specs, and a log of past work — in a **shared knowledge vault** that
lives outside this repo. It is plain markdown in git.

Find it by running `.claude/hooks/canon-path` (prints the vault path, exits 1 if
unconfigured). A `SessionStart` hook normally injects the vault's router note
into context automatically; if it didn't, resolve the path and read
`Vision/Agent Router.md` yourself.

**Before non-trivial work**, read from the vault:

- `Vision/` — how this team works, conventions (read first)
- `Projects/<name>.md` — what the workstream is and where it stands
- the newest `Sessions/` note linked from that project — what happened last
- `Reference/Design/` — **before building any UI.** The design canon: which token
  names exist, which components already exist (and which deliberately do not), and
  where each resolves to a Figma node and an implementation. If you are about to
  run a design tool, read the `design-tools` block first and target the vocabulary
  the row names — a generator left to pick its own invents a new one.

Reach vault content **on demand** with glob and grep against the vault path.
Do not try to load the vault; it is far larger than a context window.

**After meaningful work**, write a dated note to the vault's `Sessions/`:
goal, what changed with `repo-path:line` references, decisions, open follow-ups —
linked to its project. If a real choice was made, also add a `Decisions/` note.
Skip this for trivial questions; use judgment.

## Vault rules — non-negotiable

- **Never write PHI, personal data, secrets, keys, tokens, or `.env` contents
  into the vault.** It is a git repo; history is permanent.
- **No source code in the vault.** Link `repo/path.ts:42` instead.
- **No design-token values in the vault.** Token *names* belong there; values live
  in the repo. Write `--primary`, never `222 47% 11%`.
- Do not commit or push the vault on the user's behalf unless asked.

Detailed write conventions load automatically when you touch vault files
(see `.claude/rules/`).

## This repo

<!-- REAL HEADINGS ON PURPOSE, not a comment. An empty section is VISIBLE: an
     agent that reads this file sees that nobody has written down how to build
     this repo, and can say so. The same words hidden in an HTML comment are
     invisible in every rendered view and get skipped for years.

     Run `/repo-context` to fill this in from the repo itself, or write it by
     hand. Keep the whole file under ~200 lines — it loads in full on every
     request. Push reference material into skills or .claude/rules/ instead of
     inlining it here. -->

**If this section is still empty, fill it in.** You are about to learn most of it
anyway in order to do the work; writing it down is the difference between learning
it once and every agent after you re-deriving it. Propose it in your PR — a
teammate should correct it, not merely inherit it.

### Build and run

<!-- The exact commands, and where they are defined (package.json script, Makefile
     target, justfile). Cite the file so the next reader can check it hasn't
     drifted. Include how to run it locally, and the port. -->

### Test

<!-- How to run the suite, how to run ONE test, and how coverage is produced.
     If this repo is declared in the vault's testing canon
     (Reference/Testing/), name the suite slug — the floor and the CI gate live
     there, not here, so they cannot drift out of sync with the audit. -->

### Architecture in three sentences

<!-- Entry point, the one or two boundaries that matter, and where the data lives.
     Three sentences, not a diagram. If it needs more, it needs a vault note —
     link that instead. -->

### Gotchas

<!-- The things that cost someone half a day and are not visible from the code:
     the migration that must be applied by hand, the env var with no default, the
     test that only passes from the repo root, the service you must start first.
     This is the highest-value part of this file. Write what surprised you. -->
