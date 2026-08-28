---
name: cognitive-coverage
description: This skill should be used when the user wants to check whether they actually understand something they built with an agent — "quiz me", "cognitive coverage", "do I understand this", "test my understanding", "what did we just build" — or after a substantial feature lands and nobody has verified the human can explain it. Quizzes against the real code, grades honestly, and records a dated assessment in the knowledge vault.
version: 0.1.0
---

# Cognitive Coverage

Test whether the human can explain what their agent built, record the result with a
date, and make the gaps visible.

## Why this exists

Code review asks *"is this correct?"* Tests ask *"does it work?"* Neither asks the
question that decides whether a team can operate what it ships: **can a person
explain it without reading it again?**

Agent-built code fails this silently. It passes review because it *is* correct. The
gap only surfaces at 2am, or in an architecture argument, or when the person who
"wrote" it has to change it and discovers they are reading it for the first time.

Coverage here means the same thing it means for tests: which parts are exercised.
Not "did you feel confident" — **which specific parts of this system can you
actually account for.**

## The failure mode to avoid

**A quiz that everyone passes is worse than no quiz.** It converts an unknown gap
into a false belief, and it wastes the one moment the person was willing to be
tested.

Three ways this goes wrong, all of which you must actively resist:

1. **Softball questions.** "What does this function do?" is answerable from the
   name. Ask what would be answerable only by someone who understands: what breaks
   it, where the state lives, what happens on the second call, why this and not the
   obvious alternative.
2. **Accepting a vague answer.** "It handles the auth flow" is not an answer. If a
   response would fit three different implementations, it is a miss. Say so.
3. **Grading generously because the person is your user.** You are not being kind by
   passing them. Record what happened.

## Procedure

### 1. Establish what "it" is

Do not ask the user what they built — find out, then confirm. Guessing wrong wastes
their time; asking is work they already did.

- `git log` and `git diff` for the branch or the session's commits
- The newest `Sessions/` note in the vault, which should say what changed and why
- The files actually touched

State the scope in one line and ask them to correct it: *"Quizzing you on X — the
Y that does Z. Right scope?"*

If the change is trivial, say so and stop. A quiz about a typo fix teaches nothing
and trains them to skip the next one.

### 2. Read the implementation properly

You are about to grade answers, so you need the ground truth. Read the code, not the
diff summary. Note specifically:

- Where state lives, and what happens when two things touch it at once
- The failure paths, and which ones are silent
- Anything surprising: an ordering dependency, a fallback, a guard that exists
  because of a specific bug
- What it *does not* do, and what someone would wrongly assume it does

### 3. Build the question set

**Six to ten questions**, ordered easy to hard, covering these bands. Skip a band
that genuinely does not apply and say which:

| Band | The question it answers |
|---|---|
| **Shape** | What are the pieces and how does data move between them? |
| **State** | What is stored, where, and who else can change it? |
| **Failure** | What happens when it breaks, and would you find out? |
| **Boundary** | What is deliberately out of scope, and what breaks if you assume otherwise? |
| **Decision** | Why this approach and not the obvious alternative? What was traded? |
| **Change** | Where would you add the next feature, and what would you break? |

At least one question must be about something **surprising** in the implementation —
a guard, an ordering constraint, a fallback. That is where understanding actually
lives, and it is what nobody retains from watching an agent work.

### 4. Ask them one at a time

Never dump the whole set. One question, wait, respond, next.

- Do not hint before they answer.
- If the answer is partial, say what is missing and move on. Do not coach to a pass.
- If they say "I don't know", accept it plainly and move on. It is a data point, not
  a failure of manners. Do not soften it.
- After each answer, give the correct one in two or three sentences, with the
  `repo/path:line` where they can see it. **The teaching is the point** — the score
  is just the record.

### 5. Grade, honestly

Per question: **solid** / **partial** / **gap**. Per band: the same.

Rules that keep the grade meaningful:

- An answer that would fit a different implementation is **partial** at best.
- "I don't know" is a **gap**, never a partial.
- Do not average bands into a single percentage and lead with it. A person who is
  solid on shape and blank on failure modes has a specific, actionable problem, and
  a single number hides it.

### 6. Record it in the vault

Write to `Reference/Cognitive Coverage/<feature-slug>.md`, **newest entry first** so
the latest state is the first thing read.

Use the `Cognitive Coverage` template if the vault has one. If the note already
exists, **prepend a new dated entry — never overwrite the old one.** The history is
the value: it shows whether understanding improved after someone went and read the
code, or quietly decayed.

```markdown
---
type: cognitive-coverage
feature: <slug>
subject: <who was quizzed>
latest_assessment: YYYY-MM-DD
updated: YYYY-MM-DD
generated: { by: <your-model-id>, at: <ISO 8601 UTC> }
---

# Cognitive Coverage — <Feature>

Implementation: `repo/path` · Built: YYYY-MM-DD · Spec: [[ ]]

## YYYY-MM-DD — <subject>

| Band | Result | Note |
|---|---|---|
| Shape | solid | |
| State | partial | could not say what happens on a concurrent write |
| Failure | gap | |

**Gaps worth closing:** the specific thing, and where to read it.

**Questions asked:** <the set, so a re-test can be harder rather than identical>
```

Record the questions. A re-test that asks the same questions measures memory, not
understanding.

### 7. Close the loop

Say plainly which gaps matter and what to do about them:

- A **failure-band gap** on something in production is worth acting on today.
- A **decision-band gap** means the reasoning was never captured — that is a
  `Decisions/` note somebody owes, not a personal failing.
- A gap that is really missing documentation is a vault gap, not a coverage gap. Say
  which it is; they are fixed by different people.

## Notes

**Why the result is stored when canon's rule is "derived, never stored".** That rule
exists for values a tool can recompute — a token, a violation count, a trust tier.
This cannot be recomputed: it records what a specific person could explain on a
specific date. It is provenance of understanding, the same kind of fact as
`verified:`, and it is only meaningful with the date attached.

**One person at a time.** If two people need assessing, run it twice and record two
entries. A merged result tells you nothing about either of them.

**This is not a performance review.** It is a coverage report for a system, and the
subject is the person best placed to close the gaps. Frame the output that way — if
it reads as a scorecard on a colleague, nobody will ask for it a second time, and
the ones who most need it will be the first to stop.
