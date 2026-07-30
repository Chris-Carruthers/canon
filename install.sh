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

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$KIT_DIR/templates/repo"
MARKER="<!-- canon:knowledge-vault -->"

TARGET=""
VAULT=""
DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --vault) VAULT="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
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

echo "Installing canon into $TARGET"

# --- hooks + resolver --------------------------------------------------------
run mkdir -p "$TARGET/.claude/hooks" "$TARGET/.claude/rules"
for f in session-start.sh session-end-check.sh; do
  run cp "$TPL/.claude/hooks/$f" "$TARGET/.claude/hooks/$f"
  run chmod +x "$TARGET/.claude/hooks/$f"
  say "hook: .claude/hooks/$f"
done
run cp "$KIT_DIR/bin/canon-path" "$TARGET/.claude/hooks/canon-path"
run chmod +x "$TARGET/.claude/hooks/canon-path"
say "resolver: .claude/hooks/canon-path"

# --- path-scoped rules -------------------------------------------------------
run cp "$TPL/.claude/rules/knowledge-vault.md" "$TARGET/.claude/rules/knowledge-vault.md"
say "rules: .claude/rules/knowledge-vault.md"

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

# --- CLAUDE.md (append once, never overwrite) --------------------------------
CM="$TARGET/CLAUDE.md"
if [ "$DRY" = "1" ]; then
  say "[dry-run] ensure CLAUDE.md vault block"
elif [ ! -f "$CM" ]; then
  { printf '%s\n' "$MARKER"; cat "$TPL/CLAUDE.md"; } > "$CM"
  say "created CLAUDE.md"
elif grep -qF "$MARKER" "$CM" 2>/dev/null; then
  say "CLAUDE.md already has the vault block — left alone"
else
  { printf '\n\n%s\n' "$MARKER"; cat "$TPL/CLAUDE.md"; } >> "$CM"
  say "appended vault block to existing CLAUDE.md"
fi

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
