/**
 * agent.mjs — asking a question of the vault with a model.
 *
 * This is the only part of the connector stack that needs the Agent SDK. Keeping
 * it separate means the MCP server and the path-safety tests do not.
 */

import path from "node:path";
import { query } from "@anthropic-ai/claude-agent-sdk";

export const READ_ONLY_TOOLS = ["Read", "Grep", "Glob"];

export function die(msg) {
  console.error(`canon: ${msg}`);
  process.exit(1);
}

export function list(v) {
  return (v || "").split(/[,\s]+/).map((s) => s.trim()).filter(Boolean);
}

/**
 * Find the vault. Uses the same resolution order as the rest of canon, by
 * shelling out to canon-path where possible, so there is one definition of
 * "where is the vault" across the whole kit rather than a JS reimplementation
 * that can disagree with the shell one.
 */
export function resolveVault() {
  if (process.env.CANON_HOME) {
    const p = process.env.CANON_HOME.replace(/^~(?=$|\/)/, os.homedir());
    if (!fs.existsSync(p)) die(`CANON_HOME is set to '${p}' but that does not exist`);
    return fs.realpathSync(p);
  }
  const here = import.meta.dirname;
  for (const candidate of [
    path.resolve(here, "../../bin/canon-path"),
    path.resolve(here, "../../.canon/canon-path"),
    "canon-path",
  ]) {
    try {
      const out = execFileSync(candidate, { encoding: "utf8" }).trim();
      if (out && fs.existsSync(out)) return fs.realpathSync(out);
    } catch { /* try the next */ }
  }
  const cfg = path.join(os.homedir(), ".config/canon/path");
  if (fs.existsSync(cfg)) {
    const line = fs.readFileSync(cfg, "utf8").split("\n")
      .find((l) => l.trim() && !l.startsWith("#"));
    if (line && fs.existsSync(line.trim())) return fs.realpathSync(line.trim());
  }
  die("cannot find the vault. Set CANON_HOME, or write the path into ~/.config/canon/path");
}

/**
 * Fail-closed access control.
 *
 * These connectors BYPASS git permissions: git decides who can clone the vault,
 * the chat platform decides who is in the channel. Where those sets differ, an
 * open bot hands notes to people who were never granted access. So an empty
 * allowlist is a hard error at startup, not a permissive default.
 */
export function makeGate({ channels = [], users = [], roles = [], platform = "chat" }) {
  if (!channels.length && !users.length && !roles.length) {
    die(
      `refusing to start with no allowlist.\n` +
      `  This bot can read the whole vault, and ${platform} membership is not the same\n` +
      `  as git access. Allow specific channels, users, or roles.\n` +
      `  Use '*' for channels only if everyone who can reach this bot may read every note.`
    );
  }
  const open = channels.includes("*");
  return function allowed({ channel, user, userRoles = [] } = {}) {
    if (open) return true;
    if (channel && channels.includes(channel)) return true;
    if (user && users.includes(user)) return true;
    if (roles.length && userRoles.some((r) => roles.includes(r))) return true;
    return false;
  };
}

export function systemPrompt(router) {
  return `You answer questions about this team's knowledge vault, which is on disk at
the current working directory. You are READ-ONLY: you can search and read notes,
and you cannot change anything.

How to answer:
- Start by reading ${router} to learn what lives where, then glob and grep for what
  the question needs. Do not try to read the whole vault; it is far too large.
- Answer from what the notes actually say. If the vault does not cover it, say so
  plainly rather than filling the gap from general knowledge — a confident answer
  the notes do not support is worse than "not recorded here".
- Note when something looks stale: if a note says work is pending and a later
  session note says it shipped, say which is newer.
- Be brief. This is a chat message, not a document. Lead with the answer.
- Never reveal credentials or personal data if you happen to encounter any; report
  that you found something that looks sensitive instead, and where.`;
}

function relativise(vault, p) {
  if (!p) return null;
  const abs = path.isAbsolute(p) ? p : path.join(vault, p);
  const rel = path.relative(vault, abs);
  return rel && !rel.startsWith("..") ? rel : null;
}

/**
 * Ask the vault a question.
 *
 * Platform-agnostic: you pass callbacks for progress and get back the answer plus
 * the notes consulted. Citing sources is not decoration — an answer you cannot
 * trace to a note cannot be verified, and cannot be corrected at the source.
 */
export async function askVault({
  vault, question, model, router, maxTurns = 24, resumeSessionId = null,
  onProgress = () => {}, onSession = () => {},
}) {
  const consulted = new Set();
  let answer = "";

  try {
    for await (const msg of query({
      prompt: question,
      options: {
        model,
        cwd: vault,                    // pinned: cannot reach other repositories
        appendSystemPrompt: systemPrompt(router),
        maxTurns,
        ...(resumeSessionId ? { resume: resumeSessionId } : {}),
        allowedTools: READ_ONLY_TOOLS,
        permissionMode: "bypassPermissions",
      },
    })) {
      if (msg.session_id) onSession(msg.session_id);

      if (msg.type === "assistant") {
        for (const block of msg.message?.content ?? []) {
          if (block.type !== "tool_use") continue;
          const rel = relativise(vault, block.input?.file_path || block.input?.path);
          if (rel) consulted.add(rel);
          onProgress({ tool: block.name, consulted: consulted.size });
        }
      }

      if (msg.type === "result") {
        answer = msg.subtype === "success"
          ? msg.result
          : `I stopped early (\`${msg.subtype}\`). Try a narrower question.`;
      }
    }
  } catch (err) {
    console.error("agent run failed:", err);
    return { answer: `Something went wrong: \`${err?.message ?? String(err)}\``, sources: [], failed: true };
  }

  return { answer, sources: [...consulted].slice(0, 8), failed: false };
}

