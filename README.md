<p align="center">
  <img src="assets/hero.png" alt="canon — shared knowledge for AI teams" width="100%">
</p>

<p align="center">
  <a href="https://github.com/Chris-Carruthers/canon/actions/workflows/ci.yml"><img src="https://github.com/Chris-Carruthers/canon/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/license-MIT-A78BFA" alt="MIT">
  <img src="https://img.shields.io/badge/requires-bash%20%C2%B7%20git%20%C2%B7%20python3-6366F1" alt="requirements">
  <img src="https://img.shields.io/badge/tests-228%20passing-22C55E" alt="tests">
</p>

<h3 align="center">The opinionated starter kit for a shared knowledge canon.</h3>

<p align="center">
  Built on Obsidian, Git, and Markdown. Your team's AI agents read the same
  accumulated knowledge — and write what they learn back into it.<br>
  <em>Every session makes the team smarter.</em>
</p>

<p align="center">
  <strong>For everyone on a team building with AI</strong> — product, design, research,
  program and project management,<br>support, clinical, ops, strategy, leadership,
  engineering. Not an engineering tool.<br>
  <em>It pays off most when the team is cross-functional: a decision recorded by one
  discipline<br>becomes context for an assistant working in another.</em>
</p>

**Three ways in.** New to the idea? Start with the plain-English walkthrough below.
Here to install it? Jump to **[Quickstart](#quickstart)**. Don't use a terminal?
**[Getting Started — No Terminal](docs/GETTING-STARTED-NO-TERMINAL.md)** gets you
reading the vault with two apps and no commands.

<details>
<summary><strong>Contents</strong></summary>

- [New here? Read this first](#new-here-read-this-first) — the plain-English version
- **[Getting Started — No Terminal](docs/GETTING-STARTED-NO-TERMINAL.md)** — GitHub Desktop + Obsidian, no commands
- [How it works](#how-it-works) — the two diagrams
- [What you get](#what-you-get) · [Install as a Claude Code plugin](#install-it-as-a-claude-code-plugin) · [Quickstart](#quickstart) · [How it finds the vault](#how-it-finds-the-vault)
- [Claude Desktop and Cowork](#claude-desktop-and-cowork) — connected folder, or the `.mcpb` bundle
- [Works with agents that are not Claude](#works-with-agents-that-are-not-claude) — seven runtimes from one template
- [Reading it as a human](#reading-it-as-a-human-obsidian-optional) — Obsidian, optional
- [Design, and why](#design-and-why) — the limits that shaped it
- [Sync](#sync-automatic-inbound-deliberate-outbound) · [The gate](#the-gate) · [Trust](#trust-telling-an-agent-draft-from-a-checked-fact) · [Ownership](#ownership-not-everything-should-be-everyones)
- [Ask it from chat](#ask-it-from-chat) — Slack, Discord, MCP
- [Configuration](#configuration) · [Before you roll this out](#before-you-roll-this-out-to-a-team) · [Status](#status)

</details>

---

## New here? Read this first

*No terminal required to understand it. Skip to [Quickstart](#quickstart) if you just want to install it.*

### The one-sentence version

A folder of notes on your computer that both you and your AI assistant read and
write, shared with your team — so what everyone learns accumulates instead of
living in one person's head and one person's chat history.

### What it puts on your computer

**1. A notes folder.** Ordinary text files, organised by kind: what you decided
and why, what each project is and where it stands, background on customers or
domains, and a dated log of every work session.

**2. A standing instruction for your AI assistant.** A small config file telling
it: *before real work, read the notes; after real work, write down what happened.*
It applies everywhere you work, so you don't have to remember to ask.

**3. Nothing else.** In particular, **you do not need a code repository.** If you
have one the notes sit alongside it and stay out of it — code never goes in the
notes, they point at it by location instead (*"the bug was in `auth.ts`, line
42"*). If you don't have one, nothing here changes. See
[Two ways to set it up](#two-ways-to-set-it-up).

A useful way to picture it: the notes folder is the **team's shared notebook**.
Everyone keeps a copy on their own desk, and a master copy lives online that the
copies get matched against. Nobody edits a live document at the same time as
anybody else — you change your copy, then send it up.

### Two ways to set it up

The examples in this README wire canon into a code repository, and that has misled
people into reading it as an engineering tool. **It is for everyone on a team
building with AI** — product, design, research, program and project management,
support, clinical, strategy, leadership, and engineering. Engineers are very much
included; they are just not the point. Whoever on your team is asking an assistant
to do real work is who this is for, and the value compounds precisely when those
people are *not* all in the same discipline: a decision recorded by product is
context engineering needed, and a constraint discovered in code is context product
needed.

**A code repository is one place to put the standing instruction, not a
requirement.** Pick whichever line describes your work:

| Your work is… | Point your assistant at | Setup |
|---|---|---|
| Meetings, decisions, research, customers, roadmap, strategy | **the vault itself** | `install.sh /path/to/vault` |
| Designs, specs, tickets, plans — anything not in a code repo | **the vault itself** | `install.sh /path/to/vault` |
| Changing code in a repo, and you want the notes next to it | **the code repo** | `install.sh /path/to/repo` |

Both give you the same vault, the same commands and the same automatic reading of
context. You can do both — engineers usually do, because they want the notes
loaded while they work in the repo.

**Why the choice exists at all**, since it is not obvious: the end-of-session
prompt that asks *"you did real work — write it down"* decides whether real work
happened by looking for **changed files in the folder your assistant is working
in.** That is a good signal for a code repo and no signal at all for a folder that
isn't one. If your work is meetings and decisions rather than commits, make the
vault the working folder — then the files you changed *are* the notes you wrote,
and the prompt fires exactly when it should. Point a non-engineering session at
some unrelated folder and you get the reading half of the loop but never the
writing half, which is the half worth having.

**You may not need an assistant runtime at all.** Reading the vault, contributing
notes by hand, and asking questions of it from Slack, Discord or Claude Desktop
all work without ever installing canon into a folder. See
[Getting Started — No Terminal](docs/GETTING-STARTED-NO-TERMINAL.md) and
[Ask it from chat](#ask-it-from-chat).

### What happens in a normal work session

1. You ask your assistant for something.
2. It reads the notes first — the project's page, the last session's log — so it
   starts with context instead of asking you to re-explain.
3. You do the work.
4. At the end it writes a dated note: what changed, what was decided, what's still
   open, linked to the project.

Next week, *"why did we do it that way?"* has an answer with a date on it. In six
months, when the person who decided it is on holiday, their reasoning is still there.

### What you actually do

| You want to… | You do this |
|---|---|
| Read or explore the notes | Open the folder in **Obsidian**. `Cmd+O` jumps to any note by name. |
| Add a document — a PDF, a deck, a transcript | Drop it in the `Sources` folder and run `/ingest`. Your assistant reads it and files the useful parts into the right notes. |
| Find where something stands | Open the project's note, then the newest session log linked from it. |
| Tidy up after a busy week | Run `/lint-vault`. It reports broken links, stale notes and contradictions, and offers to fix them. |
| Share your notes with the team | One command that checks them and sends them up. |

**You rarely write the notes by hand.** You drop things in, ask questions, and the
notes get maintained as a side effect of the work.

### Automatic, versus your decision

| Step | Who |
|---|---|
| Reading the notes at the start | **Automatic** |
| Writing the session note at the end | **Automatic**, with a nudge if it gets skipped |
| Getting teammates' updates | **Automatic** — and only ever a safe update; it will not overwrite something you are mid-edit on |
| **Publishing your notes to the team** | **You decide.** Never automatic. |

That last line is deliberate. Once something is published it is effectively
permanent, so a person looks first. Reading is safe to automate; publishing isn't.

### The safety net, and its limit

Before anything is saved, an automatic check looks for passwords, API keys and
things shaped like personal identifiers, and **refuses the save** if it finds any.

It is honest about what it cannot do. It is good at spotting *credentials* — text
with a recognisable shape. It is poor at spotting **personal or confidential
information written as ordinary prose**, because a pattern-matcher cannot
recognise a story about a named individual. So the rule stands on its own: **don't
put sensitive personal information in the notes.** The check is a backstop, not
permission.

### How a teammate joins

1. Install Obsidian — free, including for work use.
2. Copy the notes folder down — one command, once.
3. Tell their machine where it lives — one line, once.

Then they can read everything the team knows, and so can their AI assistant.

**Not everyone uses a terminal**, and reading the vault does not require one — the
setup steps a reader can skip are only needed to commit. Hand those teammates
**[Getting Started — No Terminal](docs/GETTING-STARTED-NO-TERMINAL.md)**: GitHub
Desktop plus Obsidian, click to clone, click to get updates, no commands at all.

### Which assistants this works with

The notes are plain Markdown, so **any** tool that can read files can use them —
Claude Code, Codex, Cursor, Gemini CLI, or a person with `grep`.

`install.sh` writes the same instruction block for **seven runtimes** — Claude Code,
`AGENTS.md`, Gemini CLI, Copilot, Cursor, Windsurf and Cline — all generated from one
template. See [Works with agents that are not Claude](#works-with-agents-that-are-not-claude).

The *automatic* wiring — the part that loads context at the start of a session and
writes the note at the end — is **Claude Code only**, because it is the runtime with
a hook system to attach to. Adding others as they grow one is a welcome contribution;
see [CONTRIBUTING](CONTRIBUTING.md). Nothing about the notes themselves is
Claude-specific.

---

## How it works

A small map goes into the agent's context every session. The vault itself stays on
disk and gets searched on demand — it is far larger than any context window, so
loading it is not an option and is not the point.

```mermaid
flowchart TB
    H(["SessionStart hook"])
    R["Agent Router · ~40 lines<br/>in context, every session"]
    A["Your agent"]
    V[("Vault on disk · thousands of notes<br/>never loaded whole")]
    W["Work happens in your working folder<br/>a code repo, or the vault itself"]
    S(["Stop hook"])
    Q{"Session note<br/>written?"}
    N["Remind — or block"]
    E["Session ends"]

    H -->|"injects · capped at 10k chars"| R
    R --> A
    A <-.->|"glob + grep, just-in-time"| V
    A --> W
    W --> S
    S --> Q
    Q -->|"no"| N
    N -.->|"finish the job"| A
    Q -->|"yes"| E

    classDef hook fill:#1F2937,stroke:#A78BFA,stroke-width:2px,color:#E5E7EB
    classDef core fill:#161B22,stroke:#6366F1,stroke-width:2px,color:#E5E7EB
    classDef store fill:#0D1117,stroke:#6366F1,stroke-width:2px,color:#E5E7EB
    classDef good fill:#161B22,stroke:#22C55E,stroke-width:2px,color:#E5E7EB
    class H,S hook
    class R,A,W,N core
    class V store
    class E good
    class Q hook
```

Sharing is asymmetric on purpose. Reading is safe to automate; publishing is
irreversible, so it stays deliberate and passes a gate first.

```mermaid
flowchart LR
    RM[("Shared remote")]
    G{{"canon-scan · canon-guard"}}
    X["Refused —<br/>fix it before it<br/>enters history"]
    P["push<br/>only when you ask"]

    subgraph local["Your machine"]
        W["Notes your agent wrote"]
        C["Local commit"]
        W --> C
    end

    RM -->|"pull · automatic"| W
    C --> G
    G -->|"clean"| P
    G -->|"credential, or a path<br/>you do not own"| X
    P --> RM

    classDef core fill:#161B22,stroke:#6366F1,stroke-width:2px,color:#E5E7EB
    classDef store fill:#0D1117,stroke:#6366F1,stroke-width:2px,color:#E5E7EB
    classDef gate fill:#1F2937,stroke:#A78BFA,stroke-width:2px,color:#E5E7EB
    classDef good fill:#161B22,stroke:#22C55E,stroke-width:2px,color:#E5E7EB
    classDef bad fill:#161B22,stroke:#F87171,stroke-width:2px,color:#E5E7EB
    class W,C core
    class RM store
    class G gate
    class P good
    class X bad
    style local fill:#0D1117,stroke:#A78BFA,stroke-width:1px,color:#A78BFA
```

## What you get

| Piece | What it does |
|---|---|
| **A vault** | Markdown notes: `Decisions/`, `Projects/`, `Sessions/`, `Reference/`, … in one git repo |
| **A design canon** | `Reference/Design/` — token names, a component inventory, and design assets an agent can resolve. Names and pointers, never values |
| **A router note** | The one small file agents load every session — a map of what lives where |
| **Repo wiring** | `CLAUDE.md` + `SessionStart` hook so agents find the vault from any repo |
| **A session-note check** | A `Stop` hook that notices when work happened but nothing got written down |
| **Path-scoped rules** | Write conventions that load only when an agent touches vault files |
| **`canon-sync`** | Pull, scan, commit, and — only when you ask — push |
| **`canon-scan`** | Blocks credentials and obvious identifiers from entering git history |
| **`canon-guard`** | Warns when a commit touches a note somebody else owns |
| **`canon-status`** | Are you in step with the team? Silent when you are |
| **`canon-trust`** | Who wrote each note, who confirmed it, what has gone stale |
| **`canon-verify`** | Records that a human read a note and stands behind it |
| **`canon-design-audit`** | Does the code match the design canon? Derives violations and coverage every run; never compares token values |
| **Chat connectors** | Ask the canon questions from **Slack** or **Discord**; read-only, cites its sources |
| **MCP server** | Exposes the vault to **any MCP client** — Claude Desktop, Cursor, VS Code. One connector, not one per editor |

## Install it as a Claude Code plugin

Two commands, no clone:

```
/plugin marketplace add Chris-Carruthers/canon
/plugin install canon@canon
```

Then `/canon-setup`, which is the one thing a plugin cannot do for you: **tell this
machine where the vault is.** Everything else — the SessionStart and Stop hooks, the
CLI, the slash commands — arrives with the plugin.

| | Plugin | `install.sh` |
|---|---|---|
| Hooks (load context, notice a missing note) | ✅ every project | ✅ the folder you install into |
| `canon-sync` / `canon-status` / `canon-trust` / `canon-design-audit` | ✅ bundled | ✅ if you put `bin/` on `PATH` |
| `/canon-sync`, `/canon-status`, `/canon-setup` | ✅ | — |
| Instruction files for **other** agents | — | ✅ six runtimes |
| The commit-time secret gate | — | — *(lives in the vault; run its `bootstrap.sh`)* |
| Teammates inherit it by cloning the repo | — | ✅ commit `.claude/` and `CLAUDE.md` |

**Use both if you work across repos**: the plugin gives *you* the hooks everywhere,
`install.sh` gives *the repo* wiring your teammates get by cloning.

Two things worth being straight about. **The plugin does not install the secret
gate** — that is a git hook inside the vault, so run `./.canon/bootstrap.sh` there or
nothing checks notes for credentials before they enter history. And **the same hook
scripts serve both installs**; they look for their tools in the repo copy, then
`${CLAUDE_PLUGIN_ROOT}/bin`, then `PATH`. One file, three resolution sites, so plugin
mode and installed mode cannot drift apart.

## Claude Desktop and Cowork

Cowork runs sessions **in the cloud by default**, and that single fact decides how
you should hook up a vault — because the vault is a folder on your laptop.

| | Cowork **cloud** session | Cowork **local** session · Claude Desktop |
|---|---|---|
| Read the vault as a **connected folder** | ✅ routed through the desktop app | ✅ |
| canon's **MCP bundle** (`.mcpb`) | ❌ *local MCP servers do not run in cloud sessions* | ✅ |
| Best option | connected folder | either; the bundle adds search tools |

### The zero-install option: connect the folder

Add the vault folder as a **connected folder** in Claude Desktop. Nothing to
install, and it works in cloud sessions too, because the cloud session reaches
local files back through the desktop app. Claude reads the notes directly.

Tell it to *"read `Vision/Agent Router.md` first"* and it will find its way around —
the router exists precisely so an agent does not have to guess at folder names.

### The bundle: one file, one dialog

For local sessions and Claude Desktop, `canon.mcpb` installs canon's read-only MCP
server by double-click. You pick your vault folder in a dialog; there is no config
file to hand-edit and no terminal.

```bash
./connectors/mcpb/build.sh      # produces canon.mcpb
```

Four tools — `canon_router`, `canon_search`, `canon_list`, `canon_read` — and **no
write tool at all**. Every caller-supplied path goes through a symlink-aware check
that refuses anything outside the vault you selected.

Building needs node and npm, because a `.mcpb` carries its own `node_modules` so the
person installing it does not have to. That is why it is a build step rather than a
dependency the kit acquires — canon's core stays `bash`, `git`, `python3`.

**One thing to decide deliberately.** In a cloud session, the notes Claude reads
leave your machine; in a local session they do not. Which is acceptable depends
entirely on what is in your vault, and it is a call for whoever is accountable for
that content — not a default this project should pick for you.

Worth knowing while you decide: canon's scanner gates **credentials** at commit
time and has no opinion about what you later choose to share, so it is not the
control here. If your vault carries client, patient or otherwise regulated
material, answer this question before connecting it, and read
[Use Claude Cowork safely](https://support.claude.com/en/collections/19667525-claude-cowork).
Record the answer as a `Decisions/` note so the next person does not have to
re-litigate it.

## Works with agents that are not Claude

`install.sh` writes the **same instruction block** into every runtime that has a
conventional filename, all generated from one template so they cannot disagree:

| Runtime | File |
|---|---|
| Claude Code | `CLAUDE.md` |
| Codex, Zed, Jules, and anything else on the open convention | `AGENTS.md` |
| Gemini CLI | `GEMINI.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/knowledge-vault.mdc` |
| Windsurf | `.windsurf/rules/knowledge-vault.md` |
| Cline | `.clinerules/knowledge-vault.md` |

All on by default; opt out with `--no-gemini`, `--no-copilot`, `--no-windsurf`,
`--no-cline`, or `--claude-only`. `--uninstall` removes every one of them **without
needing the same flags you installed with**, and deletes files it created outright
rather than leaving empty ones behind.

**The honest limit:** these make other agents *read* the vault, which is most of the
value. Only Claude Code gets the hooks that load context automatically and notice a
session ending with nothing written down — the other runtimes have no hook system to
attach to. Adding one when they do is a welcome contribution; see
[CONTRIBUTING](CONTRIBUTING.md).

## Quickstart

*About five minutes. Nothing to install beyond `bash`, `git` and `python3`.*

```bash
git clone https://github.com/Chris-Carruthers/canon && cd canon

# 1. Create the vault — or point this at a folder of notes you already have
./bin/canon-init-vault ~/team-vault

# 2. Set it up: records the path for this machine, installs the commit safety check
cd ~/team-vault && ./.canon/bootstrap.sh && cd -

# 3. Wire up the folder you work in. Pick ONE — see "Two ways to set it up".
./install.sh ~/team-vault            # a. no code repo: the vault IS your workspace
./install.sh /path/to/your/repo      # b. a code repo — safe if it already has a CLAUDE.md

# 4. Confirm it resolves
~/team-vault/.claude/hooks/canon-path           # prints the vault path
./bin/canon-sync --status                       # what would sync; changes nothing
```

Then open a Claude Code session in that folder and ask *"what does the team
knowledge vault say about how we work?"* If the wiring is live, it answers from
the router note without being told where to look.

In case (b), commit `.claude/` and `CLAUDE.md` so teammates inherit the repo
wiring by cloning. In case (a) they are already in the vault, so cloning the vault
is all a teammate needs.

**Joining a vault that already exists** is shorter — clone it and run its bootstrap;
everything it needs is committed inside:

```bash
git clone <your-vault-repo> ~/team-vault
cd ~/team-vault && ./.canon/bootstrap.sh
```

## How it finds the vault

Nothing hardcodes a path. `canon-path` resolves, first hit wins:

1. `$CANON_HOME`
2. `<repo>/.canon` — a marker file containing the path (commit this to pin a
   convention for the team)
3. `~/.config/canon/path`
4. `~/canon`

An explicitly-set `$CANON_HOME` that points nowhere **fails loudly instead of
falling back** — silently loading a different vault than you asked for is worse
than loading none.

Rule 2 is a **file**. Inside a vault, `.canon` is a *directory* of vendored
tooling, so a vault used as its own workspace does not match rule 2 and resolves
by rule 3 instead. That is why step 2 of the Quickstart matters: `bootstrap.sh`
writes the path into `~/.config/canon/path`. Nothing breaks if you skip it, but
the commands will not find the vault.

## Reading it as a human (Obsidian, optional)

The vault is plain markdown, so any editor works and `grep` works. Your agents
never touch Obsidian; they read files. But humans navigate knowledge by following
links, and that's what [Obsidian](https://obsidian.md) adds for free:

- **`Cmd+O`** to jump to any note by name — the fastest thing in it
- **Backlinks** — "what else references this?", which is how you find context you
  didn't know to ask for
- **Graph view** — see the shape of what the team knows
- **Bases** — live tables generated from frontmatter, so human dashboards stop
  being hand-maintained (and stop being a merge-conflict surface)

> [!IMPORTANT]
> **A Bases table is rendered from a query at view time — it is not text in the
> file.** A human sees a live table; an agent greps the file and sees a query
> definition, not the rows. So: **Bases for human dashboards, plain text for
> anything an agent must read.** The router note especially must stay literal
> text, or you have built an index your agents cannot see.

It's [free for commercial use](https://obsidian.md/license) — the paid Commercial
License is optional support, not a requirement. Point it at the vault folder with
*Open folder as vault*.

Sharing this with someone who does not use a terminal? Give them
[Getting Started — No Terminal](docs/GETTING-STARTED-NO-TERMINAL.md) instead of this
README.

**What you lose without it:** `[[wikilinks]]` render as literal text elsewhere, so
you get a searchable folder rather than a connected one. Everything is still
readable. Nothing breaks.

`canon-init-vault` writes a `.gitignore` that commits shared editor settings while
excluding per-person UI state, so nobody fights over pane layouts.

### Two rules if you use the Obsidian Git plugin

1. **Don't run its timer alongside `CANON_AUTOPULL`.** Two processes pulling on
   independent schedules is how you manufacture a race with the editor's own
   autosave. Prefer the session-start pull: a timer fires mid-sentence, session
   start doesn't.
2. **Keep mobile read-only.** The plugin uses `simple-git` — the real git binary —
   on desktop, so its commits *do* run your hooks and the gate holds. On mobile it
   falls back to `isomorphic-git`, which does **not** run hooks, so mobile writes
   are ungated. Mobile also has no SSH auth and hard repo-size limits. Read on a
   phone by browsing the repo on your git host instead.

## Design, and why

**The vault is reached on demand, never inlined.** `CLAUDE.md` loads in full on
every request, `@`-imports don't reduce context, and hook-injected context is
capped at 10,000 characters. So the only thing that enters context is a short
router note; the agent then globs and greps the vault for what it actually
needs. That's also how Claude Code's own retrieval is designed — filesystem
search just-in-time, not a vector database.

**Size budgets are load-bearing.** Index notes ≤200 lines / 25 KB, detail notes
under 500 lines, references one level deep, TOC over 100 lines. Agents retrieve
by filename and structure long before they read content, so naming and shape are
infrastructure, not style.

**Layered defaults, because nothing guarantees "always."** `CLAUDE.md` and rules
are additive and reconciled by model judgment; hooks fire on their event but can
be skipped by an unaccepted trust dialog, are scoped per project, and can be
disabled by enterprise policy. Redundancy is the design. Pair every preventer
with a detector — the `Stop` hook exists precisely because the end-of-session
write is the step that gets skipped.

## Sync: automatic inbound, deliberate outbound

Sharing a vault fails in a specific way: everyone writes locally, nobody commits,
and the "shared" vault quietly becomes a set of private ones. So sync is
automated — but asymmetrically, because the three steps carry very different
risk.

| Step | Default | Why |
|---|---|---|
| **Pull** | automatic (`CANON_AUTOPULL=1`) | Pure upside. `--ff-only`, so it cannot rewrite history or strand a rebase under an open editor. |
| **Commit** | local, opt-in (`CANON_AUTOCOMMIT=1`) | Real history and diffs, still nothing leaves your machine. |
| **Push** | **never automatic** | The irreversible step. Once a note is on a remote it may be cached or indexed even after you delete it. |

```bash
canon-sync              # pull, scan, commit locally
canon-sync --push       # ...and push, only if the scan passed
canon-sync --status     # what would happen, changes nothing
canon-sync --branch     # put it on a branch for review instead of on trunk
```

### What happens when two people push at once

They will. A fifteen-person vault is fifteen agents writing notes, and the window
between your pull and your push is as long as the scan takes.

If a teammate lands a commit in that window, git refuses yours as
non-fast-forward. Untreated that produces the precise failure this tool exists to
prevent — *"committed"*, then *"push failed"*, and your notes still on your
laptop. So `canon-sync` **rebases onto what arrived and pushes again**, up to
three times. Notes are near-append-only, so that rebase is almost always somebody
else's new files sliding past yours, and you see one line about it.

When the rebase hits a genuine conflict — two people editing the same lines of
the same note — it stops, aborts the rebase, leaves your commit intact, and says
so. It never leaves you in a half-finished rebase to discover later. A failure
that is *not* a race (auth, network, a protected branch) fails immediately with
git's own message rather than retrying against a wall.

If your team isn't handling regulated or sensitive data, this asymmetry is
probably more caution than you need — install a git plugin, auto-sync every ten
minutes, move on. The gate below is what buys you the right to automate more.

### Being reminded, since push is manual

Making push deliberate creates its own failure: everyone writes locally, nobody
shares, and the "shared" vault quietly becomes a set of private ones. So both hooks
call `canon-status`, which reports uncommitted work, commits the team has not seen,
and how long since anyone pulled — then says which command to run.

- **At session start** it rides along with the router, so your agent knows the vault
  may be stale and can caveat an answer instead of stating a stale fact confidently.
- **At session end**, when you are finishing up and can act on it.

Two things make it a reminder rather than nagging. **It is silent when you are in
step** — a notification that always fires is one people learn to ignore. And **it
makes no network call**: unpushed commits and uncommitted files are local facts, and
staleness comes from the timestamp on the last fetch, so a session start never waits
on the network or hangs offline.

Run it yourself any time with `canon-status`. On by default — unlike auto-pull and
auto-commit, it changes nothing.

## The gate

`canon-scan` inspects **only the lines being added** in a staged commit, so
existing content isn't re-flagged forever. It runs `gitleaks` when present and
always also applies its own high-precision patterns, so it works on a machine
with nothing installed.

`canon-install-vault-hooks` puts it in the vault's `pre-commit`, which means
**it fires on plain `git commit` too** — not only through `canon-sync`. Verified:
a planted API key blocks both paths, and an auto-commit that trips the gate
reports itself instead of failing silently.

Two limits, stated plainly:

- **`.git/hooks` is not shared by cloning.** Each teammate runs
  `canon-install-vault-hooks` once. Your git host's own push protection is the
  only gate nobody can skip — turn it on.
- **If `core.hooksPath` is set** (husky, the pre-commit framework, a shared team
  hooks dir) git ignores `.git/hooks` entirely. The installer detects this and
  installs into the real directory, because a gate in a directory git never reads
  is worse than no gate — you believe you are covered. It tells you when it does.
- **Editor sync plugins are fine on desktop, and a hole on mobile.** Obsidian Git
  ships two backends: `simple-git` (which spawns the real `git` binary) on
  desktop, and `isomorphic-git` on mobile, because a plugin cannot use a native
  git install on Android or iOS. So on **desktop the plugin's commits do run your
  hooks** and the gate holds; on **mobile they do not**, and mobile also has no
  SSH auth and hard repo-size limits. Treat mobile as read-only for a gated
  vault.

**Measured false-positive burden.** Run over a real 2,040-file vault: 28 flagged
lines, *all* of them inside a vendored third-party documentation mirror
containing synthetic HL7 examples and sample JWTs. **Zero** false positives
across ~240 human- and agent-authored notes. Exclude a vendored doc tree with
a line in the committed `.canon-scan-exclude` rather than loosening the patterns —
committed, so the exclusion applies to the whole team instead of one shell.

It also refuses **merge conflict markers**, which is the likeliest way a
git-synced vault gets quietly damaged — they render as ordinary text in an editor,
so they are easy to miss and easy to commit into a note.

And the honest ceiling: this catches **credentials** well and **personal or
health information written as ordinary prose** poorly. A regex cannot recognise a
clinical anecdote. Convention and human review remain the real controls.

## Ask it from chat

Not everyone will open an editor, and a knowledge base is only as useful as its
ways in. Two optional connectors answer questions from the vault and **cite the
notes they used**, so an answer can be traced back — and the note corrected.

| | |
|---|---|
| **Slack** | [`connectors/slack/`](connectors/slack/README.md) — mention it, DM it, or `/canon` |
| **Discord** | [`connectors/discord/`](connectors/discord/README.md) — `/canon`, with threaded follow-ups |
| **MCP** | [`connectors/mcp/`](connectors/mcp/README.md) — any MCP client: Claude Desktop, Cursor, VS Code via Copilot |

```
@canon  what did we decide about the auth migration, and why?
  → answer, plus 📄 Decisions/2026-06-11 — ….md · Projects/Auth.md
```

**Read-only by construction.** The agent gets `Read`, `Grep`, `Glob` and nothing
else, with `cwd` pinned to the vault. This lives once in
[`connectors/shared/agent.mjs`](connectors/shared/agent.mjs) — two copies of a safety
model is two things that can drift, and drift here means a read-only bot quietly
becoming something else. The test suite asserts the tool list *and* asserts that no
connector declares its own.

**They bypass your git permissions**, and that is the part to think about: git
decides who can clone the vault, the chat platform decides who is in the channel.
Where those differ the bot is a hole, so both **refuse to start without an
allowlist**. Be stricter on Discord — those servers are usually broader.

**Prefer one protocol over N integrations.** The MCP server is the answer to
"can we have a VS Code extension?" — it serves every MCP host for a fraction of the
code, needs no API key (the host's model reasons; the server just returns notes),
and unlike the Obsidian MCP servers it does not require Obsidian to be running.

Optional by design: they need Node and a couple of npm packages, which the core kit
does not. **None has been run against live credentials yet** — each README has a
verification checklist; treat it as acceptance criteria, not a formality.

## Works with agents other than Claude

`install.sh` writes the same instruction block into **`CLAUDE.md`** *and*
**`AGENTS.md`**, and drops a Cursor rule at `.cursor/rules/knowledge-vault.mdc`.
[AGENTS.md](https://github.com/agentsmd/agents.md) is the cross-tool convention
other coding agents read, so Codex, Cursor and friends get the vault contract
without extra work.

Both files are generated from one template and the test suite asserts their blocks
are **byte-identical**, because two hand-maintained copies of the same instructions
is a guarantee they will disagree within a month.

## Trust: telling an agent draft from a checked fact

Once most notes are written by agents, "what does the vault say" stops being enough.
A reader needs to know **what this was made from, whether anyone checked it, and
whether it is still true.** Four optional frontmatter keys make that answerable:

```yaml
generated: { by: claude-opus-5, at: 2026-07-30T21:00:00Z }   # how it was produced
verified:  { by: human:chris,   at: 2026-07-30T22:15:00Z }   # who confirmed it
status: stable                                              # draft|stable|deprecated
stale_after: 2026-10-30                                     # absolute date, not a TTL
```

`generated` and `verified` are kept separate on purpose: **who wrote a note need not
be who confirmed it**, and collapsing them loses the only interesting thing about the
distinction.

**Trust tiers are derived, never stored.** No `verified` key means unverified;
non-human actors only means machine-confirmed; any `human:<id>` means human-reviewed.
Storing a *score* instead would be subjective, unportable between readers, and stale
the moment it was written — so canon records signals and lets the reader judge.

```
$ canon-trust
  Trust tiers (derived from `verified`, never stored)
    human-reviewed        14  ███████
    machine-confirmed      3  █
    unverified           198  ████████████████████████████████████

  Agent-written and never confirmed (198):
    Decisions/2026-07-30 — token validation.md  ← claude-opus-5
    …
  Confirm one after reading it:  canon-verify <path>
```

`canon-verify <note>` stamps a human review. It deliberately **does not read or
judge the note** — you confirm, it records that you did. A tool that stamped notes
automatically would manufacture exactly the false confidence the field exists to
prevent. Agents are told to write `generated` and *never* to write `verified` for
themselves.

Every key is optional and nothing is ever rejected for lacking them — absence just
carries meaning. The shape follows the
[Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md),
so a canon vault stays legible to other OKF-aware tooling.

## The design canon: names and pointers, never values

A design system is mostly code, and code stays out of the vault. So
`Reference/Design/` holds the part that isn't code — and the split is sharper than
it first looks:

> A token **name** is API surface, like a schema field name, and `Reference/` is for
> schemas. A token **value** is source. It has a format, it belongs to a cascade, and
> any tool can read it from the repo when asked.

Copy values into the vault and you have built a second source of truth that drifts
silently while reading as authoritative.

**For coding agents, the useful part is that assets resolve deterministically.**
Frozen fenced blocks — `design-tokens`, `design-components` and `design-tools` —
give a three-rung ladder, and *every rung's absence is detectable*:

| Rung | Field | Needs |
|---|---|---|
| Exported image | `image: Attachments/Design/<slug>--<variant>--<state>@<theme>.png` | nothing |
| Figma node | `figma: { file: <key>, node: <dash-form-id> }` | Figma MCP or an authed fetch |
| Implementation | `impl: repo/path[:line]` | the repo |

Filenames are **constructible**, so an agent derives the expected path from the slug
and checks whether it exists rather than guessing. **Omit a key you do not have —
never `TODO`.** Absence is the signal, and coverage is derived from it. `status:
absent` is a legitimate row: *"there is no shared `PageHeader`"* stops an agent
hunting for one and stops it silently inventing a fourth.

The third block, `design-tools`, records what is approved for *making* UI — and any
tool whose role writes UI must name the vocabulary it targets, checked against the
tokens block. A generator given no target does not abstain from picking one, it
invents one. See **[`docs/DESIGN-TOOLS.md`](docs/DESIGN-TOOLS.md)**.

### `canon-design-audit`

```
$ canon-design-audit ~/code/web-app
canon-design-audit 0.2.0
  scanned 695 file(s) in 1 repo(s)
  canon: 5 vocabular(ies), 24 component(s)

  VIOLATION DS-PALETTE-UTILITY     14054
              web-app/src/Page.tsx:31  bg-blue-500
              … and 14049 more
  VIOLATION DS-COLOR-LITERAL       551
  GAP       DS-FORMAT-SPLIT        19
              --primary  declared in app-shell, optimize, tenant-hub across
                         formats hsl-triplet, oklch

  coverage: image 0/24 · figma 6/24 · impl 20/24 · absent 4
```

Two claims worth being precise about, because they are why the thing is usable:

**Derived, never stored.** It reads the contract from the vault and the facts from
the code and recomputes on every run. No frontmatter caches a verdict, no note holds
a score, and there is no scorecard to keep current. `--report` writes one dated
`Outputs/` note carrying `stale_after: +30d`, so `canon-trust --strict` fails on an
audit nobody re-ran.

**It never compares two token values.** Deciding whether `var(--foreground)` equals
`222 47% 11%` is a CSS resolution problem — aliases, `calc()`, colour spaces, the
cascade, shadow-root scoping — and a regex cannot solve it. So it compares **name
sets and format labels** and leaves value equivalence to the browser. This is a
direct lesson from a real token-parity script that reports nine false results out of
twenty-six and is consequently read by nobody.

Everything else follows from the same instinct: **VIOLATION** is a fact you can check
by opening the cited line, **GAP** is a judgement call and can never fail a build,
the Tailwind rule uses a **closed list** of the default palette so `bg-primary` is
structurally unmatchable, the skip-list is **learned from the canon** so declaring a
vocabulary silences its own false positives, and `--strict` compares against a
`.canon-design-baseline` rather than zero — on a repo with fourteen thousand existing
violations the only useful signal is *did it get worse*.

It is **read-only in every repo it scans**, asserted by a test. And it is not in any
pre-commit hook: it scans code repos, not the vault. It measures. Enforcement is
CODEOWNERS on the token files plus branch protection, in the repos where those files
live.

## Ownership: not everything should be everyone's

`Vision/` is direction from leadership; session notes are everyone's. Both live in
one vault, so ownership is layered:

1. **Rules + router** tell agents `Vision/` is owned — catches the likeliest
   failure, which is an agent tidying a vision doc because tidying is what agents do.
2. **`.canon-owners`** maps globs to owners; `canon-guard` warns (or blocks) at
   commit time and says what to do instead. A seatbelt, not a lock.
3. **`CODEOWNERS` + branch protection** is the only layer that actually enforces —
   it runs on the server and `--no-verify` can't touch it.

And the hard boundary: git cannot restrict *reading*. Write governance fits in one
repo; if someone must not read something, that needs a second repo.

**Read [`docs/MULTIPLAYER.md`](docs/MULTIPLAYER.md)** for the full model — the four
classes of file, where conflicts actually occur, and how to choose a write model
without accidentally requiring a PR per session note.

## Configuration

| Variable | Default | Effect |
|---|---|---|
| `CANON_HOME` | — | Vault path override; wins over everything |
| `CANON_AUTOPULL` | `0` | `1` = `git pull --ff-only` at session start, skipped if the tree is dirty |
| `CANON_ENFORCE_SESSION_NOTE` | `remind` | `block` = tell Claude to finish; `off` = disable |
| `CANON_SESSION_NOTE_WINDOW_MIN` | `720` | How recent a session note counts as "written" |
| `CANON_AUTOCOMMIT` | `0` | `1` = commit vault changes locally at session end (never pushes) |
| `CANON_ROUTER` | `Vision/Agent Router.md` | Which note gets injected |
| `CANON_SESSIONS_DIR` | `Sessions` | Where session notes live |
| `CANON_SCAN_EXCLUDE` | — | Colon-separated regexes of paths the scanner skips (per-machine; prefer the committed `.canon-scan-exclude`) |
| `CANON_GUARD` | `warn` | `block` = refuse commits to paths you don't own; `off` = disable |
| `CANON_BRANCH_MODE` | `auto` | `trunk` = always push direct; `branch` = always open a PR; `auto` = direct, except for governed paths |
| `CANON_SKIP_SCAN` | `0` | `1` = bypass the gate. Be sure. |

Auto-pull is **off by default**: a hook that mutates a git repo you didn't ask
it to touch is a bad default, and a half-rebased vault is worse than a stale one.

## Before you roll this out to a team

- **Make the vault repo private**, and decide read/write access deliberately.
- **Nothing with personal data, secrets, or credentials goes in.** Git history is
  permanent. Run `canon-install-vault-hooks` before the first push, and turn on
  your host's push protection. Note that path-based `permissions.deny` rules
  cannot see content — they will not catch an identifier written into prose, and
  neither will the scanner if it is phrased as a sentence.
- **If you're in a regulated industry, get the compliance question answered
  first** — where this data may live, and under what agreement with your git
  host. Do this before the vault has a hundred notes in it, not after.
- **Pin a Claude Code version** and run `docs/VERIFY.md` against it. The hook and
  skill surface changes frequently; version-stale config that silently does
  nothing is the most common failure.

## What this is not

Not an agent-memory product, not a vector store, not a server. It is a set of
conventions plus the smallest amount of wiring that makes them fire
automatically. It composes with markdown-native memory tools rather than
competing with them — they own storage and retrieval; this owns the *practice*.

Obsidian is **recommended, not required**: it is the nicest way for a human to
read a linked vault, and nothing in the kit depends on it. Requirements stay
`bash`, `git`, `python3`.

**Not an engineering-only tool**, despite the examples. It is for whole teams
building with AI — product, design, research, program and project management,
support, clinical, ops, strategy, leadership, engineering. The vault is a git
repository because git is a good way to share a folder of text between fifteen
laptops with history and no server, *not* because the content is code. Product,
clinical, ops and strategy notes are the common case, and a cross-functional team
is where this pays off most: the whole point is that a decision made in one
discipline is available to an assistant working in another.

One thing genuinely *is* engineering-shaped and worth knowing about: the
end-of-session prompt infers "real work happened" from changed files in your
working folder, which is a good signal in a code repo and no signal in a folder
that isn't one. [Two ways to set it up](#two-ways-to-set-it-up) is how you make it
fire for work that isn't commits — point it at the vault, and the files you
changed *are* the notes you wrote.

## Requirements

`bash`, `git`, `python3`. No package installs, no daemons, no network calls.

**Not required:** a code repository, an IDE, a terminal (for readers and
contributors — see [Getting Started — No Terminal](docs/GETTING-STARTED-NO-TERMINAL.md)),
or any particular AI assistant.

## Status

Tested end to end: fresh repo; repo with a pre-existing `CLAUDE.md` and
`settings.json` (both preserved, merged not clobbered); repeat installs (no
duplication); unconfigured and misconfigured vaults; the `Stop` hook across
seven states; the gate blocking five secret formats via both `canon-sync` and
plain `git commit`; auto-commit off, on, and blocked-by-gate.

Two known unknowns, deliberately not papered over:

1. **`Stop`-hook `block` mode's output shape** is the one thing not confirmed
   against a known-good working example. That is why it defaults to non-blocking
   `remind`. `docs/VERIFY.md` step 5 tells you how to confirm it on your version.
2. **Prose-level personal-data detection** is weak by nature, and the compliance
   question — where this data may live, under what agreement with your git host —
   is yours to answer, not this kit's.

Requires `bash`, `git`, `python3`. No package installs, no daemons, no network
calls.
