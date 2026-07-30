# Changelog

Notable changes to canon. Versions follow [semver](https://semver.org); the
public surface is the CLI flags, the config variables, and the file formats
(`.canon`, `.canon-owners`, `.canon-scan-allow`, `.canon-scan-exclude`).

## [Unreleased]

### Added

- **Chat connectors** — ask questions of the vault from **Slack**
  (`connectors/slack/`, Socket Mode so no public URL) or **Discord**
  (`connectors/discord/`, slash command with threaded follow-ups). Answers cite the
  notes they came from. Optional components: they need Node and a couple of npm
  packages, which the core kit does not.
  - Shared logic lives in `connectors/shared/core.mjs` — vault resolution, the
    allowlist gate, the agent call, citation extraction. The safety model is
    defined once so two platforms cannot drift apart on it.
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
