#!/usr/bin/env bash
# bootstrap.sh — run this once, right after you clone this vault.
#
#   ./.canon/bootstrap.sh
#
# It does two things and nothing else:
#   1. Tells your machine where this vault lives, so your agent can find it.
#   2. Installs the pre-commit safety check, which refuses to save a note
#      containing a credential or an obvious personal identifier.
#
# Why this exists: git hooks are NOT copied when you clone a repository. Without
# this step your commits are ungated, and nothing tells you so. Everything it
# needs is committed inside this vault, so there is nothing else to download.
#
# Safe to re-run.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="$(cd "$HERE/.." && pwd)"

echo "Vault: $VAULT"
echo

# --- 1. record the path for this machine -------------------------------------
CFG="$HOME/.config/canon"
if [ -f "$CFG/path" ] && [ "$(head -1 "$CFG/path" 2>/dev/null)" = "$VAULT" ]; then
  echo "  ✓ machine already points here ($CFG/path)"
else
  mkdir -p "$CFG"
  printf '%s\n' "$VAULT" > "$CFG/path"
  echo "  ✓ recorded the vault path in $CFG/path"
fi

# --- 2. install the safety check ---------------------------------------------
if [ ! -d "$VAULT/.git" ]; then
  echo "  ! not a git repository — skipping the commit check" >&2
else
  if [ -x "$HERE/canon-install-vault-hooks" ]; then
    "$HERE/canon-install-vault-hooks" "$VAULT" | sed 's/^/  /'
  else
    echo "  ! .canon/canon-install-vault-hooks is missing — commits will be UNGATED" >&2
    echo "    ask whoever maintains this vault to commit it" >&2
  fi
fi

# --- what now ----------------------------------------------------------------
cat <<EOF

Done. To check it worked, try to commit something that looks like a secret:

  cd "$VAULT"
  echo 'AKIA1234567890ABCDEF' > _probe.md
  git add _probe.md && git commit -m probe     # should be REFUSED
  git reset -q && rm -f _probe.md

Next:
  * Open this folder in Obsidian: File > Open folder as vault.
  * Read Vision/How This Works — Plain English.md if you have not already.
  * You are done unless you want your agent writing notes for you, in which case
    follow the contributor steps in the team guide.
EOF
