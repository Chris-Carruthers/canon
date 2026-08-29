# Changelog

Notable changes to canon. Versions follow [semver](https://semver.org); the
public surface is the CLI flags, the config variables, and the file formats
(`.canon`, `.canon-owners`, `.canon-scan-allow`, `.canon-scan-exclude`).

## [Unreleased]

_Nothing yet._

## [0.3.0] — 2026-08-29

### Added

- **Releases exist now, and a stale install says so.** There were **no git tags and
  no GitHub releases**, and `VERSION` had not moved in 68 commits — everything since
  `413d433` accumulated under `[Unreleased]` at 0.2.0. So nobody could be behind,
  because there was nothing to be behind of, and nothing anywhere checked.

  Worse, **three copies drift independently**: the kit, the vault's vendored
  `.canon/` tools, and each repo's `.claude/hooks/`. Upgrading the kit does nothing
  to a repo wired weeks ago — it keeps running the old hooks, silently, forever, and
  nothing in the files says how old they are.

  `canon-init-vault` and `install.sh` now stamp `.canon-version` where they write.
  `canon-status` compares those against what is actually running and names the
  command that fixes it — `re-run canon-init-vault`, `re-run install.sh`. Both hooks
  export `CANON_REPO` so the repo copy can be checked at all; without it that check
  could never fire, and the repo copy is the one most likely to be stale.

  **The release check does not live in `canon-status`.** That command runs in a
  `SessionStart` hook and promises no network call — a hook that hangs on a bad
  connection is worse than a stale version number. `canon-sync` already makes a
  network call, so it asks GitHub once a day and writes the answer to
  `${XDG_CACHE_HOME:-~/.cache}/canon/latest-release`; `canon-status` only reads it.
  Best-effort throughout: no curl, no network, no releases, a rate limit — all leave
  the cache alone and say nothing. Opt out with `CANON_CHECK_UPDATES=0`.

  An in-step install is **silent**. A banner that always shows is one people stop
  reading, which is exactly how the solo-vault nag survived this long.

- **A vault with no remote was reported as out of step with a team that does not
  exist.** `canon-init-vault` creates a repo and configures no remote, so
  `canon-status` found no `.git/FETCH_HEAD` and said *"never pulled from the team ·
  Get up to date: canon-sync"* — on **every vault's first run**, and permanently for
  anyone working alone. The `SessionStart` hook instructs the agent to raise this in
  its first reply, so canon's opening move was a standing complaint the user could
  not act on: with no remote, `canon-sync` has nothing to pull.

  Team signals are now conditional on a remote existing. A solo vault with
  uncommitted work says *"Save it locally: canon-sync (no remote yet — add one to
  share with a team)"* rather than offering `--push` into nowhere, and a clean one
  is silent. Add a remote and every previous signal returns unchanged.

  The test that covered this **required** the wrong message — `has "flags a vault
  never pulled"` against a vault with no remote — so the suite encoded the defect
  instead of catching it. Replaced with assertions for both states.

  The `Stop` hook echoes `canon-status`, so it inherited the same wrong framing in
  prose it hardcodes: *"out of step with the team"* and *"the note is not shared
  until it is pushed"*. Both are now conditional on a remote existing — a solo
  vault is told its work is unsaved and one lost laptop from gone, which is the
  true and actionable version.

- **The MCP server's header promised a default it did not have.** It said large
  vendored subtrees are *"skipped by default"* and named the 79 MB documentation
  mirror it would otherwise drown in. The actual defaults are `.git`, `.canon` and
  `node_modules`; the exclusion is opt-in via `CANON_MCP_EXCLUDE`. The package
  README stated this correctly, so the wrong copy was the one a maintainer reads,
  and the failure it promised to prevent is the exact one a real vault hits.

- **Six version declarations CI never checked, two already wrong.** The check
  covered `bin/canon-*` and `install.sh` only. `connectors/slack/package.json` and
  `connectors/discord/package.json` were still on `0.1.0`, and
  `connectors/mcp/src/server.mjs` hardcoded `version: "0.1.0"` as the identity it
  advertises **over the protocol** — so an MCP client saw a version that nothing
  else in the repo agreed with. All now derive from `VERSION`, and the CI step
  covers `plugin.json`, the `.mcpb` manifest, all three connector packages, and the
  string inside the server.

