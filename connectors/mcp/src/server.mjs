#!/usr/bin/env node
/**
 * canon-mcp — expose the team's knowledge vault to any MCP client.
 *
 * One connector instead of one per editor. Claude Desktop, Cursor, VS Code via
 * Copilot, and anything else that speaks MCP all get the same four tools.
 *
 * WHY THIS AND NOT AN EDITOR PLUGIN: a VS Code extension serves VS Code. An MCP
 * server serves every MCP host, present and future, and it is a fraction of the
 * code. The existing Obsidian MCP servers require Obsidian to be *running* plus a
 * plugin; this reads the filesystem, so it works headless, on a server, in CI.
 *
 * DESIGN:
 *
 * 1. It returns note CONTENT and LOCATIONS. It does not reason. The host's model
 *    does that — which is the whole point of MCP, and why this needs no model
 *    client and no API key.
 *
 * 2. Read-only. There is no write tool. Not "a write tool that refuses" — no
 *    write tool exists. Writing to the canon belongs where it is reviewable.
 *
 * 3. Every caller-supplied path goes through safeResolve(), which refuses
 *    traversal and symlinks pointing out of the vault. That is the entire
 *    security boundary and it is unit-tested in test/paths.test.mjs.
 *
 * 4. Large vendored subtrees are skipped by default. A vault with a 79 MB vendor
 *    documentation mirror will otherwise drown every search in irrelevance.
 */

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema, ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { resolveVault, safeResolve, list } from "../../shared/vault.mjs";

const VAULT = resolveVault();
const ROUTER = process.env.CANON_ROUTER || "Vision/Agent Router.md";
const MAX_BYTES = Number(process.env.CANON_MCP_MAX_BYTES || 120_000);
const EXCLUDE = list(process.env.CANON_MCP_EXCLUDE).concat([".git", ".canon", "node_modules"]);

const excluded = (rel) => EXCLUDE.some((e) => rel === e || rel.startsWith(`${e}/`) || rel.includes(`/${e}/`));

// ── vault reads ─────────────────────────────────────────────────────────────
function readNote(rel) {
  const abs = safeResolve(VAULT, rel);
  const st = fs.statSync(abs);
  if (st.isDirectory()) throw new Error(`${rel} is a directory — use canon_list`);
  const buf = fs.readFileSync(abs, "utf8");
  return buf.length > MAX_BYTES
    ? `${buf.slice(0, MAX_BYTES)}\n\n[truncated at ${MAX_BYTES} bytes — read a narrower section or grep instead]`
    : buf;
}

function walk(dir, out = [], depth = 0) {
  if (depth > 12) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, entry.name);
    const rel = path.relative(VAULT, abs);
    if (excluded(rel)) continue;
    if (entry.isDirectory()) walk(abs, out, depth + 1);
    else if (entry.name.endsWith(".md")) out.push(rel);
  }
  return out;
}

function listNotes(globish) {
  const all = walk(VAULT).sort();
  if (!globish) return all;
  // Deliberately simple: substring or * wildcard. Filenames are the index here,
  // and a full glob implementation would be more surface than the job needs.
  const rx = new RegExp(
    globish.split("*").map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join(".*"),
    "i",
  );
  return all.filter((f) => rx.test(f));
}

function search(qry, limit = 40) {
  // git grep where available: fast, respects .gitignore, no shell quoting games.
  try {
    const out = execFileSync(
      "git", ["-C", VAULT, "grep", "-n", "-I", "--no-color", "-i", "-e", qry, "--", "*.md"],
      { encoding: "utf8", maxBuffer: 8 * 1024 * 1024 },
    );
    return out.split("\n").filter(Boolean)
      .filter((l) => !excluded(l.split(":")[0]))
      .slice(0, limit);
  } catch (e) {
    if (e.status === 1) return [];                 // git grep: no matches
    // Not a git repo, or git missing: fall back to reading files ourselves.
    const hits = [];
    for (const rel of walk(VAULT)) {
      const lines = fs.readFileSync(path.join(VAULT, rel), "utf8").split("\n");
      lines.forEach((line, i) => {
        if (hits.length < limit && line.toLowerCase().includes(qry.toLowerCase())) {
          hits.push(`${rel}:${i + 1}:${line.trim().slice(0, 200)}`);
        }
      });
      if (hits.length >= limit) break;
    }
    return hits;
  }
}

// ── MCP surface ─────────────────────────────────────────────────────────────
const TOOLS = [
  {
    name: "canon_router",
    description:
      "Read the vault's router note first. It maps what lives where and how to search it. " +
      "Start here before any other canon tool — it is small and saves you guessing at folder names.",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "canon_search",
    description:
      "Case-insensitive full-text search across the vault's notes. Returns path:line:snippet. " +
      "Use this to locate notes, then canon_read the promising ones. Prefer several narrow " +
      "searches over one broad one.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "Text to search for" },
        limit: { type: "number", description: "Max results (default 40)" },
      },
      required: ["query"],
    },
  },
  {
    name: "canon_list",
    description:
      "List note paths, optionally filtered by a pattern such as 'Decisions/*' or '2026-07*'. " +
      "Filenames in this vault are named for their concept, so listing is often faster than searching.",
    inputSchema: {
      type: "object",
      properties: { pattern: { type: "string", description: "Substring or * wildcard" } },
    },
  },
  {
    name: "canon_read",
    description:
      "Read one note by its vault-relative path, e.g. 'Decisions/2026-07-30 — thing.md'. " +
      "Follow [[wikilinks]] by reading the note whose filename matches.",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string", description: "Vault-relative path" } },
      required: ["path"],
    },
  },
];

const server = new Server(
  { name: "canon", version: "0.1.0" },
  { capabilities: { tools: {} } },
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args = {} } = req.params;
  const text = (t) => ({ content: [{ type: "text", text: t }] });

  try {
    switch (name) {
      case "canon_router":
        return text(readNote(ROUTER));

      case "canon_search": {
        const hits = search(String(args.query ?? ""), Number(args.limit) || 40);
        return text(hits.length
          ? hits.join("\n")
          : `No matches for "${args.query}". Try canon_list to see what exists, or a broader term.`);
      }

      case "canon_list": {
        const found = listNotes(args.pattern ? String(args.pattern) : null);
        return text(found.length ? found.join("\n") : "No notes matched.");
      }

      case "canon_read":
        return text(readNote(String(args.path ?? "")));

      default:
        return { content: [{ type: "text", text: `Unknown tool: ${name}` }], isError: true };
    }
  } catch (err) {
    // Surface the reason — a client that gets "path escapes the vault" can correct
    // itself, whereas a bare failure just gets retried.
    return { content: [{ type: "text", text: `${err.message}` }], isError: true };
  }
});

await server.connect(new StdioServerTransport());
// stdout is the protocol channel; anything human-readable must go to stderr.
console.error(`canon-mcp ready · vault ${VAULT} · tools: ${TOOLS.map((t) => t.name).join(", ")}`);
