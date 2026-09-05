# Plug and Play — Rules for everyone working here

**This is the rulebook. Read it before you touch anything.**

It is written in plain English on purpose. The person who owns this project is not an
engineer. If you cannot explain a change to him in plain English, the change is probably
wrong or you do not understand it well enough yet.

---

## What this is

A shared foundation for a family of native iPhone apps. It is **not an app itself**.

Planned apps: a travel app (first), a scripture study app, a health and fitness app, a
college student app. Code written here runs in all of them.

## The one test that decides what belongs here

Before adding anything to this repository, answer this in writing, in the pull request:

> **Would both a travel app and a scripture study app want this?**

If no, it belongs in the individual app, not here. There is no third answer. This single
rule is what decides whether this foundation stays useful or turns into a junk drawer.

---

## Decisions already made — implement these, do not reopen them

Each of these has a written reason in `docs/decisions/`. Read the reason before
arguing with the decision. Then argue if you still disagree — but in an issue, not by
quietly building something else.

**The app itself**
- Native SwiftUI only. No webviews. No UIKit unless it is wrapped and the wrapper is
  justified in a decision record.
- Swift 6 with strict concurrency enabled. No `@unchecked Sendable` without a decision record.
- Minimum iOS 18. Built with the iOS 26 SDK or later (Apple requires this for submission).
- Views are `@Observable` models observed directly. No view models, no MVVM ceremony.
- Dependency injection through the SwiftUI environment. **No singletons.**

**Data**
- **Local-first, always.** Every feature works fully with the phone in airplane mode.
  Nothing shows a spinner waiting for a server to answer a question it could answer itself.
- SwiftData for storage on the device.
- CloudKit for sync between a user's own devices, and for sharing between people.
- Sync sits behind a protocol (`SyncProvider`). Feature code never imports CloudKit
  directly. This is what lets a different sync system be swapped in later without
  rewriting the apps.

**Identity and money**
- Sign in with Apple. No other login provider unless an app genuinely needs one.
- StoreKit 2 for subscriptions and purchases. Apple's in-app purchase system, not Stripe.
- Entitlements (what a user has paid for) are checked through `PPPay`, never by an app
  reading a receipt itself.

**Structure**
- One Swift package, eight modules, semantic version tags.
- Apps depend on a **tagged version** (`from: "1.2.0"`), never on `main`. A change here
  must never be able to break four shipped apps at once.
- Feature modules never import each other. They import `PPCore`.
- Every input and output edge — disk, network, sync, purchase — sits behind a protocol
  so it can be faked in a test.

**Dependencies**
- Apple's own frameworks first, every time.
- No third-party dependency without a decision record explaining what it does that
  Apple's SDK cannot.

---

## The modules

| Module | What it owns |
|---|---|
| `PPCore` | Logging, error handling, configuration, feature flags |
| `PPDesign` | Colors, typography, spacing, shared components — the family look |
| `PPData` | SwiftData stack, CloudKit sync behind `SyncProvider`, migrations |
| `PPAuth` | Sign in with Apple |
| `PPPay` | StoreKit 2 subscriptions, entitlements, paywall components |
| `PPNotify` | Push and local notifications |
| `PPInput` | Voice-to-text and photo capture |
| `PPOnboard` | First-run flow and permission requests |

`PPInput` exists because every planned app wants both: travel notes, scripture
journalling, and fitness logging all benefit from speaking instead of typing and from
attaching a photo quickly. Building it once, well, beats bolting it on four times.

---

## Definition of done

A piece of work is not done until all of these are true:

- [ ] `swift build` and `swift test` pass
- [ ] No new compiler warnings
- [ ] Anything other apps can call has a doc comment and a test
- [ ] Works with the phone offline, or the pull request explains why that is impossible
- [ ] A decision record written for any architectural choice
- [ ] `docs/roadmap.md` updated **in the same commit** as the work it describes
- [ ] The pull request says what you did **not** do, and why

That last one is not filler. Agents are consistently over-confident about their own
work. Writing down what you skipped is the cheapest quality control in this project, and
it gives the reviewer something specific to attack.

## Handing off

You do not finish a job by announcing you are done. You finish by moving the job card to
the next person and leaving a note that says:

1. What you changed
2. What you were unsure about
3. What the reviewer should attack first

Full process in `docs/agent-workflow.md`.

## Writing style, in code and in documents

- Comments explain **why**, never what. If what the code does is unclear, rename things.
- Name things the way a user would say them, not the way the system is built.
- Delete dead code. Do not leave it commented out.
- Documents must be true on the day they are written. Never describe something as
  finished when it is not. A document that overstates progress is worse than no document.

## Always ask whether it is still the best way

Before building something, ask: *is this still the current best approach?* Apple changes
things every year. Do not use an older pattern because it is familiar, and do not
copy a pattern out of this repository without checking it is still right.

Challenging a settled decision is welcome from anyone, on any job. Do it in an issue with
a reason, not by quietly building something different.

---

## Hard-won facts — do not rediscover these

*Every time something costs more than an hour to figure out, it gets written down here so
nobody pays for it twice. Add to this list. Never delete from it.*

- **CI builds this package for macOS 14, not iOS 18.** `swift build` / `swift test` on
  the macOS runner compile for the *host*, and the run reports
  `Target Platform: arm64e-apple-macos14.0` even though `Package.swift` declares
  `.iOS(.v18)`. So anything introduced in iOS 18 / macOS 15 will not compile in CI:
  SwiftUI's `@Entry` macro and `Synchronization.Mutex` are the two that bite first. Use
  an explicit `EnvironmentKey` and `os.OSAllocatedUnfairLock` instead, or move testing
  onto an iOS simulator destination, which is the real fix and a bigger job.