- **Feature wiring is asserted, not assumed.** A feature has to reach six surfaces —
  the router, `How We Work`, both repo rules files, `agent-instructions.md` and the
  README — and every one of them had shipped reaching a different subset. Cognitive
  coverage never reached `agent-instructions.md` or `How We Work`; house voice
  reached neither rules file; template packs reached nothing an agent reads, so no
  agent knew optional templates existed. Nothing failed, because each surface was
  only ever checked one at a time.

  `agent-instructions.md` is the one that matters most: `install.sh` writes it into
  **all seven** runtime files, so anything absent there is invisible to Gemini,
  Copilot, Windsurf, Cline and `AGENTS.md`. Three new assertions close the matrix,
  one per surface class.

  Fixed alongside: `Reference/Writing/`, `Reference/Testing/` and
  `Reference/Cognitive Coverage/` added to the reading list every runtime gets;
  template packs described in both rules files; a `Cognitive coverage` section in
  `How We Work`, which had none.

- **A template filed into a folder canon never creates.** `Design Critique` pointed
  at `Reviews/` — absent from `canon-init-vault`'s directory list, covered by no
  `.gitkeep`, and named nowhere else in the kit, so a teammate cloning the vault
  would not have had the directory at all. Now `Reference/Design/Critiques/`, and a
  new assertion checks every template's `File as:` destination against the folders
  that actually get scaffolded.

- **Every note template now carries `generated:` and says where it is filed.**
  `Handoff` and `Product Spec` were the two without provenance frontmatter, and the
  assertion covering it was pinned to `8` — it recorded the gap rather than catching
  it, so both stayed that way through every run. It now counts templates *without*
  the key and requires zero. Five templates never said where the note goes: Client,
  Decision, Handoff, Project and Session Log. Handoff mattered most, because the
  spec cites it by path.

- **`plugin.json` advertised two of three skills.** `repo-context` was missing.

- **The README's nav omitted the design canon** while listing every newer feature —
  each release added its own entry and the biggest one was never retrofitted.

- **`--help` works on every script, and is asserted.** Five of the twelve bins took
  the flag as a positional argument: `canon-init-vault --help` got as far as
  `mkdir --help` and printed `mkdir: illegal option -- -`, which reads as a crash
  rather than a usage error; `canon-scan` and `canon-install-vault-hooks` failed
  with "not a directory" / "not a git repo"; `canon-guard` printed nothing and
  exited 0; `canon-path` ignored the flag and printed the vault path.

  All thirteen entry points now share one idiom, extending the `--version` case
  that was already uniform. Help renders the file's own header comment with the
  `#` markers stripped, so it terminates wherever the header does instead of at a
  hardcoded line number — the seven scripts that did have `-h` used
  `sed -n '2,NNp'`, which silently truncates the moment somebody adds a paragraph.

  CI asserts what a reader actually needs: exit 0, non-empty, no leaked comment
  marker, first line names the script, and `-h` is byte-identical to `--help`.
  Nothing tested `--help` before; only `--version` was covered.

