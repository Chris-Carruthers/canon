#!/usr/bin/env node
/**
 * canon-discord — ask questions of the team's knowledge canon from Discord.
 *
 * Use /canon <question>. The bot answers from the vault, cites the notes it read,
 * and opens a thread so follow-ups keep context.
 *
 * Read-only and fail-closed; both live in ../../shared/vault.mjs so Slack and
 * Discord cannot drift apart on the parts that matter.
 *
 * ⚠️  Same warning as every connector: this BYPASSES git permissions. Git decides
 *     who can clone the vault, Discord decides who is in the server. Discord
 *     servers are usually broader than a work chat, so be stricter here, not
 *     looser. It refuses to start until you allow specific channels, roles, or
 *     users.
 *
 * WHY SLASH COMMANDS AND NOT MENTIONS: reading arbitrary message text needs the
 * privileged MessageContent intent, which Discord gates and which means the bot
 * sees everything said in the server. A slash command hands us only what the user
 * deliberately typed at us. Less privilege for the same feature — so mentions are
 * opt-in via CANON_DISCORD_ALLOW_MENTIONS=1, and off by default.
 */

import path from "node:path";
import os from "node:os";
import {
  Client, GatewayIntentBits, Events, REST, Routes,
  SlashCommandBuilder, MessageFlags,
} from "discord.js";
import "dotenv/config";
import { resolveVault, makeGate, clip, list, die, makeStore } from "../../shared/vault.mjs";
import { askVault } from "../../shared/agent.mjs";

const MODEL = process.env.CANON_DISCORD_MODEL || "claude-sonnet-5";
const ROUTER = process.env.CANON_ROUTER || "Vision/Agent Router.md";
const MAX_TURNS = Number(process.env.CANON_DISCORD_MAX_TURNS || 24);
const STORE = process.env.CANON_DISCORD_STORE
  || path.join(os.tmpdir(), "canon-discord-threads.json");
const ALLOW_MENTIONS = process.env.CANON_DISCORD_ALLOW_MENTIONS === "1";
const DISCORD_LIMIT = 2000;   // hard cap on a Discord message

const TOKEN = process.env.DISCORD_BOT_TOKEN || die("DISCORD_BOT_TOKEN is not set — see connectors/discord/README.md");
const APP_ID = process.env.DISCORD_APP_ID || die("DISCORD_APP_ID is not set (Application ID from the developer portal)");
const GUILD_ID = process.env.DISCORD_GUILD_ID || "";

const VAULT = resolveVault();
const store = makeStore(STORE);

const allowed = makeGate({
  channels: list(process.env.CANON_DISCORD_ALLOW_CHANNELS),
  users: list(process.env.CANON_DISCORD_ALLOW_USERS),
  roles: list(process.env.CANON_DISCORD_ALLOW_ROLES),
  platform: "Discord",
});

const DENIED = "🔒 Not enabled here. Ask whoever runs the canon bot to allow this channel — the vault may contain things not everyone has access to.";

// ── register the slash command ──────────────────────────────────────────────
const command = new SlashCommandBuilder()
  .setName("canon")
  .setDescription("Ask a question of the team's knowledge canon")
  .addStringOption((o) =>
    o.setName("question").setDescription("What do you want to know?").setRequired(true))
  .toJSON();

async function registerCommands() {
  const rest = new REST({ version: "10" }).setToken(TOKEN);
  // Guild-scoped registration appears instantly; global takes up to an hour.
  const route = GUILD_ID
    ? Routes.applicationGuildCommands(APP_ID, GUILD_ID)
    : Routes.applicationCommands(APP_ID);
  await rest.put(route, { body: [command] });
  console.log(`  registered /canon ${GUILD_ID ? `in guild ${GUILD_ID}` : "globally (may take ~1h)"}`);
}

