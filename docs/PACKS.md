# Template packs

`canon-init-vault` ships a small core of note templates. Everything else is a pack you
ask for.

```
canon-pack list
canon-pack add engineering
canon-pack remove engineering
canon-init-vault --pack product-ladder --pack engineering /path/to/vault
```

## Why the core is small

The core set has to be right for every team that installs canon, so it holds only the
documents almost everybody writes. Adding a template that four teams in ten would use
is not free: it lands in the other six vaults, where it makes `Templates/` harder to
read and quietly implies somebody ought to be filling it in.

This is the same rule the design canon states about component notes — *thirty notes for
thirty primitives is boilerplate, not knowledge*. A folder is a recommendation. Make it
long enough and it stops being one.

## The packs

### `product-ladder` — 4 templates

One-pager · PR-FAQ · Six-pager · Shape Up Pitch

The cheap rungs below `Product Spec`. The core ships one product document and it is the
heavyweight one: five fixed sections, machine-checkable blocks, sequential IDs. Right
for funded work, wrong as the first artefact for an idea nobody has agreed on — writing
it takes long enough that finishing feels like progress, and it produces acceptance
criteria for something that may not survive its first reading.

**Skip it if** your team already has a product-document format its readers expect. Two
formats for the same job is worse than either.

### `engineering` — 4 templates

RFC / Design Proposal · Architecture Overview · Runbook · Postmortem

The gap that matters most here is the **RFC**. canon's `Decision` template is an ADR:
retrospective by design, recording what was chosen after the choosing. There is no core
template for the document that does the *persuading* — the Oxide RFD, the Go proposal,
the design doc that goes round for two weeks before anyone writes code. Teams without
one either decide in chat and lose the reasoning, or write an ADR pre-emptively and
pretend the argument already happened.

An accepted RFC usually produces a `Decisions/` note. Keep both: the RFC is the
argument, the ADR is the durable record of what it settled.

**Skip Runbook and Postmortem if** you run nothing in production. Delete them after
installing rather than leaving them empty — an unused template still signals that
somebody should be filling it in.

### `research-craft` — 3 templates

Research Findings · Design Critique · Content & UX Copy Guide

Three documents that shape what gets built without describing it. Without
**Research Findings**, research survives as remembered anecdote — somebody says "users
hate that flow" and nobody can reconstruct whether that was six people or one loud one.
**Design Critique** stops the same objection being raised in three separate reviews.
**Content & UX Copy Guide** stops interface text being negotiated per string.

**Skip it if** nobody does research. The honest move is to say so in a `Reference/` note
rather than install a template that stays empty and implies otherwise.

## What `add` and `remove` actually do

**`add` never overwrites.** An existing file is left alone and reported, exactly like
`canon-init-vault`. Re-running is safe and is how you pick up new templates after
upgrading the kit.

**`remove` only deletes what it shipped.** A file goes only if it is still
byte-identical to the template in the kit. The moment somebody has edited it, it is
their note and not ours — it is kept and reported. Without that rule an `add` typo
followed by a `remove` would silently destroy somebody's work, which is not a trade any
convenience is worth.

## Voice ships regardless

The `house-voice` reference files for pack templates live in the kit and are always
present, installed pack or not. A skill costs nothing until it loads, so gating them
saves nothing — and a template arriving without the guidance for how to write it is the
worse failure.

## `canon-pack` is not vendored into vaults

Unlike `canon-scan` and the rest, it is not self-contained: it copies files out of the
kit's `templates/packs/`, which is not in your vault. A vendored copy would resolve an
empty pack directory and report "no packs available", which reads as a fact about canon
rather than a broken install. It refuses to run instead, and says why.

## Adding a pack

A pack is a directory. There is no registry to update.

```
templates/packs/<name>/
  pack.md              # starts with a "> one-line description" that canon-pack list reads
  Templates/*.md       # copied into <vault>/Templates/
```

Ship a `skills/house-voice/references/<doctype>.md` alongside each template and add the
row to the skill's table — CI asserts that every template points at a reference file
that exists **and** that every reference file is reachable from the skill, so a pack
with orphaned voice guidance will not merge.
