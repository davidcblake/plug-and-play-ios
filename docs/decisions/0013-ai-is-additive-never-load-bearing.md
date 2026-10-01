# 0013 — AI adds to a screen that already works

**Date:** 2026-09-07
**Status:** Proposed
**Depends on:** 0010

## What we decided

**No screen may require a model to function.** Every screen works with the phone in
airplane mode and no model available. AI makes a working screen better; it is never the
reason a screen works.

## Why this needs writing down

`AGENTS.md` says every feature works fully offline. Cloud AI cannot. Those two facts sit
in the same repository and the contradiction does not announce itself — it arrives as one
screen, built on a good day with good signal, whose empty state says *"Preparing your
study…"* and whose behaviour on a plane is a spinner.

Nobody decides to break local-first. It gets broken one screen at a time by people who had
signal.

## What the rule forbids, concretely

- A screen whose **only** content is generated.
- An empty state that waits on a model instead of saying what is there.
- A **spinner** on the path to reading something already on the device. `0002` already
  says this; AI is the most likely thing to violate it.
- A save, an edit or a delete that goes through a model.

## What it permits, and how the good version works

The strongest pattern is **generate ahead, read locally**. `0010` notes that batch
generation costs half as much; it is also the answer here. Tomorrow's study is generated
overnight, synced down, and **read from disk** — instant, offline, no spinner, half price.
The app is not waiting on a model. It is reading a file, which is what this whole
foundation is built to do well.

Where something genuinely has to be generated on demand — a question asked right now — the
screen behaves like any other screen that is fetching something optional: it is already
useful, and the generated part arrives into a place that was not empty.

And the on-device tier from `0010` is not affected by any of this. It works on a plane.

## The foundation test

Not the usual shape — this is a rule, not a feature — but it binds all four:

- **Travel** — the app is needed most in Rome on bad roaming. This is the app the whole
  local-first argument was built on, and the one where an AI feature would do the most
  damage by pretending it is essential.
- **Scripture study** — read on a plane, in a chapel, in a canyon. Spindle's own promise
  is that studies stay readable offline; generate-ahead is what keeps that true once AI is
  involved.
- **Fitness** — logged in a basement gym with no signal.
- **Student notes** — a lecture hall with four hundred people on one access point, which
  is functionally airplane mode.

## What it costs

**Some good ideas are not allowed.** A screen that would be genuinely delightful with a
model and useless without it cannot be built. That is the constraint doing its job, and it
will be annoying at least once.

**Generate-ahead is more work than generate-on-demand.** Something has to decide what to
prepare, prepare it, and sync it down before the person opens the app.

**Guessing wrong wastes money.** Content generated ahead and never read is paid for. That
is a real cost, and it is smaller than the cost of an app that fails when the signal does.

## Revisit when

An on-device model can do the work that currently needs the network. That does not weaken
this rule — it makes it cheap to keep.
