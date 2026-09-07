import CloudKit
import Foundation
import os
import Testing
@testable import PPData

/// An iCloud account a test can sign in and out of.
///
/// The provider asks one question — what is the account status — and this is
/// what answers it. Everything a CI simulator cannot do (be signed in, be
/// signed out a second later, refuse to answer at all) happens here.
private final class Account: Sendable {
    struct Unreachable: Error {}

    private let answer: OSAllocatedUnfairLock<CKAccountStatus?>

    init(_ status: CKAccountStatus) {
        answer = OSAllocatedUnfairLock(initialState: status)
    }

    func set(_ status: CKAccountStatus) {
        answer.withLock { $0 = status }
    }

    /// Stop answering, the way a device that cannot reach CloudKit does.
    func stopAnswering() {
        answer.withLock { $0 = nil }
    }

    func status() async throws -> CKAccountStatus {
        guard let status = answer.withLock({ $0 }) else { throw Unreachable() }
        return status
    }
}

/// Wait for the first status this provider reports that the test is about.
///
/// Every test using this carries a time limit, so a provider that never reports
/// what is expected fails the test rather than hanging it forever — which is
/// the worst way for a test to be wrong.
private func firstStatus(
    from provider: CloudKitSyncProvider,
    matching predicate: (SyncStatus) -> Bool
) async -> SyncStatus? {
    for await status in provider.statusUpdates() where predicate(status) {
        return status
    }
    return nil
}

@Suite("Sync backed by iCloud")
struct CloudKitSyncProviderTests {
    @Test("Every answer iCloud can give turns into something a person could be told")
    func mapsEveryAccountStatus() {
        #expect(CloudKitSyncProvider.availability(for: .available) == .ready)
        #expect(CloudKitSyncProvider.availability(for: .noAccount) == .notSignedIn)
        #expect(CloudKitSyncProvider.availability(for: .restricted) == .restricted)
        #expect(CloudKitSyncProvider.availability(for: .couldNotDetermine) == .unknown)
        // Signed in, but iCloud is waiting on a password or new terms. Not the
        // same as a device that forbids iCloud, and told differently.
        #expect(CloudKitSyncProvider.availability(for: .temporarilyUnavailable) == .needsAttention)
    }

    @Test("Asks iCloud without being told to", .timeLimit(.minutes(1)))
    func asksOnItsOwn() async {
        let account = Account(.available)
        let (changes, _) = AsyncStream<Void>.makeStream()
        let provider = CloudKitSyncProvider(
            askingAccountStatus: { try await account.status() },
            watching: changes
        )

        // Nothing called `refresh()`. An app that had to remember to start this
        // would be an app reporting `unknown` forever.
        let ready = await firstStatus(from: provider) { $0.availability == .ready }

        #expect(ready?.availability == .ready)
    }

    @Test("Asks again when somebody signs out of iCloud", .timeLimit(.minutes(1)))
    func noticesSomebodySigningOut() async {
        let account = Account(.available)
        let (changes, iCloudSaysTheAccountChanged) = AsyncStream<Void>.makeStream()
        let provider = CloudKitSyncProvider(
            askingAccountStatus: { try await account.status() },
            watching: changes
        )
        _ = await firstStatus(from: provider) { $0.availability == .ready }

        account.set(.noAccount)
        iCloudSaysTheAccountChanged.yield()

        let signedOut = await firstStatus(from: provider) { $0.availability == .notSignedIn }
        #expect(signedOut?.availability == .notSignedIn)
        #expect(signedOut?.isWorthMentioning == true)
    }

    @Test("Never claims to be syncing, and never invents a last-synced time", .timeLimit(.minutes(1)))
    func staysHonestAboutWhatItCannotKnow() async {
        let account = Account(.available)
        let (changes, _) = AsyncStream<Void>.makeStream()
        let provider = CloudKitSyncProvider(
            askingAccountStatus: { try await account.status() },
            watching: changes
        )

        let ready = await firstStatus(from: provider) { $0.availability == .ready }

        // SwiftData exposes neither of these. A spinner on a timer and a
        // "last synced" that really means "last launched" are both lies a
        // person would make decisions on. See docs/decisions/0022.
        #expect(ready?.activity == .idle)
        #expect(ready?.lastSynced == nil)
    }

    @Test("A check that fails does not forget what was already known", .timeLimit(.minutes(1)))
    func aFailedCheckKeepsWhatItKnew() async {
        let account = Account(.available)
        let (changes, iCloudSaysTheAccountChanged) = AsyncStream<Void>.makeStream()
        let provider = CloudKitSyncProvider(
            askingAccountStatus: { try await account.status() },
            watching: changes
        )
        _ = await firstStatus(from: provider) { $0.availability == .ready }

        account.stopAnswering()
        iCloudSaysTheAccountChanged.yield()

        let failed = await firstStatus(from: provider) {
            if case .failed = $0.activity { return true }
            return false
        }

        // "You were signed in a moment ago and we could not check just now" is
        // both more useful and more true than going back to knowing nothing.
        #expect(failed?.availability == .ready)
        #expect(failed?.isWorthMentioning == true)
    }

    @Test("The person is told their data is still on the phone", .timeLimit(.minutes(1)))
    func theFailureSaysTheDataIsSafe() async {
        let account = Account(.available)
        account.stopAnswering()
        let (changes, _) = AsyncStream<Void>.makeStream()
        let provider = CloudKitSyncProvider(
            askingAccountStatus: { try await account.status() },
            watching: changes
        )

        let failed = await firstStatus(from: provider) {
            if case .failed = $0.activity { return true }
            return false
        }

        guard let activity = failed?.activity, case .failed(let failure) = activity else {
            Issue.record("Expected the provider to report a failed check")
            return
        }
        // Nothing about sync failing stops the app working, and the message
        // has to say so — otherwise it reads as "your notes are gone".
        #expect(failure.userMessage.contains("still on this phone"))
        #expect(failure.logMessage.contains("accountStatus"))
    }
}
