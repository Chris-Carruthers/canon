# Getting Started — No Terminal

For anyone who doesn't use the command line and doesn't want to. You'll install two
free apps, click a few buttons, and be reading everything your team knows.

**About 15 minutes. No commands. Nothing to type except your password.**

> [!NOTE]
> **Setting this up for your team?** Fill in the two blanks below before you share
> this page — the repository name and the folder name — and delete this box. Everything
> else works as written.
>
> - Your vault repository: `<your-org>/<your-vault-repo>`
> - The folder name to use locally: `<your-vault-folder>`

> [!IMPORTANT]
> **Before you start** you need a GitHub account and access to your team's vault. You'll
> know it worked when the repository page loads instead of showing "404." That's the
> only prerequisite — ask whoever set it up if you're not sure.

## Three words you'll see, in plain English

The apps use some jargon. It's only three ideas:

| Word | What it means |
|---|---|
| **Fetch / Pull** | *Get everyone's latest notes.* Like refreshing your email. |
| **Commit** | *Save a snapshot of your changes,* with a short note about what you did. |
| **Push** | *Share your saved changes with the team.* Until you push, nothing you wrote is visible to anyone else. |

That's genuinely it. You can ignore everything else the apps show you.

---

## Step 1 — Install GitHub Desktop

This is the app that copies the notes to your computer and keeps them up to date.
Free, made by GitHub, and you never see a command line.

1. Go to **[desktop.github.com](https://desktop.github.com)** and download it.
2. Open it. Click **Sign in to GitHub.com** and sign in.
3. When it asks about "Git config," click **Finish**. The defaults are correct.

## Step 2 — Copy the notes to your computer

1. Choose **File → Clone repository** from the top menu.
2. Click the **GitHub.com** tab. You'll see the repositories you can access.
3. Find and select your team's vault repository.
   *Not listed? You don't have access yet — ask, then come back.*
4. Under **Local path**, click **Choose…** and pick where it should live.
5. **Use the exact folder name your team agreed on.** Other tools look for that name,
   so this is worth getting right rather than guessing.
6. Click **Clone**.

It may take a minute or two depending on how many notes there are. When the progress
bar finishes you're done — the notes are now an ordinary folder on your computer.

## Step 3 — Install Obsidian

This is the app you'll actually read in. Also free, including for work use.

1. Go to **[obsidian.md/download](https://obsidian.md/download)** and install it.
2. Open it. On the welcome screen choose **Open folder as vault**.
3. Select the folder you just cloned.
4. If it asks whether you trust the folder, click **Trust author and enable plugins**.

You should now see the vault's folders listed down the left side.

## Step 4 — Learn four things and you're fluent

Genuinely four. Everything else is optional.

| To do this | Press or click |
|---|---|
| **Jump to any note by name** | `Cmd + O` (Mac) or `Ctrl + O` — start typing, it finds it. The fastest thing in the app. |
| **Search everything** | `Cmd + Shift + F` |
| **See what links to the note you're reading** | The **Backlinks** panel on the right. This is how you find context you didn't know to look for. |
| **See the shape of what the team knows** | The **graph** icon in the left sidebar |

**Start at `Home.md`** if the vault has one, or `Vision/` otherwise.

## Step 5 — Getting everyone's updates

Teammates add notes constantly. To get them:

1. Open **GitHub Desktop**.
2. Click **Fetch origin** at the top. If there are updates the button becomes
   **Pull origin** — click that too.
3. Switch back to Obsidian. The new notes are simply there. No restart needed.

**Do this whenever you sit down to read.** Notes you haven't pulled are notes you
don't have — and confidently reading a stale answer is the main thing that goes wrong.

---

## If you want to write notes too

Reading is most of the value and you can stop above. But if you want to add or edit:

1. **Write in Obsidian.** Type normally; it saves as you go.
2. **Open GitHub Desktop.** Your changes appear in the left panel.
3. **Describe what you did** in the *Summary* box at the bottom left. A short sentence
   is plenty — *"Added notes from the Tuesday planning call."*
4. Click **Commit to main**.
5. Click **Push origin** at the top.

Steps 4 and 5 together are "save" and "share." Nothing you write is visible to anyone
until you push.

> [!WARNING]
> **What must never go in a note**
>
> - **Personal or confidential information about real people.** Not even if it looks
>   anonymised. If your team works in a regulated field, whoever set this up will have
>   specific rules — ask for them, and treat them as absolute.
> - **Passwords, keys, or tokens.** If it looks like a long random string that lets
>   someone log into something, it doesn't belong in a note.
>
> These matter because the notes keep permanent history. Something written and then
> deleted is still recoverable, so the fix is not writing it in the first place.

**There may be a safety net, and you should know its limits.** If whoever set this up
installed the commit check, anything that looks like a password or an ID number is
blocked before it can be saved. That check is good at spotting **credentials** and
**poor at spotting information about people written as ordinary prose** — it can't
recognise a story about someone. So it catches accidents. The rules above are still
yours to follow.

Ask whether your team also enabled their host's own secret scanning. On GitHub that's
a repository setting, and on private repositories it can require a paid plan — worth
confirming rather than assuming.

## When something looks wrong

**"There's weird text in a note with `<<<<<<<` in it."**
Two people edited the same lines and both versions are being shown to you. Don't try
to clean it up — **ask**. It takes someone familiar with git two minutes, and guessing
can lose someone else's work.

**"GitHub Desktop is showing an error I don't understand."**
Screenshot it and ask. Don't click buttons to make it go away — that's how work gets
lost. Nothing is harmed by waiting.

**"My push was rejected."**
Usually someone else pushed first. Click **Fetch origin**, then **Pull origin**, then
**Push origin** again. If it still refuses, ask.

**"I can't find a note I know exists."**
`Cmd + O` searches names; `Cmd + Shift + F` searches inside every note. If neither
finds it, you may not have pulled recently — try Step 5.

## What you can safely ignore

- **Branches.** You'll only ever use `main`. Don't create others.
- **Hidden folders** like `.canon` and `.obsidian`. Machine plumbing.
- **Everything else GitHub Desktop shows you.** Fetch, Commit, Push. That's the app.

---

Curious how it works, or want your AI assistant reading the vault too? That's the
[main README](../README.md) — but you don't need any of it to read and contribute notes.
