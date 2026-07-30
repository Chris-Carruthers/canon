#!/usr/bin/env node
/**
 * canon-slack — ask questions of the team's knowledge canon from Slack.
 *
 * Mention the bot, DM it, or use /canon. It answers from the vault and cites the
 * notes it used, so anybody can go read the source.
 *
 * DESIGN, and the parts that matter:
 *
 * 1. READ-ONLY, enforced by the tool list. The agent gets Read, Grep and Glob and
 *    nothing else — no Write, no Edit, no Bash, no web access. A Slack bot that
 *    can edit the canon is a Slack bot that can quietly rewrite your decisions.
 *    Writing stays where it is reviewable: a session, a commit, a diff.
 *
 * 2. cwd is pinned to the vault, so the agent cannot read your other repos even
 *    with read-only tools.
 *
 * 3. Socket Mode: the process dials out to Slack. No public URL, no inbound
 *    firewall rule, runs fine on a laptop or a small box.
 *
 * 4. Thread = conversation. Follow-ups resume the same agent session, so "why?"
 *    works as a second message.
 *
 * ⚠️  THE THING TO UNDERSTAND BEFORE YOU DEPLOY THIS:
 *
 *     This connector BYPASSES your git permissions. Git decides who can clone the
 *     vault; Slack decides who is in the channel. If those two sets differ, this
 *     bot is a hole — anyone who can message it can read anything in the vault,
 *     including notes they were never granted access to.
 *
 *     So it refuses to answer anybody until you explicitly allow them.
 *     Set CANON_SLACK_ALLOW_CHANNELS and/or CANON_SLACK_ALLOW_USERS.
 *     Fail-closed is the only sane default for a knowledge base.
 */

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execFileSync } from "node:child_process";
import { App, LogLevel } from "@slack/bolt";
import { query } from "@anthropic-ai/claude-agent-sdk";
import "dotenv/config";

// ── config ──────────────────────────────────────────────────────────────────
const MODEL = process.env.CANON_SLACK_MODEL || "claude-sonnet-5";
const ROUTER = process.env.CANON_ROUTER || "Vision/Agent Router.md";
const STORE = process.env.CANON_SLACK_STORE || path.join(os.tmpdir(), "canon-slack-threads.json");
const MAX_TURNS = Number(process.env.CANON_SLACK_MAX_TURNS || 24);

const ALLOW_CHANNELS = list(process.env.CANON_SLACK_ALLOW_CHANNELS);
const ALLOW_USERS = list(process.env.CANON_SLACK_ALLOW_USERS);

function list(v) {
  return (v || "").split(/[,\s]+/).map((s) => s.trim()).filter(Boolean);
}

function die(msg) {
  console.error(`canon-slack: ${msg}`);
  process.exit(1);
}

// ── locate the vault ────────────────────────────────────────────────────────
// Prefer the same resolver the rest of canon uses, so there is exactly one
// definition of "where is the vault" across the whole kit.
function resolveVault() {
  if (process.env.CANON_HOME) {
    const p = process.env.CANON_HOME.replace(/^~(?=$|\/)/, os.homedir());
    if (!fs.existsSync(p)) die(`CANON_HOME is set to '${p}' but that does not exist`);
    return fs.realpathSync(p);
  }
  for (const candidate of [
    path.resolve(import.meta.dirname, "../../../bin/canon-path"),
    "canon-path",
  ]) {
    try {
      const out = execFileSync(candidate, { encoding: "utf8" }).trim();
      if (out && fs.existsSync(out)) return fs.realpathSync(out);
    } catch { /* try the next one */ }
  }
  const cfg = path.join(os.homedir(), ".config/canon/path");
  if (fs.existsSync(cfg)) {
    const p = fs.readFileSync(cfg, "utf8").split("\n").find((l) => l.trim() && !l.startsWith("#"));
    if (p && fs.existsSync(p.trim())) return fs.realpathSync(p.trim());
  }
  die("cannot find the vault. Set CANON_HOME, or write the path into ~/.config/canon/path");
}

