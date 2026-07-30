#!/usr/bin/env node
/**
 * canon-slack — ask questions of the team's knowledge canon from Slack.
 *
 * Mention the bot, DM it, or use /canon. It answers from the vault and cites the
 * notes it used, so anybody can go read the source.
 *
 * Read-only and fail-closed; both live in ../../shared/vault.mjs so Slack and
 * Discord cannot drift apart on the parts that matter.
 *
 * ⚠️  This connector BYPASSES git permissions. Git decides who can clone the
 *     vault; Slack decides who is in the channel. Where those differ, an open bot
 *     hands notes to people who were never granted access — so it refuses to start
 *     until you allow specific channels or users.
 *
 * Socket Mode: the process dials out, so no public URL and no inbound firewall
 * rule. Runs fine on a laptop for a pilot.
 */

import path from "node:path";
import os from "node:os";
import { App, LogLevel } from "@slack/bolt";
import "dotenv/config";
import { resolveVault, makeGate, clip, list, die, makeStore } from "../../shared/vault.mjs";
import { askVault } from "../../shared/agent.mjs";

const MODEL = process.env.CANON_SLACK_MODEL || "claude-sonnet-5";
const ROUTER = process.env.CANON_ROUTER || "Vision/Agent Router.md";
const MAX_TURNS = Number(process.env.CANON_SLACK_MAX_TURNS || 24);
const STORE = process.env.CANON_SLACK_STORE || path.join(os.tmpdir(), "canon-slack-threads.json");
const SLACK_LIMIT = 2900;

for (const k of ["SLACK_BOT_TOKEN", "SLACK_APP_TOKEN"]) {
  if (!process.env[k]) die(`${k} is not set — see connectors/slack/README.md`);
}

const VAULT = resolveVault();
const store = makeStore(STORE);

const allowed = makeGate({
  channels: list(process.env.CANON_SLACK_ALLOW_CHANNELS),
  users: list(process.env.CANON_SLACK_ALLOW_USERS),
  platform: "Slack",
});

const DENIED = ":lock: Not enabled here. Ask whoever runs the canon bot to allow this channel — the vault may contain things not everyone has access to.";

async function ask({ client, channel, threadTs, text, user }) {
  if (!text) return;
  const placeholder = await client.chat.postMessage({
    channel, thread_ts: threadTs, text: ":hourglass_flowing_sand: _reading the canon…_",
  });

  const prior = store.get(threadTs);
  const { answer, sources } = await askVault({
    vault: VAULT, question: text, model: MODEL, router: ROUTER, maxTurns: MAX_TURNS,
    resumeSessionId: prior?.sessionId || null,
    onSession: (sid) => store.set(threadTs, { sessionId: sid, user }),
    onProgress: ({ consulted }) => {
      client.chat.update({
        channel, ts: placeholder.ts,
        text: `:hourglass_flowing_sand: _reading the canon… (${consulted || "searching"})_`,
      }).catch(() => {});
    },
  });

  const body = clip(answer || "_No answer._", SLACK_LIMIT);
  const blocks = [{ type: "section", text: { type: "mrkdwn", text: body } }];
  if (sources.length) {
    blocks.push({
      type: "context",
      elements: [{ type: "mrkdwn", text: `:page_facing_up: ${sources.map((s) => `\`${s}\``).join(" · ")}` }],
    });
  }

  await client.chat.update({ channel, ts: placeholder.ts, text: body, blocks })
    .catch(() => client.chat.update({ channel, ts: placeholder.ts, text: body }).catch(() => {}));
}

const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  appToken: process.env.SLACK_APP_TOKEN,
  socketMode: true,
  logLevel: process.env.CANON_SLACK_DEBUG ? LogLevel.DEBUG : LogLevel.WARN,
});

app.event("app_mention", async ({ event, client, say }) => {
  if (!allowed({ channel: event.channel, user: event.user })) {
    await say({ thread_ts: event.thread_ts || event.ts, text: DENIED });
    return;
  }
  await ask({
    client, channel: event.channel, threadTs: event.thread_ts || event.ts,
    text: (event.text || "").replace(/<@[^>]+>\s*/g, "").trim(), user: event.user,
  });
});

// Follow-ups in a thread we already own, so a bare "why?" works.
app.message(async ({ message, client }) => {
  if (message.subtype || message.bot_id) return;
  const key = message.thread_ts;
  const isDM = message.channel_type === "im";
  if (!key && !isDM) return;
  if (key && !store.has(key)) return;
  if (!allowed({ channel: message.channel, user: message.user })) return;
  await ask({
    client, channel: message.channel, threadTs: key || message.ts,
    text: (message.text || "").trim(), user: message.user,
  });
});

app.command("/canon", async ({ command, ack, client, respond }) => {
  await ack();
  if (!allowed({ channel: command.channel_id, user: command.user_id })) {
    await respond({ response_type: "ephemeral", text: DENIED });
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
  `  vault: ${VAULT}\n` +
  `  model: ${MODEL}\n` +
  `  tools: Read, Grep, Glob (read-only)`
);
