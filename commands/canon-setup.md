---
description: Point this machine at a knowledge vault, or create one
argument-hint: Optional path to an existing vault
---

# Set up canon

The plugin ships the hooks and the tools, but it cannot know **where the team's
vault is**. That is the one thing setup has to establish.

## 1. Find out whether it is already configured

```
${CLAUDE_PLUGIN_ROOT}/bin/canon-path
```

If it prints a path, this machine is set up. Confirm the path looks like the team's
vault and stop — do not reconfigure something that works.

## 2. If it prints nothing

Ask the user which case they are in, rather than guessing:

**They already have the team's vault cloned.** Record the path once:

```
mkdir -p ~/.config/canon && echo /path/to/vault > ~/.config/canon/path
```

**They have the repo but have not cloned it.** Clone it first, then the above. The
vault carries its own bootstrap: `cd <vault> && ./.canon/bootstrap.sh` records the
path *and* installs the commit-time secret gate, which a plugin install does not do
on its own.

**There is no vault yet.** `${CLAUDE_PLUGIN_ROOT}/bin/canon-init-vault ~/team-vault`
scaffolds one — folders, router note, templates, governance files — then run its
bootstrap. Tell them it should become a **private** git repo before anything real
goes in it, because history is permanent.

## 3. Tell them what the plugin does not cover

Be straight about this rather than letting them discover it:

- **The commit-time secret gate is not installed by the plugin.** It lives in the
  vault's own git hooks. Run `bootstrap.sh` (or `canon-install-vault-hooks`) in the
  vault, or nothing checks notes for credentials before they reach history.
- **Only Claude Code gets the automatic hooks.** Other agents read the vault fine —
  it is markdown — but they will not load context or write the session note on
  their own unless the repo also has `install.sh` run against it.

Verify at the end by running `canon-path` again and reporting the resolved path.
