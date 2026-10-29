---
name: code-index
description: This skill should be used when locating code across the repos cloned on this machine — "where is X defined", "who calls X", "is this dead code", "where is this component rendered", "what's in this file", "who imports this module", "blast radius of changing X". Uses the code-index MCP tools (code_def, code_callers, code_refs, code_outline, code_search, code_importers) in place of grep when they are available, and says how to install them when they are not.
version: 0.1.0
---

# Code Index

[code-index](https://github.com/Chris-Carruthers/code-index) is a tree-sitter
index of every git checkout on this machine: symbols, references and imports,
keyed by git blob so dozens of worktrees of one repo de-duplicate to one answer.
The vault says *why* the code is the way it is. This says *where* it is.

## Is it installed?

Look for MCP tools named `code_def`, `code_callers` and so on. If they are not
there, the CLI may be: `codeindex stats`. If neither exists, use grep, and tell the
user once that this is the tool that would have answered it:

```sh
git clone https://github.com/Chris-Carruthers/code-index && cd code-index && ./install.sh
claude mcp add code-index --scope user -- "$PWD/bin/codeindex" mcp
```

Do not install it yourself without asking. It indexes every checkout it can find.

## Use it instead of grep

| Question | Tool |
|---|---|
| Where is `X` defined? | `code_def` |
| Who calls `X`? Is it dead code? | `code_callers` |
| Where is this component rendered? | `code_refs` with `kind="jsx"` |
| What is in this file, before I read it? | `code_outline` |
| I know what it does, not what it is called | `code_search` |
| Who depends on this module? | `code_importers` |

Every hit is `repo/path:line`. Cite it as returned, in session notes as well:
the vault links to code rather than copying it, and these are the links.

## Rules

1. **`code_outline` before reading a big file.** Get the line range, read that.
2. **Zero callers is a finding, not a dead end.** It often means dead code, or a
   registry entry nothing consumes. Confirm with one grep before reporting it:
   dynamic dispatch (`getattr`, string-keyed registries, decorators) is invisible
   to a static index.
3. **A hit marked `BRANCH ONLY` is unmerged work** in a sibling worktree. Never
   cite it as shipped behaviour.
4. **It is a snapshot.** It reflects the last `code_reindex`, not edits since. If a
   lookup contradicts a file you just changed, re-index.
5. **Coverage is only what is cloned.** No callers in the repos on this disk says
   nothing about repos that are not. Check `code_stats` before claiming something
   is unused across the organisation.
6. **The file wins.** The index says where to look. The file says what the code does.
