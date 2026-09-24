# Working in this repo

canon is the kit that wires a repo to a team's shared knowledge vault: an installer,
a set of standalone `bin/canon-*` tools, the templates they copy, and a Claude Code
plugin. The bar for any change is in [CONTRIBUTING.md](CONTRIBUTING.md). Read it
first, because the rules there are enforced by review, not just by CI.

`AGENTS.md` is an identical copy of this file. Edit both, or neither.

## This repo

### Build and run

- There is nothing to build. The only requirements are `bash`, `git` and `python3`
  (CONTRIBUTING.md), and "no new dependencies" is a rule, not an accident.
- Try the installer against a throwaway folder, never a real repo:
  `./install.sh "$(mktemp -d)" --dry-run`, then again without `--dry-run`. `--help`
  lists the per-runtime opt-outs, and `--uninstall` reverses an install.
- Every tool in `bin/` runs standalone and answers `--help` and `--version`
  (`canon-path`, `canon-sync`, `canon-scan`, `canon-status`, `canon-init-vault`,
  `canon-pack`, `canon-test-audit`, `canon-design-audit`, …).
- The plugin manifest is `.claude-plugin/`. Skills, commands and hooks live in
  `skills/`, `commands/` and `hooks/`.

### Test

- Whole suite: `./test/run.sh`. It builds a throwaway vault and repo in `$TMPDIR`,
  runs every script and asserts on behaviour. No network, no installs. It's one
  bash file with no single-test runner, so add a case next to the ones it resembles.
- CI (`.github/workflows/ci.yml`) runs on every push and PR, with four jobs:
  - `test (ubuntu-latest)` and `test (macos-latest)`: `./test/run.sh`. The macOS
    leg is bash 3.2.
  - `shellcheck`: `shellcheck --shell=bash --severity=warning --exclude=SC1091,SC2016 install.sh bin/canon-* templates/repo/.claude/hooks/*.sh test/run.sh`.
  - `hygiene`: executables are executable, the connectors pass `node --check`,
    plus `node test/paths.test.mjs` and `node test/links.test.mjs`. It also checks
    that versions agree with `VERSION`, that the README test badge matches the
    suite, and that no absolute home-directory paths exist anywhere.
- There is no coverage tool. The assertion count in the README badge is the only
  number tracked.

### Architecture in three sentences

`install.sh` copies `templates/repo/` into a target folder and generates every
agent runtime's instruction file (CLAUDE.md, AGENTS.md, GEMINI.md, Copilot, Windsurf,
Cline) from the single `templates/repo/agent-instructions.md`, so they cannot drift.
The `bin/canon-*` tools do the runtime work: `canon-path` resolves which vault
applies, `canon-sync`/`canon-scan` gate what enters vault history, and the
`canon-*-audit` tools read a vault's frozen fences. `templates/vault/` and
`templates/packs/` seed a vault, and `connectors/` holds optional Slack, Discord and
MCP front-ends over the same vault.

### Gotchas

- **Never paste real output into docs, templates or tests.** Every slug, number and
  path in an example must be invented (CONTRIBUTING.md rules 6 and 7). This has
  leaked a private vault's details more than once, each time through an example
  copied from a real run. Grep the whole kit for your own org's names and numbers
  before opening a PR.
- **Adding assertions breaks the build until you update the README badge**
  (`tests-N%20passing`). The `hygiene` job compares it to the suite's real count.
- **A version bump touches every declaration.** `VERSION`, each `bin/canon-*` and
  `install.sh --version`, `.claude-plugin/plugin.json`, the connector manifests and
  the MCP server's advertised version must all agree, or `hygiene` fails.
- **Bash 3.2.** No `declare -A`, `mapfile`, `${var,,}` or globstar. GNU and BSD tools
  also differ (`tr` bracket expressions, `sed -i`), and only the CI matrix catches it.
- **Edit the template, never a generated copy.** A new agent-facing feature needs a
  bullet in both `templates/repo/.claude/rules/` and `templates/repo/.cursor/rules/`,
  because that's what an agent in a code repo actually loads. Green tests have
  shipped a feature that was wired into the vault only.
- **Hooks exit 0 on every path.** The `set -e` split between installers and hooks is
  deliberate (CONTRIBUTING.md), so don't unify it.
- A tool that reads kit files (like `canon-pack`, which reads `templates/packs/`)
  can't be vendored into a vault as-is. Check before vendoring a new one.
