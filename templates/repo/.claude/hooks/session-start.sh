#!/usr/bin/env bash
# SessionStart hook — put the vault's router note into context, optionally sync.
#
# Contract: NEVER break a session. Always exit 0. SessionStart cannot block a
# session, so the worst failure mode here is "no context injected".
#
# Emits: {"hookSpecificOutput":{"hookEventName":"SessionStart",
#                               "additionalContext":"..."}}
#
# additionalContext is hard-capped by Claude Code at 10,000 characters
# (~2,500 tokens); overflow spills to a file. We truncate well under that.

set -u

CAP=8000
ROUTER_REL="${CANON_ROUTER:-Vision/Agent Router.md}"

emit() {
  # $1 = text to inject. Uses python3 for correct JSON escaping.
  python3 - "$1" <<'PY' 2>/dev/null || true
import json, sys
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": sys.argv[1],
    }
}))
PY
}

# Locate the resolver: prefer the copy installed in this repo, fall back to PATH.
RESOLVER="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/canon-path"
if [ ! -x "$RESOLVER" ]; then
  RESOLVER="$(command -v canon-path 2>/dev/null || true)"
fi
[ -n "$RESOLVER" ] && [ -x "$RESOLVER" ] || exit 0

VAULT="$("$RESOLVER" 2>/dev/null || true)"

if [ -z "$VAULT" ]; then
  # Distinguish "never set up" from "set up but pointing at nothing" — the
  # second is almost always a stale export or a moved directory, and saying so
  # saves the user a long hunt. An explicit CANON_HOME is deliberately NOT
  # allowed to fall back: silently loading a different vault than the one asked
  # for is worse than loading none.
  if [ -n "${CANON_HOME:-}" ]; then
    emit "Knowledge vault: MISCONFIGURED. \$CANON_HOME is set to '${CANON_HOME}' but that directory does not exist, so no team context is loaded. Fix or unset \$CANON_HOME (it deliberately does not fall back to other config). Do not assume team conventions are in context."
  else
    emit "Knowledge vault: NOT CONFIGURED. No shared team context is loaded. To enable, set \$CANON_HOME, or write the vault path into $HOME/.config/canon/path, or add a .canon file at the repo root. Until then, do not assume team conventions are in context."
  fi
  exit 0
fi

# Optional sync. Off by default: a hook that mutates a git repo the user did not
# ask it to touch is a bad default, and a mid-rebase vault is worse than a stale
# one. Opt in with CANON_AUTOPULL=1.
#
# DELIBERATELY --ff-only, and deliberately NOT --rebase --autostash.
#
# The vault is very likely open in an editor right now. Obsidian holds notes in
# memory and autosaves a second or two after you stop typing, so a pull that
# rewrites files underneath it races that buffer: whichever writes last wins, and
# Obsidian can win with stale content. A fast-forward cannot rewrite local
# commits, cannot leave a half-finished rebase, and cannot produce conflict
# markers — if it is not a clean fast-forward it does nothing at all.
#
# We also skip entirely when the tree is dirty, because those are exactly the
# files someone is editing. Reconciling divergent history is a deliberate act:
# that is what `canon-sync` is for, run when you are looking at it.
if [ "${CANON_AUTOPULL:-0}" = "1" ] && [ -d "$VAULT/.git" ]; then
  if [ -z "$(git -C "$VAULT" status --porcelain 2>/dev/null | head -1)" ]; then
    git -C "$VAULT" pull --ff-only --quiet >/dev/null 2>&1 || true
  fi
fi

ROUTER="$VAULT/$ROUTER_REL"
if [ ! -f "$ROUTER" ]; then
  emit "Knowledge vault is at $VAULT but its router note ($ROUTER_REL) is missing. Explore the vault directly with glob/grep before assuming conventions. Consider running: canon-init-vault \"$VAULT\""
  exit 0
fi

BODY="$(head -c "$CAP" "$ROUTER" 2>/dev/null || true)"
[ -n "$BODY" ] || exit 0

# Is the vault in step with the team? Purely local checks — no network call, so this
# cannot slow down or hang a session start. Silent when everything is current.
STATUS=""
SH="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/canon-status"
[ -x "$SH" ] || SH="$(command -v canon-status 2>/dev/null || true)"
if [ -n "$SH" ] && [ -x "$SH" ]; then
  STATUS="$("$SH" "$VAULT" 2>/dev/null || true)"
fi
[ -n "$STATUS" ] && STATUS="

NOTE ON FRESHNESS — tell the user if it matters to their question:
$STATUS"

emit "Shared knowledge vault is at: $VAULT
The team's conventions and index follow. Reach vault content on demand with glob/grep/Read against that path — do not attempt to load the whole vault.

--- BEGIN $ROUTER_REL ---
$BODY
--- END $ROUTER_REL ---$STATUS"
exit 0
