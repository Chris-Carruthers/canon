# Contributing

Thanks for looking. This project is deliberately small, and staying small is a
feature — so the most useful contributions are usually sharper, not bigger.

## Quick start

```bash
git clone https://github.com/Chris-Carruthers/canon && cd canon
./test/run.sh          # ~10s, no network, no installs, sandboxed in $TMPDIR
```

If that passes you have a working environment. Requirements are `bash`, `git`,
and `python3` — nothing else, and that constraint is intentional.

## The bar for a change

1. **`./test/run.sh` passes**, on macOS and Linux if you can manage both.
2. **New behaviour comes with a test.** The suite is plain bash asserting on real
   sandboxed runs; adding a case is usually four lines. A change with no test is
   a change we cannot keep working.
3. **`shellcheck` is clean** (`--severity=warning`). CI runs it.
4. **Works on bash 3.2.** Stock macOS ships 3.2.57, so no `declare -A`, no
   `mapfile`, no `${var,,}`, no globstar. CI has a macOS leg to catch this.
5. **No new dependencies.** If you need a package manager, it belongs in a
   different project.

## Design principles, so review isn't a surprise

These are the rules the existing code follows. A PR that breaks one isn't
automatically rejected, but it needs an argument.

- **Hooks never break a turn.** Anything running as a Claude Code hook exits 0 on
  every path it can, and degrades to doing nothing rather than failing loudly.
  A hook that breaks the user's session will be disabled, and then it protects
  nothing.
- **Nothing hardcodes a path.** All resolution goes through `canon-path`.
- **Never clobber the user's files.** The installer merges into an existing
  `settings.json` and appends one marked block to an existing `CLAUDE.md`.
  Re-running is always safe. `--uninstall` removes only what we added.
- **Automate reading, gate writing.** Pull is safe to automate; push is
  irreversible and stays deliberate. See `docs/MULTIPLAYER.md`.
- **`set -e` discipline is deliberate and split.** Installers and scaffolds use
  `set -euo pipefail` — they mutate the user's repo, so aborting on the first
  error is correct. Hooks and the resolver use `set -u` / `set -uo pipefail`
  *without* `-e`, because they must reach their own error handling and exit 0
  rather than dying mid-script and breaking a session. Don't "fix" the
  inconsistency by unifying them.
- **State the limits in the code.** Where something can't be enforced, say so in
  a comment rather than implying a guarantee. The `Stop`-hook block mode ships
  off for exactly this reason.
- **Be honest about unknowns.** "Verified on X" and "unconfirmed" are both fine
  in docs. Confident wrongness is not.

## Things that would genuinely help

- **Support for other agent runtimes.** The vault is plain markdown; only the
  hook wiring is Claude Code-specific. Cursor rules, `AGENTS.md`, and others are
  all reasonable additions.
- **A `.canon-owners` → `CODEOWNERS` generator**, so the two files cannot drift.
- **Better prose-level detection of personal data.** The current scanner catches
  credentials well and prose poorly, and it says so. This is the most valuable
  open problem in the project.
- **Real adoption reports.** If you run this on a team for a month, what decayed?
  Who ended up maintaining it? That's worth more than a feature.

## Things that are out of scope

- A server, daemon, or hosted service.
- Vector search or embeddings in the kit itself. If your vault outgrows grep, the
  right answer is a purpose-built tool alongside it, not one bolted in here.
- Coupling to Obsidian. Obsidian is a nice reader for the vault; it is not a
  dependency, and it should stay that way.

## Reporting a bug

Include your OS, `bash --version`, agent runtime version, and what `./test/run.sh`
says. If it's a hook that didn't fire, `docs/VERIFY.md` is the fastest way to
localise it — telling us which of its steps failed usually identifies the cause
immediately.

## Security

Found a way for the gate to leak a credential into history? Please don't open a
public issue. Report it privately via GitHub's security advisory form on the
repository.