// ── answering ───────────────────────────────────────────────────────────────
function render(answer, sources) {
  const cited = sources.length ? `\n\n-# 📄 ${sources.map((s) => `\`${s}\``).join(" · ")}` : "";
  return clip(answer || "_No answer._", DISCORD_LIMIT - cited.length) + cited;
}

async function answerInteraction(interaction, question) {
  await interaction.deferReply();          // the agent will exceed Discord's 3s window

  const { answer, sources } = await askVault({
    vault: VAULT, question, model: MODEL, router: ROUTER, maxTurns: MAX_TURNS,
    onProgress: () => {},                  // deferReply already shows "thinking…"
  });

  const sent = await interaction.editReply(render(answer, sources));

  // Open a thread so follow-ups keep context without needing the slash command.
  try {
    const thread = await sent.startThread({
      name: clip(question.replace(/\s+/g, " "), 90),
      autoArchiveDuration: 1440,
    });
    store.set(thread.id, { user: interaction.user.id });
  } catch { /* threads may be disabled in this channel; not fatal */ }
}

async function answerInThread(message, question) {
  const prior = store.get(message.channel.id);
  const thinking = await message.channel.send("⏳ _reading the canon…_");

  const { answer, sources } = await askVault({
    vault: VAULT, question, model: MODEL, router: ROUTER, maxTurns: MAX_TURNS,
    resumeSessionId: prior?.sessionId || null,
    onSession: (sid) => store.set(message.channel.id, { sessionId: sid }),
  });

  await thinking.edit(render(answer, sources));
}

// ── wiring ──────────────────────────────────────────────────────────────────
const intents = [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages];
if (ALLOW_MENTIONS) intents.push(GatewayIntentBits.MessageContent);

const client = new Client({ intents });

client.once(Events.ClientReady, async (c) => {
  await registerCommands().catch((e) => console.error("  command registration failed:", e.message));
  console.log(
    `canon-discord up as ${c.user.tag}\n` +
    `  vault:  ${VAULT}\n` +
    `  model:  ${MODEL}\n` +
    `  tools:  Read, Grep, Glob (read-only)\n` +
    `  mentions: ${ALLOW_MENTIONS ? "on (privileged intent)" : "off — slash command only"}`
  );
});

client.on(Events.InteractionCreate, async (interaction) => {
  if (!interaction.isChatInputCommand() || interaction.commandName !== "canon") return;

  const userRoles = interaction.member?.roles?.cache
    ? [...interaction.member.roles.cache.keys()] : [];

  if (!allowed({ channel: interaction.channelId, user: interaction.user.id, userRoles })) {
    await interaction.reply({ content: DENIED, flags: MessageFlags.Ephemeral });
    return;
  }
  try {
    await answerInteraction(interaction, interaction.options.getString("question", true));
  } catch (err) {
    console.error("interaction failed:", err);
    const msg = `Something went wrong: \`${err?.message ?? String(err)}\``;
    if (interaction.deferred) await interaction.editReply(msg).catch(() => {});
    else await interaction.reply({ content: msg, flags: MessageFlags.Ephemeral }).catch(() => {});
  }
});

// Follow-ups inside a thread we opened, plus optional mentions.
client.on(Events.MessageCreate, async (message) => {
  if (message.author.bot) return;

  const inOurThread = message.channel.isThread?.() && store.has(message.channel.id);
  const mentionedUs = ALLOW_MENTIONS && message.mentions.users.has(client.user.id);
  if (!inOurThread && !mentionedUs) return;

  const userRoles = message.member?.roles?.cache ? [...message.member.roles.cache.keys()] : [];
  const gateChannel = message.channel.isThread?.()
    ? (message.channel.parentId || message.channel.id)
    : message.channel.id;
  if (!allowed({ channel: gateChannel, user: message.author.id, userRoles })) return;

  const question = message.content.replace(/<@!?\d+>/g, "").trim();
  if (!question) return;
  await answerInThread(message, question).catch((e) => console.error("thread reply failed:", e));
});

await client.login(TOKEN);
