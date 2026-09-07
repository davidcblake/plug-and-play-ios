import Foundation
import Testing
import os
@testable import PPCore

/// A place data lives, which can be told to fail.
private struct Store: HoldsPersonalData {
    let whatItHolds: String
    let fails: Bool
    /// What is still there afterwards. Non-zero models the worst kind of
    /// store: one that says it deleted and did not.
    let remainingAfterErasing: Int
    let startingCount: Int
    /// Set while erasing so a test can tell "already deleted" from "never
    /// asked".
    private let erased = ErasedFlag()

    init(
        _ whatItHolds: String,
        count: Int = 1,
        fails: Bool = false,
        remainingAfterErasing: Int = 0
    ) {
        self.whatItHolds = whatItHolds
        self.startingCount = count
        self.fails = fails
        self.remainingAfterErasing = remainingAfterErasing
    }

    func personalDataCount() async -> Int {
        erased.value ? remainingAfterErasing : startingCount
    }

    func erasePersonalData() async throws {
        if fails {
            throw UnexpectedError(userMessage: "Could not delete.")
        }
        erased.set()
    }
}

/// A tiny box so the test double can change without being a class itself.
///
/// Locked the way everything else in this package is, rather than with
/// `@unchecked Sendable`, which `AGENTS.md` forbids without a decision record —
/// and which a test fixture is not a good enough reason to spend one on.
/// `Sendable` is spelled out because Swift infers it for structs and enums and
/// **never for classes** — a final class with immutable, `Sendable` storage has
/// to say so itself.
private final class ErasedFlag: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: false)

    var value: Bool { state.withLock { $0 } }

    func set() { state.withLock { $0 = true } }
}

@Suite("Forgetting somebody")
struct PersonalDataTests {
    @Test("Everything that let go is named, and nothing failed")
    func erasesEverything() async {
        let report = await PersonalData.erase(from: [
            Store("your notes"),
            Store("your photos"),
            Store("your sign-in")
        ])

        #expect(report.erased == ["your notes", "your photos", "your sign-in"])
        #expect(report.failed.isEmpty)
        #expect(report.isComplete)
    }

    @Test("One failure does not stop the rest")
    func keepsGoingAfterAFailure() async {
        // Stopping at the first failure leaves somebody half-deleted with no
        // way of knowing which half, and the next attempt starts from an
        // unknown state.
        let report = await PersonalData.erase(from: [
            Store("your notes"),
            Store("your photos", fails: true),
            Store("your sign-in")
        ])

        #expect(report.erased == ["your notes", "your sign-in"])
        #expect(report.failed == ["your photos"])
    }

    @Test("Anything left means the person is not deleted")
    func incompleteIsNotDeleted() async {
        // The assertion an app's "you have been deleted" screen must depend on.
        // Somebody told they are gone when they are not will stop asking.
        let report = await PersonalData.erase(from: [
            Store("your notes"),
            Store("your sign-in", fails: true)
        ])

        #expect(report.isComplete == false)
    }

    @Test("Deleting nothing succeeds")
    func nothingToDeleteIsFine() async {
        let report = await PersonalData.erase(from: [])

        #expect(report.isComplete)
        #expect(report.erased.isEmpty)
    }

    @Test("A store that says it deleted but did not is counted as a failure")
    func verifiesRatherThanTrusting() async {
        // The whole reason counting exists. A deletion that reports success
        // without checking is trust without evidence, and this is the store
        // that abuses it: it returns without throwing and keeps the data.
        let report = await PersonalData.erase(from: [
            Store("your notes"),
            Store("your photos", count: 12, remainingAfterErasing: 12)
        ])

        #expect(report.erased == ["your notes"])
        #expect(report.failed == ["your photos"])
        #expect(report.isComplete == false)
    }

    @Test("What would be deleted can be counted before anybody decides")
    func summarisesBeforeDeleting() async {
        // "487 entries going back to March" is a decision somebody can make.
        // "This cannot be undone" is a sentence they have learned to scroll past.
        let holdings = await PersonalData.summary(of: [
            Store("your notes", count: 487),
            Store("your sign-in", count: 1)
        ])

        #expect(holdings == [
            PersonalDataHolding(whatItHolds: "your notes", count: 487),
            PersonalDataHolding(whatItHolds: "your sign-in", count: 1)
        ])
    }

    @Test("Everything is asked, in the order given")
    func keepsTheCallersOrder() async {
        // Order is the caller's to choose, and it matters: revoking an identity
        // before deleting the data it protects can take away the access needed
        // to delete it.
        let report = await PersonalData.erase(from: [
            Store("first"), Store("second"), Store("third")
        ])

        #expect(report.erased == ["first", "second", "third"])
    }
}

@Suite("A deletion that was interrupted")
struct InterruptedErasureTests {
    @Test("Nothing is remembered when nobody asked")
    func remembersNothingByDefault() {
        #expect(InMemoryErasureMemory().isErasureUnfinished == false)
    }

    @Test("A finished deletion leaves nothing to come back to")
    func clearsWhenComplete() async {
        let memory = InMemoryErasureMemory()

        let report = await PersonalData.erase(
            from: [Store("your notes")],
            remembering: memory
        )

        #expect(report.isComplete)
        #expect(memory.isErasureUnfinished == false)
    }

    @Test("An incomplete deletion is still remembered")
    func remembersWhatDidNotFinish() async {
        // The app was killed, or the network died. From the person's side they
        // already tapped the button and closed the app — so if this is not
        // written down, they stay half-deleted forever and never find out.
        let memory = InMemoryErasureMemory()

        let report = await PersonalData.erase(
            from: [Store("your notes"), Store("your photos", fails: true)],
            remembering: memory
        )

        #expect(report.isComplete == false)
        #expect(memory.isErasureUnfinished)
    }

    @Test("Launching with an unfinished deletion finishes it")
    func finishesOnNextLaunch() async {
        let memory = InMemoryErasureMemory(isUnfinished: true)

        let report = await PersonalData.finishInterruptedErasure(
            of: [Store("your notes"), Store("your sign-in")],
            remembering: memory
        )

        #expect(report?.isComplete == true)
        #expect(memory.isErasureUnfinished == false)
    }

    @Test("Launching normally does nothing at all")
    func doesNothingWhenNobodyIsPartDeleted() async {
        // Almost every launch. It must be free and must not touch anything.
        let memory = InMemoryErasureMemory()

        let report = await PersonalData.finishInterruptedErasure(
            of: [Store("your notes")],
            remembering: memory
        )

        #expect(report == nil)
    }

    @Test("The flag survives the app closing")
    func survivesRelaunch() {
        let suiteName = "pp.erasure.tests.\(UUID().uuidString)"
        defer { UserDefaults.standard.removeSuite(named: suiteName) }
        let memory = DefaultsErasureMemory(suiteName: suiteName)

        memory.rememberErasureStarted()

        // A second reader is what "the app was killed and reopened" looks like.
        #expect(DefaultsErasureMemory(suiteName: suiteName).isErasureUnfinished)

        memory.rememberErasureFinished()
        #expect(DefaultsErasureMemory(suiteName: suiteName).isErasureUnfinished == false)
    }
}
