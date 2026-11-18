/**
 * agent.mjs — asking a question of the vault with a model.
 *
 * This is the only part of the connector stack that needs the Agent SDK. Keeping
 * it separate means the MCP server and the path-safety tests do not.
 */

import path from "node:path";
import { query } from "@anthropic-ai/claude-agent-sdk";
import { confineTools } from "./vault.mjs";

export const READ_ONLY_TOOLS = ["Read", "Grep", "Glob"];

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
        cwd: vault,
        appendSystemPrompt: systemPrompt(router),
        maxTurns,
        ...(resumeSessionId ? { resume: resumeSessionId } : {}),
        allowedTools: READ_ONLY_TOOLS,
        permissionMode: "bypassPermissions",
        // The boundary: allowedTools above only pre-approves, it does not restrict.
        hooks: { PreToolUse: [{ hooks: [confineTools(vault, READ_ONLY_TOOLS)] }] },
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