- **Template packs, and `canon-pack`** — optional note templates, asked for rather than
  installed.

  `canon-init-vault` copied every file under `templates/vault/` into every vault, which
  is right for the core and wrong for everything else. Growing the catalogue to
  twenty-one templates so that three teams each find four useful would have made
  `Templates/` unreadable for all of them — the same failure the design canon names,
  *thirty notes for thirty primitives is boilerplate, not knowledge*.

  Three packs. **`product-ladder`** (One-pager, PR-FAQ, Six-pager, Shape Up Pitch) is the
  cheap rungs below the heavyweight `Product Spec`, which was the only product document
  the core shipped and is the wrong first artefact for an unproven idea.
  **`engineering`** (RFC, Architecture Overview, Runbook, Postmortem) closes the biggest
  structural gap: `Decision` is an ADR, retrospective by design, so canon could record a
  decision but not **argue** for one. **`research-craft`** (Research Findings, Design
  Critique, Content & UX Copy Guide).

  `canon-pack list | add | remove`, plus `canon-init-vault --pack <name>` through the
  same code path. **`add` never overwrites** — identical contract to init, so re-running
  is how you pick up new templates after an upgrade. **`remove` only deletes what it
  shipped**: a file goes only if it is still byte-identical to the kit's template, and
  an edited one is kept and reported. Without that rule an `add` typo followed by a
  `remove` silently destroys somebody's note.

  `canon-pack` is **not** vendored into vaults. Unlike the other bins it is not
  self-contained — it copies out of `templates/packs/`, which is not in the vault — so a
  vendored copy would resolve an empty directory and report "no packs available" as
  though that were a fact. A detached copy now refuses to run and says why.

  Eleven more `house-voice` reference files, one per pack template, shipping whether or
  not the pack is installed: a skill costs nothing until it loads, and a template
  arriving without its voice is the worse failure. CI walks `templates/packs/` in the
  same both-directions wiring check as the core — every template points at a reference
  file that exists, and every reference file is reachable from the skill.

  The bare-init template count stays asserted at 10, which is now the regression guard
  that packs are genuinely opt-in.

- **House voice** — a map from each document type to a writer with a real corpus, the
  moves to imitate, and the anti-model to avoid.

  The templates said what sections a document has and nothing said how it should
  *read*, so structure got enforced and prose got improvised — and improvised prose
  defaults to whatever register the writer last saw. A Decision note becomes meeting
  minutes: who attended, what was discussed, no statement of what was chosen or what it
  cost. A Handoff becomes a status report, with the unmerged branch marked "in
  progress", an adjective standing where a fact should be. Both pass the template check
  and are useless to the next person.

  Ships as the `house-voice` skill with eleven reference files, one per document type,
  each in six fixed parts: who to write like · why them · who **not** to write like and
  what goes wrong · the moves · what to go read · a five-question pre-save check.

  **The selection criterion is a retrievable corpus of that exact document type, not
  fame**, and that decides most of the picks. An agent cannot imitate a sensibility it
  has never read; it can imitate a corpus. The most celebrated designer of the last
  thirty years left almost nothing written, so asking for his voice yields reverent
  adjectives — the model fills the gap with the *idea* of the person. GOV.UK's design
  system has ten thousand pages of exactly the document you are writing.

  **Every file names an anti-model, and it does more work than the exemplar.** "Write it
  like Nygard's ADR" is advice; "do not write it like meeting minutes, which record what
  was discussed rather than what was chosen" names the failure the writer is otherwise
  about to commit.

  Two new vault notes, seeded by `canon-init-vault`: `Reference/Writing/House Voice.md`,
  which **overrides** the shipped defaults because a team's own exemplars are the more
  valuable thing, and `Reference/Writing/Choosing a Document.md`, the escalation ladder —
  which document at which stage, pick the cheapest rung that still works. Plus a voice
  pointer in the header of all ten note templates, a router row, and a `How We Work`
  section. No template was added, so the template count stays at 10.

