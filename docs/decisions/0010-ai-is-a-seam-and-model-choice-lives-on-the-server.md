# 0010 — Every app is AI-native, and no app knows which model it is using

**Date:** 2026-09-07
**Status:** Proposed

## What we decided

Every app on this foundation can use AI. **No app ever names a model.** An app says what
*job* it needs done and how demanding that job is; something else decides what answers it.

That decision lives **on the server**, not in the app, and not in this package.

A ninth module, `PPIntelligence`, holds the seam the apps talk to.

---

## The foundation test

*Would at least three of the four planned apps want this? Name them.* Tested hardest
against fitness.

- **Travel** — "what should we do with a free afternoon in Rome", summarising a day of
  notes into something worth keeping, turning a photographed menu into a translation.
- **Scripture study** — this *is* the app. Spindle generates a study from a passage:
  background, principles, cross-references, questions, an invitation to act.
- **Fitness** — why a lift has plateaued, what to do differently next week, a plan built
  from what actually got logged. Fitness is numbers over time, and the thing a person
  wants from numbers over time is *an explanation*. It is not the weakest case here; it
  may be the strongest.
- **Student notes** — turning a lecture into flashcards, a quiz, or a summary before an
  exam.

4 of 4, and unusually evenly.

## Why the app must not name the model

**Because apps ship on their own schedule, and models do not.** `AGENTS.md` already says
apps depend on a *tagged version* of this package so a change here cannot break four
shipped apps at once. Model choice has the same shape and a worse clock: the useful
models change every few months, and getting a new one into four apps means four releases
through App Review — days each, at best.

If the model is named in the app, switching costs a release. If it is named on the
server, switching costs an edit. That single difference decides where this logic goes,
and it is not close.

It also means an app built today keeps working when a model it has never heard of
replaces the one it was built against.

## What the app says instead

An app describes the **job** and how **demanding** it is:

- *What kind of work is this?* Sorting something into a category. Summarising. Writing
  something long. Reasoning through a hard problem.
- *How demanding is this instance of it?* Routine, or genuinely hard.

Those two together are what the server routes on. The app never learns the answer, and
never needs to.

## Three tiers, and the cheapest one is free

Choosing the right model is not only about picking a cheaper cloud model. There are three
places work can happen, and the first one is the one people forget:

1. **On the phone.** iOS 26 ships an on-device model through Apple's Foundation Models
   framework. It is free, works in airplane mode, and nothing leaves the device — which
   is exactly the promise the rest of this foundation is built on. For sorting, tagging,
   short summaries and rewrites, this should be the default, and no server should be
   involved at all. *(Not yet verified against the shipping SDK — see what this costs,
   below.)*
2. **A small cloud model**, for work the phone cannot do but that does not need the best.
3. **The most capable model**, for the work that actually earns it.

An app that sends "give this note a title" to a frontier model over the network has made
two mistakes, not one: it spent money it did not need to, and it broke offline.

## The finding that changes the shape of this

**Before building a model cascade, measure one model at a lower effort setting.**

Current guidance from Anthropic's own documentation is explicit about this, and it cuts
against the obvious design:

- Lower effort on a current model often matches or beats a *previous-generation* model at
  high effort. The cheap way to spend less is frequently the same model thinking less,
  not a different model.
- **Prompt caches are model-scoped.** A cascade across three models forfeits cache reuse
  between them. A system that switches models to save money can spend more than one model
  that keeps its cache warm.
- Judge cost per *completed task*, not per request. A cheaper call that needs two more
  turns to get there is not cheaper.

So the policy the server holds is not only "which model" — it is **"which model, at what
effort."** Effort is the first lever, model is the second, and the on-device model is the
zeroth. A design that only swapped models would have optimised the wrong variable.

## Swapping vendors

The seam is vendor-neutral by construction: an app describes a job, so nothing in any app
mentions Anthropic, or any other provider. Vendor SDKs live on the server, behind the
same policy that picks the model.

Being honest about the limit: **a seam makes swapping possible, not free.** Prompts are
tuned per model family, and a prompt that works well on one vendor's model will need
re-tuning on another's. What this buys is that the re-tuning happens in one place, on a
server, rather than in four apps that each have to ship.

## What we are not doing

- **No API key on a device, ever.** `docs/security.md` rule 1. This is the reason the
  cloud tiers need a server at all, and it is not negotiable.
- **No routing logic in the Swift package.** `PPIntelligence` is a seam and a vocabulary
  for describing jobs. It holds no model names, no prices and no policy.
- **No cascade until effort tuning has been measured.** See above.
- **No streaming yet**, and no tool use through this seam. Both are real and both should
  wait until one app needs them, so the shape is designed against a use rather than a
  guess.

## What it costs

**A ninth module**, where `AGENTS.md` and `README.md` both say eight. That is a change to
a settled structural decision and should be made deliberately or not at all.

**A server**, which `docs/decisions/0002` was proud not to need. Local-first survives
this — every app still reads and writes its own data offline, and tier 1 works with no
network at all — but "no server to run" becomes "one small server to run", and that is a
real cost in money, attention and a thing that can be down at 3am.

**An unverified claim.** The on-device tier above rests on Apple's Foundation Models
framework working the way the announcement describes. Nobody here has run it. If it does
not hold, tier 1 collapses into tier 2 and the cheapest work gets more expensive.

## Revisit when

- The first app measures real traffic, and we learn whether effort tuning alone was
  enough.
- Apple's on-device model is tried in anger.
- A second vendor is actually swapped in, which is the only real test of whether this seam
  was drawn in the right place.
