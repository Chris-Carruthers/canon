#!/usr/bin/env bash
# build.sh — pack canon's MCP server into a double-clickable .mcpb bundle.
#
#   ./connectors/mcpb/build.sh [output.mcpb]
#
# Produces `canon.mcpb`, which a person installs by double-clicking it in Claude
# Desktop. They pick their vault folder in a dialog; no config file, no terminal.
#
# WHY THIS EXISTS SEPARATELY FROM THE KIT. canon's core is bash + git + python3
# with no package installs, on purpose. This bundle needs node and npm, because a
# .mcpb has to carry its own node_modules — the whole point is that the person
# installing it does not have to run npm. So it is a build step you run, not a
# dependency the kit acquires.
#
# The bundle keeps the repo's directory layout rather than flattening it, because
# server.mjs imports ../../shared/vault.mjs. Flattening would mean editing that
# import, which would mean the bundled copy and the repo copy differ — and a
# second copy that has to be kept in step is how this kit has been bitten before.

set -euo pipefail

CANON_VERSION="0.2.0"
case "${1:-}" in --version|-V) printf 'canon %s\n' "$CANON_VERSION"; exit 0 ;; esac

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT="$(cd "$HERE/../.." && pwd)"
OUT="${1:-$KIT/canon.mcpb}"

command -v node >/dev/null 2>&1 || { echo "build.sh: needs node (>=20)" >&2; exit 2; }
command -v npm  >/dev/null 2>&1 || { echo "build.sh: needs npm" >&2; exit 2; }

# The manifest's version must match VERSION, or people install 0.2.0 and get
# something else. Checked here rather than trusted, because nothing else would
# notice until a user reported it.
WANT="$(cat "$KIT/VERSION")"
GOT="$(node -e "process.stdout.write(require('$HERE/manifest.json').version)")"
[ "$WANT" = "$GOT" ] || { echo "build.sh: manifest says $GOT, VERSION says $WANT" >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo "staging…"
mkdir -p "$STAGE/connectors"
cp "$HERE/manifest.json" "$STAGE/manifest.json"
cp -R "$KIT/connectors/mcp"    "$STAGE/connectors/mcp"
cp -R "$KIT/connectors/shared" "$STAGE/connectors/shared"
cp "$KIT/LICENSE" "$STAGE/LICENSE" 2>/dev/null || true

echo "installing production deps…"
( cd "$STAGE/connectors/mcp" && npm install --omit=dev --silent --no-audit --no-fund )

# Sanity-check before packing rather than after shipping: the entry point must
# parse, and the manifest must point at a file that is actually in the bundle.
node --check "$STAGE/connectors/mcp/src/server.mjs"
ENTRY="$(node -e "process.stdout.write(require('$STAGE/manifest.json').server.entry_point)")"
[ -f "$STAGE/$ENTRY" ] || { echo "build.sh: entry_point $ENTRY is not in the bundle" >&2; exit 1; }

echo "packing…"
rm -f "$OUT"
( cd "$STAGE" && zip -qr "$OUT" . -x '*.DS_Store' )

echo
echo "built: $OUT"
echo "  $(du -h "$OUT" | cut -f1)"
echo
echo "Install it by double-clicking it, or drag it onto Claude Desktop's"
echo "Settings > Extensions. You will be asked to pick your vault folder."
echo
echo "Note: local MCP servers do NOT run in Cowork CLOUD sessions. For those, add"
echo "the vault as a connected folder in Claude Desktop instead — see the README."