- **A testing canon, and `canon-test-audit`** — what is tested, the floor it may not
  fall below, and whether the gate that checks it can actually block a merge.

  `Reference/Testing/` holds two frozen fenced blocks, `test-suites` and
  `test-gates`, following the design canon's split: **thresholds and pointers, never
  measurements.** The percentage lives in the coverage report your suite already
  writes; a number typed into a note is wrong the next day and still reads as
  authoritative. Ships with a `Test Canon` note template (templates 9 → 10), a
  router row, `How We Work` doctrine, and a rule bullet in **both** the Claude and
  Cursor rules files.

  Two rules carry the value, and both were learned expensively. **A floor is a
  ratchet, not a target** — set it to the coverage you already have, rounded down;
  one set to where you wish you were fails on day one, gets muted within a week, and
  then measures nothing while still looking like a control. **A gate nobody made
  required is a decoration** — a workflow that runs, reports and cannot block a
  merge is advice, and that difference is invisible from a checkout.

  `canon-test-audit` reads the contract from the vault and the facts from your repos
  and derives everything on every run. The check worth the whole tool is
  **`TEST-GATE-BRANCH-MISMATCH`**: forge branch filters are case-sensitive, so a
  workflow filtered on `dev` against a branch named `Dev` runs on nothing — no run,
  no failure, no signal, and a PR list that looks clean. It is a string comparison,
  and it is the difference between a gate and a decoration.

  Also `TEST-FLOOR-BREACH`, `TEST-REPORT-MISSING` (an unverifiable floor reads as a
  passing one), `TEST-REPORT-STALE`, `TEST-GATE-WORKFLOW-MISSING`,
  `TEST-GATE-JOB-MISSING`, `TEST-BLOCK-MALFORMED`, and as GAPs —
  `TEST-GATE-ADVISORY`, `TEST-SUITE-UNDECLARED`, `TEST-FLOOR-ABSENT`,
  `TEST-REPORT-UNDECLARED`. `--strict` compares against a `.canon-test-baseline`
  rather than zero, because on a repo with a long tail of untested code the only
  useful signal is *did it get worse*. `--ratchet` prints the floor each suite could claim today and
  **deliberately refuses to suggest a lower one**, since lowering a floor is how a
  ratchet quietly becomes a target.

  **Four deliberate non-goals**, each of them the design. It never runs your tests —
  executing an arbitrary repo's suite is slow, needs its dependencies, and is a
  code-execution surface pointed at whatever the canon names; it reads the report the
  suite already wrote and reports its age. It never computes coverage — it parses
  cobertura, lcov or an istanbul json-summary, and an unrecognised format is a clean
  error, because a guessed denominator is a confident wrong number. It cannot see
  branch protection, which is server-side, so `required:` is a **human attestation**
  recorded with `canon-verify` and `TEST-GATE-ADVISORY` can never fail a build. And
  it does not judge whether coverage is *meaningful* — a test that merely imports a
  module takes it from 0% to 100%, which is a documented caveat for the human
  setting the floor rather than a faked check.

  Read-only in every repo it scans, asserted by a test. In no pre-commit hook: it
  scans code repos, not the vault. `TEST-REPORT-STALE` is an explicit
  `--max-report-age` window rather than a comparison against HEAD's commit time —
  commit time is when somebody committed, not when the code changed, so the
  obvious-looking version fires on "ran the suite, then committed", and a rule that
  fires on correct behaviour is a rule people switch off.

- **`repo-context` skill, and the other half of `CLAUDE.md`** — the repo-specific
  section of the generated instruction files was an HTML comment, so canon
  guaranteed every repo had the files and nothing about the repo knowledge in them.

  `templates/repo/agent-instructions.md` now ships a real `## This repo` skeleton —
  build and run, test, architecture in three sentences, gotchas — as **headings
  rather than a comment**, because an empty section is visible and an agent can say
  nobody wrote this down, whereas the same words in a comment are invisible in every
  rendered view.

  `/repo-context` fills it in from the repo itself — manifests, the CI workflow,
  compose files, env templates — and **cites where each command is defined** rather
  than asserting one it never saw, because a confidently wrong build command is
  worse than a blank section. As a byproduct it emits the `test-suites` and
  `test-gates` rows above: it has just read the test config and the workflow, which
  is exactly what the canon needs, so the rows are produced then instead of becoming
  a second chore nobody does. If the workflow's branch filter disagrees with what
  git calls the branch, it reports that as a finding rather than quietly writing the
  working one down.

