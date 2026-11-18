# The testing canon: a ratchet, and a gate that actually runs

`Reference/Testing/` answers "is this tested?" in writing. Same split as the design
canon, for the same reason: it holds **thresholds and pointers, never
measurements**. The percentage lives in the coverage report your suite already
writes; a number typed into a note is wrong the next day and still reads as
authoritative.

Two frozen fenced blocks, `test-suites` and `test-gates`, declare what exists:

```test-suites
- suite: api-python
  repo: api
  command: pytest -q
  report: coverage.xml
  format: cobertura
  metric: lines
  floor: 62
  status: enforced
```

```test-gates
- gate: api-ci
  repo: api
  workflow: .github/workflows/ci.yml
  job: test
  branches: [Dev]
  required: false
```

Two rules carry most of the value:

> **A floor is a ratchet, not a target.** Set it to the coverage you already have,
> rounded down. It only ever goes up.

A floor set to where you wish you were fails on day one, gets muted within a week,
and then measures nothing at all — while still looking like a control to anyone
reading the config.

> **A gate nobody made required is a decoration.**

A workflow that runs, reports, and cannot block a merge is advice. That difference
is invisible from a checkout, because branch protection is server-side, so
`required:` is a **human attestation** recorded with `canon-verify` and never
inferred. The Test Canon template gives "who can make a check required" its own
ownership row, because that is reliably the role nobody holds — and repo-admin
rights are rare enough that a team can merge a dozen PRs building gates and remain
completely ungated.

## `canon-test-audit`

```
$ canon-test-audit ~/code/api ~/code/web-app ~/code/svc
canon-test-audit 0.3.0
  canon: 3 suite(s), 2 gate(s) across 3 repo(s)

  VIOLATION TEST-FLOOR-BREACH            1
              web-frontend (web-app)  lines 17.6% is below the declared floor of 18
  VIOLATION TEST-GATE-BRANCH-MISMATCH    1
              api/.github/workflows/ci.yml  filter says 'dev', canon declares
                'Dev' — forge branch filters are CASE-SENSITIVE, so this gate
                has never run
  GAP       TEST-GATE-ADVISORY           1
              api-ci  required: false — a red run can still merge
  GAP       TEST-SUITE-UNDECLARED        1
              svc  tested (pytest.ini, tests/) but no test-suites row declares it

  measured  api-python             lines 62.4% (floor 62)
  measured  web-frontend           lines 17.6% (floor 18)
  coverage: report 2/2 · floor 2/2 · gate 2/2 · required 1/2 · absent 1
```

*Illustrative figures from made-up repos.*

**The branch-filter check is the one worth the whole tool.** Forge branch filters
are case-sensitive: a workflow filtered on `dev` against a branch named `Dev` runs
on nothing. No run, no failure, no signal, and a PR list that looks clean — for as
long as you let it. It is a string comparison, and it is the difference between a
gate and a decoration.

Everything else follows the same instincts as the design audit. **Derived, never
stored** — no note holds a percentage and there is no scorecard to keep current;
`--report` writes one dated `Outputs/` note carrying `stale_after: +30d`, so
`canon-trust --strict` fails on an audit nobody re-ran. **VIOLATION** is a fact you
can check by opening the cited file, **GAP** is a judgement call and can never fail
a build. `--strict` compares against a `.canon-test-baseline` rather than zero,
because on a repo with a long tail of untested code the only useful signal is
*did it get worse*. And
`--ratchet` prints the floor each suite could claim today — while deliberately
refusing to suggest a **lower** number, since lowering a floor is how a ratchet
quietly becomes a target.

Four things it will not do, each of them the design rather than an omission:

- **It never runs your tests.** Executing an arbitrary repo's suite is slow, needs
  that repo's dependencies, and is a code-execution surface pointed at whatever the
  canon happens to name. It reads the report your suite already wrote, and tells
  you how old it is.
- **It never computes coverage.** It parses cobertura, lcov, or an istanbul
  json-summary. An unrecognised format is a clean error, not a guess, because a
  guessed denominator is a confident wrong number.
- **It cannot see branch protection** — hence the attestation above. A tool that
  inferred it would produce confident false results, and a report with known-false
  lines is a report nobody reads.
- **It does not judge whether coverage is *meaningful*.** A test that merely
  imports a module takes it from 0% to 100%. That trap is a documented caveat for
  the human setting the floor, not a faked check.

It is **read-only in every repo it scans**, asserted by a test, and it is in no
pre-commit hook: it scans code repos, not the vault. It measures. Enforcement is a
required status check, set in the forge by somebody with admin.

## The other half of `CLAUDE.md`

canon writes `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` and four more from one
template, so they cannot drift. Those files tell an agent about the vault — and for
a long time they said nothing about **the repo it is standing in**.

So the template also ships a `## This repo` skeleton: build and run, test,
architecture in three sentences, and gotchas. **Real headings, deliberately, rather
than a comment** — an empty section is visible, and an agent can say nobody has
written this down. The same words in an HTML comment are invisible in every
rendered view and get skipped for years.

```
/repo-context
```

fills it in from the repo itself — manifests, the CI workflow, compose files, env
templates — and **cites where each command is defined** rather than asserting one
it never saw, because a confidently wrong build command is worse than a blank
section. As a byproduct it emits the `test-suites` and `test-gates` rows above:
you have just read the test config and the workflow, which is exactly what the
canon needs, so it is produced then instead of becoming a second chore nobody does.
If the workflow's branch filter disagrees with what git actually calls the branch,
it reports that as a finding instead of quietly writing the working one down.
