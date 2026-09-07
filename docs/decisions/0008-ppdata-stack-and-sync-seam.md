# 0008 — The SwiftData stack, and what the sync seam actually is

**Date:** 2026-09-07
**Status:** Accepted
**Implements part of:** 0002

## What we decided

`PPData` builds SwiftData containers and hands back Apple's own `ModelContainer`. There
is **no protocol in front of storage**. There *is* a protocol in front of sync
(`SyncProvider`, as `0002` requires), and it has no `sync()` method, because there is
nothing to call.

This is the first of two pieces of work. The CloudKit adapter, sharing, and migrations
are the second.

---

## The foundation test

*Would at least three of the four planned apps want this? Name them.* Tested hardest
against fitness, which is numbers over time while the others are notes attached to a
thing.

### `PPModelStore` — 4 of 4

- **Travel** — trips, days, places, the note attached to each.
- **Scripture study** — highlights, journal entries against a passage.
- **Fitness** — workouts, sets, weights, dates. Many small records written often.
- **Student notes** — lectures, assignments, due dates.

Fitness is the reason the default is what it is. A set gets logged mid-workout, in a
basement gym with no signal, and the save has to finish now. It is the app least able to
tolerate a store that waits for a network, which is the whole argument for local-first
stated as a use rather than a principle.

### `SyncProvider` and `SyncStatus` — 4 of 4

- **Travel** — "sign in to iCloud so your family can see this trip."
- **Scripture study** — the same study open on a phone and an iPad.
- **Fitness** — a year of logged workouts is the most painful thing on this list to lose
  to a new phone, and the person who never signed into iCloud is the one who loses it.
- **Student notes** — lecture notes taken on one device, revised on another.

The shared need is not "sync my data" — SwiftData does that. It is **being able to tell
someone that syncing is not happening**, which no app can do without asking.

### `InMemorySyncProvider` — 4 of 4

Every app needs to build the screen that says "you are not signed into iCloud" and be
sure it looks right. Signing out of iCloud on a device to check is not a test anybody
runs twice. `0002` names this as a reason the seam exists at all.

---

## Why there is no protocol in front of storage

`AGENTS.md` says every input and output edge sits behind a protocol so it can be faked in
a test. Disk is an edge. So this needs an argument.

**SwiftData is already the seam.** A test builds the same store with `.temporary` and
gets a real, working store that lives in memory and vanishes afterwards. The rule exists
so that edges can be faked; this edge already can be. What the rule asks for is the
*capability*, not a protocol per edge.

**A wrapper would cost more than it buys.** Putting `PPDatabase` in front of
`ModelContainer` means every app loses `@Query`, `@Environment(\.modelContext)`, and
SwiftData's SwiftUI previews — the three things that make SwiftData worth using. We would
be reimplementing Apple's framework in order to satisfy a rule whose purpose is already
met.

**Sync is different, and that is why it gets the protocol.** CloudKit has no in-memory
equivalent. You cannot make it fail on demand, cannot sign a test out of iCloud, and
cannot make it slow. That is exactly the case the rule was written for.

If an app ever needs to leave SwiftData, this decision is the one that costs. We think
that is a smaller bet than the four apps and their previews.

## Why `SyncProvider` has no `sync()`

SwiftData mirrors to CloudKit on its own, on a schedule Apple decides. Nothing in the app
triggers it. A `sync()` method would be a lie told in a protocol: it would compile, an
app would call it, and it would do nothing.

What an app genuinely needs is to **ask**: is syncing possible, is it happening, when did
it last work. That is what the protocol offers, and it is the difference between an app
that says "sign in to iCloud to see this on your iPad" and one that silently never syncs.

Nothing on this protocol is on the path to reading or writing data. Saving goes through
SwiftData and finishes in airplane mode. Sync only reports on what happens afterwards,
which is what keeps the local-first promise from quietly depending on a network.

## Why one `SyncStatus` value rather than three properties

A view observes one thing, a fake sets one thing, and `Equatable` lets SwiftUI skip a
redraw when nothing actually changed. `isWorthMentioning` is on it because the answer is
*no* far more often than people expect: an app that keeps announcing its sync state is
telling on itself, and only two states — not signed in, or a failure — are worth a
person's attention.

## Why the default is `.synced`

Local-first means a person's own devices agreeing is the normal case, not the special
one. An app that genuinely should keep data on one device has to say so, which is a
decision worth making out loud.

## What is deliberately not here

**Sharing.** `0006` names sharing a record between people as the standing example of real
foundation work, and the travel app needs it. It is not in this protocol yet, because
designing a sharing API with no CloudKit implementation to test it against is how you
invent a shape that does not fit. It arrives with the adapter.

**Naming a specific CloudKit container.** `.synced` uses whatever the app's entitlements
name. Supporting more than that is untestable until there is an account to test with.

**Migrations.** Second piece of work. They matter — changing the shape of stored data
without losing what people saved is where apps hurt themselves — and they deserve their
own attention rather than a corner of this one.

## What it costs

`.synced` and `.thisDeviceOnly` are **not exercised by any test**. Both need an Apple
Developer account and CloudKit entitlements, which the project does not have yet
(`docs/roadmap.md`, blockers). Only `.temporary` is tested. So the code that decides
whether an app's data leaves the phone is, today, read but not run.

## Revisit when

- The Apple Developer account exists and `.synced` can actually be tested.
- Sharing gets built, which may reshape this protocol rather than extend it.
- An app needs a second store, or a store it can turn sync on and off for at runtime.
