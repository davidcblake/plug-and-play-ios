# 0023 — Knowing whether there is a connection

**Date:** 2026-10-28
**Status:** Accepted

## What we decided

`PPCore` gains a `Connectivity` seam: `isOnline`, a stream of changes,
`SystemConnectivity` over Apple's `NWPathMonitor`, `InMemoryConnectivity` for
tests, and `AlwaysOnline` as the default.

**It was extracted from Spindle rather than invented here.** Spindle for iPhone
shipped a 30-line `Connection` type to TestFlight; this is that type, generalised
and given a seam and tests. That direction matters: the foundation earned this
piece by watching an app need it, rather than guessing one would.

## The foundation test — 4 of 4

Tested hardest against fitness, which is numbers over time while the other three
are notes attached to a thing.

- **Travel** — abroad on expensive, throttled or absent roaming. The app the
  whole local-first argument was built on.
- **Scripture study** — on a plane, or in a canyon. Already shipping this code.
- **Fitness** — a basement gym with no signal, which is where logging actually
  happens. The strongest case on the list, not the weakest: the one app whose
  core use happens somewhere with no bars.
- **Student notes** — four hundred people on one lecture-hall access point,
  which is functionally airplane mode.

## Why almost nothing should ask

Every app here reads and writes its own data on the device. Those screens do not
care whether there is a signal, and a screen that checks before reading from
disk has misunderstood the foundation.

This exists for the few places that genuinely cannot work without a connection —
preparing something on a server, sending something to somebody — so they can say
"no connection" plainly instead of showing a spinner that never ends. **If a new
screen reaches for this, that is worth a second look**: usually the right answer
is that the screen should not have needed a network at all.

## Why the default is "online"

Getting this wrong optimistically costs a request that fails and says so.
Getting it wrong pessimistically greys out a button that would have worked,
which is a worse way to be wrong and much harder for a person to argue with —
they can see the wifi symbol and the app is telling them otherwise.

The same reasoning sets the first answer `SystemConnectivity` gives, before the
path monitor has reported anything.

## Why `nonisolated(unsafe)` on the monitor

`NWPathMonitor` is designed to be used from the queue it is started on and is
safe to hold, but Apple does not mark it `Sendable`, so the compiler cannot see
that. The alternative was `@unchecked Sendable` on the whole type, which
switches the check off for every property the type ever grows. One spelled-out
exception on one property is the smaller hole, and `AGENTS.md` asks for exactly
this to be written down rather than waved through.

Spindle's version sidestepped it by being `@MainActor`-isolated. That is fine for
one app and wrong for a seam, because a protocol pinned to the main actor cannot
be used from anywhere else.

## What it costs

**`SystemConnectivity` is not exercised by any test.** It would report whatever
the CI runner's network is doing, which is not a test, it is a weather report.
What is tested is the seam, the fake, the stream bookkeeping, and the rule that a
repeat is not a change. The real monitor is read and not run — the same honest
gap as the rest of the foundation's Apple halves.

**One more public name in `PPCore`.** Small, and the junk-drawer risk is real
enough that the next extraction should have to argue just as hard.

## Revisit when

- A screen asks for this and should not have, which is evidence the local-first
  rule has slipped somewhere.
- `PPData`'s `SyncStatusBroadcaster` and this file's `ConnectivitySignal` turn
  out to be the same thing twice, which they nearly are. One generic in `PPCore`
  would serve both; it was not worth widening this change to find out.