const VAULT = resolveVault();

for (const [k, v] of Object.entries({
  SLACK_BOT_TOKEN: process.env.SLACK_BOT_TOKEN,
  SLACK_APP_TOKEN: process.env.SLACK_APP_TOKEN,
})) if (!v) die(`${k} is not set — see connectors/slack/README.md`);

if (!ALLOW_CHANNELS.length && !ALLOW_USERS.length) {
  die(
    "refusing to start with no allowlist.\n" +
    "  This bot can read the whole vault, and Slack membership is not the same as\n" +
    "  git access. Set CANON_SLACK_ALLOW_CHANNELS and/or CANON_SLACK_ALLOW_USERS.\n" +
    "  Use CANON_SLACK_ALLOW_CHANNELS='*' only if every Slack member may read every note."
  );
}

// ── thread → session persistence ────────────────────────────────────────────
let threads = {};
try { threads = JSON.parse(fs.readFileSync(STORE, "utf8")); } catch { /* first run */ }
const saveThreads = () => {
  try { fs.writeFileSync(STORE, JSON.stringify(threads, null, 2)); } catch { /* non-fatal */ }
};

// ── access control ──────────────────────────────────────────────────────────
function allowed({ channel, user }) {
  if (ALLOW_CHANNELS.includes("*")) return true;
  if (channel && ALLOW_CHANNELS.includes(channel)) return true;
  if (user && ALLOW_USERS.includes(user)) return true;
  return false;
}

// ── the agent call ──────────────────────────────────────────────────────────
const SYSTEM = `You answer questions about this team's knowledge vault, which is on
disk at the current working directory. You are READ-ONLY: you can search and read
notes, and you cannot change anything.

How to answer:
- Start by reading ${ROUTER} to learn what lives where, then glob and grep for what
  the question needs. Do not try to read the whole vault; it is far too large.
- Answer from what the notes actually say. If the vault does not cover it, say so
  plainly rather than filling the gap from general knowledge — a confident answer
  the notes do not support is worse than "not recorded here".
- Note when something looks stale: if a note says work is pending and a later
  session note says it shipped, say which is newer.
- Be brief. This is a chat message, not a document. Lead with the answer.
- Never reveal credentials or personal data if you happen to encounter any; report
  that you found something that looks sensitive instead, and where.`;

function relativise(p) {
  if (!p) return null;
  const abs = path.isAbsolute(p) ? p : path.join(VAULT, p);
  const rel = path.relative(VAULT, abs);
  return rel && !rel.startsWith("..") ? rel : null;
}

