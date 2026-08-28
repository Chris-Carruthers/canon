---
type: spec
title: "<Title>"
status: draft            # draft | accepted | shipped | superseded
spec_revision: 1
author: "<name>"
created: YYYY-MM-DD
updated: YYYY-MM-DD
generated: { by: <actor>, at: YYYY-MM-DDTHH:MM:SSZ }
---

<!--
Voice: skills/house-voice/references/product-spec.md — your own map wins: Reference/Writing/House Voice.md
File as: Specs/<slug>.product-spec.md    Companion ops doc: Handoffs/<slug>.handoff.md

WHY THIS SHAPE. The spec is intent — what and why — and it stays the single
source of truth. Tickets, PRs and handoffs point back to it by path rather than
restating it, because restated intent drifts.

The five sections below are in a deliberate order and each has a job. Keep them
in order and do not merge them:
  Problem     — the pain, with no solution in it
  Hypothesis  — the causal bet, with no metrics in it
  Scope       — the boundary, including what you decided NOT to do
  Acceptance  — pre-launch pass/fail gates
  Success     — post-launch behaviour change

The fenced blocks give you machine-checkable structure. IDs are sequential per
prefix (AC-1, AC-2… / SM-1, SM-2…). If you write a validator, that is what it
reads; if you do not, the structure still keeps humans and agents honest.

Delete the sections that do not apply — an empty ritual section is worse than
an absent one. Keep this file under 500 lines.
-->

## Problem

Who has the pain, what its nature is, and why it matters now. Be specific about
who — "users" is not a who. No solutions in this section.

## Hypothesis

The causal bet: what ships, for whom, what behaviour changes as a result, and
why you believe that. No metrics, thresholds, or feature lists here.

## Scope

```scope
in:
  - what ships
out:
  - explicitly excluded
cut:
  - considered and deliberately dropped (record this — it is the most
    frequently lost and most frequently re-litigated information in a spec)
```

## Acceptance Criteria

Pre-launch pass/fail gates. Prose alone is not a criterion — each item must be
checkable by someone who did not write it. Tag non-functional gates in the
criterion text so they are greppable.

```acceptance-criteria
- id: AC-1
  criterion: <functional gate — observable, binary>
- id: AC-2
  criterion: "Security — <authn/authz, encryption, tenancy, audit requirement>"
- id: AC-3
  criterion: "Latency — p95 < Xms, p99 < Yms under <stated load>"
```

<!-- Delete this block unless the feature has AI/model behaviour to evaluate. -->
```ai-evals
- id: EVAL-1
  type: exact_match          # exact_match | contains | regex | llm_judge | human_review
  evaluator: deterministic   # deterministic | llm | human
  pass_threshold: 1.0
  cases:
    - input: <scenario>
      expected: <required outcome>
```

## Success Metrics

Post-launch behaviour, not launch activity. "Shipped" is not a metric. Mark
whether each target is committed or still provisional — a provisional target
needs a named owner, or it will never become committed.

```success-metrics
- id: SM-1
  metric: <business or user outcome>
  target: ">= X%"
  target_status: committed        # committed | provisional
  window: <time period>
- id: SM-2
  metric: availability
  target: ">= 99.9%"
  target_status: provisional
  target_owner: "<name>"
  window: monthly
```

## Compliance & Data Handling

<!-- Delete entirely if this feature touches no regulated or sensitive data. -->

**Data classification:** what class of data this touches (public / internal /
confidential / personal / regulated).

**Regime applicability.** State status *honestly*. Never claim a certification
or authorization you do not hold — a spec that overstates compliance posture is
worse than one that omits it, because someone downstream will rely on it.

| Regime | Applies? | Status | Gap / note |
|---|---|---|---|
| <e.g. GDPR / CCPA> | only if <condition> | in scope / n/a | — |
| <e.g. SOC 2 Type II> | yes | in scope, **not yet certified** | evidence: <where> |
| <e.g. sector regime> | only if <condition> | **target, not pursued** | no authorization |

**Safeguards:** encryption in transit and at rest · authn/authz and tenant
scoping · audit logging and retention · data residency · least privilege.
Anything that is a hard gate must also appear as a tagged Acceptance Criterion —
otherwise it is an aspiration, not a requirement.

**Honest gaps:** what is explicitly *not* done yet.

## Service Levels

<!-- Mark N/A with a reason for non-service work (pure UI, prototype, docs). -->

| Objective | Target | Notes |
|---|---|---|
| Availability | 99.9% / month | error budget ≈ 43 min/month |
| Interactive latency | p95 < 500ms, p99 < 1s | per endpoint |
| Error rate | < 0.5% | 5xx / total |
| Rate limit | TBD | per tenant/user |
| Degradation | <behaviour when a dependency is down> | — |

Pre-launch gates belong in Acceptance Criteria; ongoing adherence belongs in
Success Metrics. Write `TBD — ratify` where the load model is genuinely unknown
rather than inventing a number.

## Risks

What could fail, how you would detect it, and the fallback.

## Open Questions

Track these here, where they stay attached to the intent that raised them.
- [ ] ...

## Rollout

Sequencing, feature flags, environment gates, who is affected and when.

## Relations

- Project: [[ ]]
- Handoff: [[<slug>.handoff]]
- Decisions: [[ ]]

<!--
Revision log — bump spec_revision and updated on meaningful intent changes:
- r1 (YYYY-MM-DD) — initial.
-->
