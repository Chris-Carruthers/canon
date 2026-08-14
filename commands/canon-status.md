---
description: Is the knowledge vault in step with the team?
---

# Vault status

```
${CLAUDE_PLUGIN_ROOT}/bin/canon-status
```

Falls back to `canon-status` on `PATH` if the plugin copy is not present.

It reports uncommitted notes, commits the team has not seen, how long since anyone
pulled, and whether you are parked on an unmerged review branch. **Silence means
you are in step** — it exits 0 and prints nothing, so no news is good news rather
than a broken command.

It makes no network call, by design: unpushed commits and uncommitted files are
local facts, and staleness comes from the timestamp of the last fetch. So a slow or
absent connection cannot hang it.

If it reports something, say which command fixes it. Do not run `canon-sync --push`
on the user's behalf unless they ask.
