# Changelog

Notable changes to canon. Versions follow [semver](https://semver.org); the
public surface is the CLI flags, the config variables, and the file formats
(`.canon`, `.canon-owners`, `.canon-scan-allow`, `.canon-scan-exclude`).

## [Unreleased]

### Added

- **Push-race recovery in `canon-sync`.** When a teammate lands a commit between
  our pull and our push, git refuses ours as non-fast-forward. It now rebases
  onto what arrived and retries, up to three times, saying so once per attempt.
  Previously this printed `push failed` and left the user committed-but-unshared
  — the exact failure the tool exists to prevent, triggered by nothing worse than
  two people working at the same time. A genuine same-lines conflict stops with
  the commit intact and **no half-finished rebase**; a failure that is not a race
  (auth, network, protected branch) fails immediately with git's own message
  instead of retrying against a wall.

- **Branch modes — `CANON_BRANCH_MODE`, default `auto`.** `auto` pushes ordinary
  notes straight to the shared branch and routes changes that touch a governed
  path onto `canon/<you>/<timestamp>` with a pull-request link. The decision is
  made from **what is staged, not who is running it**, so the same person gets a
  direct push for a session note and a review branch for a vision edit without
  choosing. `--branch` and `--trunk` override per-run; `trunk` and `branch` force
  one shape for everything.
  - The working tree **stays on the review branch**, so notes do not vanish from
    the editor while a PR is open.
  - A second sync **continues the same pull request** instead of opening one per
    session.
  - `canon-status` now counts an unmerged review branch as unshared work. Pushed
    to a branch is not shared, and every other signal would have read as in step.
  - This is cooperative, not enforcement — `--trunk` bypasses it. Its job is to
    stop people hitting a server-side ruleset by accident. See `docs/MULTIPLAYER.md`.
- **`canon-guard --check`** — silent detection mode; exit status is the answer.
  How `canon-sync` decides trunk vs branch without printing the ownership lecture
  twice.

### Changed

- **Session-note filenames are author-scoped in the agent-facing rules:**
  `YYYY-MM-DD — <title> (<initials>).md`. The convention was already documented in
  `docs/MULTIPLAYER.md` and the router, but the two rule files an agent actually
  reads every session specified the unscoped form — so agents never applied it,
  and two people writing about the same thing on the same day collided on a
  filename for no reason. All four now agree.
- The Stop hook reports unshared vault work even when the repo tree is clean. A
  session that only ever touched the vault used to slip through the
  "did real work happen here" gate silently. It still never demands a session
  note for a session that changed no code.

### Fixed

- **`canon-sync --push` aborted before pushing on stock macOS.** `"origin/$BRANCH…"`
  — bash 3.2 folds the UTF-8 ellipsis bytes into the variable name, so under
  `set -u` it died with `BRANCH<junk>: unbound variable` after the commit and
  before the push. `test/run.sh` now lints for unbraced `$VAR` before any
  non-ASCII byte, which `bash -n` cannot catch.
- `canon-sync` no longer treats "this branch has no upstream yet" as a failed
  pull. On a freshly created branch it said `pull failed` and exited 1.

### Added (earlier in this cycle)

- **Provenance and trust frontmatter** — four optional keys (`generated`,
  `verified`, `status`, `stale_after`) that make an agent-maintained vault
  trustable: what a note was made from, whether a human ever confirmed it, and
  whether it is still current. Shape borrowed from the
  [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
  so vaults stay legible to other OKF-aware tooling.
  - **`canon-trust`** reports tiers, lifecycle and staleness across the vault, and
    lists agent-written notes nobody has confirmed. `--tier` filters; `--strict`
    exits non-zero on rot so CI can fail on it. Excludes `Templates/` and honours
    the vault's committed scan exclusions.
  - **`canon-verify <note>`** records a human review as a `verified:` entry. One
    entry per actor (re-confirming replaces rather than stacking), promotes a bare
    mapping to a list when a second verifier appears, and never touches
    `generated`. It does not read or judge the note — you confirm, it records.
  - Trust tiers are **derived, never stored**: a stored score is subjective,
    unportable and stale on arrival. canon records signals.
  - Agents are instructed to write `generated` and **never** `verified` for
    themselves, in both the Claude and Cursor rule files and the router.
  - Note templates carry the keys so they get copied by default. All keys are
    optional; a note without them is still valid and is never rejected.

- **MCP server** (`connectors/mcp/`) — exposes the vault to any MCP client: Claude
  Desktop, Cursor, VS Code via Copilot. Four read-only tools (`canon_router`,
  `canon_search`, `canon_list`, `canon_read`) and **no write tool at all**. One
  connector rather than one plugin per editor, and it needs no model client or API
  key: it returns notes, the host's model reasons.
  - Every caller-supplied path goes through `safeResolve()`, which resolves
    symlinks before comparing and refuses anything outside the vault.
    `test/paths.test.mjs` covers 10 cases and runs with plain `node`, no install —
    a security check that needs a network fetch is one that stops being run.
- **`AGENTS.md` and Cursor rules.** `install.sh` now writes the same instruction
  block into both `CLAUDE.md` and `AGENTS.md` from one template, and installs
  `.cursor/rules/knowledge-vault.mdc`. The test suite asserts the two blocks are
  byte-identical. This makes "works with your agent too" true rather than a claim
  the hero image made and the code did not back.

- **Chat connectors** — ask questions of the vault from **Slack**
  (`connectors/slack/`, Socket Mode so no public URL) or **Discord**
  (`connectors/discord/`, slash command with threaded follow-ups). Answers cite the
  notes they came from. Optional components: they need Node and a couple of npm
  packages, which the core kit does not.
  - Shared logic is split by dependency: `connectors/shared/vault.mjs` (locating,
    gating, safe reads — **dependency-free**, asserted by tests) and
    `connectors/shared/agent.mjs` (the model call). That split is what lets the MCP
    server avoid a model client it has no use for, and lets the path-safety tests
    run without installing anything.
  - Discord defaults to the slash command rather than mentions: answering mentions
    needs the privileged MessageContent intent, which lets the bot read every
    message in the server. Opt in with `CANON_DISCORD_ALLOW_MENTIONS=1`.
  - **Read-only by construction**: `allowedTools` is `Read`/`Grep`/`Glob` only and
    `cwd` is pinned to the vault. The test suite asserts the list and asserts that
    no connector declares its own, so it cannot regress or diverge.
  - **Fails closed**: refuses to start without `CANON_SLACK_ALLOW_CHANNELS` or
    `CANON_SLACK_ALLOW_USERS`, because the bot bypasses git permissions — git
    decides who can clone the vault, Slack decides who is in the channel.
  - **Neither has been run against live credentials.** The Slack design follows a
    working bot on the same libraries; treat each README's verification list as
    acceptance criteria rather than a formality.
- **Vaults bootstrap themselves.** `canon-init-vault` vendors the tooling into the
  vault's `.canon/` with a `bootstrap.sh`, so a teammate who clones only the vault
  can complete setup in one command with nothing else to download.

### Fixed

- `canon-install-vault-hooks` honours `core.hooksPath`. When it is set git ignores
  `.git/hooks` entirely, so the gate was being installed where git never looks —
  silently inert, verified by a planted key committing successfully.
- An existing `pre-commit` hook is now chained rather than replaced.

## [0.1.0] — 2026-07-30

First release. Everything below is verified by `./test/run.sh` (51 assertions).

### Added

- **Provenance and trust frontmatter** — four optional keys (`generated`,
  `verified`, `status`, `stale_after`) that make an agent-maintained vault
  trustable: what a note was made from, whether a human ever confirmed it, and
  whether it is still current. Shape borrowed from the
  [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
  so vaults stay legible to other OKF-aware tooling.
  - **`canon-trust`** reports tiers, lifecycle and staleness across the vault, and
    lists agent-written notes nobody has confirmed. `--tier` filters; `--strict`
    exits non-zero on rot so CI can fail on it. Excludes `Templates/` and honours
    the vault's committed scan exclusions.
  - **`canon-verify <note>`** records a human review as a `verified:` entry. One
    entry per actor (re-confirming replaces rather than stacking), promotes a bare
    mapping to a list when a second verifier appears, and never touches
    `generated`. It does not read or judge the note — you confirm, it records.
  - Trust tiers are **derived, never stored**: a stored score is subjective,
    unportable and stale on arrival. canon records signals.
  - Agents are instructed to write `generated` and **never** `verified` for
    themselves, in both the Claude and Cursor rule files and the router.
  - Note templates carry the keys so they get copied by default. All keys are
    optional; a note without them is still valid and is never rejected.

- **MCP server** (`connectors/mcp/`) — exposes the vault to any MCP client: Claude
  Desktop, Cursor, VS Code via Copilot. Four read-only tools (`canon_router`,
  `canon_search`, `canon_list`, `canon_read`) and **no write tool at all**. One
  connector rather than one plugin per editor, and it needs no model client or API
  key: it returns notes, the host's model reasons.
  - Every caller-supplied path goes through `safeResolve()`, which resolves
    symlinks before comparing and refuses anything outside the vault.
    `test/paths.test.mjs` covers 10 cases and runs with plain `node`, no install —
    a security check that needs a network fetch is one that stops being run.
- **`AGENTS.md` and Cursor rules.** `install.sh` now writes the same instruction
  block into both `CLAUDE.md` and `AGENTS.md` from one template, and installs
  `.cursor/rules/knowledge-vault.mdc`. The test suite asserts the two blocks are
  byte-identical. This makes "works with your agent too" true rather than a claim
  the hero image made and the code did not back.

- **Vault resolution** — `canon-path` resolves `$CANON_HOME` → `<repo>/.canon` →
  `~/.config/canon/path` → `~/canon`. An explicitly-set but invalid `$CANON_HOME`
  fails loudly rather than falling back, so you never silently load a different
  vault than you asked for.
- **Repo wiring** — `install.sh` installs a `CLAUDE.md` block, `.claude/settings.json`
  entries, path-scoped rules, and two hooks. Merges into existing files, never
  clobbers, idempotent on re-run. `--uninstall` removes only what it added.
- **`SessionStart` hook** — injects the vault's router note as `additionalContext`,
  truncated to stay under the 10,000-character cap. Optional `git pull` behind
  `CANON_AUTOPULL=1`.
- **`Stop` hook** — detects a session that changed files but wrote no session
  note. `remind` by default; `block` and `off` available. Fires once per session.
  Optional local auto-commit behind `CANON_AUTOCOMMIT=1`, which never pushes.
- **`canon-sync`** — pull, scan, commit, and push only on `--push`. Automatic
  inbound, deliberate outbound.
- **`canon-scan`** — credential and identifier gate over *added lines only*.
  Uses `gitleaks` when present plus built-in high-precision patterns. Suppress by
  line via `.canon-scan-allow` or by path via `.canon-scan-exclude`, both
  committed so a whole team shares one list.
- **`canon-guard`** — warns (or blocks) when a commit touches a path owned by
  someone else, per `.canon-owners`. Advisory by design; `CODEOWNERS` plus branch
  protection is the enforcing layer.
- **`canon-install-vault-hooks`** — puts both checks in the vault's `pre-commit`,
  so plain `git commit` is gated too, not only `canon-sync`.
- **Vault scaffold** — `canon-init-vault` creates the folder structure, router,
  conventions, six note templates (Session Log, Decision, Project, Client,
  Product Spec, Handoff), `.canon-owners`, and a `CODEOWNERS` starter.
- **Docs** — `docs/MULTIPLAYER.md` (ownership and permission model),
  `docs/VERIFY.md` (smoke tests against your pinned runtime), `CONTRIBUTING.md`.
- **CI** — test suite on Linux and macOS, `shellcheck`, and hygiene checks
  (executable bits, version agreement, no leaked absolute paths).

### Known limitations

Stated here because they shape how much you should trust the tool:

- **The `Stop`-hook `block` output shape is unconfirmed** against a known-good
  working example, which is why `remind` is the default. `docs/VERIFY.md` step 5
  tells you how to confirm it on your runtime version.
- **Prose-level personal-data detection is weak.** The scanner catches
  credentials well; a regex cannot recognise a clinical anecdote or a named
  individual in a sentence. Convention and human review remain the real controls.
- **`.git/hooks` is not shared by cloning** — each teammate runs
  `canon-install-vault-hooks` once. Server-side push protection is the only gate
  nobody can skip.
- **`core.hooksPath` is honoured.** When it is set, git ignores `.git/hooks`
  completely; the installer detects it and installs into the real hooks directory,
  chaining any hook already there.
- **Editor sync plugins bypass git hooks on mobile only.** Obsidian Git uses
  `simple-git` (the real git binary) on desktop, so its commits DO run the gate;
  it falls back to `isomorphic-git` on mobile, which does not. Mobile should be
  read-only for a gated vault.
- **Governance cannot restrict reading.** Path ownership controls writes; if
  someone must not *read* something, it needs a separate repository.
- **Branch protection on private GitHub repos requires a paid plan**, so the
  enforcing layer may not exist on your account. Verify before relying on it.
