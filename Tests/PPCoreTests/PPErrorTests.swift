import Testing
@testable import PPCore

private struct TripNotFound: PPError {
    let userMessage = "That trip is no longer on your phone."
}

private struct SyncRefused: PPError {
    let userMessage = "Couldn't sync. Your changes are safe on this phone."
    let logMessage = "CKError.permissionFailure on private database"
}

private struct Underlying: Error, Sendable {}

@Suite("PPError")
struct PPErrorTests {
    @Test("Log message falls back to the user message when none is given")
    func logMessageDefaultsToUserMessage() {
        let error = TripNotFound()
        #expect(error.logMessage == error.userMessage)
    }

    @Test("A specific log message is kept separate from what the user sees")
    func logMessageCanDiffer() {
        let error = SyncRefused()
        #expect(error.userMessage == "Couldn't sync. Your changes are safe on this phone.")
        #expect(error.logMessage == "CKError.permissionFailure on private database")
        #expect(error.logMessage != error.userMessage)
    }
}

@Suite("UnexpectedError")
struct UnexpectedErrorTests {
    @Test("Has a plain-language default a person could actually read")
    func hasReadableDefault() {
        let error = UnexpectedError()
        #expect(error.userMessage == "Something went wrong. Please try again.")
    }

    @Test("Describes the wrapped error in the log, not on screen")
    func describesUnderlyingInLog() {
        let error = UnexpectedError(underlying: Underlying())

        #expect(error.logMessage.contains("Underlying"))
        #expect(error.userMessage == "Something went wrong. Please try again.")
    }

    @Test("An explicit log message wins over the wrapped error's description")
    func explicitLogMessageWins() {
        let error = UnexpectedError(
            logMessage: "migration v3 -> v4 failed",
            underlying: Underlying()
        )

        #expect(error.logMessage == "migration v3 -> v4 failed")
    }
}
