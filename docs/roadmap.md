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

> ⚠️ **This bar was not met for two days, and the checkboxes above overstated it.** Every
> tick was real, but they were earned by CI compiling the *package*, and no app had ever
> depended on it.
>
> `Example/` now does. It is generated from `Example/project.yml` by XcodeGen
> (`docs/decisions/0021-xcodegen.md`) and built by the `Example App` workflow, which is
> the first time anything has consumed this package — and the first time any of
> `PPDesign` has been on a screen.

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
      - [x] CloudKit adapter: `CloudKitSyncProvider`, reporting whether syncing can
            happen for this person from `CKContainer`'s account status, and asking
            again whenever iCloud says the account changed. `SyncStatus.activity`
            stays `.idle` and `lastSynced` stays `nil` because **SwiftData exposes no
            sync progress** — reasoning, and the three tempting lies rejected, in
            `docs/decisions/0022-the-cloudkit-sync-provider.md`
      - [x] Naming a CloudKit container: `Kind.syncedTo(container:)`, which `0008`
            deferred until there was an account to point it at
      - [ ] Sharing a record between people — **blocked**, see below

      > ⚠️ **The line that actually calls CloudKit has still never run.** Every
      > transition `CloudKitSyncProvider` makes is tested — each account status, an
      > account changing underneath it, a check that fails — but a CI simulator has no
      > iCloud account and no entitlement, so the call to `CKContainer` itself is read
      > and not run. Same for opening a `.synced` or `.syncedTo` store: only
      > `.temporary` and `.stored(at:)` are opened by tests. What *is* tested is that
      > no store a test can build points at a real iCloud container.
      >
      > **Sharing is blocked on a decision, not on an account.**
      > `docs/decisions/0020` leaves it undecided what happens to a shared record when
      > its owner deletes their account, and that has to be settled before anything
      > that can share ships.
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
            `PersonalData` in `PPCore` so an app can forget somebody across every module
            at once — counted before so a person knows what they are losing, checked
            afterwards rather than trusted, and written down before it starts so an
            interrupted deletion finishes on the next launch instead of leaving somebody
            half-deleted — `docs/decisions/0020-account-deletion.md`
      - [ ] Apple's implementation, including revoking the token — **blocked** on the
            Developer Program
      - [ ] Keychain storage of the identifier (`docs/security.md` rule 2)

      > ⚠️ **Nobody can sign in yet.** Every screen is buildable — signed out, signing in,
      > cancelled, revoked — and none of them will do anything until there is an account
      > and a device.
- [ ] `PPNotify` — push and local notifications
      - [x] Local reminders: `Reminder`, `ReminderSchedule`, the `Reminders` seam,
            `NoReminders` as the honest default and `InMemoryReminders` so a test can see
            what an app scheduled
      - [x] Two mistakes made impossible: duplicates (an id replaces rather than adds) and
            silently losing reminders past Apple's limit of 64 —
            `docs/decisions/0018-reminders-are-local.md`
      - [ ] Actually telling iOS (`UNUserNotificationCenter`) — needs a device
      - [ ] Push — **not started on purpose**; no planned app has yet named something that
            has to be pushed rather than worked out by the phone

      > ⚠️ **Nothing here has fired a real notification.** That needs a device and somebody
      > waiting until tomorrow morning. What is tested is what an app scheduled and whether
      > it made either of the two classic mistakes.
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
| ~~Apple Developer Program enrollment~~ | ~~Phases 2, 3, 4~~ | **Cleared 2026-09-07.** Enrolled as an individual, renewing September 2027. A development certificate and App IDs for Spindle and Dossier exist. No CloudKit containers yet, and no App ID for VEYA |
| Small Business Program application | Phase 3 pricing | Not started |
