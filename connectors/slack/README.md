# canon-slack

**Ask questions of your team's knowledge canon from Slack.** Read-only.

```
@canon  what did we decide about the auth migration, and why?

  We moved token validation into the gateway in June rather than per-service.
  The reason recorded was operational: three services were each re-implementing
  refresh and drifting. The trade-off accepted was a single point of failure,
  mitigated by the gateway's existing HA setup.
  📄 Decisions/2026-06-11 — token validation at the gateway.md · Projects/Auth.md
```

It answers from the notes and **cites which ones it used**, so anyone can go read
the source — and correct the note if it's wrong.

## Why this is separate from the rest of the kit

canon's core is `bash`, `git` and `python3` with no installs. This connector needs
Node and two npm packages, so it lives here as an **optional component**. Not
installing it costs you nothing else.

## The thing to understand before you deploy it

> [!WARNING]
> **This bypasses your git permissions.** Git decides who can clone the vault.
> Slack decides who is in the channel. If those two sets differ, this bot is a
> hole: anyone who can message it can read anything in the vault, including notes
> they were never granted access to.

So it **refuses to start without an allowlist.** Fail-closed is the only sane
default for a knowledge base. Set `CANON_SLACK_ALLOW_CHANNELS` (channel IDs) or
`CANON_SLACK_ALLOW_USERS`, and use `*` only if every workspace member may read
every note.

Think of the allowlist as answering: *"who already has read access to this vault?"*
If the answer is "a subset of the workspace", the bot belongs in a private channel
containing exactly those people.

## Read-only, by construction

The agent gets `Read`, `Grep` and `Glob`. That's the whole list — no `Write`, no
`Edit`, no `Bash`, no web access — and `cwd` is pinned to the vault so it can't
reach your other repositories.

This is deliberate and worth keeping. A Slack bot that can edit the canon is a
Slack bot that can quietly rewrite a decision, with no diff and no reviewer.
Writing stays where it's reviewable: a session, a commit, a pull request. If you
find yourself wanting to add `Bash` for convenience, that's the moment to stop.

## Setup

**1. Create the Slack app** at [api.slack.com/apps](https://api.slack.com/apps) → *From scratch*.

- **Socket Mode** → enable. Generate an **App-Level Token** with `connections:write`
  (this is `SLACK_APP_TOKEN`, starts `xapp-`). Socket Mode means no public URL and
  no inbound firewall rule — the process dials out.
- **OAuth & Permissions** → Bot Token Scopes: `app_mentions:read`, `chat:write`,
  `channels:history`, `groups:history`, `im:history`, `im:read`, `im:write`,
  and `commands` if you want the slash command.
- **Event Subscriptions** → enable, and subscribe to bot events: `app_mention`,
  `message.channels`, `message.groups`, `message.im`.
- **Slash Commands** → optional: create `/canon`, leave the Request URL blank
  (Socket Mode does not use it).
- **Install to Workspace**, then copy the **Bot User OAuth Token** (`xoxb-`).

> If a slash command reports *"/canon is not a valid command"*, you almost
> certainly created it but didn't **reinstall the app** afterwards.

**2. Configure and run.**

```bash
cd connectors/slack
npm install
cp .env.example .env    # fill in tokens + the allowlist
npm start
```

You should see `canon-slack up` with the vault path, the model, `Read, Grep, Glob`,
and your allowlist echoed back. If the allowlist line is empty it will refuse to
start — that's the fail-closed default doing its job.

**3. Invite it** to the allowed channel (`/invite @canon`) and ask something.

## Verify it before you trust it

Nobody has run this against live Slack tokens yet, so treat these as the
acceptance checks rather than a formality:

1. **It answers from the vault.** Ask about something recorded in a note and check
   the citations name the right files.
2. **It admits ignorance.** Ask about something genuinely not in the vault. It
   should say so, not improvise. If it improvises, the system prompt needs work.
3. **It is actually read-only.** Ask it to edit or delete a note. It should be
   unable to, not merely unwilling.
4. **The allowlist holds.** Message it from a channel that isn't allowed. Expect
   the refusal, not an answer.
5. **Threads carry context.** Ask a question, then just `why?` as a follow-up in
   the thread.

## Running it somewhere

It's a long-lived process that needs the vault on disk and outbound HTTPS.

- **A laptop** is fine for a pilot. It stops when the laptop sleeps.
- **A small always-on box** is the usual answer. On macOS use a `launchd` agent
  with `RunAtLoad` and `KeepAlive`; on Linux a `systemd` unit with `Restart=always`.
- **Keep the vault fresh** wherever it runs — a stale clone gives confidently
  outdated answers, which is worse than no bot. A periodic `git pull --ff-only` in
  the vault is enough.

## Configuration

| Variable | Default | Effect |
|---|---|---|
| `SLACK_BOT_TOKEN` | — | **Required.** `xoxb-…` |
| `SLACK_APP_TOKEN` | — | **Required.** `xapp-…`, needs `connections:write` |
| `CANON_SLACK_ALLOW_CHANNELS` | — | **Required** (or users). Channel IDs, or `*` |
| `CANON_SLACK_ALLOW_USERS` | — | Slack user IDs |
| `CANON_HOME` | via `canon-path` | Vault location |
| `CANON_SLACK_MODEL` | `claude-sonnet-5` | Model |
| `CANON_ROUTER` | `Vision/Agent Router.md` | Note it reads first |
| `CANON_SLACK_MAX_TURNS` | `24` | Cap on agent turns per question |
| `CANON_SLACK_STORE` | tmpdir | Thread → session map |
| `CANON_SLACK_DEBUG` | — | Verbose Bolt logging |

## Known limits

- **Untested against live Slack.** The design is lifted from a working bot built on
  the same libraries, but this exact code has not talked to Slack. Work the
  verification list above before you announce it.
- **It reads a clone, not the remote.** Answers are only as current as the last
  pull on the host.
- **No write path, by design.** It cannot capture a Slack decision *into* the
  vault. That's a separate connector, and it needs a review step rather than
  writing straight to the canon.
- **Slack's 3-second ack** is handled by posting a placeholder and editing it, so
  long answers are fine — but a very long answer gets truncated to fit a message.
