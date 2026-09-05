/// An error that knows how to talk to a person and how to talk to a log.
///
/// The split is the whole point. `userMessage` is shown on screen and must be
/// something a person can act on, in their words. `logMessage` carries the
/// detail an engineer needs and is never shown to anyone.
///
/// Feature code should define its own error types conforming to this rather
/// than throwing strings or leaking a framework's error text into the
/// interface — "The operation couldn't be completed (NSURLErrorDomain -1009)"
/// is a failure of manners, not just of wording.
public protocol PPError: Error, Sendable {
    /// Shown to the person using the app. Plain language, and where possible,
    /// what they can do about it.
    var userMessage: String { get }

    /// Written to the log. Free to name types, codes, and internals — this
    /// never reaches a screen.
    var logMessage: String { get }
}

extension PPError {
    /// Defaults to the user-facing text, so a conforming type only has to
    /// supply `logMessage` when it has something more specific to say.
    public var logMessage: String { userMessage }
}

/// The failure to reach for when nothing more specific fits yet.
///
/// Deliberately plain. If you find an app throwing this in more than a couple
/// of places, that is a sign the feature needs its own named error type — see
/// the `PPError` documentation.
public struct UnexpectedError: PPError {
    public let userMessage: String
    public let logMessage: String
    /// The underlying error, when this is wrapping one.
    ///
    /// Required to be `Sendable`: `PPError` is `Sendable`, and a stored plain
    /// `any Error` would quietly break that under Swift 6 strict concurrency.
    public let underlying: (any Error & Sendable)?

    public init(
        userMessage: String = "Something went wrong. Please try again.",
        logMessage: String? = nil,
        underlying: (any Error & Sendable)? = nil
    ) {
        self.userMessage = userMessage
        self.underlying = underlying
        // A blank log message is worse than no log message: it looks like the
        // error was recorded when nothing usable was. Treat it as absent and
        // fall through to something that actually says what happened.
        self.logMessage = logMessage?.nonBlank
            ?? underlying.map { String(describing: $0) }
            ?? userMessage
    }
}

extension String {
    /// `nil` when this is empty or nothing but whitespace.
    fileprivate var nonBlank: String? {
        allSatisfy(\.isWhitespace) ? nil : self
    }
}
