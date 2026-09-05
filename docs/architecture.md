# How this is built, and why

Written so a non-engineer can follow it. Every technology named here was chosen for a
reason, and the reason is written down in `docs/decisions/`.

## The big idea

Instead of building a new app from nothing every time, we build one strong foundation
once. Each new app sits on top of it and only adds the parts that make that app
different.

The foundation is a **Swift package** — a labelled box of reusable code. Each app is its
own project that says "I depend on version 1.4 of Plug and Play," and gets everything in
the box.

The version number matters. An app upgrades when its owner decides to, not the moment
someone changes the foundation. That's what stops one careless change breaking four
apps at once.

## The thing that shapes everything: local-first

**Every app keeps its own data on the phone, and works completely with no internet.**

This is the most important decision in the project, so it's worth understanding why.

The obvious way to build an app is: the app is a window, the real data lives on a server,
the app asks the server for everything. That's how websites work. It's also why so many
apps show you a spinner when your signal is bad.

We do the opposite. The data lives on the phone. The app reads and writes it instantly,
with no network involved at all. Syncing happens quietly in the background *afterwards*,
and if it can't happen right now, nothing breaks.

What that buys:

- **The travel app works in Rome on a bad roaming signal.** That's the whole point of a
  travel app — you need it most exactly when the signal is worst.
- **The scripture app works on a plane.**
- **No server to run.** No hosting bill, no database to maintain, no 3am outage, no
  security patches on a machine you forgot you owned.
- **Everything feels instant**, because nothing is waiting on a network.

The syncing is done by **CloudKit**, which is Apple's. It syncs a user's data between
their own iPhone, iPad and Mac for free, and it's private — even Apple can't read it.
It also lets people share: your whole family can see the same trip itinerary, offline,
with no server anywhere.

The catch, stated honestly: CloudKit only works on Apple devices, and it can't run
logic on a server. If an app ever needs a website version, an Android version, or
server-side processing, it needs something else. That's why syncing sits behind a
swappable piece — see below.

## The swappable seam

Feature code never talks to CloudKit directly. It talks to something called
`SyncProvider`, and CloudKit sits behind that.

This is a small amount of extra work now — maybe a day — and it's the difference between
"we'd have to rewrite the app" and "we'd swap one piece" if an app outgrows CloudKit
later. Every place the foundation touches the outside world works this way: storage,
network, sync, purchases. Each one has a seam.

It also makes testing possible. A test can put a fake behind the seam and check the app
behaves correctly when syncing fails, which is impossible if the app calls CloudKit
directly.

## The eight pieces

**`PPCore` — the wiring**
Logging, error handling, settings, and feature switches (turning a half-built feature on
for yourself but off for everyone else). Every other module depends on this one. It
depends on nothing.

**`PPDesign` — the family look**
Colors, fonts, spacing, buttons, cards, loading states, empty states. The reason your
apps will look like they came from the same company rather than four different
freelancers. Underrated, and the piece most likely to save you time on app four.

**`PPData` — remembering things**
The SwiftData setup, the CloudKit sync behind its seam, and the machinery for changing
the shape of stored data without losing what people already saved. That last part sounds
minor and is where most apps eventually hurt themselves.

**`PPAuth` — knowing who someone is**
Sign in with Apple. One tap, no password to forget, no email to verify, and Apple lets
people hide their real address. For apps like these it's both the simplest and the most
private option.

**`PPPay` — getting paid**
Subscriptions through Apple's own system, checking what someone has paid for, and
reusable paywall screens. Apple takes 15% under the Small Business Program (under $1M a
year) rather than the standard 30% — apply for it.

**`PPNotify` — notifications**
Push notifications and reminders that fire on the phone itself. Local reminders need no
server at all, which suits a local-first app.

**`PPInput` — talking and photographing**
Voice-to-text and quick photo capture. Every planned app wants both — trip notes,
scripture journalling, meal and workout logging. Building it properly once beats bolting
it onto four apps badly.

**`PPOnboard` — the first two minutes**
The first-run flow and the way permissions get asked for. Asking for location the instant
someone opens an app is how you get refused; asking at the moment it obviously helps is
how you get a yes. Getting this right once, in one place, lifts every app.

## How a new app gets built

1. Copy the app template.
2. Rename it — one script changes the name, the identifier and the icon.
3. Add the screens and data that make *this* app different.
4. Everything else — storage, sync, sign-in, payments, design, notifications — is
   already there.

The goal is that app four takes a fraction of the time app one took. If it doesn't,
something in the foundation is wrong and we should say so rather than pretending.

## What we deliberately gave up

Being honest about the costs, so nobody rediscovers them as surprises:

- **iPhone only.** No website version, no Android. Each would be a separate build.
- **Apple's ecosystem.** CloudKit, StoreKit and Sign in with Apple are all Apple's. That's
  a deliberate trade: much less to build and run, in exchange for being tied to one
  platform.
- **Swift.** AI models have somewhat more practice with web languages than with Swift.
  The gap has narrowed a lot, but you'll notice it occasionally.
