# canon-discord

**Ask questions of your team's knowledge canon from Discord.** Read-only.

```
/canon what did we decide about the auth migration, and why?

  We moved token validation into the gateway in June rather than per-service.
  The reason recorded was operational: three services were each re-implementing
  refresh and drifting. The trade-off accepted was a single point of failure,
  mitigated by the gateway's existing HA setup.
  📄 Decisions/2026-06-11 — token validation at the gateway.md · Projects/Auth.md
```

It cites the notes it used, and opens a thread so follow-ups keep context — ask
`why?` in the thread and it remembers.

## Read the warning first

> [!WARNING]
> **This bypasses your git permissions.** Git decides who can clone the vault.
> Discord decides who is in the server. Where those differ, the bot hands notes to
> people who were never granted access.
>
> **Discord servers are usually broader than a work chat** — community members,
> contractors, bots, that person from the conference. Be *stricter* here than you
> would be on Slack, not looser.

It **refuses to start without an allowlist**. Allow specific channels, roles, or
users; `*` exists but means "everyone who can reach this bot may read every note."

Role-based allowlisting is usually the right fit for Discord:
`CANON_DISCORD_ALLOW_ROLES=<role id>` scales better than listing people.

## Read-only, by construction

The agent gets `Read`, `Grep` and `Glob` — no `Write`, no `Edit`, no `Bash`, no web
access — with `cwd` pinned to the vault.

This lives in `../shared/core.mjs` alongside the Slack connector, deliberately: two
copies of a safety model is two things that can drift, and drift here means a
read-only bot quietly becoming something else. The test suite asserts the tool list
and asserts that **no connector declares its own**.

## Slash command, not mentions

By default the bot only responds to `/canon`. Answering `@mentions` needs Discord's
**privileged MessageContent intent**, which means the bot can read every message in
the server — a lot of access for a small convenience. A slash command hands it only
what someone deliberately typed at it.

Mentions are available via `CANON_DISCORD_ALLOW_MENTIONS=1` if you want them, and
off until you ask.

## Setup

**1. Create the application** at
[discord.com/developers/applications](https://discord.com/developers/applications)
→ *New Application*.

- **Bot** → *Reset Token* and copy it (`DISCORD_BOT_TOKEN`).
- **General Information** → copy the **Application ID** (`DISCORD_APP_ID`).
- Leave *Privileged Gateway Intents* **off** unless you want mentions.
- **OAuth2 → URL Generator** → scopes `bot` and `applications.commands`; bot
  permissions *Send Messages*, *Send Messages in Threads*, *Create Public Threads*,
  *Read Message History*. Open the generated URL to invite it.

**2. Get the IDs you need.** Discord → *Settings → Advanced → Developer Mode* on,
then right-click → *Copy ID* for the server, channel, and any role.

**3. Configure and run.**

```bash
cd connectors/discord
npm install
cp .env.example .env      # tokens, app id, and the allowlist
npm start
```

Expect `canon-discord up as <bot>#0000` with the vault path, the model,
`Read, Grep, Glob`, and whether mentions are on. Set `DISCORD_GUILD_ID` so `/canon`
registers instantly in that server — global registration can take an hour.

## Verify it before you trust it

This has **not been run against live Discord credentials**. Treat these as
acceptance checks:

1. **It answers from the vault**, and the citations name the right files.
2. **It admits ignorance.** Ask something genuinely not in the notes — it should
   say so, not improvise. If it improvises, the system prompt needs work.
3. **It is actually read-only.** Ask it to edit or delete a note. It should be
   unable, not merely unwilling.
4. **The allowlist holds.** Run `/canon` from a channel that isn't allowed; expect
   an ephemeral refusal.
5. **Threads carry context.** Ask a question, then just `why?` in the thread it
   opens.
6. **Long answers survive.** Ask something broad and confirm it truncates cleanly
   rather than erroring — Discord caps a message at 2,000 characters.

## Configuration

| Variable | Default | Effect |
|---|---|---|
| `DISCORD_BOT_TOKEN` | — | **Required.** Bot token |
| `DISCORD_APP_ID` | — | **Required.** Application ID |
| `DISCORD_GUILD_ID` | — | Register `/canon` in one server (instant) instead of globally |
| `CANON_DISCORD_ALLOW_CHANNELS` | — | **Required** (or roles/users). Channel IDs, or `*` |
| `CANON_DISCORD_ALLOW_ROLES` | — | Role IDs — usually the right choice here |
| `CANON_DISCORD_ALLOW_USERS` | — | User IDs |
| `CANON_DISCORD_ALLOW_MENTIONS` | off | `1` = also answer @mentions (needs the privileged intent) |
| `CANON_HOME` | via `canon-path` | Vault location |
| `CANON_DISCORD_MODEL` | `claude-sonnet-5` | Model |
| `CANON_ROUTER` | `Vision/Agent Router.md` | Note it reads first |
| `CANON_DISCORD_MAX_TURNS` | `24` | Cap on agent turns per question |
| `CANON_DISCORD_STORE` | tmpdir | Thread → session map |

## Known limits

- **Untested against live Discord.** Work the verification list above first.
- **It reads a clone**, so answers are only as fresh as the last pull on the host.
  A stale bot answering confidently is worse than no bot; keep the vault pulled.
- **No write path, by design.** It cannot capture a Discord decision *into* the
  vault. That is a separate connector and it needs a review step rather than
  writing straight to the canon.
- **2,000-character messages.** Long answers truncate visibly.
- **Threads inherit their parent channel's permission.** A thread under an allowed
  channel is allowed; the gate checks the parent, not the thread.