async function ask({ client, channel, threadTs, text, user }) {
  const placeholder = await client.chat.postMessage({
    channel, thread_ts: threadTs, text: ":hourglass_flowing_sand: _reading the canon…_",
  });

  const prior = threads[threadTs];
  const consulted = new Set();
  let answer = "";

  try {
    for await (const msg of query({
      prompt: text,
      options: {
        model: MODEL,
        cwd: VAULT,                       // pinned: cannot wander into other repos
        appendSystemPrompt: SYSTEM,
        maxTurns: MAX_TURNS,
        ...(prior?.sessionId ? { resume: prior.sessionId } : {}),
        // The whole safety model in one line. Read-only by construction: no Write,
        // no Edit, no Bash, no WebFetch. Do not "just add Bash" for convenience.
        allowedTools: ["Read", "Grep", "Glob"],
        permissionMode: "bypassPermissions",
      },
    })) {
      const sid = msg.session_id;
      if (sid && threads[threadTs]?.sessionId !== sid) {
        threads[threadTs] = { ...(threads[threadTs] || {}), sessionId: sid, user };
        saveThreads();
      }

      if (msg.type === "assistant") {
        for (const block of msg.message?.content ?? []) {
          if (block.type !== "tool_use") continue;
          const rel = relativise(block.input?.file_path || block.input?.path);
          if (rel) consulted.add(rel);
          await client.chat.update({
            channel, ts: placeholder.ts,
            text: `:hourglass_flowing_sand: _reading the canon… (${consulted.size || "searching"})_`,
          }).catch(() => {});
        }
      }

      if (msg.type === "result") {
        answer = msg.subtype === "success"
          ? msg.result
          : `:warning: I stopped early (\`${msg.subtype}\`). Try a narrower question.`;
      }
    }
  } catch (err) {
    console.error("agent run failed:", err);
    answer = `:x: Something went wrong: \`${err?.message ?? String(err)}\``;
  }

  // Cite sources. An answer you cannot trace back to a note is not much use in a
  // knowledge base, and this is what lets someone correct the note itself.
  const sources = [...consulted].slice(0, 8);
  const blocks = [{ type: "section", text: { type: "mrkdwn", text: clip(answer || "_No answer._") } }];
  if (sources.length) {
    blocks.push({
      type: "context",
      elements: [{ type: "mrkdwn", text: `:page_facing_up: ${sources.map((s) => `\`${s}\``).join(" · ")}` }],
    });
  }

  await client.chat.update({
    channel, ts: placeholder.ts, text: clip(answer || "No answer.", 3000), blocks,
  }).catch(async () => {
    await client.chat.update({ channel, ts: placeholder.ts, text: clip(answer, 3000) });
  });
}

function clip(s, n = 2900) {
  if (!s) return "";
  return s.length > n ? `${s.slice(0, n)}\n\n_…truncated._` : s;
}

// ── wiring ──────────────────────────────────────────────────────────────────
const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  appToken: process.env.SLACK_APP_TOKEN,
  socketMode: true,
  logLevel: process.env.CANON_SLACK_DEBUG ? LogLevel.DEBUG : LogLevel.WARN,
});

const denied = ":lock: Not enabled here. Ask whoever runs the canon bot to allow this channel — the vault may contain things not everyone has access to.";

app.event("app_mention", async ({ event, client, say }) => {
  if (!allowed({ channel: event.channel, user: event.user })) {
    await say({ thread_ts: event.thread_ts || event.ts, text: denied });
    return;
  }
  const text = (event.text || "").replace(/<@[^>]+>\s*/g, "").trim();
  await ask({ client, channel: event.channel, threadTs: event.thread_ts || event.ts, text, user: event.user });
});

// Follow-ups in a thread we already own, so "why?" works without re-mentioning.
app.message(async ({ message, client }) => {
  if (message.subtype || message.bot_id) return;
  const key = message.thread_ts;
  const isDM = message.channel_type === "im";
  if (!key && !isDM) return;
  if (key && !threads[key]) return;
  if (!allowed({ channel: message.channel, user: message.user })) return;
  await ask({
    client, channel: message.channel,
    threadTs: key || message.ts, text: (message.text || "").trim(), user: message.user,
  });
});

app.command("/canon", async ({ command, ack, client, respond }) => {
  await ack();
  if (!allowed({ channel: command.channel_id, user: command.user_id })) {
    await respond({ response_type: "ephemeral", text: denied });
    return;
  }
  const posted = await client.chat.postMessage({
    channel: command.channel_id,
    text: `:mag: *${command.text}* — asked by <@${command.user_id}>`,
  });
  await ask({
    client, channel: command.channel_id, threadTs: posted.ts,
    text: command.text, user: command.user_id,
  });
});

await app.start();
console.log(
  `canon-slack up\n` +
  `  vault:    ${VAULT}\n` +
  `  model:    ${MODEL}\n` +
  `  tools:    Read, Grep, Glob (read-only)\n` +
  `  channels: ${ALLOW_CHANNELS.join(", ") || "(none)"}\n` +
  `  users:    ${ALLOW_USERS.join(", ") || "(none)"}`
);
