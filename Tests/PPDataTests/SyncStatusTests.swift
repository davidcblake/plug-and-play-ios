import Foundation
import Testing
@testable import PPData

@Suite("What an app knows about syncing")
struct SyncStatusTests {
    @Test("A new status assumes nothing")
    func defaultsToUnknown() {
        let status = SyncStatus()

        #expect(status.availability == .unknown)
        #expect(status.activity == .idle)
        #expect(status.lastSynced == nil)
    }

    @Test("Ordinary syncing is not worth interrupting anybody about")
    func quietWhenNormal() {
        #expect(SyncStatus(availability: .ready, activity: .idle).isWorthMentioning == false)
        #expect(SyncStatus(availability: .ready, activity: .working).isWorthMentioning == false)
        // An app that was built not to sync is not broken, so it says nothing.
        #expect(SyncStatus(availability: .turnedOff, activity: .idle).isWorthMentioning == false)
        #expect(SyncStatus(availability: .unknown, activity: .idle).isWorthMentioning == false)
    }

    @Test("Not being signed in is worth saying, because only the person can fix it")
    func speaksUpWhenThePersonCanAct() {
        #expect(SyncStatus(availability: .notSignedIn).isWorthMentioning)
        #expect(SyncStatus(availability: .restricted).isWorthMentioning)
        // The one somebody can clear in a minute in Settings, which makes it
        // the most worth saying of the three.
        #expect(SyncStatus(availability: .needsAttention).isWorthMentioning)
    }

    @Test("A failure is worth saying even when everything else looks fine")
    func speaksUpOnFailure() {
        let failed = SyncStatus(
            availability: .ready,
            activity: .failed(SyncFailure(userMessage: "Could not reach iCloud."))
        )

        #expect(failed.isWorthMentioning)
    }

    @Test("A sync failure has one message for a person and one for the log")
    func failureKeepsTheTwoVoicesApart() {
        let spelledOut = SyncFailure(
            userMessage: "Could not reach iCloud. Your notes are safe on this phone.",
            logMessage: "CKError 4097: connection to service failed"
        )
        #expect(spelledOut.userMessage.contains("safe on this phone"))
        #expect(spelledOut.logMessage.contains("CKError"))

        // With nothing specific to log, the log gets the readable one rather
        // than an empty string, matching `UnexpectedError` in PPCore.
        let plain = SyncFailure(userMessage: "Could not reach iCloud.")
        #expect(plain.logMessage == plain.userMessage)
    }
}
