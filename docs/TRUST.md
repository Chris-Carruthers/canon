# Trust: telling an agent draft from a checked fact

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

```bash
canon-trust --tier unverified               # list only one tier
canon-verify --stale-after 2026-12-01 <note>  # confirm it, and say when to re-check
canon-verify --actor process:nightly <note>   # record a non-human check
```

Your identity comes from `git config user.email`; set `CANON_ACTOR` to override it.

Every key is optional and nothing is ever rejected for lacking them — absence just
carries meaning. The shape follows the
[Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md),
so a canon vault stays legible to other OKF-aware tooling.
