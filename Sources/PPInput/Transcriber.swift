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

    public func startDictation() async throws -> AsyncStream<Transcript> {
        throw InputFailure.dictationUnavailable
    }

    public func stopDictation() {}
}
