#!/usr/bin/env bash
# Stop hook — notice when a work session is ending without a session note.
#
# The weak link in a knowledge loop is never the reading, it is the writing at
# the end. This hook detects "real work happened, nothing was written down".
#
# Two modes:
#   remind (DEFAULT) — emit {"systemMessage": ...}. Never blocks anything.
#   block            — emit {"decision":"block","reason":...} so Claude is told
#                      to finish the job. Opt in with:
#                        CANON_ENFORCE_SESSION_NOTE=block
#
# VERIFY BEFORE TRUSTING block MODE on your pinned Claude Code version — the
# blocking output shape for Stop hooks is the one part of this kit not confirmed
# against a known-good local example. See docs/VERIFY.md.
#
# Fires at most ONCE per session (state file guard). An unguarded blocking Stop
# hook is an infinite loop.

set -u

MODE="${CANON_ENFORCE_SESSION_NOTE:-remind}"
[ "$MODE" = "off" ] && exit 0

REPO="${CLAUDE_PROJECT_DIR:-$PWD}"

# --- read the hook event (for session_id); tolerate absence -------------------
STDIN_JSON=""
if [ ! -t 0 ]; then STDIN_JSON="$(cat 2>/dev/null || true)"; fi

SESSION_ID="$(printf '%s' "$STDIN_JSON" | python3 -c '
import json,sys
try: print(json.load(sys.stdin).get("session_id") or "")
except Exception: print("")
' 2>/dev/null || true)"
[ -n "$SESSION_ID" ] || SESSION_ID="$(printf '%s' "$REPO" | cksum | cut -d" " -f1)"

STATE_DIR="${TMPDIR:-/tmp}/canon-hooks"
mkdir -p "$STATE_DIR" 2>/dev/null || true
GUARD="$STATE_DIR/reminded-$SESSION_ID"

# Already handled this session — stay silent, and never block twice.
[ -f "$GUARD" ] && exit 0

# --- resolve the vault -------------------------------------------------------
RESOLVER="$REPO/.claude/hooks/canon-path"
[ -x "$RESOLVER" ] || RESOLVER="$(command -v canon-path 2>/dev/null || true)"
[ -n "$RESOLVER" ] && [ -x "$RESOLVER" ] || exit 0
VAULT="$("$RESOLVER" 2>/dev/null || true)"
[ -n "$VAULT" ] || exit 0

SESSIONS_DIR="${CANON_SESSIONS_DIR:-Sessions}"
[ -d "$VAULT/$SESSIONS_DIR" ] || exit 0

# --- optional: commit vault changes locally ----------------------------------
# LOCAL ONLY — never pushes. Opt in with CANON_AUTOCOMMIT=1. Off by default
# because silently committing to someone's repo is a rude default; on is the
# right setting once a team has agreed to it.
#
# Runs the scanner first via the vault's pre-commit hook, so a credential in a
# generated note stops the commit instead of entering history.
if [ "${CANON_AUTOCOMMIT:-0}" = "1" ] && [ -d "$VAULT/.git" ]; then
  if [ -n "$(git -C "$VAULT" status --porcelain 2>/dev/null | head -1)" ]; then
    git -C "$VAULT" add -A >/dev/null 2>&1 || true
    n="$(git -C "$VAULT" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')"
    if ! git -C "$VAULT" commit --quiet \
           -m "vault: $n file(s) from session in $(basename "$REPO")" >/dev/null 2>&1; then
      # Most likely the pre-commit scanner refused. Surface it rather than
      # failing silently — a swallowed gate is worse than no gate.
      python3 - "$VAULT" <<'PY' 2>/dev/null || true
import json, sys
print(json.dumps({"systemMessage":
  "Vault auto-commit was BLOCKED — most likely the canon-scan pre-commit gate "
  "found something that looks like a credential or personal identifier in a "
  "note written this session. Nothing was committed. Inspect it before this "
  f"goes any further: git -C '{sys.argv[1]}' diff --cached"}))
PY
      exit 0
    fi
  fi
fi

# --- did real work happen in this repo? --------------------------------------
# Signal: tracked-file modifications or new untracked files. Cheap and honest;
# a read-only Q&A session produces none and is correctly left alone.
CHANGES=0
if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  if [ -n "$(git -C "$REPO" status --porcelain 2>/dev/null | head -1)" ]; then
    CHANGES=1
  fi
fi
[ "$CHANGES" = "1" ] || exit 0

# --- was a session note written recently? ------------------------------------
WINDOW_MIN="${CANON_SESSION_NOTE_WINDOW_MIN:-720}"   # default 12h
RECENT="$(find "$VAULT/$SESSIONS_DIR" -type f -name '*.md' \
            -newermt "-${WINDOW_MIN} minutes" 2>/dev/null | head -1)"
[ -n "$RECENT" ] && exit 0

# --- nothing written: remind or block ----------------------------------------
: > "$GUARD" 2>/dev/null || true

REPO_NAME="$(basename "$REPO")"
MSG="This session changed files in ${REPO_NAME} but no note was written to ${SESSIONS_DIR}/ in the vault (${VAULT}). Per the team knowledge conventions, meaningful work ends with a dated session note: goal, what changed with repo-path:line refs, decisions, open follow-ups, linked to its project. Write it now, or state explicitly that this session did not warrant one."

# Unshared notes are the failure that quietly kills a shared vault: everyone writes
# locally, nobody pushes, and the shared copy becomes a set of private ones. Worth
# saying at the moment someone is finishing up and can act on it.
SH="$REPO/.claude/hooks/canon-status"
[ -x "$SH" ] || SH="$(command -v canon-status 2>/dev/null || true)"
if [ -n "$SH" ] && [ -x "$SH" ]; then
  SYNC="$("$SH" "$VAULT" 2>/dev/null || true)"
  [ -n "$SYNC" ] && MSG="$MSG

Also: $SYNC"
fi

if [ "$MODE" = "block" ]; then
  python3 - "$MSG" <<'PY' 2>/dev/null || true
import json, sys
print(json.dumps({"decision": "block", "reason": sys.argv[1]}))
PY
else
  python3 - "$MSG" <<'PY' 2>/dev/null || true
import json, sys
print(json.dumps({"systemMessage": sys.argv[1]}))
PY
fi
exit 0
