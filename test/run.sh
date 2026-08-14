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

# Unbraced "$VAR" followed by a multibyte character. bash 3.2 folds the UTF-8
# bytes into the variable name, so "origin/$BRANCH…" dies under set -u as
# "BRANCH<junk>: unbound variable". bash -n cannot see it — it is a runtime
# failure, and this kit is full of prose-y echoes with ellipses and em dashes.
if LC_ALL=C grep -n '\$[A-Za-z_][A-Za-z0-9_]*[^ -~]' \
     "$KIT"/bin/canon-* "$KIT"/install.sh \
     "$KIT"/templates/repo/.claude/hooks/*.sh 2>/dev/null; then
  bad "no unbraced \$VAR before a multibyte char" "brace it: \${VAR}…"
else
  ok "no unbraced \$VAR before a multibyte char"
fi

# ---------------------------------------------------------------------------
section "vault scaffold"
SB="$(mktemp -d)"; V="$SB/vault"; R="$SB/repo"
"$KIT/bin/canon-init-vault" "$V" >/dev/null 2>&1
is "creates the router"        "$([ -f "$V/Vision/Agent Router.md" ] && echo y)" "y"
is "creates 8 note templates" "$(find "$V/Templates" -name '*.md' | wc -l | tr -d ' ')" "8"
is "gitkeeps every folder"    "$(find "$V" -name .gitkeep | wc -l | tr -d ' ')" "13"
is "ships .canon-owners"      "$([ -f "$V/.canon-owners" ] && echo y)" "y"
is "ships a self-bootstrap"   "$([ -x "$V/.canon/bootstrap.sh" ] && echo y)" "y"
missing_tools=""
for t in canon-scan canon-guard canon-path canon-install-vault-hooks; do
  [ -x "$V/.canon/$t" ] || missing_tools="$missing_tools $t"
done
is "vendors its own tooling"  "${missing_tools:-none}" "none"

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
has "also writes AGENTS.md"    "$(cat AGENTS.md 2>/dev/null)" "Shared knowledge vault"
is  "installs cursor rules"    "$([ -f "$R2/.cursor/rules/knowledge-vault.mdc" ] && echo y)" "y"
CB="$(grep -A200 'canon:knowledge-vault' CLAUDE.md | tail -n +2)"
AB="$(grep -A200 'canon:knowledge-vault' AGENTS.md | tail -n +2)"
is  "CLAUDE.md and AGENTS.md blocks are identical" "$([ "$CB" = "$AB" ] && echo same || echo DRIFTED)" "same"
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

# Put the vault in step first. The hook now checks sync status before the
# repo-changes gate, so "silent" only means anything once there is nothing to say.
git_q -C "$V" add -A >/dev/null 2>&1; git_q -C "$V" commit -qm base >/dev/null 2>&1
: > "$V/.git/FETCH_HEAD"
is "silent on a clean tree, vault in step" "$(stop s1)" ""

# Clean repo, unshared vault work: worth saying, but never worth demanding a
# session note for — this session did not change any code.
echo stray > "$V/Projects/stray.md"
OUTV="$(stop s1b)"
# Asserted on behaviour, not on wording — the prose here gets revised, the
# contract does not: say something, name the command, demand nothing.
has "flags unshared vault work on a clean tree" "$OUTV" "systemMessage"
has "and names the command to fix it"           "$OUTV" "canon-sync"
case "$OUTV" in *"no note was written"*) bad "demands no note on a clean tree" ;; *) ok "demands no note on a clean tree" ;; esac
git_q -C "$V" add -A >/dev/null 2>&1; git_q -C "$V" commit -qm stray >/dev/null 2>&1

cd "$R" || exit 1
echo change > work.txt
has "reminds when nothing was written" "$(stop s2)" "systemMessage"
is "fires once per session" "$(stop s2)" ""
printf -- '---\ntype: session\n---\n# n\n' > "$V/Sessions/note.md"

# The note exists but is still on this laptop. Writing it and sharing it are two
# different failures; the hook must still say something, and must not block.
OUTN="$(stop s4)"
has "nudges when the note is unshared" "$OUTN" "canon-sync --push"
case "$OUTN" in *'"decision"'*) bad "the unshared nudge never blocks" ;; *) ok "the unshared nudge never blocks" ;; esac

# Note written AND shared — the fully-good session. Silence is the whole point.
git_q -C "$V" add -A >/dev/null 2>&1; git_q -C "$V" commit -qm notes >/dev/null 2>&1
: > "$V/.git/FETCH_HEAD"
is "silent once a note exists and is shared" "$(stop s5)" ""
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
nbak=0
for f in "$V2/.git/hooks/"pre-commit.bak.*; do [ -e "$f" ] && nbak=$((nbak+1)); done
is "no redundant .bak duplicate"        "$nbak" "0"
# re-running must not overwrite the already-chained hook with our own
"$KIT/bin/canon-install-vault-hooks" "$V2" >/dev/null 2>&1
if grep -q 'canon-scan' "$V2/.git/hooks/pre-commit.canon-chained" 2>/dev/null; then
  bad "re-install does not chain our own hook"; else ok "re-install does not chain our own hook"; fi
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

# The Slack connector is optional and needs Node, so we cannot run it here. But
# its safety properties are static and MUST NOT regress — someone adding Bash "for
# convenience" turns a read-only Q&A bot into a remote shell over the vault.
section "connector safety (static)"
# Connectors are optional and need Node, so we cannot run them here. Their safety
# properties are static and MUST NOT regress: someone adding Bash "for
# convenience" turns a read-only Q&A bot into a remote shell over the vault.
CORE="$KIT/connectors/shared/agent.mjs"
VAULTMOD="$KIT/connectors/shared/vault.mjs"
MCP="$KIT/connectors/mcp/src/server.mjs"
APPS="$KIT/connectors/slack/src/app.mjs $KIT/connectors/discord/src/app.mjs $MCP"

if [ -f "$CORE" ]; then
  if command -v node >/dev/null 2>&1; then
    parse_fail=""
    for f in "$CORE" "$VAULTMOD" $APPS; do
      node --check "$f" >/dev/null 2>&1 || parse_fail="$parse_fail $(basename "$(dirname "$(dirname "$f")")")"
    done
    is "core + all connectors parse" "${parse_fail:-none}" "none"
  fi

  # The tool list lives in ONE place. Assert its exact contents.
  TOOLS="$(python3 -c "
import re
s=open('$CORE').read()
m=re.search(r'READ_ONLY_TOOLS\s*=\s*\[([^\]]*)\]', s)
print(','.join(t.strip().strip(chr(34)+chr(39)) for t in m.group(1).split(',') if t.strip()) if m else 'PARSE-FAIL')")"
  is "core tool list is read-only"  "$TOOLS" "Read,Grep,Glob"

  # And no connector may declare its own — that is how two platforms drift apart
  # and one of them quietly gains write access.
  own=0
  for f in $APPS; do
    [ -f "$f" ] && own=$((own + $(grep -c 'allowedTools:' "$f")))
  done
  is "no connector declares its own tools" "$own" "0"

  is "cwd pinned to the vault in core"     "$(grep -c 'cwd: vault' "$CORE")" "1"

  # vault.mjs must stay dependency-free, or the MCP server needs a model client it
  # does not use and the path-safety test stops being runnable without a network.
  is "vault.mjs has no external imports" "$(grep -cE '^import .* from "[^n.]' "$VAULTMOD")" "0"
  # The MCP server must expose no write tool. Not one that refuses — none at all.
  if grep -qE 'canon_(write|edit|delete|create)' "$MCP"; then
    bad "MCP server exposes a write tool"; else ok "MCP server has no write tool"; fi
  if command -v node >/dev/null 2>&1; then
    (cd "$KIT" && node test/links.test.mjs >/dev/null 2>&1) \
      && ok "markdown links and anchors resolve" \
      || bad "broken link or anchor — run: node test/links.test.mjs"
    node "$KIT/test/paths.test.mjs" >/dev/null 2>&1 \
      && ok "MCP path-traversal boundary holds (10 cases)" \
      || bad "MCP path-traversal tests FAILED — run test/paths.test.mjs"
  fi
  if grep -q "refusing to start with no allowlist" "$CORE"; then
    ok "fails closed without an allowlist"; else bad "no fail-closed allowlist check in core"; fi

  # Tokens must never be committable.
  miss=""
  for d in slack discord mcp; do
    grep -qE '^\.env$' "$KIT/connectors/$d/.gitignore" 2>/dev/null || miss="$miss $d"
  done
  is ".env gitignored in every connector" "${miss:-none}" "none"
fi

section "sync reminders"
V5="$SB/vault5"
"$KIT/bin/canon-init-vault" "$V5" >/dev/null 2>&1
cd "$V5" || exit 1; git init -q; git config user.email t@t; git config user.name Test
git add -A >/dev/null; git commit -qm init >/dev/null

is "vendors canon-status"          "$([ -x "$V5/.canon/canon-status" ] && echo y)" "y"
# No remote and never fetched: it should say something, not crash.
has "flags a vault never pulled"   "$("$KIT/bin/canon-status" "$V5" 2>/dev/null)" "never pulled"
"$KIT/bin/canon-status" "$V5" >/dev/null 2>&1
is "exits 1 when action is needed" "$?" "1"

# Uncommitted work must be reported.
echo scratch > "$V5/Projects/x.md"
has "flags uncommitted files"      "$("$KIT/bin/canon-status" "$V5" 2>/dev/null)" "uncommitted"
has "suggests the push command"    "$("$KIT/bin/canon-status" "$V5" 2>/dev/null)" "canon-sync --push"
rm -f "$V5/Projects/x.md"

# A clean, freshly fetched vault must be SILENT — a reminder that always fires is
# a reminder people learn to ignore.
: > "$V5/.git/FETCH_HEAD"
OUTQ="$("$KIT/bin/canon-status" "$V5" 2>/dev/null)"
is "silent when nothing to do"     "${OUTQ:-silent}" "silent"
"$KIT/bin/canon-status" "$V5" >/dev/null 2>&1
is "exits 0 when in step"          "$?" "0"

# No network call, or a session start on a bad connection hangs.
is "makes no network call"          "$(grep -cE '^[^#]*git (-C [^ ]+ )?(fetch|ls-remote)' "$KIT/bin/canon-status")" "0"
cd "$V" || exit 1

# ---------------------------------------------------------------------------
section "provenance and trust"
V4="$SB/vault4"
"$KIT/bin/canon-init-vault" "$V4" >/dev/null 2>&1
cd "$V4" || exit 1; git init -q; git config user.email chris@example.com; git config user.name Chris

is "vendors canon-trust + canon-verify" \
   "$([ -x "$V4/.canon/canon-trust" ] && [ -x "$V4/.canon/canon-verify" ] && echo y)" "y"
is "templates carry generated:" \
   "$(grep -l 'generated:' "$V4"/Templates/*.md | wc -l | tr -d ' ')" "6"

printf -- '---\ntype: decision\ngenerated: { by: some-agent/1, at: 2026-07-30T10:00:00Z }\n---\n# x\n' > "$V4/Decisions/a.md"
printf -- '---\ntype: reference\nverified: { by: process:ci, at: 2026-07-02T02:00:00Z }\nstale_after: 2020-01-01\n---\n# y\n' > "$V4/Reference/b.md"

T="$("$KIT/bin/canon-trust" "$V4" 2>/dev/null)"
has "reports the unverified tier"        "$T" "unverified"
has "flags an agent-written note"        "$T" "Decisions/a.md"
has "derives machine-confirmed"          "$T" "machine-confirmed"
has "flags a stale note"                 "$T" "Reference/b.md"
is  "--tier filters"                     "$("$KIT/bin/canon-trust" "$V4" --tier machine-confirmed --quiet 2>/dev/null)" "Reference/b.md"
"$KIT/bin/canon-trust" "$V4" --strict >/dev/null 2>&1
is  "--strict fails on rot"              "$?" "1"
is  "excludes Templates/ from the count" "$(printf '%s' "$T" | grep -c 'Templates/')" "0"

# canon-verify: adds, is idempotent per actor, promotes a bare mapping, never
# touches generated, and refuses a note with no frontmatter.
"$KIT/bin/canon-verify" "$V4/Decisions/a.md" >/dev/null 2>&1
is "verify adds a human entry"    "$(grep -c 'by: human:chris' "$V4/Decisions/a.md")" "1"
"$KIT/bin/canon-verify" "$V4/Decisions/a.md" >/dev/null 2>&1
is "re-verify does not duplicate" "$(grep -c 'by: human:chris' "$V4/Decisions/a.md")" "1"
"$KIT/bin/canon-verify" --actor process:ci "$V4/Decisions/a.md" >/dev/null 2>&1
is "a second actor stacks"        "$(grep -c '^  - { by:' "$V4/Decisions/a.md")" "2"
is "never writes a broken one-liner" "$(grep -c '^verified:  ' "$V4/Decisions/a.md")" "0"
is "leaves generated alone"       "$(grep -c 'by: some-agent/1' "$V4/Decisions/a.md")" "1"
has "tier becomes human-reviewed" "$("$KIT/bin/canon-trust" "$V4" --tier human-reviewed --quiet 2>/dev/null)" "Decisions/a.md"
"$KIT/bin/canon-verify" "$V4/Reference/b.md" >/dev/null 2>&1
is "promotes a bare mapping to a list" "$(grep -c '^  - { by:' "$V4/Reference/b.md")" "2"
printf '# no frontmatter\n' > "$V4/Projects/none.md"
"$KIT/bin/canon-verify" "$V4/Projects/none.md" >/dev/null 2>&1
is "refuses a note with no frontmatter" "$?" "1"
cd "$V" || exit 1

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
section "plugin packaging"
# Claude Code parses these before it will show the plugin at all, so a typo here
# is invisible until someone tries to install and gets nothing.
python3 -c "import json;json.load(open('$KIT/.claude-plugin/plugin.json'))" 2>/dev/null \
  && ok "plugin.json is valid JSON" || bad "plugin.json is invalid JSON"
python3 -c "import json;json.load(open('$KIT/.claude-plugin/marketplace.json'))" 2>/dev/null \
  && ok "marketplace.json is valid JSON" || bad "marketplace.json is invalid JSON"
python3 -c "import json;json.load(open('$KIT/hooks/hooks.json'))" 2>/dev/null \
  && ok "hooks.json is valid JSON" || bad "hooks.json is invalid JSON"

is "plugin version tracks VERSION" \
  "$(python3 -c "import json;print(json.load(open('$KIT/.claude-plugin/plugin.json'))['version'])" 2>/dev/null)" \
  "$(cat "$KIT/VERSION")"
is "marketplace lists the plugin" \
  "$(python3 -c "import json;print(json.load(open('$KIT/.claude-plugin/marketplace.json'))['plugins'][0]['name'])" 2>/dev/null)" \
  "canon"

# Every command the plugin hooks references must exist at the path it names,
# resolved from the plugin root. A hooks.json pointing at a moved script fails
# silently at session start, which is the worst place for it.
missing_hookfiles=""
for rel in $(python3 -c "
import json,re
d=json.load(open('$KIT/hooks/hooks.json'))
for ev in d['hooks'].values():
    for g in ev:
        for h in g['hooks']:
            m=re.search(r'\\\$\{CLAUDE_PLUGIN_ROOT\}/([^\"]+)', h['command'])
            if m: print(m.group(1))
" 2>/dev/null); do
  [ -f "$KIT/$rel" ] || missing_hookfiles="$missing_hookfiles $rel"
done
is "hooks.json points at files that exist" "${missing_hookfiles:-none}" "none"

# The same hook script must work whether canon was installed into a repo or added
# as a plugin. Assert the plugin-root fallback is present in both, because losing
# it breaks plugin mode without breaking any other test.
missing_fallback=""
for f in session-start.sh session-end-check.sh; do
  LC_ALL=C grep -q 'CLAUDE_PLUGIN_ROOT' "$KIT/templates/repo/.claude/hooks/$f" \
    || missing_fallback="$missing_fallback $f"
done
is "hooks resolve tools from the plugin root too" "${missing_fallback:-none}" "none"

# Plugin mode: no repo copy, nothing on PATH, only CLAUDE_PLUGIN_ROOT.
PLUGOUT="$(cd "$SB" && env -u CANON_HOME CLAUDE_PLUGIN_ROOT="$KIT" CANON_HOME="$V4" \
  bash "$KIT/templates/repo/.claude/hooks/session-start.sh" </dev/null 2>/dev/null)"
has "SessionStart works in plugin mode" "$PLUGOUT" "hookSpecificOutput"

missing_cmds=""
for c in canon-sync canon-status canon-setup; do
  [ -f "$KIT/commands/$c.md" ] || missing_cmds="$missing_cmds $c"
done
is "ships the slash commands" "${missing_cmds:-none}" "none"

# ---------------------------------------------------------------------------
section "other agent runtimes"
R3="$SB/repo3"; mkdir -p "$R3"; git init -q "$R3" 2>/dev/null
"$KIT/install.sh" "$R3" --vault "$V4" >/dev/null 2>&1
missing_rt=""
for f in CLAUDE.md AGENTS.md GEMINI.md .github/copilot-instructions.md \
         .windsurf/rules/knowledge-vault.md .clinerules/knowledge-vault.md \
         .cursor/rules/knowledge-vault.mdc; do
  [ -f "$R3/$f" ] || missing_rt="$missing_rt $f"
done
is "writes an instruction file per runtime" "${missing_rt:-none}" "none"

# Generated from ONE template, so they cannot drift. Six hand-maintained copies of
# the same instructions is six chances to disagree, silently.
drift=""
BASE="$(cat "$R3/CLAUDE.md")"
for f in AGENTS.md GEMINI.md .github/copilot-instructions.md \
         .windsurf/rules/knowledge-vault.md .clinerules/knowledge-vault.md; do
  [ "$(cat "$R3/$f")" = "$BASE" ] || drift="$drift $f"
done
is "every runtime file is byte-identical" "${drift:-none}" "none"

"$KIT/install.sh" "$R3" --vault "$V4" >/dev/null 2>&1
is "re-install does not duplicate the block" \
  "$(LC_ALL=C grep -c 'canon:knowledge-vault' "$R3/GEMINI.md" | tr -d ' ')" "1"

is "--claude-only writes no extra runtimes" \
  "$(R4="$SB/repo4"; mkdir -p "$R4"; git init -q "$R4" 2>/dev/null; \
     "$KIT/install.sh" "$R4" --vault "$V4" --claude-only >/dev/null 2>&1; \
     [ -f "$R4/GEMINI.md" ] && echo present || echo absent)" "absent"

# Uninstall must not need the same flags it was installed with — nobody remembers
# them, and a tool you cannot cleanly remove is one people will not try.
"$KIT/install.sh" "$R3" --uninstall >/dev/null 2>&1
left=""
for f in GEMINI.md .github/copilot-instructions.md \
         .windsurf/rules/knowledge-vault.md .clinerules/knowledge-vault.md; do
  [ -e "$R3/$f" ] && left="$left $f"
done
is "uninstall removes every runtime file" "${left:-none}" "none"
is "and prunes the directories it created" \
  "$([ -d "$R3/.windsurf" ] || [ -d "$R3/.clinerules" ] && echo left || echo pruned)" "pruned"

# ---------------------------------------------------------------------------
section "design canon"
# The design canon is the one note type whose machine-readable half ships with a
# validator, so the template and the tool must agree on the fence names. These
# assertions are the tripwire for the failure the kit already has once: a Product
# Spec template whose fence names never matched the validator written for it.
# A fresh vault on purpose. By this point $V has had its router overwritten with
# "EDITED" by the non-destructive-rerun check and its .canon-owners rewritten by
# the ownership-guard section, so asserting file shape against it tests the
# earlier tests' leftovers rather than the templates.
V8="$SB/vault8"; "$KIT/bin/canon-init-vault" "$V8" >/dev/null 2>&1
DSY="$V8/Templates/Design System.md"
DCO="$V8/Templates/Design Component.md"
is "ships a Design System template"    "$([ -f "$DSY" ] && echo y)" "y"
is "ships a Design Component template" "$([ -f "$DCO" ] && echo y)" "y"
has "declares the design-tokens fence"     "$(cat "$DSY")" '```design-tokens'
has "declares the design-components fence" "$(cat "$DSY")" '```design-components'
has "marks the contract frozen"            "$(cat "$DSY")" "FROZEN"

# The component note's frontmatter IS one block row. If they drift, promoting a
# row to a note silently loses fields, so assert the shared keys exist in both.
missing_keys=""
for k in figma image impl tokens status; do
  LC_ALL=C grep -q "^${k}:" "$DCO" || missing_keys="$missing_keys $k"
done
is "component frontmatter carries the row keys" "${missing_keys:-none}" "none"
has "component template uses dash-form node ids" "$(cat "$DCO")" "dash-form-node-id"

# The whole reason the canon can live in a vault: names, never values.
has "system template forbids token values" "$(cat "$DSY")" "Names in the vault"
missing_rules=""
for f in "$R2/.claude/rules/knowledge-vault.md" "$R2/.cursor/rules/knowledge-vault.mdc"; do
  LC_ALL=C grep -q "design-token values\|Design-token values" "$f" 2>/dev/null \
    || missing_rules="$missing_rules $(basename "$f")"
done
is "BOTH rules files ban token values" "${missing_rules:-none}" "none"

# Router must advertise it, and must still fit the budget it advertises.
has "router routes Reference/Design"  "$(cat "$V8/Vision/Agent Router.md")" "Reference/Design/"
RL="$(wc -l < "$V8/Vision/Agent Router.md" | tr -d ' ')"
if [ "$RL" -lt 150 ]; then ok "router still under 150 lines ($RL)"; else bad "router still under 150 lines" "$RL"; fi
RB="$(wc -c < "$V8/Vision/Agent Router.md" | tr -d ' ')"
if [ "$RB" -lt 8000 ]; then ok "router still under the 8000-byte cap ($RB)"; else bad "router under 8000 bytes" "$RB"; fi

# .canon-owners is first-match-wins, so a design rule BELOW `Reference/** *` is
# dead. Assert the ordering, not merely the presence.
OWN="$V8/.canon-owners"
DL="$(LC_ALL=C grep -n 'Reference/Design/' "$OWN" | head -1 | cut -d: -f1)"
OL="$(LC_ALL=C grep -n '^Reference/\*\*' "$OWN" | head -1 | cut -d: -f1)"
if [ -n "$DL" ] && [ -n "$OL" ] && [ "$DL" -lt "$OL" ]; then
  ok "design owner rule sits above the open Reference rule"
else
  bad "design owner rule sits above the open Reference rule" "design@$DL open@$OL"
fi

# ---------------------------------------------------------------------------
section "design audit"
# A detector is only worth having if you trust it, and trust dies on false
# positives — the kit's own cautionary example is a token-parity script that
# reports 9 false results out of 26 and is therefore read by nobody. So most of
# these assertions are about what the tool must NOT report.
DA="$KIT/bin/canon-design-audit"
is "vendors canon-design-audit" "$([ -x "$V8/.canon/canon-design-audit" ] && echo y)" "y"

RP="$SB/coderepo"; mkdir -p "$RP/src/components/ui" "$RP/src/styles"
git -C "$RP" init -q 2>/dev/null
# The declared token file. It is SUPPOSED to contain literals.
printf ':root {\n  --primary: 222 47%% 11%%;\n  --background: 0 0%% 100%%;\n}\n' \
  > "$RP/src/styles/globals.css"
# A violator, plus two things that must not be flagged.
printf 'export const B = () => <button className="bg-blue-500 bg-primary" style={{color:"#ff0044"}} />\n' \
  > "$RP/src/components/ui/button.tsx"
printf '// commented out: #abcdef\nconst url = "https://x.example/#nope";\n' \
  > "$RP/src/components/ui/safe.tsx"

mkdir -p "$V8/Reference/Design"
cat > "$V8/Reference/Design/canon.md" <<'CANON'
```design-tokens
- vocabulary: demo
  source: coderepo/src/styles/globals.css
  format: hsl-triplet
  scope: ":root"
  names: [--primary, --background]
  status: canonical
```

```design-components
- slug: button
  name: Button
  vocabulary: demo
  impl: coderepo/src/components/ui/button.tsx
  tokens: [--primary]
  status: shipped
- slug: ghost
  name: Ghost
  vocabulary: demo
  impl: coderepo/src/components/ui/nope.tsx
  image: Attachments/Design/ghost--primary--default@light.png
  figma: { file: https://figma.com/design/abc?node-id=1-2&t=SESSIONTOKEN, node: 1-2 }
  status: shipped
- slug: page-header
  name: Page Header
  status: absent
```
CANON

AJ="$("$DA" --vault "$V8" --json "$RP" 2>/dev/null)"
pick() { printf '%s' "$AJ" | python3 -c "
import json,sys
d=json.load(sys.stdin); f=d['findings']
import os
q=os.environ['Q']
if q=='count': print(d['counts'].get(os.environ['R'],0))
elif q=='locs': print(' '.join(x['location'] for x in f if x['rule']==os.environ['R']))
elif q=='details': print(' | '.join(x['detail'] for x in f if x['rule']==os.environ['R']))
elif q=='cov': print(d['coverage'][os.environ['R']])
" 2>/dev/null; }

is "flags a Tailwind palette utility" "$(Q=count R=DS-PALETTE-UTILITY pick)" "1"
has "and names the utility" "$(Q=details R=DS-PALETTE-UTILITY pick)" "bg-blue-500"
has "citing repo/path:line" "$(Q=locs R=DS-PALETTE-UTILITY pick)" "coderepo/src/components/ui/button.tsx:1"
isnt "does NOT flag bg-primary" "$(Q=details R=DS-PALETTE-UTILITY pick)" "bg-primary"
is "flags a hex literal" "$(Q=count R=DS-COLOR-LITERAL pick)" "1"
isnt "does NOT flag the declared token file" "$(Q=locs R=DS-COLOR-LITERAL pick)" "coderepo/src/styles/globals.css:2"
isnt "does NOT flag a commented-out hex" "$(Q=details R=DS-COLOR-LITERAL pick)" "#abcdef"
is "reports a dead impl pointer" "$(Q=count R=DS-POINTER-DEAD pick)" "1"
is "reports a missing image" "$(Q=count R=DS-ASSET-MISSING pick)" "1"
is "rejects a pasted Figma URL with a session token" "$(Q=count R=DS-FIGMA-MALFORMED pick)" "1"
is "counts deliberately-absent components" "$(Q=cov R=absent pick)" "1"
is "derives impl coverage" "$(Q=cov R=impl pick)" "2"

# Placeholders defeat the design: absence is the signal, so TODO must be refused.
printf '\n```design-components\n- slug: todo-thing\n  name: Todo\n  impl: TODO\n```\n' >> "$V8/Reference/Design/canon.md"
AJ="$("$DA" --vault "$V8" --json "$RP" 2>/dev/null)"
is "refuses TODO instead of an omitted key" "$(Q=count R=DS-BLOCK-MALFORMED pick)" "1"
AJ="$("$DA" --vault "$V8" --json "$RP" 2>/dev/null)"

# Baseline, not zero: on a repo with thousands of pre-existing violations the
# useful signal is "did it get worse", and a tool that fails on run 1 is ignored
# by run 2.
"$DA" --vault "$V8" --strict "$RP" >/dev/null 2>&1
is "--strict fails with no baseline" "$?" "1"
"$DA" --vault "$V8" --baseline-write "$RP" > "$RP/.canon-design-baseline" 2>/dev/null
"$DA" --vault "$V8" --strict "$RP" >/dev/null 2>&1
is "--strict passes at baseline" "$?" "0"
printf 'export const C = () => <div className="text-rose-600" />\n' > "$RP/src/components/ui/more.tsx"
"$DA" --vault "$V8" --strict "$RP" >/dev/null 2>&1
is "--strict fails on a regression above baseline" "$?" "1"

# The report is generated, dated, stamped as a process, and stores no verdict.
"$DA" --vault "$V8" --report --quiet "$RP" >/dev/null 2>&1
is "writes exactly one dated report" "$(find "$V8/Outputs" -name '*Design System Audit*' | wc -l | tr -d ' ')" "1"
REP="$(find "$V8/Outputs" -name '*Design System Audit*' | head -1)"
has "stamps the report as a process"   "$(cat "$REP")" "process:canon-design-audit"
has "sets stale_after so rot surfaces" "$(cat "$REP")" "stale_after:"
is  "stores no score" \
  "$(LC_ALL=C grep -cE '^(compliance_score|design_coverage|a11y_grade|score):' "$REP" | tr -d ' ')" "0"

# Read-only in the scanned repo. This is a hard property, not a nice-to-have.
git -C "$RP" add -A >/dev/null 2>&1; git_q -C "$RP" commit -qm base >/dev/null 2>&1

# Build output is the biggest false-positive source there is — a framework build
# emits bundled CSS full of palette utilities, and counting it says nothing about
# what anyone wrote. Once the repo has an index, scan what git tracks: gitignored
# build output then disappears without needing a skip-list that keeps up with
# every framework's output directory naming.
mkdir -p "$RP/server"
printf 'const x = "bg-emerald-700 bg-emerald-800 bg-emerald-900";\n' > "$RP/server/entry.preview.js"
AJ="$("$DA" --vault "$V8" --json "$RP" 2>/dev/null)"
isnt "skips untracked build output in a git repo" \
  "$(Q=locs R=DS-PALETTE-UTILITY pick)" "coderepo/server/entry.preview.js:1"
isnt "and does not count it" "$(Q=details R=DS-PALETTE-UTILITY pick)" "bg-emerald-700"
# Compared before/after rather than asserted empty: the assertion is "the tool
# changed nothing", not "the repo happens to be clean". An earlier version of this
# check silently measured a fixture file created two lines above it.
BEFORE="$(git -C "$RP" status --porcelain)"
"$DA" --vault "$V8" --report "$RP" >/dev/null 2>&1
is "never writes in the scanned repo" "$(git -C "$RP" status --porcelain)" "$BEFORE"

# An unscanned repo is unknown, not broken — the tool's easiest false positive.
AJ="$("$DA" --vault "$V8" --json "$SB/nonexistent-elsewhere" 2>/dev/null)"
is "unscanned repo pointers are not called dead" "$(Q=count R=DS-POINTER-DEAD pick)" "1"

"$DA" >/dev/null 2>&1; is "refuses to run with no repo" "$?" "2"

# ---------------------------------------------------------------------------
section "concurrent writers"
# Two people and one shared branch, which is the whole point of a team vault.

SY="$KIT/bin/canon-sync"
# Pin the bare repo's HEAD instead of inheriting init.defaultBranch. Without this
# the fixture passes on a machine that defaults to `main` and fails on one that
# defaults to `master`: the clone below finds no matching branch, checks nothing
# out, and the teammate can never push — so the race these tests assert on never
# happens. symbolic-ref rather than `init -b`, which needs git >= 2.28.
RMT="$SB/team.git"; git init -q --bare "$RMT"; git -C "$RMT" symbolic-ref HEAD refs/heads/main
V6="$SB/vault6"                       # "us"
"$KIT/bin/canon-init-vault" "$V6" >/dev/null 2>&1
cd "$V6" || exit 1
git init -q; git config user.email us@t; git config user.name Us
git remote add origin "$RMT"
git add -A >/dev/null; git commit -qm init >/dev/null; git branch -M main
git push -q -u origin main

MATE="$SB/mate"                       # the teammate
git clone -q "$RMT" "$MATE"
git -C "$MATE" config user.email mate@t; git -C "$MATE" config user.name Mate
mate_pushes() {  # land a commit on the shared branch, the way a teammate would
  printf '%s\n' "$2" > "$MATE/$1"
  git -C "$MATE" add -A >/dev/null; git -C "$MATE" commit -qm "mate: $1" >/dev/null
  git -C "$MATE" push -q
}

# THE case this section exists for: our push is refused because someone landed
# work between our pull and our push. It must still end up shared.
mate_pushes "Sessions/mate-1.md" "theirs"
echo ours > "$V6/Sessions/ours-1.md"
OUT6="$(CANON_HOME="$V6" "$SY" --push --no-pull -m "ours 1" 2>&1)"
has "retries after losing a push race" "$OUT6" "a teammate pushed first"
has "and lands the work"               "$OUT6" "pushed"
is  "nothing left unshared"            "$(git -C "$V6" rev-list --count origin/main..HEAD)" "0"
is  "the teammate's work survived"     "$(git -C "$V6" cat-file -e origin/main:Sessions/mate-1.md 2>/dev/null && echo y)" "y"
is  "ours is on the shared branch"     "$(git -C "$MATE" fetch -q origin && git -C "$MATE" cat-file -e origin/main:Sessions/ours-1.md 2>/dev/null && echo y)" "y"

# A real conflict — same file, same line — must stop, keep the commit, and leave
# no half-finished rebase behind for the next command to trip over.
printf 'shared\n' > "$V6/Projects/hot.md"
git -C "$V6" add -A >/dev/null; git -C "$V6" commit -qm base >/dev/null; git -C "$V6" push -q
git -C "$MATE" pull -q --rebase
mate_pushes "Projects/hot.md" "their version"
printf 'our version\n' > "$V6/Projects/hot.md"
OUT7="$(CANON_HOME="$V6" "$SY" --push --no-pull -m "ours 2" 2>&1)"
has "explains a genuine conflict" "$OUT7" "two people edited the same lines"
is  "leaves no rebase in progress" "$([ -d "$V6/.git/rebase-merge" ] || [ -d "$V6/.git/rebase-apply" ] && echo stuck || echo clean)" "clean"
is  "keeps our commit"             "$(git -C "$V6" log -1 --format=%s)" "ours 2"
git -C "$V6" rebase --abort >/dev/null 2>&1
git -C "$V6" reset -q --hard origin/main; git -C "$V6" clean -qfd

# A failure that is NOT a race must fail fast and say what git said, not spin.
git -C "$V6" remote set-url origin "$SB/nope.git"
OUT8="$(CANON_HOME="$V6" "$SY" --push --no-pull -m x 2>&1; true)"
case "$OUT8" in *"a teammate pushed first"*) bad "does not retry a non-race failure" ;; *) ok "does not retry a non-race failure" ;; esac
git -C "$V6" remote set-url origin "$RMT"

# ---------------------------------------------------------------------------
section "branch mode"
# Baseline the owner's world: a governed glob and a vision doc already on trunk.
printf 'Vision/**  boss@t\n' > "$V6/.canon-owners"
mkdir -p "$V6/Vision"; echo y > "$V6/Vision/Product Vision.md"
git -C "$V6" add -A >/dev/null; git -C "$V6" commit -qm owners >/dev/null; git -C "$V6" push -q

G6="$KIT/bin/canon-guard"
echo x > "$V6/Sessions/plain.md"; git -C "$V6" add -A >/dev/null
CANON_GUARD=warn "$G6" --check "$V6" >/dev/null 2>&1
is "--check passes an open path" "$?" "0"
OUTC="$(CANON_GUARD=warn "$G6" --check "$V6" 2>&1)"
is "--check is silent"           "${OUTC:-silent}" "silent"
echo edited > "$V6/Vision/Product Vision.md"; git -C "$V6" add -A >/dev/null
CANON_GUARD=warn "$G6" --check "$V6" >/dev/null 2>&1
is "--check flags a governed path" "$?" "1"
# Vault filenames have spaces by convention, so a whitespace-split path list
# reports fragments and can match a glob against the wrong string.
has "reports the whole filename, spaces and all" \
    "$(CANON_GUARD=warn "$G6" "$V6" 2>&1)" "Vision/Product Vision.md"
git -C "$V6" reset -q; git -C "$V6" checkout -q -- "Vision/Product Vision.md"

# auto: an ordinary note goes straight to the shared branch.
CANON_HOME="$V6" CANON_BRANCH_MODE=auto "$SY" --push -m "a note" >/dev/null 2>&1
is "auto pushes a plain note to trunk" "$(git -C "$V6" rev-parse --abbrev-ref HEAD)" "main"

# auto: a governed change routes to a review branch instead, and trunk stays clean.
echo changed > "$V6/Vision/Product Vision.md"
OUT9="$(CANON_HOME="$V6" CANON_BRANCH_MODE=auto "$SY" --push -m "vision edit" 2>&1)"
BR6="$(git -C "$V6" rev-parse --abbrev-ref HEAD)"
case "$BR6" in canon/*) ok "auto routes a governed change to a branch" ;; *) bad "auto routes a governed change to a branch" "on $BR6" ;; esac
has "names the base branch"   "$OUT9" "from main"
has "points at the pull request" "$OUT9" "review"
is  "trunk did not get the governed edit" \
    "$(git -C "$V6" show origin/main:Vision/Product\ Vision.md 2>/dev/null)" "y"
is  "the branch reached the remote" "$(git -C "$V6" rev-list --count "origin/$BR6..HEAD" 2>/dev/null || echo ?)" "0"

# The notes must still be on disk — a vault whose files vanish into a branch is
# a vault someone will stop trusting.
is "the edit is still on disk" "$(cat "$V6/Vision/Product Vision.md")" "changed"

# canon-status must not call a parked review branch "in step".
: > "$V6/.git/FETCH_HEAD"
has "status flags a parked review branch" "$("$KIT/bin/canon-status" "$V6" 2>&1)" "review branch"

# A second sync from the branch continues the same PR rather than stacking a new one.
echo more > "$V6/Vision/Product Vision.md"
OUT10="$(CANON_HOME="$V6" "$SY" --push -m "vision edit 2" 2>&1)"
has "continues the same review branch" "$OUT10" "continuing"
is  "and creates no second branch" "$(git -C "$V6" rev-parse --abbrev-ref HEAD)" "$BR6"
has "--trunk cannot strand commits on a branch" \
    "$(echo z > "$V6/Vision/Product Vision.md"; CANON_HOME="$V6" "$SY" --push --trunk -m z 2>&1)" \
    "--trunk ignored"

git -C "$V6" checkout -q main
is "an unpushed branch does not break the pull" \
   "$(git -C "$V6" checkout -q -b canon/us/fresh; CANON_HOME="$V6" "$SY" --status >/dev/null 2>&1; \
      echo hi > "$V6/Sessions/fresh.md"; CANON_HOME="$V6" "$SY" -m fresh 2>&1 | grep -c 'pull failed')" "0"
git -C "$V6" checkout -q main

is "rejects an unknown branch mode" \
   "$(CANON_HOME="$V6" CANON_BRANCH_MODE=nonsense "$SY" --status >/dev/null 2>&1; echo $?)" "2"

cd "$V" || exit 1

# ---------------------------------------------------------------------------
section "uninstall"
"$KIT/install.sh" "$R2" --uninstall >/dev/null 2>&1
is "removes our hooks"        "$([ -f "$R2/.claude/hooks/session-start.sh" ] && echo present || echo gone)" "gone"
is "removes cursor rules"     "$([ -f "$R2/.cursor/rules/knowledge-vault.mdc" ] && echo present || echo gone)" "gone"
if grep -q "canon:knowledge-vault" "$R2/AGENTS.md" 2>/dev/null; then
  bad "strips the AGENTS.md block"; else ok "strips the AGENTS.md block"; fi
has "leaves foreign hooks alone" "$(cat "$R2/.claude/settings.json")" "keep-me"
has "leaves CLAUDE.md body"      "$(cat "$R2/CLAUDE.md")" "npm test"
if grep -q "canon:knowledge-vault" "$R2/CLAUDE.md" 2>/dev/null; then
  bad "strips our CLAUDE.md block"; else ok "strips our CLAUDE.md block"; fi

# ---------------------------------------------------------------------------
printf '\n\033[1m%d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