- **`cognitive-coverage` skill** — a graded quiz on what your agent just built,
  recorded with a date.

  Code review asks *is this correct*; tests ask *does it work*. Neither asks whether
  a **person** can explain it without reading it again. Agent-built code fails that
  quietly, precisely because it passes review.

  Six to ten questions across six bands — shape, state, failure, boundary, decision,
  change — asked one at a time and graded against the implementation. At least one
  must be about something *surprising* in the code, because that is where
  understanding lives and it is what nobody retains from watching an agent work.

  Records to `Reference/Cognitive Coverage/<feature>.md`, newest first, **appending
  rather than overwriting**, with the questions asked so a re-test can be harder
  instead of identical. Ships with a `Cognitive Coverage` note template (templates
  8 → 9) and a router row.

  **Most of the design is refusing to be nice.** A quiz everyone passes is worse than
  no quiz: it converts an unknown gap into a false belief and burns the one moment
  somebody was willing to be tested. So an answer that would equally fit a different
  implementation is *partial* at best, "I don't know" is a *gap* and never a partial,
  softball questions answerable from a function name are called out as a failure
  mode, and the bands are never averaged into one number — a person solid on shape
  and blank on failure modes has a specific problem that a percentage hides.

  It stores its result, against the kit's derived-never-stored rule, and says why:
  this cannot be recomputed, because it records what a specific person could explain
  on a specific date. Same class of fact as `verified:`.

  Framed as a coverage report for a system rather than a performance review — stated
  in the skill itself, because if it reads as a scorecard on a colleague then nobody
  asks for it twice and the people who need it stop first.
- **`--export` and `--view`: the canon as one document, for both audiences.**

  The canon was written for machines and readable by neither. An agent that wanted it
  as data had to reimplement the `Reference/Design/` walk and three fence regexes,
  and the only existing parser lives inside a bash heredoc where nothing can import
  it — `--json` exported two integers about the new block. A person had to open
  several notes and then a CSS file in a repo they may not have cloned, and there was
  no swatch anywhere: image coverage is routinely 0 of N.

  `--export` prints the resolved canon as JSON — vocabularies with their **current
  values read from the repo**, components with which rungs resolve, registered tools
  with their targets joined out per repo, and the tokens more than one vocabulary
  claims. `--view` writes the same model to `Outputs/<date> — Design System View.md`:
  plain markdown so an agent greps it, tables and colour chips so a person reads it
  in Obsidian. The kit's own rule is Bases for human dashboards and plain text for
  anything an agent must read — and a Base cannot see inside a fenced block, so the
  only surface that serves both is a derived one.

  Values appear and are still not stored: both outputs are dated and regenerated,
  exactly like the audit report. Where a naming repo was not scanned the values read
  `unverifiable` rather than absent — unscanned is unknown, not empty. Colours are
  emitted as the CSS function their declared format implies and left for the renderer
  to resolve, because deciding whether two colour spaces agree is the browser's job,
  not a regex's.

  The collision table is the part no previous artifact had: the tokens several
  vocabularies each declare, flagged where they also differ in colour space. That is
  where "I assumed they matched" starts, and it was previously only assertable in
  prose — which is how this canon came to hold a value claim it had no way to notice
  going stale.

- **A `design-tools` block** — a third frozen fenced block in the design canon,
  recording what is approved for *making or fixing* UI, alongside a
  `templates/repo/DESIGN.md` for wiring a tool to it and `docs/DESIGN-TOOLS.md`
  with two worked entries.

  The canon could say what existed and whether the code conformed. It had no answer
  for "what do I use to build one", so an agent reaching `Reference/Design/` learned
  that nothing was canonical and stopped there.

  The block follows the kit's only existing precedent for an external design vendor.
  Figma has no registry entry — it is a typed pointer field on a component row,
  validated by `canon-design-audit`, with a hard rule against storing the URL. So a tool row
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

  **A vault whose blocks are valid and which registers no tools produces
  byte-identical findings to a build without this feature.** An unused registry
  should be invisible, not a row of zeroes. Scoped deliberately: `--help` gained
  three lines, and `PLACEHOLDER_KEYS` grew by five names that also apply to token
  and component rows, so a pre-existing row with `status: TODO` can now report one
  more finding than it used to.

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

- **`values-to` is gone from `design-tools`; where values land is derived.** It was
  a verbatim copy of one vocabulary's `source`, and that duplication is exactly how
  it came to hold a single path for a tool used across three repos. Every
  vocabulary's `source` is repo-prefixed, so the vocabulary whose source sits in the
  repo you are editing is the one to target — *"vocabulary X for surface Y"* was
  already fully expressed by the two blocks together. `--export` renders the join as
  `targets: [{repo, vocabulary, format, values_in}]`. A removal, rather than the
  `targets:` key this was heading towards.

