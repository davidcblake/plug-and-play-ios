import Foundation

/// Words heard so far.
///
/// Dictation arrives in pieces: a guess that improves as somebody keeps
/// talking, and eventually one last version that stops changing. `isFinal`
/// says which of those this is, and it is the difference between a text field
/// that flickers and one that settles.
public struct Transcript: Sendable, Equatable {
    /// Everything heard so far in this stretch of talking, not just the newest
    /// words. A view shows this and nothing else.
    public let text: String
    /// Whether this stops changing. The last one in a stream is final; every
    /// one before it is a guess.
    public let isFinal: Bool

    public init(text: String, isFinal: Bool = false) {
        self.text = text
        self.isFinal = isFinal
    }
}

/// Whether dictation can happen, and what it needs first.
///
/// This exists because of how on-device speech recognition actually works: the
/// language model is **downloaded on first use**. Until it is there, an app
/// that says "listening" is lying, and an app that just fails looks broken.
///
/// It is also the one moment dictation touches the network, which is worth
/// being honest about in a foundation that promises everything works offline.
/// Once prepared, it never needs the network again.
public enum TranscriberReadiness: Sendable, Equatable {
    /// Ready now, with no network and nothing to wait for. The normal state,
    /// and the state every use after the first.
    case ready
    /// The language model has to be fetched before anything can be heard.
    /// Once, on a network, and then never again.
    case needsPreparing
    /// This device or this language cannot do it at all. Not a wait — an
    /// answer. An app should stop offering dictation rather than showing a
    /// button that fails.
    case unavailable
}

/// Turning speech into words.
///
/// The seam every app dictates through. Nothing above this line knows whether
/// the words came from Apple's speech recognition, from a test, or from a
/// preview.
///
/// **This is deliberately not a "record audio" API.** Nothing here hands back a
/// recording, because none of the planned apps want one — they want the words.
/// Keeping audio out of the seam means audio never has to be stored, moved, or
/// explained to anybody.
public protocol Transcriber: Sendable {
    /// Whether dictation can happen right now, and what it needs first.
    ///
    /// Safe to ask on launch — this is looking, not downloading, and not
    /// asking anybody for permission.
    func readiness() async -> TranscriberReadiness

    /// Fetch whatever is missing, which today means the language model.
    ///
    /// Slow, needs a network, and happens once. Call it when somebody has
    /// shown they want to dictate — not on launch, for the same reason
    /// permissions are not asked on launch.
    ///
    /// Doing nothing is the correct behaviour when already ``TranscriberReadiness/ready``.
    ///
    /// - Throws: ``InputFailure`` when the model could not be fetched.
    func prepare() async throws

    /// Start listening.
    ///
    /// The stream yields a better guess each time the words change, then one
    /// final transcript, then finishes. It always finishes — a view can `for
    /// await` over it without arranging its own way out.
    ///
    /// - Throws: ``InputFailure`` when listening cannot start at all: no
    ///   permission, no recogniser, no microphone.
    func startDictation() async throws -> AsyncStream<Transcript>

    /// Stop listening. The stream finishes after its final transcript.
    ///
    /// Safe to call when nothing is listening, because a view that got
    /// dismissed halfway does not know what state it was in.
    func stopDictation()
}

/// Cannot hear anything, and says so.
///
/// The default. An app that has not wired up dictation is not listening, and
/// this reports that plainly rather than appearing to work and staying silent.
public struct NoTranscriber: Transcriber {
    public init() {}

    public func readiness() async -> TranscriberReadiness { .unavailable }

    public func prepare() async throws {
        throw InputFailure.dictationUnavailable
    }

    public func startDictation() async throws -> AsyncStream<Transcript> {
        throw InputFailure.dictationUnavailable
    }

    public func stopDictation() {}
}
