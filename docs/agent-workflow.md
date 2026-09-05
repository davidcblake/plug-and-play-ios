# How the AI team works

Four AI helpers work on this project: Claude, Codex, Gemini and Grok. This is how work
moves between them without anyone copying and pasting.

**Current status (2026-09-05): Claude, Grok and Gemini are connected. Codex is not.**
Claude via `.github/workflows/claude.yml`, Grok via `grok-review.yml`, Gemini via
`gemini-auditor.yml`. Codex has a seat below but nothing wakes it — its account ran out
of credit, and no workflow was ever written for it.

Two honest limits on what is wired up:

- **Gemini only sees the diff**, not the whole repository, so drift between a changed
  file and an unchanged one can still slip past. A periodic whole-repository sweep is the
  fix and has not been built.
- **Nobody is filling Codex's seat.** Grok covers per-line review, Gemini covers
  cross-file drift, and bug-hunting-by-a-second-opinion is simply not happening right
  now. Do not read three green checks as three kinds of scrutiny.

## Why four instead of one

Not to divide the work up four ways. **Because they make different mistakes.**

Four AIs from four companies have genuinely different blind spots. That is the entire
value, and it only pays off if you use it deliberately: one writes something, a
*different* one tries to break it. Split features between them instead and you get four
styles that don't fit together, and you'll spend your review time reconciling them.

## The four seats

Each seat has exactly one owner. Shared ownership is no ownership.

**Claude — the Builder**
Designs how the pieces fit together and writes most of the real code. Takes the large,
messy jobs that touch many files at once.

**Codex — the Inspector**
Reviews work it did not write. Hunts for bugs, missed edge cases, and things that will
break later. Writes tests designed to prove the Builder wrong.

**Gemini — the Auditor**
Reads the whole project at once to catch inconsistencies and drift. Keeps the
documentation honest. Checks work against Apple's current rules and design guidelines.

**Grok — the Challenger**
Asks whether settled decisions are still the right ones. Argues against the existing
design. Checks that we are using the current best approach rather than a familiar old one.

Repetitive, low-judgement work goes to whichever seat is cheapest for that particular
job. Decide per task, not on a rota — the point is cost, not fairness.

## The one rule that cannot bend

> **Whoever writes something never reviews it.**

Not "usually." Not "unless it's faster." Never. The moment the Builder can also approve
its own work, you are paying for four AIs and getting one opinion.

Everything else in this document is a guideline. This is not.

## Why the Challenger seat exists

In July 2026 this project made an architecture decision that went unexamined until
September, resting on an assumption about Apple's rules that nobody had tested. The whole
approach had to be abandoned.

Someone's actual job is now to ask "is this still right?" That's what the seat is for.
Anyone may challenge a decision at any time — but one seat is *required* to.

## How a job moves

The job card is a GitHub issue. The label on it says whose turn it is. Nothing is copied
anywhere; the card and its comments are the whole record.

1. **You** write the job card and put the Builder's label on it.
2. **The label wakes the right AI**, which reads the card and every comment on it.
3. **It works**, opens a proposal, comments what it did and what it was unsure about,
   then swaps its own label for the next seat's.
4. **The next AI wakes** and picks up with full context.
5. **A Mac only wakes up at the end**, once review has passed, because Mac time costs
   roughly ten times what an ordinary build computer costs.
6. **You approve or send back.** Your comment restarts the loop.

## What a good job card contains

- **What** needs to be done, specifically
- **Which seat** starts it
- **What to read first** — always `AGENTS.md`, plus anything specific
- **What "done" looks like** — how you'd check it
- **What not to do** — the boundaries

Vague job cards produce vague work and cost more, because the AI spends turns guessing.

## Keep job cards small

A card asking for seven modules and five documents at once will sometimes fail at 80%,
and you will have paid for 80% with little to show. Three smaller cards each finish, each
land visibly, and a failure only costs the piece it was on.

Big card = fewer round trips. Small card = fails cheaply. Small usually wins.

## The six-round limit

If a card bounces between AIs six times, all the labels come off and it gets marked
**needs a human**.

Two AIs politely handing a job back and forth all night is the most common way a setup
like this wastes real money. If it isn't solved in six passes, it has been misunderstood,
and a seventh pass won't fix that. You will.

## Rules for everyone

1. Read `AGENTS.md` before doing anything.
2. Never change the foundation without review by a different seat.
3. Anything touching security or money gets an extra check.
4. `docs/roadmap.md` is the source of truth for status, updated in the same commit.
5. Speak up if something looks wrong or outdated, even when it isn't your seat's job.
6. Dave is in charge. When a decision is his to make, ask — don't assume.
