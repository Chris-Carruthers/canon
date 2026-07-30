# Multiplayer: whose files are whose

Everyone reads and writes the same vault at the same time, with agents writing
too. This document is the ownership model — what is yours, what is the team's,
and how content that shouldn't be edited by everyone stays that way.

## The mental model

There is **no server and no locking.** Each person has a complete copy of every
file on their own disk. Git is the only thing connecting those copies, and it
connects them in discrete jumps — a pull, a push — not continuously.

```
   your disk            git remote            teammate's disk
  ┌──────────┐   push   ┌──────────┐   pull   ┌──────────┐
  │  vault/  │ ───────► │  vault/  │ ───────► │  vault/  │
  │  (full)  │ ◄─────── │ (canon)  │ ◄─────── │  (full)  │
  └──────────┘   pull   └──────────┘   push   └──────────┘
       ▲                                            ▲
   your agent                                 their agent
   reads + writes                             reads + writes
```

Two consequences people get wrong:

- **Reading is always safe, always concurrent, never blocks anyone.** Nobody can
  lock you out of a note. The only risk of reading is reading something *stale* —
  which is why pull is the one step worth automating aggressively.
- **Writing is only "shared" after a push.** Until then your work is invisible to
  everyone, including your teammate's agent that would have benefited from it.
  This is the failure mode that kills shared vaults: everyone writes locally,
  nobody pushes, and the shared vault silently becomes fifteen private ones.

## Four classes of file

The useful distinction is not "yours vs. the team's" — it's **how a file
behaves when two people touch it.** Four classes, and the conflict risk of each:

| Class | Examples | Written by | Conflict risk |
|---|---|---|---|
| **Private** | agent auto-memory, `.claude/settings.local.json`, editor UI state | you only, never shared | **none** — gitignored, never travels |
| **Append-only** | `Sessions/`, `Decisions/`, `Specs/`, `Handoffs/` | one new file per unit of work | **near-zero** — different filenames never collide |
| **Shared-editable** | `Projects/`, `Clients/`, `Reference/` | everyone, edited in place | **real** — this is where conflicts actually happen |
| **Governed** | `Vision/`, the router, `.canon-owners` | owners only, by proposal | **none by design** — changes go through review |

**The insight worth internalising:** most of what a knowledge vault produces is
append-only, and append-only content cannot conflict. A fifteen-person team all
running agents that write session notes generates fifteen new files a day and
zero conflicts. The conflict surface is *only* the shared-editable layer plus any
hand-maintained index — which is why a generated table beats a hand-written map
for *human* dashboards, and why small single-concept notes beat large ones.

One caveat on generated tables: they render from a query at view time, so they are
invisible to an agent that greps the file. Use them for dashboards people read;
keep anything an agent must read as literal text.

Two habits keep even that surface small:

- **Author-scope filenames** in append-only folders: `2026-07-30 — thing (cc).md`.
  Two people writing about the same thing on the same day produce two files, not
  a collision.
- **One concept per note.** Git merges non-adjacent changes in the same file
  automatically. Conflicts only happen when two people edit the *same lines* —
  which large sprawling notes make likely and small notes make rare.

## Governed content: the Product Vision problem

You want `Vision/Product Vision.md` to come from leadership and *not* be
modifiable by everyone. Git alone cannot do this: it has no per-file permissions,
and anyone with write access to the repo can change any file in it.

So the answer is layered, and it is important to be clear about which layer is
real enforcement and which is politeness.

### Layer 1 — tell the agents (advisory)

The path-scoped rules and the router note state that `Vision/` is owned and
should be proposed against, not edited. This catches the most likely failure by
far: not a person overriding leadership, but **an agent tidying the vision doc
because tidying is what agents do.** It is reconciled by model judgment, so it is
a strong nudge and not a guarantee.

### Layer 2 — `.canon-owners` (local, bypassable)

A committed file mapping globs to owner emails:

```
Vision/**                lead@example.com
Vision/Agent Router.md   lead@example.com,staff@example.com
Sessions/**              *
```

`canon-guard` runs in the vault's `pre-commit`, compares the staged paths against
your `git config user.email`, and tells you who owns what you just touched and
what to do instead. `CANON_GUARD=block` refuses the commit outright.

This is a **seatbelt, not a lock**: it runs on the author's machine, from a file
the author can edit, and `--no-verify` skips it. Its value is catching the honest
mistake at the moment it happens, with the right alternative in the message.

### Layer 3 — CODEOWNERS + branch protection (actual enforcement)

This is the only layer that cannot be bypassed, because it runs on the server:

1. Commit `.github/CODEOWNERS` mapping `/Vision/` to your leadership team.
2. Protect the default branch: require a pull request, **require review from Code
   Owners**, and disallow bypassing.

Now anyone may propose a change to the product vision, and nobody can land one
without an owner's approval. Direct pushes to `main` are refused for everyone.

**Two caveats, both important:**

- **Branch protection is all-or-nothing per branch, not per path.** If you
  require PR review on `main`, you require it for session notes too — which
  destroys the automatic write loop. Resolve it one of two ways:
  - **Ruleset with restricted file paths** — block direct pushes that touch
    `Vision/**` while leaving other paths pushable. Verify the exact behaviour on
    your plan before relying on it; it is the neatest answer when it works.
  - **Two repos** (below) — more moving parts, completely unambiguous.
