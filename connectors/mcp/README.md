# canon-mcp

**Expose your team's knowledge canon to any MCP client.** Read-only.

One connector instead of one per editor. Claude Desktop, Cursor, VS Code via
Copilot, and anything else that speaks MCP all get the same four tools.

## Why this instead of an editor extension

A VS Code extension serves VS Code. An MCP server serves every MCP host, present
and future, for a fraction of the code. If you were about to ask for a VS Code
plugin, a Cursor plugin and a Claude Desktop integration — this is all three.

It also **needs no model client and no API key.** It returns note content and
locations; the host's model does the reasoning. That's the point of MCP, and it's
why this has exactly one dependency.

Existing Obsidian MCP servers require **Obsidian to be running** plus a plugin.
This reads the filesystem, so it works headless, on a server, in CI, and on a
machine where nobody has installed an editor.

## Tools

| Tool | What it does |
|---|---|
| `canon_router` | Reads the router note — the map of what lives where. Start here. |
| `canon_search` | Case-insensitive full-text search, returns `path:line:snippet` |
| `canon_list` | List note paths, optionally filtered (`Decisions/*`, `2026-07*`) |
| `canon_read` | Read one note by vault-relative path |

There is **no write tool.** Not one that refuses — none exists. Writing to the
canon belongs where it's reviewable: a commit, a diff, a pull request.

## Security: one boundary, tested

An MCP client can pass any string it likes as a note path. A naive `path.join`
happily produces `../../.ssh/id_rsa`, and a symlinked note is the subtler version
of the same hole.

Every caller-supplied path goes through `safeResolve()` in
`../shared/vault.mjs`, which resolves symlinks before comparing and refuses
anything landing outside the vault. **`test/paths.test.mjs` covers ten cases** —
`../` traversal, absolute paths, mid-path traversal, a symlinked directory out, a
symlinked file out, empty path, the vault root itself, null bytes — and runs in CI
with plain `node`, no install. A security check that needs a network fetch to run
is a check that eventually stops being run.

`vault.mjs` is deliberately dependency-free, and the test suite asserts that,
because the moment it imports a model client this server needs an API key it has
no use for.

## Setup

```bash
cd connectors/mcp && npm install
```

Then register it with your client. **Claude Desktop** —
`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS:

```json
{
  "mcpServers": {
    "canon": {
      "command": "node",
      "args": ["/absolute/path/to/canon/connectors/mcp/src/server.mjs"],
      "env": { "CANON_HOME": "/absolute/path/to/your/vault" }
    }
  }
}
```

**Cursor** — same shape in `.cursor/mcp.json`. **Claude Code** —
`claude mcp add canon -- node /absolute/path/to/connectors/mcp/src/server.mjs`.

Absolute paths, and set `CANON_HOME` explicitly: a GUI client won't have your
shell environment, so `canon-path`'s usual fallbacks may not resolve.

## Verify it

1. **It appears.** Restart the client; the four `canon_*` tools should be listed.
2. **It orients.** Ask "what does the canon router say?" — you should get the
   router note.
3. **It searches, then reads.** Ask a question needing several notes; watch it
   search then read the promising ones.
4. **It admits ignorance.** Ask about something genuinely not in the vault. It
   should say so rather than improvise — the tools return nothing, but the *host's*
   model decides how to handle that, so this is worth checking per client.
5. **It cannot escape.** Ask it to read `../../etc/passwd`. Expect
   `path escapes the vault`.

`npm test` in the repo root runs the traversal suite; item 5 confirms the same
thing end to end through a real client.

## Configuration

| Variable | Default | Effect |
|---|---|---|
| `CANON_HOME` | via `canon-path` | Vault location. **Set this explicitly for GUI clients.** |
| `CANON_ROUTER` | `Vision/Agent Router.md` | Which note `canon_router` returns |
| `CANON_MCP_EXCLUDE` | — | Comma-separated paths to skip in search and list |
| `CANON_MCP_MAX_BYTES` | `120000` | Truncate a single note read above this |

`.git`, `.canon` and `node_modules` are always excluded. If your vault carries a
large vendored documentation tree, add it to `CANON_MCP_EXCLUDE` — otherwise it
will drown every search in irrelevant matches.

## Known limits

- **Not yet run against a live MCP client.** The traversal boundary and the tool
  surface are tested; registration with Claude Desktop / Cursor is not. Work the
  verification list.
- **It reads a clone**, so answers are only as fresh as the last pull on the host.
- **Search is substring, not semantic.** Filenames and structure are the index
  here; that's a deliberate trade, and it's why `canon_router` exists.
- **No permission model.** Anyone who can reach the MCP server can read the whole
  vault. Unlike the chat connectors, MCP is usually one person's local client — but
  if you run it anywhere shared, that assumption is worth re-checking.
