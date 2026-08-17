# Changelog

Notable changes to canon. Versions follow [semver](https://semver.org); the
public surface is the CLI flags, the config variables, and the file formats
(`.canon`, `.canon-owners`, `.canon-scan-allow`, `.canon-scan-exclude`).

## [Unreleased]

### Added

- **A `design-tools` block** — a third frozen fenced block in the design canon,
  recording what is approved for *making or fixing* UI, alongside a
  `templates/repo/DESIGN.md` for wiring a tool to it and `docs/DESIGN-TOOLS.md`
  with two worked entries.

  The canon could say what existed and whether the code conformed. It had no answer
  for "what do I use to build one", so an agent reaching `Reference/Design/` learned
  that nothing was canonical and stopped there.

  The block follows the kit's only existing precedent for an external design vendor.
  Figma is not registered anywhere: it is a typed pointer field validated by
  `canon-design-audit`, with a hard rule against storing the URL. So a tool row
  carries an identifier and never a location — no URL to rot when a product gets
  renamed, no filesystem path, because a skill sits at a different absolute path on
  every machine.

  Two keys carry the weight. **`verified:` is required**, because third-party
  capability rots faster than anything else in this canon — features ship, limits
  change, free tiers get metered — and a claim with no date is one somebody acts on
  a year after it stopped being true. A row older than 180 days becomes a
  `DS-TOOL-STALE` **GAP**, so an unchecked claim decays into a visible absence
  rather than a quiet lie; it is a GAP and not a violation because a rule that can
  fail a build through the mere passage of time is a rule someone switches off.

  **`vocabulary:` is required for any tool whose `roles:` write UI**, and the audit
  cross-checks it against the `design-tokens` block. A generator given no target
  vocabulary does not decline to choose one — it invents one, and you meet the extra
  `--primary` months later in a diff that looked fine and a suite that stayed green.
  This is the enforcement arm of *names in the vault, values in the repo*: the tool
  is told which names to use and reads the values from the repo itself.

  New rules: `DS-TOOL-MALFORMED` (VIOLATION) and `DS-TOOL-STALE` (GAP).
  `values-to` is resolved like `impl` and `source`, so a tool aimed at a tokens file
  that does not exist reports `DS-POINTER-DEAD`.

  **A vault that registers no tools produces byte-identical output to a build
  without this feature**, in every mode including `--json`. An unused registry
  should be invisible, not a row of zeroes.

- **`canon-sync --only <path>`** (repeatable) stages just the paths you name.

  The default stays `git add -A`, which is right for one person and one vault. It
  stops being right the moment a second agent session writes to the same vault:
  `git add -A` cannot tell your notes from the half-written ones another session
  left two minutes ago, so both land in one commit under your message. Nothing is
  lost, but the history now asserts something untrue, and a shared vault's history
  is the thing you are meant to be able to trust.

  A path that does not exist is refused with exit 2 and **nothing staged**, rather
  than silently committing nothing or falling back to everything.

### Changed

- **The design-system Ownership section is a filled-in placeholder with
  instructions**, not an empty table. It now names four roles — token contract,
  component review, accessibility, and who is accountable when it stalls — and
  explains why they are usually different people, so a team can decide rather than
  guess. "Unowned" remains an explicitly valid answer, and the Evidence column
  makes assumed ownership visible as the non-answer it is.
- **The Cowork cloud-session note states the trade-off instead of recommending
  one.** Whether notes may leave the machine depends on what is in the vault, and
  that is the accountable owner's call, not this project's default. It now points
  out that the scanner gates credentials and is *not* the control for this, and
  suggests recording the answer as a `Decisions/` note.

- **Claude Desktop and Cowork support.** `connectors/mcpb/` packs canon's existing
  read-only MCP server into a double-clickable **`.mcpb` bundle**: the user picks
  their vault folder in a dialog, which is wired to `CANON_HOME`, so there is no
  config file to hand-edit and no terminal. `build.sh` verifies the manifest version
  against `VERSION` and that the entry point is actually in the bundle before
  packing, rather than after shipping.
  - The bundle keeps the repo's directory layout instead of flattening it, so
    `server.mjs` can keep importing `../../shared/vault.mjs` unchanged. Flattening
    would have created a second copy of that import to keep in step.
  - **Documented the constraint that actually decides the setup:** Cowork runs
    sessions **in the cloud by default**, and *local MCP servers do not run in cloud
    sessions*. So the bundle covers Claude Desktop and **local** Cowork sessions,
    while the zero-install path for cloud sessions is adding the vault as a
    **connected folder** — which works because a cloud session reaches local files
    back through the desktop app.
  - Also notes that in a cloud session the notes Claude reads leave the machine.
    Fine for most vaults, wrong for some; the scanner gates credentials at commit
    time and has no opinion about what you later share.
  - `connectors/mcp/package.json` bumped 0.1.0 → 0.2.0 so the version an MCP client
    reports in `serverInfo` matches the bundle a user installed.
  - Twelve assertions on manifest coherence, since CI cannot run the packer (it
    needs node and npm). The built `canon.mcpb` is gitignored — it is an artifact.

- **canon installs as a Claude Code plugin.**
  `/plugin marketplace add Chris-Carruthers/canon` then `/plugin install canon@canon`
  — no clone, and the hooks apply to every project rather than the one folder you
  ran the installer in. Ships `.claude-plugin/plugin.json`, a
  `.claude-plugin/marketplace.json` so the repo is its own marketplace,
  `hooks/hooks.json` wiring SessionStart and Stop, and three slash commands:
  `/canon-setup`, `/canon-sync`, `/canon-status`.
  - **One set of hook scripts serves both installs.** They now resolve their tools
    from the repo copy → `${CLAUDE_PLUGIN_ROOT}/bin` → `PATH`. Shipping a second
    copy under `hooks/` would have been simpler and would have drifted; this kit
    has already been bitten once by two artifacts that were supposed to agree.
  - `/canon-setup` exists because the one thing a plugin genuinely cannot do is
    know **where your vault is**. It walks the three cases and is explicit that the
    plugin does **not** install the commit-time secret gate — that is a git hook
    inside the vault.
  - Verified by installing it into real Claude Code (2.1.232) and running both
    hooks out of the plugin cache with only `CLAUDE_PLUGIN_ROOT` set, rather than
    by checking that the JSON parses.

- **`install.sh` writes instruction files for seven runtimes**, all generated from
  the single `agent-instructions.md` template so they cannot disagree: `CLAUDE.md`,
  `AGENTS.md`, `GEMINI.md`, `.github/copilot-instructions.md`,
  `.cursor/rules/knowledge-vault.mdc`, `.windsurf/rules/knowledge-vault.md`,
  `.clinerules/knowledge-vault.md`. A test asserts they are byte-identical.
  - On by default — a stray instruction file costs nothing, while a missing one is
    a teammate silently getting no context because they use a different tool. Opt
    out with `--no-gemini`, `--no-copilot`, `--no-windsurf`, `--no-cline` or
    `--claude-only`.
  - **`--uninstall` removes all of them without being handed the same flags**, and
    now **deletes** a file it created outright instead of leaving a zero-byte one.
    An uninstaller that leaves litter is one people stop trusting.
  - Stated plainly in the README: these make other agents *read* the vault. Only
    Claude Code gets the hooks, because it is the only one of the seven with a hook
    system to attach to.

- **A design system canon** — `Reference/Design/`, plus two templates
  (**Design System**, **Design Component**). Templates go 6 → 8.

  A design system is mostly code, and code stays out of the vault. So the canon
  holds the part that is *not* code: **token names, intent, and pointers.** A token
  *name* is API surface, like a schema field name, and `Reference/` is for schemas.
  A token *value* is source — it has a format, it belongs to a cascade, and any
  tool can read it from the repo on demand. Copy values into the vault and you have
  made a second source of truth that drifts silently while reading as
  authoritative. That rule is now stated in the router, `How We Work`, both rules
  files, and `agent-instructions.md`.

  - **Two frozen fenced blocks**, `design-tokens` and `design-components`,
    namespaced so a generic fence name cannot collide. The key list is documented
    in the Design System template and will be enforced by `canon-design-audit`.
    Namespacing and freezing are a direct response to the kit's existing scar: a
    Product Spec template whose fence names never matched the validator written
    against it, so every file made from the template failed the check.
  - **A three-rung resolution ladder** so a coding agent can answer "what does this
    look like / which token do I use" without guessing: an exported image at
    `Attachments/Design/<slug>--<variant>--<state>@<theme>.png` (no network, no
    auth), a Figma `{ file, node }`, then `impl: repo/path`. Filenames are
    *constructible*, so an agent derives the expected path and checks existence.
  - **Omit a key you do not have — never `TODO`.** Absence is the machine-readable
    signal and coverage is *derived* from it. A row full of `TODO`s reports as
    complete-but-broken instead of honestly incomplete.
  - **`status: absent` is a legitimate row.** "There is no shared `PageHeader`"
    stops an agent hunting for one *and* stops it silently inventing a fourth.
  - **Figma nodes are stored as `{ file, node }`, never as URLs** — a URL carries a
    rename-fragile slug and often a `t=` session parameter that is credential-shaped
    and that `canon-scan` will not catch. Node IDs are dash form here (what URLs
    carry) and colon form at the API (what it wants); the conversion is documented
    once, because it is the thing everyone gets wrong.
  - **Two tiers**: a row covers most components; a per-component note exists only
    when a reader would ask *why*. Thirty notes for thirty primitives is
    boilerplate. The note's frontmatter is deliberately the same field set as one
    row, so promoting duplicates nothing.
  - `Reference/Design/` is a **routed subtree, not a 14th top-level folder** —
    twelve edit points and an empty folder on every vault that ships no UI, for no
    retrieval benefit, since retrieval is by filename.
  - Governance rules ship **commented out** in both `.canon-owners` and
    `CODEOWNERS`, with the ordering inversion spelled out: `.canon-owners` is
    first-match-wins so the rule sits *above* the open `Reference/**` row, while
    CODEOWNERS is last-match-wins so its twin sits near the *end*. Both files also
    say what they cannot reach — the token values live in application repos, so the
    rule that actually protects a design system is CODEOWNERS *there*.
  - A **binary-assets row** in `docs/MULTIPLAYER.md`'s conflict-risk table, and a
    deterministic split: if a note cites the path in frontmatter it lives in
    `Attachments/`; if the ingest loop compiles it away it lives in `Sources/`.

- **`canon-design-audit`** — reads the contract from the vault and the facts from
  your code repos, and recomputes everything every run. Six VIOLATION rules
  (colour literals, Tailwind palette utilities, dead pointers, missing assets,
  malformed Figma references, malformed blocks) and three GAP rules (name-set and
  format-label mismatches), plus derived coverage. `--report` writes one dated
  `Outputs/` note stamped `process:canon-design-audit` with `stale_after: +30d`, so
  `canon-trust --strict` fails on an audit nobody re-ran.

  Most of its design is about **not** being the tool nobody reads. The existing
  cautionary example is a token-parity script that reports nine false `DRIFTED`
  results out of twenty-six, because it compares an alias against a literal:

  - **It never compares two token values.** Value equivalence across aliases,
    `calc()`, colour spaces, the cascade and shadow-root scoping is a CSS
    resolution problem a regex cannot solve. It compares name sets and format
    labels and leaves the rest to the browser. Stated in the header as a design
    constraint, not an omission.
  - **Two severities, one of which can fail a build.** VIOLATION is checkable by
    opening the cited line; GAP is a judgement call and never fails anything, even
    with `--strict`. A tool that fails on judgement calls gets switched off.
  - **The skip-list is learned from the canon.** Files the canon names as a
    `source:` or `catalog:` are *supposed* to contain literals, so declaring a
    vocabulary silences its own false positives.
  - **A closed list** of Tailwind's 22 default palette names × 11 steps, so
    `bg-primary` and `text-muted-foreground` are structurally unmatchable.
  - **Baseline, not zero** — `.canon-design-baseline` per repo, and `--strict` fails
    only on counts *above* it. On a repo with fourteen thousand existing violations
    the only useful signal is whether it got worse.
  - **An unscanned repo is unknown, not broken.** Pointers into repos that were not
    passed on the command line are reported as unverifiable rather than dead.
  - **Comment-stripping before matching**, and a hex heuristic that requires a hex
    letter in 3- and 4-digit forms so an issue reference like `#1234` is not read as
    a colour.
  - **Read-only in every repo it scans**, asserted by a test. Deliberately **not**
    in any pre-commit hook — it scans code repos, not the vault. It measures;
    CODEOWNERS on the token files plus branch protection is what enforces.

  Calibrated against an independently measured baseline before being trusted, and
  `docs/VERIFY.md` now carries that calibration as a numbered procedure.

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

- **The docs no longer read as a tool for engineers.** Every setup example wired
  canon into a code repository, so readers whose work is meetings, decisions and
  research concluded it was not for them. A code repo was never required — three
  of the four vault-resolution paths do not involve one, and `install.sh` works on
  a folder that is not even a git repo. New **"Two ways to set it up"** section,
  Quickstart shows both, and the no-terminal guide now ends with the non-engineer
  route instead of handing readers to a repo-shaped README.
  - Documents the reason the choice exists: the end-of-session prompt infers "real
    work happened" from **changed files in the working folder**, which is no
    signal at all outside a repo. Pointing a non-engineering session at the vault
    itself makes "files changed here" mean "notes you wrote", and the loop closes.
    Pointed anywhere else you get the reading half and never the writing half.
  - `install.sh` says the same thing when the target is not a git repo — a
    supported setup with one specific consequence, rather than a bare "warning".
  - Documents that a vault used as its own workspace resolves by
    `~/.config/canon/path`, not by rule 2: inside a vault `.canon` is a directory
    of vendored tooling, not the marker file.

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
- **`canon-guard` split staged paths on whitespace**, so a filename with a space
  in it became several fragments — it reported `Vision/Agent` for
  `Vision/Agent Router.md`, and matched globs against the fragment rather than the
  path. Vault filenames have spaces *by convention*
  (`2026-08-07 — thing (cc).md`), so this was wrong for the naming scheme canon
  itself prescribes, and `--check` inherited it, making `auto` branch mode's
  routing unreliable. Now reads `-z` NUL-delimited output.

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
