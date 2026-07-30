# Verify the wiring on your version

Agent-runtime hook and config surfaces change frequently. Config that silently
does nothing is the most common failure mode, and it is invisible — you only
notice months later when the vault is empty. So verify once, on a pinned
version, and re-verify after upgrades.

Record the result at the bottom of this file and commit it.

## 0. Pin the version

```bash
claude --version    # write it down; agree it across the team
```

## 1. The resolver

```bash
cd /path/to/wired/repo
.claude/hooks/canon-path            # expect: absolute path to the vault
echo $?                             # expect: 0

CANON_HOME=/nope .claude/hooks/canon-path ; echo "exit=$?"
                                    # expect: no output, exit=1 (no silent fallback)
```

## 2. SessionStart emits valid JSON

```bash
CLAUDE_PROJECT_DIR="$PWD" bash .claude/hooks/session-start.sh | python3 -m json.tool
```

Expect `hookSpecificOutput.hookEventName == "SessionStart"` and an
`additionalContext` containing your router note. **Check the length is under
10,000 characters** — that is a hard cap; overflow is spilled to a file rather
than injected.

## 3. SessionStart actually reaches the model

The real test, and the one people skip. Start a session in the wired repo and ask:

> What does the team knowledge vault say about how we work? Do not search — tell
> me only what is already in your context.

**Pass:** it answers from the router note.
**Fail:** it says it has no such context, or offers to go looking.

If it fails, check in this order:

1. **The workspace trust dialog** — hooks are skipped entirely until accepted.
   Look for a trust prompt on first launch in that directory.
2. **Settings scope** — `.claude/settings.json` is per project. A repo you didn't
   run `install.sh` on has no hook.
3. **Enterprise policy** — a managed-settings policy that only permits managed
   hooks will disable project hooks outright. Ask whoever administers it.
4. Run the command from step 2 by hand; a non-zero exit or stray stdout breaks
   the JSON contract.

## 4. The Stop hook

```bash
rm -f "${TMPDIR:-/tmp}"/canon-hooks/reminded-*

# clean tree -> silent
bash .claude/hooks/session-end-check.sh <<< '{"session_id":"t1"}'

# work happened, nothing written -> systemMessage
touch scratch.tmp
bash .claude/hooks/session-end-check.sh <<< '{"session_id":"t2"}'

# same session again -> silent (fires once per session; the loop guard)
bash .claude/hooks/session-end-check.sh <<< '{"session_id":"t2"}'
rm scratch.tmp
```

Then confirm it surfaces in a real session: make a trivial edit, end the
session, and see whether the reminder appears.

## 5. Block mode — verify before trusting

`CANON_ENFORCE_SESSION_NOTE=block` emits `{"decision":"block","reason":...}`.
This is the one shape in the kit **not** confirmed against a known-good working
example, which is why `remind` is the default.

To check it on your version: enable block mode in one repo, make an edit, end
the session, and observe whether Claude is actually pushed to write the note.

- **Works** → consider it for repos where the session log matters most.
- **Ignored** → stay on `remind`; the detector in step 6 is doing the real work.
- **Loops** → set `CANON_ENFORCE_SESSION_NOTE=off` immediately and rely on
  `remind`. Report it.

Do not enable block mode team-wide until one person has confirmed it on the pin.

## 6. The detector

Preventers leak; detectors tell you *how much*. Weekly, check the vault for:

- sessions where repos changed but no note was written
- notes missing `type:` / `status:` / `updated:` frontmatter
- notes over the size budgets (index >200 lines, detail >500)
- `[[wikilinks]]` pointing at notes that do not exist

Assign this to a person, not a process. An unowned knowledge base decays quietly.

---

## Verification record

| Date | Version | Resolver | SessionStart | Reaches model | Stop/remind | Stop/block | By |
|---|---|---|---|---|---|---|---|
| | | | | | | | |
