# 0011 — What the model is allowed to see

**Date:** 2026-09-07
**Status:** Proposed
**Depends on:** 0010

## What we decided

**A person's own words never leave their phone in bulk.** When a question needs private
data, the searching happens on the device, and only the few passages that actually answer
the question are sent — after the person has been told, once, that this is what happens.

## Why this is the first decision

Everything else in `0010` is about cost. This one is about whether anybody should trust
these apps at all.

The apps hold a scripture journal, a health record, private notes about family trips.
`docs/security.md` rule 6 already says never send what a journal entry said. The moment an
app can answer "what did I write about faith in April?", something has to read April.

## The three ways to do it

**Send it all to the server.** Simplest, best answers, and it means a person's spiritual
journal sits in a request log on a machine somebody administers. For a devotional app
whose users are trusting it with the most private thing they write, this is the wrong
trade at any quality level.

**Keep everything on the phone.** Only the on-device model ever sees private text, so
nothing can leak. It is also the weakest answer: the small model cannot do what the large
one can, and a person asking a hard question about their own notes gets a poor reply.

**Search locally, send the matches.** The device finds the handful of entries that bear on
the question and sends only those. Most of the journal never leaves. The person gets a
good answer to the question they asked, and nothing about the other three hundred entries
goes anywhere.

**We take the third**, with two conditions: the searching is always local, and no feature
does this before the person has been told plainly what gets sent.

## What that means concretely

- **Retrieval is on-device, always.** The search that decides what is relevant runs
  against SwiftData on the phone. A server never receives a query in order to search.
- **Only matched passages travel**, never a whole journal, never "recent entries" as a
  convenience.
- **Told once, plainly, before the first time** — in the person's words, not a policy
  link. Not a checkbox nobody reads.
- **Nothing about the content is logged.** `security.md` rule 6 already forbids it and
  this is the feature most likely to break it by accident.
- **The on-device tier answers with nothing sent at all**, which makes it the right
  default for anything it can handle (see `0010`).

## The foundation test

- **Scripture study** — "what have I written about the Atonement this year?" The case that
  makes this decision unavoidable, and the one with the most at stake.
- **Travel** — "what did we say about that restaurant in Rome?"
- **Fitness** — "when did I last squat 315?" Note this one often needs no model at all: it
  is a query, and the phone can answer it. Worth remembering before reaching for AI.
- **Student notes** — "what did the lecture say about the second law?"

4 of 4, and fitness is the useful reminder that some of these questions are database
questions wearing a natural-language coat.

## What it costs

**Worse answers to some questions.** A question whose answer is spread thinly across two
years of entries is one local retrieval will handle badly. Sending everything would answer
it better. We are choosing not to.

**Real work.** On-device retrieval good enough to find the right five entries is a genuine
piece of engineering, not a `LIKE '%faith%'` query.

**A consent moment**, which is friction, in a first-run flow that `PPOnboard` will have to
carry.

## Revisit when

- On-device models get good enough that tier 1 answers the hard questions too, at which
  point this decision gets simpler rather than harder.
- Someone asks for a feature that genuinely cannot work under this rule. That is the
  moment to have the argument again, in the open, rather than quietly widening what gets
  sent.