- **On GitHub, branch protection and rulesets for *private* repositories require
  a paid plan** (Team or Enterprise). On a free private repo, CODEOWNERS requests
  reviews but enforces nothing. Check your plan before assuming Layer 3 exists;
  if you're on free, what you actually have is Layers 1 and 2 plus a social norm.

### When you need two repos instead

There is one thing path-based governance fundamentally cannot do: **restrict
reading.** Git has no partial-read model — if you can clone the repo, you can
read every file and its entire history.

So:

| You want | Use |
|---|---|
| Everyone reads it; only owners change it | **One repo** + CODEOWNERS + protection |
| Some people must not read it at all | **Two repos.** No exceptions. |

If leadership has genuinely confidential material, it goes in a separate private
repo mounted as a second vault root — not in a subfolder with a stern README.
A subfolder is a convention; a separate repo is a boundary.

## Choosing your write model

| Model | Session notes | Governed content | Good for |
|---|---|---|---|
| **Direct push** | automatic, instant | unprotected | small trusted teams, non-sensitive content |
| **Direct push + guard** | automatic, instant | warned locally | the default this kit ships |
| **Path-restricted ruleset** | automatic, instant | PR-only | the target state for most teams |
| **PR for everything** | needs a PR per note | PR-only | regulated content, external contributors |

"PR for everything" is where teams instinctively go and it is usually wrong:
requiring review for an auto-written session note means the notes stop being
written. Govern the few files where being wrong is expensive; leave the working
layers open. **If you govern everything, people route around the vault entirely** —
and a vault nobody writes to is worth less than no vault at all.

## Pulling while an editor has the vault open

A pull rewrites files on disk underneath whatever editor is showing them. Obsidian
in particular keeps notes in memory and autosaves a second or two after you stop
typing, so this is a real race and worth understanding rather than hoping about.

**Why it is usually fine.** Notes are small, independent files, and the write
pattern is overwhelmingly *additive* — what arrives in a pull is mostly new files
your teammates created, and a new file cannot collide with the buffer you have
open. Obsidian watches the folder, notices changes, and reloads notes it is
displaying without needing a restart. Its link/tag index rebuilds itself; a
briefly stale graph is not damage.

**The one genuinely dangerous case** is narrow: a pull that *modifies the exact
note you have open with unsaved changes*. Then two writers are racing for the same
file — git, and Obsidian's autosave flushing its in-memory copy. Last write wins,
and Obsidian can win with stale content, silently discarding what the pull brought
in.

**The second hazard is conflict markers.** Git writes `<<<<<<<` / `>>>>>>>` into
the file. In an editor these render as ordinary text, which makes them easy to
miss and easy to commit — baking git's scaffolding permanently into a note.

### What this kit does about it

- **The unattended pull is `--ff-only`.** A fast-forward cannot rewrite local
  commits, cannot leave a half-finished rebase, and cannot produce conflict
  markers. If the histories have diverged it does *nothing* and stays quiet.
  Reconciling divergence is a deliberate act — that is `canon-sync`'s job, run
  when you are looking at the output.
- **It skips entirely when the tree is dirty**, because uncommitted files are
  precisely the ones someone is editing.
- **It runs at session start**, not on a timer. This is the important difference
  from timer-based auto-sync: a pull fires when you begin work, not mid-sentence.
- **`canon-scan` refuses to commit conflict markers.** A run of `=` or `-` signs
  is left alone — that is a legitimate markdown heading underline.

### What you should do

- **Do not run two auto-syncers.** If you enable `CANON_AUTOPULL` *and* an editor
  plugin that syncs every ten minutes, you have two processes pulling on
  independent schedules, which is how you manufacture the race this section is
  about. Pick one — and prefer the session-start one, because a timer fires
  mid-sentence and session start does not.
- **Keep mobile read-only.** Obsidian Git ships two backends: `simple-git`, which
  spawns the real `git` binary, on desktop; and `isomorphic-git` on mobile,
  because a plugin cannot use a native git install on Android or iOS. That means
  **desktop plugin commits do run your hooks** — the gate holds — while **mobile
  commits are ungated**. Mobile also has no SSH auth and hard repo-size limits.
  For reading on a phone, browse the repo on your git host instead.
- **Commit before you pull manually** if you have been editing — or let
  `canon-sync` do it, which stages and commits before it touches the remote.
- **After resolving a conflict, search the note for `<<<` before committing.** The
  gate catches it, but seeing it yourself is faster.

## Conflict recipes

**Same note, different lines** — git merges it. Nothing to do.

**Same note, same lines** — a real conflict. `canon-sync` stops and tells you;
resolve in the vault as you would in code. Prefer keeping both statements and
reconciling in prose over silently discarding someone's sentence.

**Two people created the same filename** — rename yours with your initials. This
is why author-scoping is the convention.

**You pulled and your local edits vanished** — they didn't; `--autostash` put them
back after the rebase. Check `git stash list` if something looks missing.

**Someone force-pushed the vault** — the one genuinely destructive operation.
Branch protection blocks it; without protection, treat it as an incident and
recover from any teammate's clone, since everyone has full history.

---
See also: `README.md` for setup · `docs/VERIFY.md` for smoke tests
