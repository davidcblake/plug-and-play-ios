# Plug and Play

A shared foundation for a family of native iPhone apps. **Not an app itself.**

Instead of building each app from nothing, we build the common parts once — storage,
sync, sign-in, payments, design, notifications — and each app adds only what makes it
different.

## Status

**Phase 0 — building the skeleton.** Nothing here is finished yet. See
[`docs/roadmap.md`](docs/roadmap.md) for what is actually done, which is the only place
status is recorded.

## Read these in order

1. [`AGENTS.md`](AGENTS.md) — the rules. Everyone reads this first, human or AI.
2. [`docs/architecture.md`](docs/architecture.md) — how it's built and why, in plain English.
3. [`docs/roadmap.md`](docs/roadmap.md) — the plan and honest status.
4. [`docs/first-app.md`](docs/first-app.md) — the travel app, the first real customer.
5. [`docs/agent-workflow.md`](docs/agent-workflow.md) — how the four AI helpers work together.
6. [`docs/security.md`](docs/security.md) — the rules that are binding, and Dave's checklist.
7. [`docs/decisions/`](docs/decisions/) — why each significant choice was made.

## The shape of it

Eight modules in one Swift package:

| Module | What it owns |
|---|---|
| `PPCore` | Logging, errors, configuration, feature flags |
| `PPDesign` | Colors, typography, spacing, shared components |
| `PPData` | On-device storage and sync |
| `PPAuth` | Sign in with Apple |
| `PPPay` | Subscriptions and entitlements |
| `PPNotify` | Push and local notifications |
| `PPInput` | Voice-to-text and photo capture |
| `PPOnboard` | First-run flow and permissions |

Apps depend on a **tagged version**, never on `main`, so a change here can never break
several shipped apps at once.

## The rule that governs what goes in

> Would at least three of the four planned apps want this — travel, scripture study,
> fitness, student notes? Name them, and say what each would use it for.

If you can only name one or two, it belongs in those apps, not here. Test it hardest
against fitness: it is numbers over time, while the others are notes attached to a thing.

## Built with

Native SwiftUI. Swift 6, strict concurrency. Minimum iOS 18. SwiftData on the device,
CloudKit for sync, Sign in with Apple, StoreKit 2. iPhone only.

Everything works offline. That is the promise the whole design is built around.
