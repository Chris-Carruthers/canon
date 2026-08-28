#!/usr/bin/env bash
# install.sh — wire a working folder up to the team knowledge vault.
#
#   ./install.sh /path/to/folder [--vault /path/to/vault] [--dry-run]
#
# The folder is wherever your assistant works. Two normal answers:
#
#   a code repo    notes load while you work in it, and stay out of it
#   the vault      when your work is meetings and decisions, not commits —
#                  then "files changed here" means "notes you wrote", which is
#                  what the end-of-session prompt keys off
#
# Writes the same instruction block for every agent runtime that has a
# conventional filename: CLAUDE.md, AGENTS.md, GEMINI.md,
# .github/copilot-instructions.md, .windsurf/rules/, .clinerules/ — all generated
# from one template so they cannot drift. Opt out with --no-gemini, --no-copilot,
# --no-windsurf, --no-cline, or --claude-only.
#
# --design also writes a DESIGN.md: the pointer file a design tool reads before it
# touches any UI, so it targets your token vocabulary instead of inventing one.
# Opt-in, because a repo with no UI does not want one. Created if absent, never
# overwritten, and left in place by --uninstall — once you fill it in it is yours.
#
# Only Claude Code gets the automatic hooks; the other runtimes have nowhere to
# attach them. They read the vault, they do not maintain it. If you want the
# hooks without install.sh, canon also ships as a Claude Code plugin — see the
# README.
#
# Idempotent and non-destructive:
#   * never overwrites an existing CLAUDE.md — appends one marked block, once
#   * merges into an existing .claude/settings.json, backing it up first
#   * safe to re-run after upgrading the kit
#
# Everything it installs is repo-relative via ${CLAUDE_PROJECT_DIR}, so the
# result is portable across machines and checkouts.

set -euo pipefail

CANON_VERSION="0.2.0"
case "${1:-}" in --version|-V) printf 'canon %s\n' "$CANON_VERSION"; exit 0 ;; esac


KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$KIT_DIR/templates/repo"
MARKER="<!-- canon:knowledge-vault -->"

TARGET=""
VAULT=""
DRY=0
UNINSTALL=0; WANT_DESIGN=0
# On by default. A stray instruction file costs nothing and is removed cleanly by
# --uninstall, whereas a missing one is a teammate quietly getting no context
# because they happen to use a different tool.
WANT_GEMINI=1; WANT_COPILOT=1; WANT_WINDSURF=1; WANT_CLINE=1

while [ $# -gt 0 ]; do
  case "$1" in
    --vault) VAULT="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --no-gemini) WANT_GEMINI=0; shift ;;
    --no-copilot) WANT_COPILOT=0; shift ;;
    --no-windsurf) WANT_WINDSURF=0; shift ;;
    --no-cline) WANT_CLINE=0; shift ;;
    --claude-only) WANT_GEMINI=0; WANT_COPILOT=0; WANT_WINDSURF=0; WANT_CLINE=0; shift ;;
    --design) WANT_DESIGN=1; shift ;;
    -h|--help) sed -n '2,29p' "$0"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[ -n "$TARGET" ] || { echo "usage: install.sh /path/to/folder [--vault PATH]" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "error: not a directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

# Not a git repo is a supported setup, not a mistake — but say what it costs,
# because the end-of-session prompt infers "real work happened" from changed
# files here and a non-repo folder can never report any.
git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "note: $TARGET is not a git repo." >&2
  echo "      Everything works except the end-of-session 'write a session note'" >&2
  echo "      prompt, which needs changed files to detect that work happened." >&2
  echo "      If your work is notes rather than code, install into the vault itself." >&2
}

say() { printf '  %s\n' "$*"; }
run() { if [ "$DRY" = "1" ]; then say "[dry-run] $*"; else "$@"; fi; }

