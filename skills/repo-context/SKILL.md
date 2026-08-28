---
name: repo-context
description: This skill should be used when a repo's CLAUDE.md / AGENTS.md has an empty "This repo" section, or when the user asks to document how a repo is built, run or tested — "fill in the repo context", "repo-context", "document this repo for agents", "why is there no build command written down". Derives the build, run and test commands from the repo itself, verifies them rather than guessing, and emits the vault's testing-canon rows as a byproduct.
version: 0.1.0
---

# Repo Context

Write down how this repo is built, run and tested — from the repo, not from
memory — into the `## This repo` section that canon installs into `CLAUDE.md`,
`AGENTS.md` and every other runtime instruction file.

## Why this exists

canon guarantees every wired repo has an instruction file. It cannot guarantee
anybody wrote the repo-specific half, and the default state of that half is empty.

So every agent that lands in the repo re-derives the same five facts — the build
command, the test command, the port, the one env var with no default, the service
you have to start first — and none of them writes it down, because none of them was
asked to. The cost is invisible per session and enormous in aggregate.

The output of this skill is the part of the file that stops that.

## The failure mode to avoid

**A confidently wrong command is worse than a blank section.** A blank section makes
an agent look; a wrong one makes it try, fail, and start debugging the wrong thing.

So the rule for this whole skill is: **cite where each command is defined, and do
not write a command you have not seen declared somewhere.** "`pnpm test` — defined
in `package.json:12`" is a fact a reader can check. "`pnpm test`" is a guess wearing
a fact's clothes. If a manifest declares nothing, write that: *"no test script is
defined in this repo"* is true, useful, and immediately actionable.

Where it is safe and fast, **run the command** and say that you did. Where it is
not — anything that starts a long-running server, touches a database, deploys,
installs into a shared environment, or costs money — do not run it. Say it is
undeclared-but-unverified instead.

## Procedure

### 1. Find the instruction file and confirm the section is empty

The body is identical in `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`,
`.github/copilot-instructions.md`, `.windsurf/rules/knowledge-vault.md` and
`.clinerules/knowledge-vault.md`, because `install.sh` generates all of them from
one template. **Whatever you write must go into every one of those that exists in
this repo** — that is the whole reason they are generated rather than hand-written,
and the drift starts the first time somebody updates only `CLAUDE.md`.

If the section already has content, do not overwrite it. Read it, check it against
the repo, and propose corrections for the lines that are now wrong. Someone chose
those words.

### 2. Read the repo, in this order

Cheapest and most authoritative first:

1. **Manifests and task runners** — `package.json` scripts, `pyproject.toml`,
   `Makefile`, `justfile`, `Cargo.toml`, `go.mod`, `composer.json`, `mise.toml`.
   These are declarations, so they are evidence.
2. **The CI workflow** — `.github/workflows/`, `.gitlab-ci.yml`, `azure-pipelines.yml`.
   **This is the best source in the repo and the most commonly skipped.** CI is the
   one place the commands are known to work, on a clean machine, in order,
   including the setup steps a human has long since forgotten they did once.
3. **Container and compose files** — `Dockerfile`, `docker-compose.yml` for ports,
   entrypoints and the services that must be up first.
4. **Env templates** — `.env.example`, `.env.sample`, settings modules. Every
   variable with no default is a gotcha candidate. **Never copy a value, only a
   name** — the vault and these files are git-tracked, and a real secret in either
   is permanent.
5. **The entry point** — whatever `main`, `app`, `index` or the console-script
   points at. One file, to name the boundaries honestly.
6. **Test config** — `pytest.ini`, `[tool.pytest]`, `jest.config.*`,
   `vitest.config.*`, and where the coverage report is written to.

### 3. Write the four subsections

Keep the whole instruction file under ~200 lines; it loads in full on every
request. If something needs more room, write a vault note and link it.

- **Build and run** — exact commands, each with the file that defines it, plus the
  local port.
- **Test** — the whole suite, a single test, and how coverage is produced.
- **Architecture in three sentences** — entry point, the one or two boundaries that
  matter, where the data lives. Three sentences. Not a diagram.
- **Gotchas** — the highest-value part. The things that are not visible from the
  code: a migration that must be applied by hand, an env var with no default, a
  test that only passes from the repo root, a service that must be started first.
  Write what surprised *you* while reading. If nothing surprised you, say the
  section is empty rather than padding it — a padded gotchas list trains people to
  stop reading it.

### 4. Emit the testing-canon rows

This is the step that makes the skill worth more than a docs chore. You have just
read the test config and the CI workflow, which is exactly what the vault's testing
canon needs — so produce it now rather than making it a separate task nobody does.

Print, for the user to paste into `Reference/Testing/<Name> — Current State.md` in
the vault (see the Test Canon template for the full contract):

```test-suites
- suite: <kebab-slug>
  repo: <this-repo-name>
  command: <the command you verified>
  report: <path the suite writes its coverage report to>
  format: cobertura
  metric: lines
  status: advisory
```

```test-gates
- gate: <kebab-slug>
  repo: <this-repo-name>
  workflow: .github/workflows/ci.yml
  job: <the job name>
  branches: [<EXACTLY as the workflow spells them>]
  required: false
```

Four rules for these rows, each of which the audit will otherwise catch later:

- **`branches:` verbatim and case-sensitive.** Copy from the workflow's `on:`
  filter, character for character. Then compare it to what git actually calls the
  branch — `git branch -r`. A filter on `dev` against a branch named `Dev` runs on
  nothing at all and looks green. If they differ, **you have found a live bug**;
  report it to the user as a finding, do not quietly write the working one.
- **Omit `floor:`.** You are reading config, not measuring. The floor is the
  coverage that already exists, and `canon-test-audit --ratchet` prints it once a
  report exists. Inventing one sets a target instead of a ratchet.
- **`required: false` unless a human has confirmed otherwise.** Branch protection
  is server-side and not knowable from a checkout. Never infer it.
- **`report:` is the summary file, not the raw dump.** istanbul writes both;
  `coverage-final.json` has no totals in it.

If this repo has no test suite at all, that is a row too — `status: absent` with a
note. Recorded absence is worth more than silence.

### 5. Hand it back as a proposal

Say what you verified by running, what you took from a declaration without running,
and what you could not determine. Then let the user correct it. The point of this
file is that it is *trusted*, and trust comes from a teammate having read it — not
from an agent having generated it.

Do not add a `verified:` entry anywhere on your own behalf. That field means a human
confirmed it.
