# Companion tools

canon owns one thing: **your team's knowledge, and the practice of keeping it.** It
deliberately does not fetch library docs, drive a browser, publish to a wiki, or tell
your agent how to write code. Other tools do those jobs well. This page names the ones
worth installing next to canon, which canon job each one supports, and the caveat that
comes with each.

**None of them is a dependency.** canon's requirements stay `bash`, `git` and
`python3`, and nothing here is installed by `install.sh` or the plugin. Every entry is
a recommendation you can ignore.

## Three rules for every companion

**1. Link, don't copy.** An external system stays the source of truth for its own
content. The vault records *your* decision about a library, not the library's API.
It links to the ticket and doesn't paste it in. Copied vendor content goes stale
without anyone noticing, and it is also where a scanner's false positives come from.
In the one real vault canon has been measured against, every flagged line sat inside
a vendored documentation mirror.

**2. Anything a tool reads can end up in a session note.** An MCP server that reads
your tracker, wiki or inbox puts that content in front of an agent, and the agent then
writes a session note to the vault. Git history is permanent, and
[the gate](../README.md#the-gate) catches credentials, not personal information written
as prose. Before connecting a server to a system holding customer, patient or otherwise
regulated data, decide what may travel from it into the vault, and record that as a
`Decisions/` note.

**3. Tool output is data, not instructions.** A ticket description, a wiki page or a
fetched web page can contain text phrased as an instruction. Agents should treat it as
material to read, never as a request from the user.

## At a glance

| Job | Companion | Kind | Pairs with |
|---|---|---|---|
| Current docs for the libraries you use | **context7** | MCP server | Decisions that cite a library version |
| Publish vault notes outward; read tickets | **Atlassian** (Confluence, Jira) | MCP server | `Outputs/`, `Decisions/`, project notes |
| Resolve design pointers to real frames | **Figma** | MCP server | [The design canon](../README.md#the-design-canon-names-and-pointers-never-values) |
| Critique and build UI against the canon | **impeccable** | Skill | [docs/DESIGN-TOOLS.md](DESIGN-TOOLS.md) |
| See the rendered result | **Chrome DevTools MCP**, **Playwright** | MCP server · plugin | [The testing canon](../README.md#the-testing-canon-a-ratchet-and-a-gate-that-actually-runs) |
| Keep each change small | **ponytail** | Plugin | Session notes, `shortcut:` debt |
| A disciplined working process | **superpowers** | Plugin | Specs, Handoffs |
| Review before merge | **code-review** | Plugin | The testing canon |
| Pull requests and issues | **`gh`** (or the GitHub MCP server) | CLI | `canon-sync --branch` |
| Exact `repo/path:line` for code the vault links to | **code-index** | MCP server | The `code-index` skill, session notes |

## The entries

### context7: current library docs

`claude mcp add --transport http context7 https://mcp.context7.com/mcp`

Gives the agent current documentation for a library, framework or SDK, so it doesn't
answer from training data that is a year old. The split with canon is clean: context7
says what the library *does*, and the vault says what *you decided* about it and why.
Cite the version in the decision. Don't paste the docs into `Reference/`, because that
breaks rule 1.

### Atlassian: Confluence and Jira

`claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp`

The usual publishing path for teams that also run a wiki. The vault is the working
layer and Confluence is where a finished, reviewed page goes for a wider audience.
**Edit the vault note first, then publish.** Say so at the foot of the published
page, or the copy becomes a second source of truth that drifts. Jira tickets are linked
from project notes, not copied into them.

Gotchas that each cost a full re-send of the page body, because an update requires the
whole body:

- **Author in HTML, not markdown, whenever the page has mentions, dates or status
  lozenges.** In markdown those nodes are positional references to what is already
  stored. Edits to their text are silently discarded, and added ones are dropped.
- **Send raw HTML, never entity-escaped HTML.** Otherwise the markup renders as visible
  text.
- **`<b>` and `<i>` are rejected.** Use `<strong>` and `<em>`.
- **A space between two adjacent inline elements is dropped.** For example,
  `</code> <code>` renders as one merged word. Move the space inside a tag.
- **Check the live page, not your input.** Fetch it back and count what you meant to
  publish: code blocks, status labels, task items.

### Figma: design pointers that resolve

`claude mcp add --transport http figma https://mcp.figma.com/mcp`

The design canon stores components as pointers, `figma: { file: <key>, node: <id> }`,
never as values. The Figma MCP server is what an agent uses to follow that pointer to
the real frame. `canon-design-audit` reports how many components resolve to a Figma
node. It does not call Figma.

### impeccable: UI critique and build

Install it from [impeccable.style](https://impeccable.style/docs/) (Apache 2.0).

Already registered as an example entry in [docs/DESIGN-TOOLS.md](DESIGN-TOOLS.md),
which explains how to wire it so it obeys the canon instead of inventing a parallel
token set. **Read the hazard there before using it.** impeccable's `document` command
writes a root `DESIGN.md` that carries token values, while canon's `DESIGN.md` (from
`install.sh --design`) is a pointer file that must not. One file cannot be both.

### Chrome DevTools MCP and Playwright: see what shipped

`claude mcp add chrome-devtools -- npx chrome-devtools-mcp@latest --isolated`
· `/plugin install playwright@claude-plugins-official`

"Tests pass" and "it renders" are different claims. A session note that says a UI
change works should come from looking at it. Two caveats. Without `--isolated`, the
DevTools server drives your everyday Chrome profile. And reading computed colours from
the DOM is not a contrast measurement: modern colour functions can report a passing
ratio for text a person cannot read, so measure real pixels.

### ponytail: the smallest complete change

`/plugin marketplace add DietrichGebert/ponytail` · `/plugin install ponytail@ponytail`
(MIT)

Pushes an agent toward the least new code that fully solves the task, and ends each
reply with what it skipped. That last line belongs in the session note's *Open / next*
section, because that is where a skipped check stops being forgotten. Known limits are
left as `shortcut:` comments, and `/ponytail-debt` lists them as a ledger.

### superpowers and code-review: process and review

`/plugin install superpowers@claude-plugins-official`
· `/plugin install code-review@claude-plugins-official`

superpowers supplies working-process skills (brainstorm, plan, test-first, execute).
Their plans are good raw material for a `Specs/` or `Handoffs/` note, as long as you
write the note in the vault and not only in the chat. code-review reviews a diff or a
pull request before merge.

If the official marketplace is not already known to your Claude Code, add it first:
`/plugin marketplace add anthropics/claude-plugins-official`.

### `gh`: pull requests

`canon-sync --branch` pushes governed changes to a review branch. When `gh` is
installed it also prints the `gh pr create` command to open the pull request. The
GitHub MCP server does the same job inside a session, if you prefer it.

### code-index: where the code is

`git clone https://github.com/Chris-Carruthers/code-index && cd code-index && ./install.sh`
(MIT)

A tree-sitter index of every git checkout on the machine, served over MCP. It answers
*where is this defined*, *who calls it* and *what is in this file* with an exact line,
which is the form rule 1 asks the vault to link in. canon's `code-index` skill tells the
agent when to use it over grep. The caveat: it is static and covers only what you have
cloned. Zero callers can mean dynamic dispatch, or a repo that is not on this disk, so
confirm before calling anything dead.

## Making them a team default

Per person, the commands above are enough. To make a companion the default for
everyone working in a repo, commit it, as canon's own wiring is committed:

- **MCP servers:** `claude mcp add --scope project …` writes a `.mcp.json` at the repo
  root. Commit it. Claude Code asks each person to approve a project server before it
  runs, which is the right default.
- **Plugins:** list the marketplace under `extraKnownMarketplaces` and the plugin under
  `enabledPlugins` in the repo's `.claude/settings.json`.

Both settings change between Claude Code versions. Check them against the version you
pinned, as [docs/VERIFY.md](VERIFY.md) does for hooks.

## What is deliberately not on this list

- **Your own internal servers.** A server over your data warehouse can be the most
  useful companion you have, but no generic list can name it.
- **Servers that need broad write access to a system holding regulated data.** Read
  access already raises rule 2, and write access doubles it.
- **Anything that replaces canon's sync.** A tool that commits and pushes the vault on
  a timer removes the human step before an irreversible push. See
  [Sync](../README.md#sync-automatic-inbound-deliberate-outbound).

Suggest an addition through [CONTRIBUTING](../CONTRIBUTING.md). Name the canon job it
supports and its caveat. A companion with no caveat has not been used for long enough.
