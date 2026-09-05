import Testing
@testable import PPCore

private struct TripNotFound: PPError {
    let userMessage = "That trip is no longer on your phone."
}

private struct SyncRefused: PPError {
    let userMessage = "Couldn't sync. Your changes are safe on this phone."
    let logMessage = "CKError.permissionFailure on private database"
}

/// Gives `String(describing:)` something stable to produce, so the assertions
/// below test intent rather than how the compiler happens to render a type name.
private struct Underlying: Error, Sendable, CustomStringConvertible {
    let description = "the underlying failure"
}

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

        #expect(error.logMessage == "the underlying failure")
        #expect(error.userMessage == "Something went wrong. Please try again.")
    }

    @Test(
        "A blank log message falls through instead of recording nothing",
        arguments: ["", "   ", "\n\t"]
    )
    func blankLogMessageFallsThrough(blank: String) {
        let wrapping = UnexpectedError(logMessage: blank, underlying: Underlying())
        #expect(wrapping.logMessage == "the underlying failure")

        let bare = UnexpectedError(userMessage: "Couldn't save.", logMessage: blank)
        #expect(bare.logMessage == "Couldn't save.")
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