# --- uninstall ---------------------------------------------------------------
# Nobody trusts a tool they cannot cleanly remove. Removes only what we added:
# our hooks, our rules, our settings entries, our CLAUDE.md block. Anything the
# repo had before is left exactly as it was.
if [ "$UNINSTALL" = "1" ]; then
  echo "Removing canon from $TARGET"
  for f in session-start.sh session-end-check.sh canon-path canon-status; do
    [ -e "$TARGET/.claude/hooks/$f" ] && { run rm -f "$TARGET/.claude/hooks/$f"; say "removed hook: $f"; }
  done
  [ -e "$TARGET/.claude/rules/knowledge-vault.md" ] \
    && { run rm -f "$TARGET/.claude/rules/knowledge-vault.md"; say "removed rules"; }
  [ -e "$TARGET/.canon" ] && { run rm -f "$TARGET/.canon"; say "removed .canon marker"; }

  SETTINGS="$TARGET/.claude/settings.json"
  if [ -f "$SETTINGS" ] && [ "$DRY" != "1" ]; then
    cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
    python3 - "$SETTINGS" <<'PY'
import json, sys
p = sys.argv[1]
with open(p) as f: d = json.load(f)

def ours(cmd): return "canon" in (cmd or "") or "session-start.sh" in (cmd or "") \
                   or "session-end-check.sh" in (cmd or "")

hooks = d.get("hooks", {})
for event in list(hooks):
    groups = []
    for g in hooks[event]:
        keep = [h for h in g.get("hooks", []) if not ours(h.get("command"))]
        if keep: groups.append({**{k: v for k, v in g.items() if k != "hooks"}, "hooks": keep})
    if groups: hooks[event] = groups
    else: del hooks[event]
if not hooks: d.pop("hooks", None)

OURS_DENY = {"Read(**/.env)", "Read(**/.env.*)", "Read(**/*.pem)",
             "Read(**/id_rsa*)", "Read(**/credentials.json)"}
perms = d.get("permissions", {})
if "deny" in perms:
    perms["deny"] = [r for r in perms["deny"] if r not in OURS_DENY]
    if not perms["deny"]: del perms["deny"]
if perms == {}: d.pop("permissions", None)

with open(p, "w") as f:
    json.dump(d, f, indent=2); f.write("\n")
print("  cleaned .claude/settings.json (backup written)")
PY
  fi

  # Every runtime file we might have written, regardless of the flags used on the
  # way in. Uninstall must not depend on being handed the same flags as install —
  # nobody remembers them, and a tool you cannot cleanly remove is one people
  # refuse to try in the first place.
  for name in CLAUDE.md AGENTS.md GEMINI.md .github/copilot-instructions.md \
              .windsurf/rules/knowledge-vault.md .clinerules/knowledge-vault.md; do
  CM="$TARGET/$name"
  if [ -f "$CM" ] && grep -qF "$MARKER" "$CM" 2>/dev/null && [ "$DRY" != "1" ]; then
    python3 - "$CM" "$MARKER" <<'PY'
import os, sys
path, marker = sys.argv[1], sys.argv[2]
lines = open(path, encoding="utf-8").read().split("\n")
try: i = next(n for n, l in enumerate(lines) if marker in l)
except StopIteration: sys.exit(0)
# Our block runs from the marker to EOF (install.sh only ever appends it).
kept = "\n".join(lines[:i]).rstrip() + "\n"
name = path.rsplit("/", 1)[-1]
if kept.strip() == "":
    # Nothing of theirs was in it, so we created the whole file. Leaving a
    # zero-byte GEMINI.md behind is litter, and litter is what makes people
    # distrust an uninstaller.
    os.remove(path)
    print(f"  removed {name} (we created it)")
else:
    open(path, "w", encoding="utf-8").write(kept)
    print(f"  stripped the canon block from {name}")
