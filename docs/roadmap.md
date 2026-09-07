# Roadmap

**This file is the single source of truth for status.** It is updated in the same commit
as the work it describes. If this file says something is done, it is done — on a real
device where that applies, not "the code is written."

Last updated: 2026-09-07

## Phase 0 — Foundation skeleton ✅ done (2026-09-05)

- [x] Swift package with eight modules, each with a test target and a passing test —
      confirmed by a green run of `Build and Test` on a macOS runner, PR #2
      (https://github.com/davidcblake/plug-and-play-ios/actions/runs/33988322889)
- [x] `AGENTS.md`, `CLAUDE.md`, and the docs in this folder
- [x] Decision records for the choices already made
- [x] Build workflow that compiles and tests on a macOS runner — same run as above
- [x] Branch protection on `main` (see `docs/security.md`) — verified by a direct push
      being rejected with `GH013: Repository rule violations found`, not by reading the
      settings page. The first two attempts went straight through: the ruleset was
      Active but its target branch list was empty, so it applied to nothing.

**Done means:** an empty app can depend on this package and it compiles.

> ⚠️ **This bar has not actually been met, and the checkboxes above overstate it.** Every
> tick is real, but they were earned by CI compiling the *package*. No app has ever
> depended on it. The host app in `Example/` is what will prove this; until it builds and
> runs, treat Phase 0 as done-except-for-its-own-definition.

## Phase 1 — The pieces that hold data ⏳ in progress

- [x] `PPCore` — logging, errors, configuration, feature flags
      - [x] Logging: `LogSink` seam, `SystemLogSink` over Apple's unified logging,
            `RecordingLogSink` for tests, injected through the SwiftUI environment
      - [x] Errors: `PPError`, splitting what a person is told from what the log records
      - [x] Configuration: `ConfigurationSource` seam, `BundleConfiguration` reading
            build-time values from `Info.plist`, `InMemoryConfiguration` for tests
      - [x] Feature flags: `FeatureFlagSource` seam, defaults carried by the flag,
            `ConfigurationFeatureFlags` so a flag flips from a shipped setting with no
            server involved
- [ ] `PPData` — SwiftData stack, `SyncProvider` protocol, CloudKit adapter, migrations
      - [x] The store: `PPModelStore.container(for:kind:)`, handing back Apple's own
            `ModelContainer`. `.synced`, `.thisDeviceOnly` and `.temporary`
      - [x] The sync seam: `SyncProvider`, `SyncStatus`, `SyncFailure`, injected through
            the SwiftUI environment; `NoSyncProvider` as the honest default and
            `InMemorySyncProvider` so a test can produce signed-out and failing states
      - [x] Reasoning, including why storage gets no protocol and sync does, in
            `docs/decisions/0008-ppdata-stack-and-sync-seam.md`
      - [x] Migrations: `container(for:migrationPlan:kind:)` passing SwiftData's own
            `VersionedSchema` and `SchemaMigrationPlan` straight through, plus
            `Kind.stored(at:)` — a store at a named file, which is the only way a
            migration can be tested at all. Reasoning in
            `docs/decisions/0009-migrations.md`
      - [ ] CloudKit adapter — **blocked**, see below
      - [ ] Sharing a record between people — **blocked**, see below

      > ⚠️ **The half that decides whether data leaves the phone is untested.** Only
      > `.temporary` and `.stored(at:)` are exercised by tests. `.synced` and
      > `.thisDeviceOnly` need an Apple Developer account and CloudKit entitlements,
      > which do not exist yet, so that code has been read and never run. Saving,
      > reading, deleting, closing and reopening, and migrating between two shapes are
      > all genuinely tested — on disk, not just in memory.
      >
      > The CloudKit adapter and sharing are **not started on purpose.** Both can be
      > written today and verified by nobody, and `docs/decisions/0008` argues that
      > designing a sharing API with nothing to test it against is how you invent a
      > shape that does not fit. They wait for the developer account.
- [x] `PPDesign` — colors, typography, spacing, core components
      - [x] Colors: `PPColor`, a light value and a dark value written as hex numbers,
            usable anywhere SwiftUI takes a style; `PPTheme`, the eleven-color family
            look, injected through the SwiftUI environment so an app changes its accent
            and keeps the rest
      - [x] Readability checked by machine, not by eye: every text color clears WCAG AA
            against every surface it is drawn on, in both appearances, as a test
      - [x] Typography: seven `PPTextStyle` values, each built on one of Apple's text
            styles so text grows with the phone's type-size setting; monospaced digits on
            the number style
      - [x] Spacing: `PPSpacing` on a four-point grid, `PPRadius`, and Apple's 44-point
            minimum tap target as a named constant
      - [x] Components: `PPButtonStyle` (prominent, quiet, destructive), `PPCard`,
            `PPEmptyState`, `PPErrorView`, `PPMetric`
      - [x] Foundation test answered per piece, and what was left out, in
            `docs/decisions/0007-ppdesign-tokens-and-components.md`

      > ⚠️ **Nothing here has been looked at on a screen**, and these ticks mean the
      > code and its tests are written and green on CI — nothing more. Green means
      > 34 tests in 9 suites passing on an iOS simulator, PR #11
      > (https://github.com/davidcblake/plug-and-play-ios/actions/runs/34012063063),
      > with no compiler warnings from this module. There is no app
      > to run it in until the example host app exists, so no color, no spacing and no
      > component has been seen by a human eye, and there are no snapshot or rendering
      > tests. Treat the *look* as unverified while the *rules* — contrast, type
      > scaling, tap targets — are tested.
      >
      > One string is English in the source: the "Try again" button on `PPErrorView`.
      > Everything else shown is passed in by the app. Localization across the
      > foundation is not started.

**Done means:** a throwaway app can save something, close, reopen, and see it again —
and the same record appears on a second device.

## Phase 2 — The pieces that involve Apple ⬜

- [ ] `PPAuth` — Sign in with Apple
      - [x] The seam: `Authentication`, `SignInState`, `SignedInPerson`, `AuthFailure`,
            with `NoAuthentication` as the honest default
      - [x] `InMemoryAuthentication`, which withholds the name after the first sign-in
            exactly as Apple does, and can be revoked from outside —
            `docs/decisions/0019-signing-in-is-optional.md`
      - [x] Account deletion: `deleteAccount()`, plus `HoldsPersonalData` and
            `PersonalData.erase(from:)` in `PPCore` so an app can forget somebody across
            every module at once — `docs/decisions/0020-account-deletion.md`
      - [ ] Apple's implementation, including revoking the token — **blocked** on the
            Developer Program
      - [ ] Keychain storage of the identifier (`docs/security.md` rule 2)

      > ⚠️ **Nobody can sign in yet.** Every screen is buildable — signed out, signing in,
      > cancelled, revoked — and none of them will do anything until there is an account
      > and a device.
- [ ] `PPNotify` — push and local notifications
- [ ] `PPOnboard` — first-run and permission requests
      - [x] `PermissionApproach` — what to *do* about a permission, not just where it
            stands. One place decides, so four apps cannot each get it subtly wrong
      - [x] `OnboardingProgress` with an in-memory fake and a real store that survives the
            app closing, so the halfway-through screen is buildable
      - [x] `PermissionStatus` moved to `PPCore`, since three modules need the words —
            `docs/decisions/0017-shared-permission-vocabulary.md`
      - [ ] Shared first-run screens, if any turn out to be shared rather than per-app
- [ ] `PPInput` — voice-to-text and photo capture
      - [x] The seams: `Transcriber`, `TextRecognizer`, `InputPermissions`, injected
            through the SwiftUI environment, with inert `No…` defaults
      - [x] The fakes: `InMemoryTranscriber`, `InMemoryTextRecognizer`,
            `InMemoryInputPermissions` — enough to build and test every dictation and
            photo screen, including the one for somebody who said no
      - [x] Reasoning, including why the halves are split, in
            `docs/decisions/0015-ppinput-seams-before-implementations.md`
      - [x] `readiness()` and `prepare()`, because the on-device language model is
            downloaded on first use — the one moment dictation needs a network
      - [ ] Apple's live dictation, on `SpeechAnalyzer` / `SpeechTranscriber` and marked
            `@available(iOS 26, *)` — see `docs/decisions/0016-the-newer-speech-api.md`
      - [ ] Apple's on-device text recognition (Vision)
      - [ ] Real permission requests

      > ⚠️ **This module cannot yet hear anybody.** The seams and fakes are built and
      > tested; nothing behind them talks to a microphone or a camera. That half needs a
      > Mac and a device — a CI simulator has neither — so it waits rather than being
      > written blind. An app can build every screen against the fakes today.
      >
      > Not blocked by the Apple Developer Program: Speech and Vision are free
      > frameworks. Blocked only on having a device to verify against.

**Done means:** each works on a physical device, not just in the simulator. Push
notifications in particular cannot be verified in a simulator.

**Blocked on:** Apple Developer Program enrollment.

## Phase 3 — Money ⬜

- [ ] `PPPay` — StoreKit 2 subscriptions, entitlement checks, paywall components
- [ ] Apply for Apple's Small Business Program (15% rather than 30%)

**Done means:** a test purchase completes in a sandbox account and the entitlement is
correctly read back.

## Phase 4 — The travel app ⬜

The real test. See `docs/first-app.md`.

- [ ] App template with the rename script
- [ ] Travel app built on the foundation
- [ ] Works fully in airplane mode
- [ ] Family sharing of one trip via CloudKit
- [ ] On TestFlight, installed by real family members

**Done means:** someone who isn't Dave has it on their phone and used it on a real trip.

## Phase 5 — Proving it's general ⬜

- [ ] Second app (scripture study) built on the same foundation
- [ ] Measure honestly: did app two take meaningfully less time than app one?

**This is the phase that proves the foundation was worth building.** Everything before it
is one app with extra structure. If app two isn't dramatically faster, say so plainly and
fix the foundation rather than declaring victory.

## Phase 6 — The rest ⬜

- [ ] Health and fitness app
- [ ] College student app
- [ ] Rebuild Dossier on the foundation, retire the old repository

---

## Known blockers

| Blocker | Blocks | Status |
|---|---|---|
| Apple Developer Program enrollment | Phases 2, 3, 4 | **Application submitted 2026-09-05.** Awaiting approval; timing is unpredictable and can take weeks |
| Small Business Program application | Phase 3 pricing | Not started |
