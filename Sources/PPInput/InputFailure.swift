import PPCore

/// Why something a person tried to say, photograph or grant did not work.
///
/// Carries both of `PPCore`'s voices: one for the person, one for the log.
public struct InputFailure: PPError, Equatable {
    public let userMessage: String
    public let logMessage: String

    public init(userMessage: String, logMessage: String? = nil) {
        self.userMessage = userMessage
        self.logMessage = logMessage ?? userMessage
    }

    /// Nothing has been wired up to listen. The default an app gets before it
    /// injects anything, and the right answer for an app that does not dictate.
    public static let dictationUnavailable = InputFailure(
        userMessage: "Dictation isn't set up in this app.",
        logMessage: "No Transcriber was injected, so NoTranscriber answered."
    )

    /// Nothing has been wired up to read text out of pictures.
    public static let textRecognitionUnavailable = InputFailure(
        userMessage: "Reading text from photos isn't set up in this app.",
        logMessage: "No TextRecognizer was injected, so NoTextRecognizer answered."
    )

    /// The person said no, or was never asked.
    public static let notPermitted = InputFailure(
        userMessage: "This needs your permission first.",
        logMessage: "Permission was not granted at the time of use."
    )
}
