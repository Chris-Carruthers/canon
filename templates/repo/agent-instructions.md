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
- Do not commit or push the vault on the user's behalf unless asked.

Detailed write conventions load automatically when you touch vault files
(see `.claude/rules/`).

<!-- Add repo-specific guidance below this line: build commands, architecture,
     testing, gotchas. Keep this whole file under ~200 lines — it loads in full
     on every request. Push reference material into skills or .claude/rules/
     instead of inlining it here. -->
