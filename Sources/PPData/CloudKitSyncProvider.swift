import CloudKit
import Foundation
import os

/// What an app can tell somebody about iCloud syncing, backed by their real
/// iCloud account.
///
/// ```swift
/// @main
/// struct VEYAApp: App {
///     private let sync = CloudKitSyncProvider()
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///         .syncProvider(sync)
///     }
/// }
/// ```
///
/// **This does not sync anything, and cannot.** SwiftData mirrors to CloudKit
/// on its own, on a schedule Apple decides — see ``SyncProvider``, which has no
/// `sync()` for that reason. What this adds is the one question SwiftData never
/// answers: *can* syncing happen for this person at all. An app that never asks
/// is an app that silently never syncs for anybody who is not signed into
/// iCloud, and never says so.
///
/// **Asking costs nothing and works offline.** `CKContainer.accountStatus()`
/// reads the account state already on the device; it is not a network call. A
/// phone in airplane mode still answers it, which is what lets this sit in a
/// local-first app without putting a network on the path to anything.
///
/// ## What it deliberately does not report
///
/// ``SyncStatus/activity`` is always ``SyncActivity/idle`` unless a check
/// itself failed. **SwiftData exposes no sync progress**, so "currently
/// syncing" is not knowable through any API this foundation is allowed to use,
/// and ``SyncStatus/lastSynced`` is always `nil` for the same reason. Inventing
/// either — a spinner on a timer, a "last synced" that means "last launched" —
/// would be a lie told in a status, and a person would make decisions on it.
/// See `docs/decisions/0022-the-cloudkit-sync-provider.md`.
public final class CloudKitSyncProvider: SyncProvider {
    private let broadcaster: SyncStatusBroadcaster
    private let askCloudKit: @Sendable () async throws -> CKAccountStatus
    /// The task asking, and re-asking. Cancelled when the provider goes away.
    private let watcher = OSAllocatedUnfairLock<Task<Void, Never>?>(initialState: nil)

    /// Watch the account behind this app's CloudKit container.
    ///
    /// - Parameter containerIdentifier: The container to ask about, such as
    ///   `"iCloud.com.example.veya"`. `nil` — the default — uses whichever
    ///   container the app's entitlements name, which is right for an app with
    ///   exactly one. Name it when the app has more than one, or when it stores
    ///   data in a container belonging to a different app in the family.
    ///
    /// It starts asking immediately, and asks again whenever iCloud says the
    /// account changed. There is nothing to start and nothing to remember to
    /// call: a provider that had to be switched on would spend its life
    /// reporting ``SyncAvailability/unknown`` in the one app whose author
    /// forgot.
    public convenience init(containerIdentifier: String? = nil) {
        self.init(
            askingAccountStatus: {
                // Built here rather than captured, so that nothing touches
                // CloudKit until somebody actually asks a question.
                let container = containerIdentifier.map { CKContainer(identifier: $0) } ?? CKContainer.default()
                return try await container.accountStatus()
            },
            watching: Self.accountChanges()
        )
    }

    /// The one a test uses.
    ///
    /// Not a second seam bolted behind the first: ``SyncProvider`` is the seam
    /// an app codes against and ``InMemorySyncProvider`` is the fake it tests
    /// with. This exists because *this type's own* behaviour — what it makes of
    /// each answer, and what it does when the answer changes — is otherwise
    /// only checkable by signing a person in and out of iCloud by hand on a
    /// device. It is internal, so no app can reach it.
    init(
        askingAccountStatus ask: @escaping @Sendable () async throws -> CKAccountStatus,
        watching accountChanges: AsyncStream<Void>
    ) {
        // Nobody has asked yet, which is not the same as "not syncing" and not
        // the same as "ready". It is the honest state for the microsecond
        // before the first answer arrives.
        broadcaster = SyncStatusBroadcaster(SyncStatus(availability: .unknown, activity: .idle))
        askCloudKit = ask

        watcher.withLock { task in
            task = Task { [weak self] in
                await self?.refresh()
                for await _ in accountChanges {
                    await self?.refresh()
                }
            }
        }
    }

    deinit {
        watcher.withLock { $0?.cancel() }
    }

    public var status: SyncStatus {
        broadcaster.current
    }

    public func statusUpdates() -> AsyncStream<SyncStatus> {
        broadcaster.updates()
    }

    /// Ask iCloud again, now.
    ///
    /// Happens on its own at launch and whenever the account changes, so most
    /// apps never call this. It is here for the app that wants to re-check when
    /// it comes back to the foreground, after somebody has been away in
    /// Settings signing in.
    public func refresh() async {
        do {
            let account = try await askCloudKit()
            broadcaster.update(
                to: SyncStatus(
                    availability: Self.availability(for: account),
                    activity: .idle,
                    lastSynced: nil
                )
            )
        } catch {
            // Keep whatever was last known rather than falling back to
            // `unknown`: "you were signed in a moment ago and we could not
            // check just now" is more useful, and more true, than forgetting.
            var next = broadcaster.current
            next.activity = .failed(
                SyncFailure(
                    userMessage: "Couldn't check your iCloud account. Everything you've saved is still on this phone.",
                    logMessage: "CKContainer.accountStatus() failed: \(error)"
                )
            )
            broadcaster.update(to: next)
        }
    }

    /// What each of Apple's account states means for somebody using the app.
    ///
    /// Internal rather than private so it can be tested against every case
    /// without an iCloud account, which is the only part of this type a
    /// simulator can check.
    static func availability(for account: CKAccountStatus) -> SyncAvailability {
        switch account {
        case .available:
            .ready
        case .noAccount:
            .notSignedIn
        case .restricted:
            .restricted
        case .temporarilyUnavailable:
            .needsAttention
        case .couldNotDetermine:
            .unknown
        @unknown default:
            // A state Apple added after this was written. Claiming it is ready
            // would be a guess in the direction that fails silently.
            .unknown
        }
    }

    /// iCloud saying the account changed — somebody signed in, signed out, or
    /// switched to a different Apple Account.
    ///
    /// Void rather than the notification itself: nothing in it is used, and the
    /// answer is always the same — go and ask again.
    private static func accountChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let watching = Task {
                for await _ in NotificationCenter.default.notifications(named: .CKAccountChanged) {
                    continuation.yield()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in watching.cancel() }
        }
    }
}