PY
  fi
  done

  [ -e "$TARGET/.cursor/rules/knowledge-vault.mdc" ] \
    && { run rm -f "$TARGET/.cursor/rules/knowledge-vault.mdc"; say "removed cursor rules"; }

  # Prune directories only if we emptied them.
  for d in "$TARGET/.claude/hooks" "$TARGET/.claude/rules" "$TARGET/.cursor/rules" "$TARGET/.cursor" \
           "$TARGET/.windsurf/rules" "$TARGET/.windsurf" "$TARGET/.clinerules" "$TARGET/.github"; do
    [ -d "$d" ] && [ -z "$(ls -A "$d" 2>/dev/null)" ] && run rmdir "$d"
  done

  echo
  echo "Done. The vault itself was not touched — remove it yourself if you want it gone."
  exit 0
fi

echo "Installing canon into $TARGET"

# --- hooks + resolver --------------------------------------------------------
run mkdir -p "$TARGET/.claude/hooks" "$TARGET/.claude/rules"
for f in session-start.sh session-end-check.sh; do
  run cp "$TPL/.claude/hooks/$f" "$TARGET/.claude/hooks/$f"
  run chmod +x "$TARGET/.claude/hooks/$f"
  say "hook: .claude/hooks/$f"
done
for tool in canon-path canon-status; do
  run cp "$KIT_DIR/bin/$tool" "$TARGET/.claude/hooks/$tool"
  run chmod +x "$TARGET/.claude/hooks/$tool"
  say "tool: .claude/hooks/$tool"
done

# --- path-scoped rules -------------------------------------------------------
run cp "$TPL/.claude/rules/knowledge-vault.md" "$TARGET/.claude/rules/knowledge-vault.md"
say "rules: .claude/rules/knowledge-vault.md"

# --- DESIGN.md, opt-in ------------------------------------------------------
# A pointer file design tools read before they touch any UI. Without one they find
# no committed design language and generate their own, which is how a codebase
# acquires a second, plausible, entirely parallel set of tokens.
#
# CREATE-IF-ABSENT, never overwritten: unlike the rules files this is the user's
# content once they fill in the vocabulary slug, and clobbering it would throw away
# the only thing that makes it useful. Not removed by --uninstall for the same
# reason.
#
# Opt-in rather than on-by-default, which inverts this installer's usual bias. A
# stray CLAUDE.md costs nothing; a stray DESIGN.md in a repo with no UI points a
# design tool at a vocabulary that has nothing to do with it.
if [ "$WANT_DESIGN" = "1" ]; then
  if [ -e "$TARGET/DESIGN.md" ]; then
    say "DESIGN.md: already present, left alone"
  else
    run cp "$TPL/DESIGN.md" "$TARGET/DESIGN.md"
    say "DESIGN.md: written — fill in the vocabulary slug and tokens path"
  fi
fi

# --- Cursor rules ------------------------------------------------------------
run mkdir -p "$TARGET/.cursor/rules"
run cp "$TPL/.cursor/rules/knowledge-vault.mdc" "$TARGET/.cursor/rules/knowledge-vault.mdc"
say "rules: .cursor/rules/knowledge-vault.mdc"

# --- settings.json (merge, never clobber) ------------------------------------
SETTINGS="$TARGET/.claude/settings.json"
if [ "$DRY" = "1" ]; then
  say "[dry-run] merge .claude/settings.json"
