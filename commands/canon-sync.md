---
description: Commit the knowledge vault locally, and push only if the user asks
argument-hint: Optional commit message, or --push
---

# Share the vault

Run canon's sync against the team's knowledge vault.

```
${CLAUDE_PLUGIN_ROOT}/bin/canon-sync $ARGUMENTS
```

If `bin/canon-sync` is not there — canon may have been installed with `install.sh`
rather than as a plugin — fall back to `canon-sync` on `PATH`, and if that is also
missing, tell the user where to find it rather than guessing.

## What to know before running it

**Push is never implied.** Plain `canon-sync` pulls, scans, and commits locally.
Only `--push` sends anything to the remote. Do not add `--push` unless the user
asked for it, in words. Once a note is on a remote it may be cached or indexed even
if it is deleted later, so the irreversible step gets a human.

**It stages everything.** `canon-sync` runs `git add -A` internally. If the vault
has changes the user did not make in this session — a real risk when several agent
sessions share one machine — say so and offer to commit explicit paths by hand
instead. Check with `git -C <vault> status --short` first when the working tree
looks busy.

**Report what actually happened.** The scan output, the number of files, and the
commit message. If the scan refuses the commit, show the finding rather than
retrying or working around it.
