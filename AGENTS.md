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

> **Would at least three of the four planned apps want this — travel, scripture study,
> fitness, student notes? Name them, and say what each would use it for.**

If you can only name one or two, the answer is no by default: it belongs in those apps.
This rule is what decides whether this foundation stays useful or turns into a junk
drawer.

**The exception, which is deliberately expensive.** Sometimes something plainly belongs
here and still fails the count — sharing a record between people is real foundation work
that the fitness app will never want. When that happens, write a decision record saying
which apps want it, why it belongs here anyway, and what it would cost to leave it out.
Same mechanism this rulebook already uses for third-party dependencies.

Do not force-fit the answer in either direction. Do not invent a use the fitness app
would never have just to reach three, and do not push something out that obviously
belongs here just because it only reaches two. The count is there to make you check, not
to think for you — but skipping it needs a written reason someone else can argue with.

Naming them is the part with teeth. "Would a couple of apps want this?" can be answered
yes in your head without checking. Naming three, and what each does with it, forces you
to actually look — and it is where you find out that two of them wanted slightly
different things and the shared version serves neither.

**Test it hardest against fitness.** Travel, scripture study and student notes are all
the same shape underneath: notes attached to a thing, in a place or a passage or a
lecture. Fitness is the odd one out — numbers over time. Something that fits only the
note-shaped apps is not foundation; it is a shared feature of three similar apps, and it
will not be there when app four needs it.

Three rather than all four, deliberately. Sharing a record between people is real
foundation work — a family trip, a family study, a study group — and the fitness app
almost certainly never wants it. A rule demanding all four would push genuine
foundation out.

**If the planned apps ever change, this rule has to be re-derived, not patched.** It
names four specific apps and leans on exactly one of them being a different shape. Drop
one, add one, and both the count and which app is the odd one out may be wrong. See
`docs/decisions/0006-widen-the-foundation-test.md`.

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

- **`swift build` on CI compiles for macOS, not iOS — and you must declare the macOS
  minimum or nothing modern compiles.** The runner is a Mac, so SwiftPM builds for the
  *host*. If `Package.swift` lists only `.iOS(.v18)`, SwiftPM falls back to a default
  macOS deployment target old enough that SwiftUI (`View`, `EnvironmentValues`, macOS
  10.15), `os.Logger` (11.0) and `OSAllocatedUnfairLock` (13.0) all fail with "only
  available in macOS X or newer" — even though none of that code will ever run on a Mac.
  `.macOS(.v15)` sits in `platforms` for this reason, paired with the iOS minimum so an
  API that is fine on iOS is not rejected by a host build. It is a build-configuration
  entry, not a change to the iPhone-only product decision (0004).
  **CI no longer builds this way** — it runs `xcodebuild` against an iOS simulator, which
  tests the platform we actually ship. The macOS entry stays because a by-hand
  `swift build` on a Mac is a useful few-second check and still compiles for the host.
  Do not trust the `Target Platform:` line Swift Testing prints at *run* time as evidence
  of the *compile* deployment target. They are different numbers, and reading the run
  line as the compile target is how this got recorded wrongly the first time.

- **The package's aggregate Xcode scheme is `PlugAndPlay-Package`, not `PlugAndPlay`.**
  Xcode generates one scheme per library product (`PPCore`, `PPData`, …) plus an
  aggregate that builds them all, and the aggregate carries the `-Package` suffix. Using
  the bare package name fails with *"The workspace named 'plug-and-play-ios' does not
  contain a scheme named 'PlugAndPlay'"*, which reads like the package is broken rather
  than like the name is wrong. `xcodebuild -list -json` prints the real list.

- **Do not hard-code a simulator name in CI.** GitHub changes the device lineup between
  runner images. The build workflow discovers the newest available iPhone simulator and
  uses its UDID, so an image update cannot silently break the build with an error that
  does not obviously mean "that iPhone no longer exists here".

- **An automated reviewer that re-runs on every push is a loop, and it will not stop on
  its own.** `grok-review.yml` and `gemini-auditor.yml` fire on each push to a pull
  request, so fixing a nit produces a fresh review, which produces a fresh nit. `PPDesign`
  went five rounds this way (PR #11) *after* the code was already compiled, tested and
  green. Two of those rounds produced a real improvement. The rest were points already
  answered coming back a second and third time, a suggestion that would not have compiled,
  and one confident "must fix" that was wrong — it quoted the very line that disproved it.
  **Two rounds with a reviewer is enough.** A point raised a third time, or a round with
  nothing new in it, means the loop has become the work: stop, say so in one line, and let
  Dave decide. The six-round limit in `docs/agent-workflow.md` governs a job card moving
  between seats; this is the same failure *inside* one pull request, where there is no
  label to hand on and nothing stops it but somebody choosing to.

- **Pushing while a build is running throws that build away.** `build.yml` sets
  `cancel-in-progress: true`, so a second push cancels the first run mid-flight. Three
  pushes in ten minutes on PR #11 killed two macOS runs at four and two minutes in, and
  bought three rounds of review on code that had never once been compiled. Mac minutes
  cost roughly ten times Linux ones. Batch the fixes, push once, and wait for the result
  before pushing again — especially when the build is the only compiler you have.