elif [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  python3 - "$SETTINGS" "$TPL/.claude/settings.json" <<'PY'
import json, sys
dst_path, src_path = sys.argv[1], sys.argv[2]
with open(dst_path) as f: dst = json.load(f)
with open(src_path) as f: src = json.load(f)

# Hooks: append our entries unless an identical command already exists.
dh = dst.setdefault("hooks", {})
for event, groups in src.get("hooks", {}).items():
    existing = dh.setdefault(event, [])
    have = {h.get("command")
            for g in existing for h in g.get("hooks", [])}
    for g in groups:
        keep = [h for h in g.get("hooks", []) if h.get("command") not in have]
        if keep:
            existing.append({**{k: v for k, v in g.items() if k != "hooks"},
                             "hooks": keep})

# Permissions.deny: union, order preserved.
sp = src.get("permissions", {}).get("deny", [])
if sp:
    perms = dst.setdefault("permissions", {})
    deny = perms.setdefault("deny", [])
    for rule in sp:
        if rule not in deny:
            deny.append(rule)

with open(dst_path, "w") as f:
    json.dump(dst, f, indent=2)
    f.write("\n")
print("  merged .claude/settings.json (backup written)")
PY
else
  cp "$TPL/.claude/settings.json" "$SETTINGS"
  say "created .claude/settings.json"
fi

# --- CLAUDE.md + AGENTS.md (append once each, never overwrite) ---------------
# One body, written into both. AGENTS.md is the cross-tool convention other coding
# agents read; CLAUDE.md is what Claude Code picks up automatically. Installing the
# identical block into both is what makes "works with your agent too" true rather
# than aspirational — and generating both from one template is what stops them
# drifting apart later.
#
# Other runtimes read the same body from their own conventional filename. Every
# one of these is generated from `agent-instructions.md`, never hand-written, for
# the same reason CLAUDE.md and AGENTS.md are: six copies of an instruction block
# maintained by hand is six chances to disagree, and the disagreement is silent.
#
# Honest about coverage: these files make other agents READ the vault. Only Claude
# Code gets the hooks that load context automatically and notice a missing session
# note — the rest have no hook system to attach to. That is a real difference and
# it is stated in the README rather than papered over.
#
# Opt out with --no-<runtime>; see --help.
RUNTIME_FILES="CLAUDE.md AGENTS.md"
[ "$WANT_GEMINI" = "1" ]   && RUNTIME_FILES="$RUNTIME_FILES GEMINI.md"
[ "$WANT_COPILOT" = "1" ]  && RUNTIME_FILES="$RUNTIME_FILES .github/copilot-instructions.md"
[ "$WANT_WINDSURF" = "1" ] && RUNTIME_FILES="$RUNTIME_FILES .windsurf/rules/knowledge-vault.md"
[ "$WANT_CLINE" = "1" ]    && RUNTIME_FILES="$RUNTIME_FILES .clinerules/knowledge-vault.md"

for name in $RUNTIME_FILES; do
  CM="$TARGET/$name"
  if [ "$DRY" = "1" ]; then
    say "[dry-run] ensure $name vault block"
    continue
  fi
  mkdir -p "$(dirname "$CM")"
  if [ ! -f "$CM" ]; then
    { printf '%s\n' "$MARKER"; cat "$TPL/agent-instructions.md"; } > "$CM"
    say "created $name"
  elif grep -qF "$MARKER" "$CM" 2>/dev/null; then
    say "$name already has the vault block — left alone"
  else
    { printf '\n\n%s\n' "$MARKER"; cat "$TPL/agent-instructions.md"; } >> "$CM"
    say "appended vault block to existing $name"
  fi
done

# --- .canon marker -----------------------------------------------------------
if [ -n "$VAULT" ]; then
  if [ "$DRY" = "1" ]; then
    say "[dry-run] write .canon -> $VAULT"
  else
    printf '# Path to this team'"'"'s shared knowledge vault.\n# Override per-machine with $CANON_HOME.\n%s\n' "$VAULT" > "$TARGET/.canon"
    say "wrote .canon -> $VAULT"
  fi
fi

echo
echo "Done. Next:"
echo "  1. Verify the vault resolves:  $TARGET/.claude/hooks/canon-path"
echo "  2. Commit .claude/ + CLAUDE.md + .canon so teammates inherit them."
echo "     (Keep personal overrides in .claude/settings.local.json — do not commit that.)"
echo "  3. Smoke-test the hooks on your pinned Claude Code version: docs/VERIFY.md"
