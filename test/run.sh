#!/usr/bin/env bash
# test/run.sh — the sandbox lifecycle, automated.
#
#   ./test/run.sh
#
# Builds a throwaway vault and repo in a temp dir, exercises every script, and
# asserts on behaviour. No network, no installs, no side effects outside $TMPDIR.
# Runs under bash 3.2 (stock macOS) as well as modern bash.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0
SB=""

cleanup() { [ -n "$SB" ] && rm -rf "$SB"; }
trap cleanup EXIT

ok()   { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; }
is()   { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected '$3', got '$2'"; fi; }
isnt() { if [ "$2" != "$3" ]; then ok "$1"; else bad "$1" "should not be '$3'"; fi; }
has()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "missing: $3" ;; esac; }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

git_q() { git -c user.email=t@example.com -c user.name=Test "$@"; }

# ---------------------------------------------------------------------------
section "syntax + version"
for f in "$KIT"/install.sh "$KIT"/bin/canon-* "$KIT"/templates/repo/.claude/hooks/*.sh "$KIT"/test/run.sh; do
  if bash -n "$f" 2>/dev/null; then :; else bad "syntax: $(basename "$f")"; fi
done
ok "all scripts parse"

python3 -c "import json,sys;json.load(open('$KIT/templates/repo/.claude/settings.json'))" 2>/dev/null \
  && ok "settings.json is valid JSON" || bad "settings.json is invalid JSON"

VER="$(cat "$KIT/VERSION" 2>/dev/null || echo MISSING)"
mismatch=""
for f in "$KIT"/bin/canon-* "$KIT"/install.sh; do
  got="$("$f" --version 2>/dev/null | awk '{print $2}')"
  [ "$got" = "$VER" ] || mismatch="$mismatch $(basename "$f"):${got:-none}"
done
is "every script reports VERSION ($VER)" "${mismatch:-none}" "none"

# bash 3.2 compatibility — stock macOS ships 3.2.57
if grep -qnE 'declare -A|mapfile|readarray|\$\{[a-zA-Z_]+,,\}|globstar' \
     "$KIT"/bin/canon-* "$KIT"/install.sh 2>/dev/null; then
  bad "bash 3.2 compatible" "found a bash 4+ construct"
else
  ok "bash 3.2 compatible (no bash 4+ constructs)"
fi

# ---------------------------------------------------------------------------
section "vault scaffold"
SB="$(mktemp -d)"; V="$SB/vault"; R="$SB/repo"
"$KIT/bin/canon-init-vault" "$V" >/dev/null 2>&1
is "creates the router"        "$([ -f "$V/Vision/Agent Router.md" ] && echo y)" "y"
is "creates 6 note templates" "$(find "$V/Templates" -name '*.md' | wc -l | tr -d ' ')" "6"
is "gitkeeps every folder"    "$(find "$V" -name .gitkeep | wc -l | tr -d ' ')" "13"
is "ships .canon-owners"      "$([ -f "$V/.canon-owners" ] && echo y)" "y"

# every folder the router advertises must exist
missing=""
for d in Vision Projects Clients Decisions Reference Sessions Specs Handoffs Outputs Sources Templates; do
  [ -d "$V/$d" ] || missing="$missing $d"
done
is "all advertised folders exist" "${missing:-none}" "none"

# re-run must not clobber
echo "EDITED" > "$V/Vision/Agent Router.md"
"$KIT/bin/canon-init-vault" "$V" >/dev/null 2>&1
is "re-run is non-destructive" "$(cat "$V/Vision/Agent Router.md")" "EDITED"
"$KIT/bin/canon-init-vault" "$V" >/dev/null 2>&1   # restore-ish; content stays EDITED

cd "$V" && git_q add -A >/dev/null && git_q commit -qm init >/dev/null
git config user.email t@example.com; git config user.name Test

# ---------------------------------------------------------------------------
section "path resolution"
mkdir -p "$R" && cd "$R" && git init -q && git config user.email t@example.com && git config user.name Test
"$KIT/install.sh" "$R" --vault "$V" >/dev/null 2>&1
RES="$R/.claude/hooks/canon-path"
is "resolves via .canon marker" "$("$RES" 2>/dev/null | xargs -I{} sh -c 'cd {} && pwd -P')" "$(cd "$V" && pwd -P)"
is "CANON_HOME wins"            "$(CANON_HOME=/tmp "$RES" 2>/dev/null)" "$(cd /tmp && pwd -P)"
"$RES" >/dev/null 2>&1; is "exit 0 when configured" "$?" "0"
CANON_HOME=/nonexistent "$RES" >/dev/null 2>&1
is "invalid CANON_HOME fails, no fallback" "$?" "1"

# ---------------------------------------------------------------------------
section "install is non-destructive"
R2="$SB/repo2"; mkdir -p "$R2/.claude"; cd "$R2" || exit 1; git init -q
printf '# Mine\n\nnpm test\n' > CLAUDE.md
printf '{"hooks":{"PostToolUse":[{"matcher":"Edit","hooks":[{"type":"command","command":"echo keep-me"}]}]},"permissions":{"allow":["Bash(npm test)"]}}\n' > .claude/settings.json
"$KIT/install.sh" "$R2" --vault "$V" >/dev/null 2>&1
S="$R2/.claude/settings.json"
has "preserves existing hook" "$(cat "$S")" "keep-me"
has "preserves existing allow" "$(cat "$S")" "Bash(npm test)"
has "adds our SessionStart"    "$(cat "$S")" "session-start.sh"
has "preserves CLAUDE.md body" "$(cat CLAUDE.md)" "npm test"
L1="$(wc -l < CLAUDE.md)"; H1="$(python3 -c "
import json;d=json.load(open('$S'));print(sum(len(g['hooks']) for e in d['hooks'].values() for g in e))")"
"$KIT/install.sh" "$R2" --vault "$V" >/dev/null 2>&1
is "re-install does not duplicate CLAUDE.md" "$(wc -l < CLAUDE.md)" "$L1"
is "re-install does not duplicate hooks" "$(python3 -c "
import json;d=json.load(open('$S'));print(sum(len(g['hooks']) for e in d['hooks'].values() for g in e))")" "$H1"

# ---------------------------------------------------------------------------
section "SessionStart hook"
OUT="$(CLAUDE_PROJECT_DIR="$R" CANON_HOME="$V" bash "$R/.claude/hooks/session-start.sh" 2>/dev/null)"
python3 -c "
import json,sys
d=json.loads('''$OUT'''.replace(chr(10),' ')) if False else json.loads(sys.stdin.read())
o=d['hookSpecificOutput']
assert o['hookEventName']=='SessionStart', o
assert len(o['additionalContext'])<10000, len(o['additionalContext'])
" <<< "$OUT" 2>/dev/null && ok "emits valid JSON under the 10k cap" || bad "SessionStart JSON invalid or oversized"
has "names the vault path" "$OUT" "$(cd "$V" && pwd -P)"

OUT2="$(CANON_HOME=/nonexistent CLAUDE_PROJECT_DIR="$R" bash "$R/.claude/hooks/session-start.sh" 2>/dev/null)"
has "diagnoses a stale CANON_HOME" "$OUT2" "MISCONFIGURED"

# ---------------------------------------------------------------------------
section "Stop hook"
export CANON_HOME="$V"
GUARDDIR="${TMPDIR:-/tmp}/canon-hooks"; rm -rf "$GUARDDIR"
SEC="$R/.claude/hooks/session-end-check.sh"
stop() { CLAUDE_PROJECT_DIR="$R" bash "$SEC" <<< "{\"session_id\":\"$1\"}" 2>/dev/null; }

# Commit the install first — the documented workflow is to commit .claude/ and
# CLAUDE.md so teammates inherit them. Without this the repo has the installer's
# own files uncommitted, which correctly reads as "work happened".
cd "$R" && git_q add -A >/dev/null 2>&1 && git_q commit -qm "install canon" >/dev/null 2>&1
is "silent on a clean tree" "$(stop s1)" ""
echo change > work.txt
has "reminds when nothing was written" "$(stop s2)" "systemMessage"
is "fires once per session" "$(stop s2)" ""
printf -- '---\ntype: session\n---\n# n\n' > "$V/Sessions/note.md"
is "silent once a note exists" "$(stop s4)" ""
rm -f "$V/Sessions/note.md"
has "block mode emits a decision" "$(CANON_ENFORCE_SESSION_NOTE=block CLAUDE_PROJECT_DIR="$R" bash "$SEC" <<< '{"session_id":"s5"}' 2>/dev/null)" '"block"'
is "off mode is silent" "$(CANON_ENFORCE_SESSION_NOTE=off CLAUDE_PROJECT_DIR="$R" bash "$SEC" <<< '{"session_id":"s6"}' 2>/dev/null)" ""

# ---------------------------------------------------------------------------
section "the secret gate"
"$KIT/bin/canon-install-vault-hooks" "$V" >/dev/null 2>&1
cd "$V" && git_q add -A >/dev/null && git_q commit -qm tools >/dev/null
is "pre-commit hook installed" "$([ -x "$V/.git/hooks/pre-commit" ] && echo y)" "y"

printf -- '---\ntype: session\n---\nChanged `api/auth.ts:42`.\n' > "$V/Sessions/clean.md"
"$KIT/bin/canon-sync" -m "clean" >/dev/null 2>&1
is "clean note commits" "$?" "0"

for pair in "sk-ant-api03-AbCdEfGhIjKlMnOpQrStUvWxYz0123456789:Anthropic" \
            "AKIA1234567890ABCDEF:AWS" \
            "ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789:GitHub" \
            "postgres://u:hunter2@db.example.com/x:URL" \
            "123-45-6789:SSN" \
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abc123:JWT"; do
  secret="${pair%:*}"; label="${pair##*:}"
  printf 'note %s here\n' "$secret" > "$V/Sessions/leak.md"
  cd "$V" && git add -A >/dev/null 2>&1
  if "$V/.canon/canon-scan" "$V" >/dev/null 2>&1; then bad "detects $label"; else ok "detects $label"; fi
  git reset -q
done
rm -f "$V/Sessions/leak.md"

# Conflict markers must be caught. This is the likeliest way a git-synced vault
# gets quietly damaged: a conflict is resolved by hand, the markers render as
# ordinary text in the editor, and they get committed into the note.
printf -- '# n\n<<<<<<< HEAD\nmine\n=======\ntheirs\n>>>>>>> branch\n' > "$V/Sessions/conflict.md"
cd "$V" && git add -A >/dev/null 2>&1
"$V/.canon/canon-scan" "$V" >/dev/null 2>&1
is "catches merge conflict markers" "$?" "1"
git reset -q; rm -f "$V/Sessions/conflict.md"

# ...but a run of = or - signs is a legitimate markdown setext heading underline.
printf -- 'A Heading\n=========\n\nprose\n\nSub\n---------\n' > "$V/Sessions/setext.md"
cd "$V" && git add -A >/dev/null 2>&1
"$V/.canon/canon-scan" "$V" >/dev/null 2>&1
is "allows markdown setext underlines" "$?" "0"
git reset -q; rm -f "$V/Sessions/setext.md"

# the scanner must not flag its own source
cd "$V" && git add -A >/dev/null 2>&1
"$V/.canon/canon-scan" "$V" >/dev/null 2>&1
is "does not flag its own source" "$?" "0"

# committed path exclusion must work (shared, not per-machine)
printf 'AKIA1234567890ABCDEF\n' > "$V/Reference/vendor-doc.md"
cd "$V" && git add -A >/dev/null 2>&1
"$V/.canon/canon-scan" "$V" >/dev/null 2>&1; before=$?
printf '(^|/)Reference/vendor-doc\\.md$\n' > "$V/.canon-scan-exclude"
git add -A >/dev/null 2>&1
"$V/.canon/canon-scan" "$V" >/dev/null 2>&1; after=$?
is "flags a vendored token by default" "$before" "1"
is ".canon-scan-exclude suppresses it" "$after" "0"
git reset -q; rm -f "$V/Reference/vendor-doc.md" "$V/.canon-scan-exclude"

# raw git commit is gated too
printf 'AKIA1234567890ABCDEF\n' > "$V/Sessions/sneak.md"
cd "$V" && git add -A >/dev/null 2>&1
git_q commit -qm sneak >/dev/null 2>&1
is "plain git commit is blocked" "$?" "1"
git reset -q; rm -f "$V/Sessions/sneak.md"

# ---------------------------------------------------------------------------
section "auto-pull is safe under an open editor"
# A dirty tree means someone is mid-edit, and those are exactly the files an
# editor is holding in memory. The hook must not touch git at all.
cd "$V" && git_q commit -qam "settle" >/dev/null 2>&1
printf 'mid-edit\n' > "$V/Projects/dirty.md"
HEAD_BEFORE="$(git -C "$V" rev-parse HEAD)"
CANON_AUTOPULL=1 CLAUDE_PROJECT_DIR="$R" bash "$R/.claude/hooks/session-start.sh" >/dev/null 2>&1
is "dirty tree: HEAD unchanged"      "$(git -C "$V" rev-parse HEAD)" "$HEAD_BEFORE"
is "dirty tree: local edit intact"   "$(cat "$V/Projects/dirty.md")" "mid-edit"
rm -f "$V/Projects/dirty.md"

# The unattended pull must be a fast-forward: it cannot rewrite local commits,
# cannot leave a half-finished rebase, and cannot write conflict markers.
if grep -q -- "--ff-only" "$R/.claude/hooks/session-start.sh"; then
  ok "hook pulls with --ff-only"; else bad "hook is not using --ff-only"; fi
if grep -q -- "pull --rebase" "$R/.claude/hooks/session-start.sh"; then
  bad "hook still rebases unattended"; else ok "hook never rebases unattended"; fi

# ---------------------------------------------------------------------------
section "an existing pre-commit hook survives install"
V2="$SB/vault2"
"$KIT/bin/canon-init-vault" "$V2" >/dev/null 2>&1
cd "$V2" && git_q add -A >/dev/null && git_q commit -qm init >/dev/null
git config user.email t@example.com; git config user.name Test
# a pre-existing check the repo already relied on
printf '#!/usr/bin/env bash\necho "PRIOR HOOK RAN"\nexit 0\n' > "$V2/.git/hooks/pre-commit"
chmod +x "$V2/.git/hooks/pre-commit"
"$KIT/bin/canon-install-vault-hooks" "$V2" >/dev/null 2>&1
is "prior hook is chained, not deleted" "$([ -x "$V2/.git/hooks/pre-commit.canon-chained" ] && echo y)" "y"
printf -- '---\ntype: session\n---\nok\n' > "$V2/Sessions/a.md"
cd "$V2" && git add -A >/dev/null 2>&1
OUTH="$(git_q commit -m "chained" 2>&1)"
has "prior hook still executes"  "$OUTH" "PRIOR HOOK RAN"
has "canon checks also execute"  "$OUTH" "canon-scan"

# a failing prior hook must veto the commit before canon's checks run
printf '#!/usr/bin/env bash\necho "PRIOR SAYS NO"\nexit 1\n' > "$V2/.git/hooks/pre-commit.canon-chained"
chmod +x "$V2/.git/hooks/pre-commit.canon-chained"
printf -- 'x\n' > "$V2/Sessions/b.md"; git add -A >/dev/null 2>&1
git_q commit -qm "should be vetoed" >/dev/null 2>&1
is "failing prior hook vetoes the commit" "$?" "1"
git reset -q; cd "$V" || exit 1

# A repo with core.hooksPath set (husky, pre-commit framework, shared hooks dir)
# makes git ignore .git/hooks completely. Installing there = a silently inert
# gate, which is worse than none because you believe you are covered.
V3="$SB/vault3"
"$KIT/bin/canon-init-vault" "$V3" >/dev/null 2>&1
cd "$V3" || exit 1
git_q add -A >/dev/null && git_q commit -qm init >/dev/null
git config user.email t@example.com; git config user.name Test
mkdir -p "$V3/myhooks"; git config core.hooksPath myhooks
"$KIT/bin/canon-install-vault-hooks" "$V3" >/dev/null 2>&1
is "installs into core.hooksPath, not .git/hooks" "$([ -x "$V3/myhooks/pre-commit" ] && echo y)" "y"
is "does NOT write the ignored .git/hooks path"   "$([ -f "$V3/.git/hooks/pre-commit" ] && echo wrote || echo clean)" "clean"
printf 'AKIA1234567890ABCDEF\n' > "$V3/Sessions/leak.md"
git add -A >/dev/null 2>&1
git_q commit -qm "must be blocked" >/dev/null 2>&1
is "gate actually fires under core.hooksPath" "$?" "1"
git reset -q; cd "$V" || exit 1

# ---------------------------------------------------------------------------
section "ownership guard"
cat > "$V/.canon-owners" <<'EOF'
Vision/**      lead@example.com
Sessions/**    *
EOF
cd "$V" && git add -A >/dev/null 2>&1 && git_q commit -qm owners >/dev/null 2>&1

echo "edit" >> "$V/Vision/How We Work.md"
git add -A >/dev/null 2>&1
G="$V/.canon/canon-guard"
OUTG="$(CANON_GUARD=warn "$G" "$V" 2>&1)"; rc=$?
is "warn mode allows the commit" "$rc" "0"
has "warn mode names the owner" "$OUTG" "lead@example.com"
CANON_GUARD=block "$G" "$V" >/dev/null 2>&1
is "block mode refuses" "$?" "1"
CANON_GUARD=off "$G" "$V" >/dev/null 2>&1
is "off mode is silent" "$?" "0"
git reset -q; cd "$V" && git checkout -- "Vision/How We Work.md" 2>/dev/null

printf -- '---\ntype: session\n---\nmine\n' > "$V/Sessions/ok.md"
git add -A >/dev/null 2>&1
CANON_GUARD=block "$G" "$V" >/dev/null 2>&1
is "open paths are unrestricted" "$?" "0"
git reset -q

# owner may edit their own governed path
git config user.email lead@example.com
echo "edit" >> "$V/Vision/How We Work.md"; git add -A >/dev/null 2>&1
CANON_GUARD=block "$G" "$V" >/dev/null 2>&1
is "the owner may edit it" "$?" "0"
git config user.email t@example.com
git reset -q

# ---------------------------------------------------------------------------
section "uninstall"
"$KIT/install.sh" "$R2" --uninstall >/dev/null 2>&1
is "removes our hooks"        "$([ -f "$R2/.claude/hooks/session-start.sh" ] && echo present || echo gone)" "gone"
has "leaves foreign hooks alone" "$(cat "$R2/.claude/settings.json")" "keep-me"
has "leaves CLAUDE.md body"      "$(cat "$R2/CLAUDE.md")" "npm test"
if grep -q "canon:knowledge-vault" "$R2/CLAUDE.md" 2>/dev/null; then
  bad "strips our CLAUDE.md block"; else ok "strips our CLAUDE.md block"; fi

# ---------------------------------------------------------------------------
printf '\n\033[1m%d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
