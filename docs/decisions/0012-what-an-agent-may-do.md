# 0012 — What an agent may do, and how it is undone

**Date:** 2026-09-07
**Status:** Proposed
**Depends on:** 0010

## What we decided

An agent may **propose** anything and **do** only what the app has declared it may do.
Everything it does is undoable, and anything destructive asks first.

Each app declares its own list of things an agent can do. The foundation provides the one
way to declare them, so four apps do not invent four ways.

## The three postures, and why the middle one

**Advisor.** The agent answers and suggests; the person does everything. Safest, and it
makes the assistant a chat window bolted to the side of an app — the thing people try once
and stop opening.

**Propose, then confirm.** The agent prepares the change and shows it; the person taps
once. Nearly all of the usefulness, and a person who is never surprised by what their app
did while they were reading.

**Do it.** Fastest, and one day it edits a scripture journal entry in a way nobody asked
for and nobody saw happen.

**We take the middle one**, with a deliberate seam: an action can be marked as safe to
perform without asking, and adding something to that list is a decision made once, in the
open, per action — not a mode a person switches on and forgets.

## The rules

- **Every agent action is undoable.** Not "most". If an action cannot be undone, it cannot
  be an agent action. This is the rule that makes the rest safe enough to be worth having.
- **Destructive actions always confirm**, whatever list they are on. Deleting a trip, a
  workout, a year of journal entries.
- **The person sees what it did**, in words, after it happens. An agent that acts silently
  is indistinguishable from a bug.
- **The agent gets the same permissions as the person**, never more. It cannot reach data
  the person could not open themselves, and `0011` still binds everything it reads.

## Why declaring actions belongs in the foundation

Each app knows its own verbs — *add a day to this trip*, *log this set*, *save this
passage*. The foundation does not, and should not.

But every one of those apps needs the same three things: a way to say what an action is
called and what it needs, a way to say whether it must be confirmed, and a way to undo it.
Built four times, they will be four shapes, four bugs, and four different answers to
"what happens if it fails halfway".

## The foundation test

- **Travel** — "move everything after Tuesday back a day" — the tedious change nobody
  wants to make by hand across nine screens.
- **Scripture study** — "save this passage to my study on faith", "start a plan through
  Alma".
- **Fitness** — "log the same session as last Thursday but ten pounds heavier". The best
  case on this list: it is fiddly data entry, done sweaty, one-handed, that a person will
  otherwise skip — and a skipped log is a hole in the numbers the whole app is about.
- **Student notes** — "make flashcards from this lecture".

4 of 4, and fitness is the one where an agent most clearly earns its place.

## What we are not doing

- **No agent that acts while the app is closed.** A background agent changing things
  unattended is a different and much larger decision, and nothing needs it yet.
- **No agent-to-agent anything.** One agent, one app, one person.
- **No tool that reaches the network directly.** Anything an agent does goes through the
  same actions a person could take, so the app's own rules apply.

## What it costs

**Undo has to be real, everywhere.** That is a genuine constraint on `PPData` and on
every app: an action that cannot be reversed cannot be automated, so some things simply
will not be agent-callable until undo exists for them.

**A confirmation tap** on most things, which is friction, and is the price of never being
surprised by your own app.

**More surface to get wrong.** Every declared action is a thing a model can call with
arguments nobody expected. Each one needs to be as careful about its inputs as if a
stranger were calling it, because in effect one is.

## Revisit when

- An app has enough safe-to-perform actions that the list itself becomes the risk.
- Somebody wants an agent that runs while the app is closed, which reopens this properly
  rather than extending it.
