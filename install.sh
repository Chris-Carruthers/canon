#!/usr/bin/env bash
# install.sh — wire a repo up to the team knowledge vault.
#
#   ./install.sh /path/to/repo [--vault /path/to/vault] [--dry-run]
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
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --vault) VAULT="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[ -n "$TARGET" ] || { echo "usage: install.sh /path/to/repo [--vault PATH]" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "error: not a directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 \
  || echo "warning: $TARGET is not a git repo — hooks will still work, but team sharing needs one" >&2

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

  for name in CLAUDE.md AGENTS.md; do
  CM="$TARGET/$name"
  if [ -f "$CM" ] && grep -qF "$MARKER" "$CM" 2>/dev/null && [ "$DRY" != "1" ]; then
    python3 - "$CM" "$MARKER" <<'PY'
import sys
path, marker = sys.argv[1], sys.argv[2]
lines = open(path, encoding="utf-8").read().split("\n")
try: i = next(n for n, l in enumerate(lines) if marker in l)
except StopIteration: sys.exit(0)
# Our block runs from the marker to EOF (install.sh only ever appends it).
kept = "\n".join(lines[:i]).rstrip() + "\n"
open(path, "w", encoding="utf-8").write("" if kept.strip() == "" else kept)
print(f"  stripped the canon block from {path.rsplit('/', 1)[-1]}")
PY
  fi
  done

  [ -e "$TARGET/.cursor/rules/knowledge-vault.mdc" ] \
    && { run rm -f "$TARGET/.cursor/rules/knowledge-vault.mdc"; say "removed cursor rules"; }

  # Prune directories only if we emptied them.
  for d in "$TARGET/.claude/hooks" "$TARGET/.claude/rules" "$TARGET/.cursor/rules" "$TARGET/.cursor"; do
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
for name in CLAUDE.md AGENTS.md; do
  CM="$TARGET/$name"
  if [ "$DRY" = "1" ]; then
    say "[dry-run] ensure $name vault block"
  elif [ ! -f "$CM" ]; then
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
