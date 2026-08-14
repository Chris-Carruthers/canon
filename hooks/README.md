# Why this points into `templates/`

`hooks.json` runs the hook scripts from
`${CLAUDE_PLUGIN_ROOT}/templates/repo/.claude/hooks/`, not from a copy in this
directory. That looks indirect, and it is deliberate.

Those same two scripts are what `install.sh` copies into a repo. Duplicating them
here would give canon two copies of its own hooks that drift — the exact failure
this kit keeps writing tests against, and the one it already lived through once when
a template and its validator disagreed about a schema.

One file, two delivery mechanisms:

| How canon was added | How the hook finds its tools |
|---|---|
| `install.sh <folder>` | the copies in `<folder>/.claude/hooks/` |
| `/plugin install canon@canon` | `${CLAUDE_PLUGIN_ROOT}/bin/` |
| either, with `bin/` on `PATH` | `PATH` |

The scripts try those three in that order, so the same file works in every case. If
you move the hook scripts, update `hooks.json` and the resolver chain in both
scripts together.