- **`status:` and `owner:` on a tool row** — `approved | trial | rejected`, and a
  rejected row needs no vocabulary. The block was telling component rows that
  `status: absent` is high-value information while having no way to say "we evaluated
  this and said no" about itself, and silence reads as nobody having looked.

- **`install.sh --design`** writes the `DESIGN.md` that makes a design tool target
  your vocabulary instead of inventing one. It shipped as a template nothing
  installed, with a doc line telling people to copy it by hand. Opt-in rather than on
  by default: a stray `CLAUDE.md` costs nothing, while a stray `DESIGN.md` in a repo
  with no UI points a tool at an unrelated vocabulary. Created if absent, never
  overwritten, and left alone by `--uninstall` — once you fill in the vocabulary slug
  it is your content, not ours.

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

- **Copy-pasting the frozen contract silently disabled the rule it documents.**
  `records()` did not strip trailing `# annotations`, and the only annotated
  authoring example the kit ships is the contract block itself. Authoring a row the
  documented way produced four malformed findings *and* left `roles:` unparsed, so
  the vocabulary requirement never fired. That is the Product Spec scar the same
  template warns about, reproduced in the commit that quotes it. A `#` is only a
  comment when whitespace follows, so `#ffffff` and `#123` survive, and quoted values
  are left alone. Now asserted directly: the annotated block, copied verbatim, must
  validate clean.

- **`roles:` is required, so the vocabulary rule cannot be switched off.** It was
  optional, and rule 1 — *omit a key you do not have* — actively taught authors that
  leaving it out was fine. A row of `slug`/`name`/`kind`/`checked` passed clean and
  reported "0 that write UI", which is the one thing the block exists to prevent.

- **`verified:` renamed to `checked:` in `design-tools`.** `verified:` is already
  load-bearing here: it means *a human confirmed this note*, it drives
  `canon-trust`'s tiers, and the rules files tell agents never to write it for
  themselves. Requiring it on every tool row, as a bare date with no actor, put
  agents in direct conflict with that instruction.

- **Template/validator drift, in the change that warns about drift.** Rule 4 never
  learned `values-to` though the code resolved it; `status: proposed` was instructed
  five times without being in the `design-tokens` enum; rule 8 forbade a filesystem
  path while the same block demonstrated one. There is also now a test that the
  template declares the `design-tools` fence, which the other two fences already had.

- **Both rules files are asserted to carry the design-tools instruction**, the same
  way they are already asserted to ban token values. Six files hand-carry a version
  of "read the block, target the vocabulary it names", against `install.sh`'s own
  comment that six hand-maintained copies is six chances to disagree, silently.
  Generating them from one source is the real fix; until then the load-bearing words
  are pinned by a test.

- **Three smaller ones.** A duplicate tool slug was reported and then silently
  overwritten, so every later check ran against the second row only and the first
  row's defects vanished behind one finding. A `checked:` date in the future is
  refused — it is not a check that happened, and ten fixtures were using
  `2099-01-01` to mean "fresh". `emits`/`version` now reject a placeholder like the
  other keys.

- **Two overclaims.** "Byte-identical output in every mode" is scoped to a vault
  whose blocks are valid: `--help` changed, and `PLACEHOLDER_KEYS` grew by names that
  also apply to token and component rows. And "Figma is not registered anywhere"
  contradicted the template's own companion list — it has no registry *entry*, which
  is the actual point.

- **A `DESIGN.md` alone does not wire a design tool up.** impeccable's context loader
  returns early without a `PRODUCT.md` and never emits the `DESIGN.md` body, so the
  guardrail reached nothing — found by running it, not by reading it. Now documented
  as a prerequisite, along with the collision that the tool's own `document` command
  writes a root `DESIGN.md` and an `.impeccable/design.json` carrying token values, at
  the path canon uses for a values-free pointer file.

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
