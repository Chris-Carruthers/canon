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
# Repo copy → plugin bin → PATH. CLAUDE_PLUGIN_ROOT is set only when canon was
# added with /plugin, and it is the only way a plugin hook can find its own files.
RESOLVER="$REPO/.claude/hooks/canon-path"
[ -x "$RESOLVER" ] || [ -z "${CLAUDE_PLUGIN_ROOT:-}" ] || RESOLVER="${CLAUDE_PLUGIN_ROOT}/bin/canon-path"
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
#
# REFUSES TO RUN WITHOUT THE GATE. Git never copies hooks on clone, so a vault can
# be perfectly usable and completely ungated, with nothing saying so. Committing by
# hand in that state is the user's own risk, taken knowingly. Automating it is not:
# it silently turns "I forgot to run bootstrap" into "an agent wrote my API key into
# permanent history." Verified: with no pre-commit hook, an autocommit will commit a
# planted AWS key without a word. So check first, and say something useful instead.
if [ "${CANON_AUTOCOMMIT:-0}" = "1" ] && [ -d "$VAULT/.git" ]; then
  HOOKS_DIR="$(git -C "$VAULT" config --get core.hooksPath 2>/dev/null || true)"
  if [ -n "$HOOKS_DIR" ]; then
    case "$HOOKS_DIR" in /*) : ;; *) HOOKS_DIR="$VAULT/$HOOKS_DIR" ;; esac
  else
    HOOKS_DIR="$VAULT/.git/hooks"
  fi
  if ! grep -qs 'canon' "$HOOKS_DIR/pre-commit" 2>/dev/null; then
    if [ -n "$(git -C "$VAULT" status --porcelain 2>/dev/null | head -1)" ]; then
      : > "$GUARD" 2>/dev/null || true
      python3 - "$VAULT" <<'PY' 2>/dev/null || true
import json, sys
print(json.dumps({"systemMessage":
  "Vault auto-commit is enabled but the pre-commit secret gate is NOT installed, so "
  "nothing was committed. This is deliberate: committing automatically without the "
  "gate is how a credential ends up in permanent history with nobody noticing.\n\n"
  f"Fix it once, and it stays fixed:  cd '{sys.argv[1]}' && ./.canon/bootstrap.sh\n\n"
  "Git never copies hooks when you clone, so this is per-machine. Until then commit "
  "the vault by hand, so a person is looking."}))
PY
    fi
    exit 0
  fi
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

# --- is the vault out of step with the team? ---------------------------------
# Checked BEFORE both the repo-changes gate and the "was a note written" return,
# on purpose. Writing the note and sharing it are two different failures, and the
# second outlives the first: everyone writes locally, nobody pushes, and a shared
# vault decays into a set of private ones. The two sessions that used to slip
# through are the well-behaved ones — agent writes the note and autocommit commits
# it, or the session only ever touched the vault and left the repo clean.
#
# Safe to run unconditionally because canon-status is SILENT when in step, so this
# speaks only when there is genuinely unshared work. No new noise on a read-only
# session with a clean vault.
export CANON_REPO="$REPO"   # so it can spot stale hooks in this repo
SH="$REPO/.claude/hooks/canon-status"
[ -x "$SH" ] || [ -z "${CLAUDE_PLUGIN_ROOT:-}" ] || SH="${CLAUDE_PLUGIN_ROOT}/bin/canon-status"
[ -x "$SH" ] || SH="$(command -v canon-status 2>/dev/null || true)"
SYNC=""
if [ -n "$SH" ] && [ -x "$SH" ]; then
  SYNC="$("$SH" "$VAULT" 2>/dev/null || true)"
fi

# "Out of step with the team" and "not shared until it is pushed" are both false
# for a vault with no remote — it is solo, and the only thing it can be is
# uncommitted. Saying otherwise names a team that does not exist and a command
# that cannot work, which is how a nudge trains people to ignore nudges.
SOLO=0
[ -z "$(git -C "$VAULT" remote 2>/dev/null)" ] && SOLO=1

# Nothing happened in the repo: the only thing still worth saying is that earlier
# vault work has not been shared. Never demand a note for a session that changed
# no code.
if [ "$CHANGES" != "1" ]; then
  [ -z "$SYNC" ] && exit 0
  : > "$GUARD" 2>/dev/null || true
  python3 - "$SYNC" "$SOLO" <<'PY' 2>/dev/null || true
import json, sys
solo = sys.argv[2] == "1"
head = ("The knowledge vault has unsaved work." if solo
        else "The knowledge vault is out of step with the team.")
tail = ("\n\nIt is not committed, so it is one lost laptop away from gone. Run the "
        "command above if the user wants it saved."
        if solo else
        "\n\nA vault only stays shared if this happens: unpushed notes are invisible "
        "to teammates, and unpulled ones mean this session read a stale picture. Run "
        "the command above if the user wants to sync.")
print(json.dumps({"systemMessage": head + "\n\n" + sys.argv[1] + tail}))
PY
  exit 0
fi

# --- was a session note written recently? ------------------------------------
WINDOW_MIN="${CANON_SESSION_NOTE_WINDOW_MIN:-720}"   # default 12h
RECENT="$(find "$VAULT/$SESSIONS_DIR" -type f -name '*.md' \
            -newermt "-${WINDOW_MIN} minutes" 2>/dev/null | head -1)"

if [ -n "$RECENT" ]; then
  # The note exists. Nothing to demand — but if it has not reached the team yet,
  # say so once. Never blocks: the work is done, this is a nudge, not a gate.
  [ -z "$SYNC" ] && exit 0
  : > "$GUARD" 2>/dev/null || true
  python3 - "$SYNC" "$SOLO" <<'PY' 2>/dev/null || true
import json, sys
solo = sys.argv[2] == "1"
head = ("A session note was written, but the vault has unsaved work." if solo
        else "A session note was written, but the vault is out of step with the team.")
tail = ("\n\nThe note is not saved until it is committed. Run the command above if "
        "the user wants to keep it."
        if solo else
        "\n\nThe note is not shared until it is pushed. Run the command above if the "
        "user wants their work to reach teammates.")
print(json.dumps({"systemMessage": head + "\n\n" + sys.argv[1] + tail}))
PY
  exit 0
fi

# --- nothing written: remind or block ----------------------------------------
: > "$GUARD" 2>/dev/null || true

REPO_NAME="$(basename "$REPO")"
MSG="This session changed files in ${REPO_NAME} but no note was written to ${SESSIONS_DIR}/ in the vault (${VAULT}). Per the team knowledge conventions, meaningful work ends with a dated session note: goal, what changed with repo-path:line refs, decisions, open follow-ups, linked to its project. Write it now, or state explicitly that this session did not warrant one."

[ -n "$SYNC" ] && MSG="$MSG

Also: $SYNC"

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
