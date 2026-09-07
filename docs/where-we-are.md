# Where we are

**Written 2026-09-07.** A snapshot for whoever picks this up next, human or AI. Read
`AGENTS.md` first, then `docs/roadmap.md` for status. This file holds only the things that
were decided in conversation and are not written down anywhere else.

## The two apps

**VEYA** — the travel app, spec'd in `docs/first-app.md`, named after the family Rome trip.
Built **native from scratch** on this foundation. No repository yet. It is the better first
native app because its own spec says no AI in version one, it needs no server, and one
person using it needs no sign-in — so it depends only on the parts of this foundation that
are finished.

**Spindle** — the scripture study companion, at `davidcblake/spindle`. Today it is Next.js
+ Supabase + the Anthropic API on Vercel, as a PWA. It is *not* a candidate for a quick
native rebuild: study generation needs a server holding an API key, which a phone cannot
do. See "Spindle's shape" below.

**Dossier** is dead. It has an old Capacitor project at `~/dossier/ios`; ignore it.

## Two things about VEYA's spec that do not survive contact with reality

**Offline maps are not a thing MapKit does.** `docs/first-app.md` promises "offline map
data". Apple's MapKit fetches tiles over the network and offers no offline download. The
options are a third-party map (a dependency needing a decision record), pre-rendered
static images of the few areas that matter, or cutting the map from version one. For a
family trip to Rome, static images may genuinely be enough.

**Family sharing needs work that does not exist.** "Everyone sees the same trip" needs
CloudKit sharing, which is unbuilt — and `docs/decisions/0020` notes that what happens to a
shared record when its owner deletes their account is undecided and **must be settled
before sharing ships**. Version one is useful without it: one person, one trip, fully
offline.

## Spindle's shape, if it is rebuilt native

Three paths were considered. The recommendation is the second:

1. **Webview shell.** Fastest. Forbidden by `docs/decisions/0001`. Would need that decision
   overturned deliberately, not quietly.
2. **Split down the middle.** The journal — saved studies, notes, highlights — goes
   local-first on SwiftData and CloudKit, which is exactly what this foundation is for.
   Study *generation* calls a thin server holding the Anthropic key. This breaks `0002`'s
   "no server" and needs a decision record amending it.
3. **Leave Spindle as a web app** and build a native scripture app later.

Dave's own system prompt for Spindle describes a **conversational companion** — talk
preparation, counsel on leadership situations, difficult questions — while the app today
generates a study from a passage you pick. Those are different products and the choice
should be made before either is built.

Cost, measured from the code: roughly **$0.03 per study** on `claude-sonnet-5`, about
**$0.90 per active user per month**, halved by generating tomorrow's study overnight
through the Batch API — which is also what keeps it offline and instant. Output tokens are
~85% of the bill; prompt caching is not worth it at this prompt size.

## The five open decision records

`#16`–`#20` propose how the apps use AI: the model-choice seam, what a model may see of
private data, what an agent may do, that AI must never be load-bearing, and what a model
may say. **They are deliberately unmerged.** They were written before any app existed, and
they will be better decisions once one does. Nothing depends on them.

## What only Dave can do

- The Apple Developer Program is **active** (individual, renewing September 2027), with a
  development certificate, App IDs including `com.wpv.spindle`, and CloudKit containers and
  App Store Connect records created on 2026-09-07.
- **Signing** is per-app and happens in Xcode when an app project exists. Nothing to sign
  yet.
- **Whether the design system actually looks right.** Contrast is machine-checked; taste is
  not. `Example/` is where to look.

## The next piece of work

**VEYA, in its own repository.** The foundation now has everything version one of it needs:
storage, migrations, the design system, reminders, the input seams, and — as of today — a
sync provider that can tell somebody whether iCloud is on. It depends on this package by a
**tagged version**, never `main` (`AGENTS.md`), so this package needs a tag before the app
can consume it.

Two things about VEYA that are settled and worth not re-deciding: the map question above is
open and version one may simply not have a map, and family sharing waits on `0020`'s
deletion question. One person, one trip, fully offline is a real product.

The CloudKit sync provider is **done** — `docs/decisions/0022`. The thing that was worth
knowing before starting it turned out to be the whole of its design: SwiftData exposes no
sync progress, so `SyncStatus.activity` reports `.idle` and `lastSynced` stays `nil` rather
than inventing either.
