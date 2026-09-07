# 0022 — The CloudKit sync provider

**Date:** 2026-09-07
**Status:** Accepted
**Implements part of:** 0002, 0008

## What we decided

`CloudKitSyncProvider` is the real implementation of `SyncProvider`. It reports one
thing — whether syncing can happen for this person — by asking `CKContainer` for the
account status, and asking again whenever iCloud says the account changed.

It reports **nothing** about sync progress, because SwiftData exposes none.

`PPModelStore.Kind` gains `.syncedTo(container:)` for an app that needs to name its
CloudKit container rather than take whatever its entitlements name. `0008` deferred that
until there was an account to test against; there is one now.

---

## The foundation test

*Would at least three of the four planned apps want this? Name them.* Tested hardest
against fitness, which is numbers over time while the other three are notes attached to
a thing.

**4 of 4**, and it is the same answer `0008` gave for the seam — which is the point,
since this is the thing that finally makes that seam do something.

- **Travel** — "sign in to iCloud so your family can see this trip." Without it, the one
  feature the whole app is for silently does not happen.
- **Scripture study** — the same study open on a phone and an iPad, or not, and knowing
  which.
- **Fitness** — the strongest case, and the reason to build this now rather than later.
  A year of logged workouts is the most painful thing on this list to lose to a new
  phone, and the person who loses it is exactly the person who never signed into iCloud
  and was never told.
- **Student notes** — lectures taken on a laptop, revised on a phone.

The shared need is not "sync my data". SwiftData does that. It is **being able to tell
somebody that syncing is not happening**, which nothing else in this foundation can.

---

## Why `activity` is always `.idle`

**SwiftData does not say what syncing is doing.** There is no public API for "a push is
in flight", "the last pull finished at 4:02", or "this record has not gone up yet". The
mirroring happens below the waterline, on Apple's schedule.

So the provider reports `.idle`, always, except when a *check* itself failed. The
alternatives were all worse:

- **A spinner on a timer.** Show "syncing" for two seconds after a save. It would be
  right by coincidence and wrong by design, and it would eventually show "synced" to
  somebody whose data had not moved in a week.
- **`lastSynced` meaning "last launched".** The property is documented as when data last
  reached the cloud. Filling it with something else makes every screen that reads it a
  liar, and this is precisely the number a person uses to decide whether it is safe to
  wipe their old phone.
- **`NSPersistentCloudKitContainer.eventChangedNotification`.** This one is tempting,
  because SwiftData is built on Core Data and those notifications really are posted. It
  was rejected: it reaches around SwiftData into an implementation detail Apple has
  never documented as SwiftData's, so it is a feature that works until an OS update
  makes it silently stop — and silently is the failure mode that matters, because a sync
  indicator that has quietly stopped updating looks exactly like one saying everything is
  fine.

`AGENTS.md` says a document that overstates progress is worse than no document. The same
is true of a status.

## Why account status is enough to be worth having

Two facts make it the right thing to report:

**It is the only part a person can act on.** Nobody can make a push happen faster. They
can sign into iCloud, re-enter a password, or accept new terms — and those are exactly
what the account status distinguishes.

**Asking works offline.** `CKContainer.accountStatus()` reads state already on the
device; it is not a network call, and a phone in airplane mode answers it. That is what
lets this sit in a local-first app without putting a network on the path to anything —
the promise `0002` makes and `0008` was careful to keep.

## Why `needsAttention` is a new state

CloudKit's `temporarilyUnavailable` means the account exists but iCloud wants something
first — usually a password re-entered or new terms accepted. Folding it into `restricted`
would tell somebody their device forbids iCloud when the truth is that iCloud is waiting
for them, and send them hunting for a setting that does not exist. It is a one-minute fix
in Settings, and the only kind of sync problem a person can actually clear, so it gets
its own word.

## Why it starts asking on its own

Constructing the provider starts the first check and the watch for account changes.
There is nothing to remember to call.

A `start()` method would be one line in an app's setup and one line of documentation, and
the app that forgot it would report `unknown` forever with nothing obviously broken.
Given the choice between ceremony and a silent trap, take the ceremony out.

## The internal initializer

`CloudKitSyncProvider` has an internal initializer taking the account question as a
closure. This is **not** a second seam behind the first: `SyncProvider` is what apps code
against and `InMemorySyncProvider` is what they test with, and neither changes.

It exists because this type's own behaviour — what it makes of each answer, what it does
when the account changes under it, what it keeps when a check fails — is otherwise
checkable only by signing a person in and out of iCloud by hand on a device. That is not
a test anybody runs twice, so it would not be run at all. It is internal, so no app can
reach it.

## What it costs

**The CloudKit half is still not run by any test.** What the tests cover is every
transition this type makes and every answer it can be given. What no test covers is the
line that actually calls `CKContainer` — a CI simulator has no iCloud account and no
entitlement, and `CKContainer.default()` on a target without one does not fail politely.
So the mapping, the watching and the reporting are tested; the call is read and not run,
and stays that way until it runs on a device with an account. `docs/roadmap.md` says so
rather than ticking the box.

**A person can be told sync is possible when it is not working.** Account available is
not the same as data moving. This provider cannot tell the difference, and neither can
SwiftData, so an app should say "syncing to iCloud is on" rather than "your trip is
backed up".

**`.syncedTo(container:)` is a promise about entitlements the package cannot check.**
Name a container the app is not entitled to and the store fails to open at launch.

## What is deliberately not here

**Sharing a record between people.** Still blocked, and now for a written reason rather
than a missing account: `0020` leaves it undecided what happens to a shared record when
its owner deletes their account, and that has to be settled before anything ships that
can share. Building the sharing API first would mean designing it around whichever answer
was convenient.

**Anything that triggers a sync.** There is still nothing to call. See `0008`.

**Checking that a model's shape is legal for CloudKit.** Synced stores refuse properties
without defaults, relationships without inverses, and unique attributes. Nothing in
SwiftData exposes that check, so it is documented on `Kind.synced` and will be found by
opening a synced store — which is one more reason to do that early on a device rather
than late.

## Revisit when

- The first app runs against a real container on a device, and we find out what the
  status actually reports in the wild.
- Apple exposes sync progress from SwiftData. Then `activity` becomes real and this
  record's central decision is reversed on purpose rather than by drift.
- Sharing gets built, which may reshape `SyncProvider` rather than extend it.
