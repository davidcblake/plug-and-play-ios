import Testing
@testable import PPCore

/// A place data lives, which can be told to fail.
private struct Store: HoldsPersonalData {
    let whatItHolds: String
    let fails: Bool

    init(_ whatItHolds: String, fails: Bool = false) {
        self.whatItHolds = whatItHolds
        self.fails = fails
    }

    func erasePersonalData() async throws {
        if fails {
            throw UnexpectedError(userMessage: "Could not delete.")
        }
    }
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
