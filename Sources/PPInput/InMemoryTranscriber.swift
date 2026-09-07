import Foundation
import os

/// A transcriber that hears exactly what you tell it to.
///
/// This is how a dictation screen gets built and tested without a microphone,
/// a person, or a quiet room. Give it the words, and it delivers them the way
/// real dictation does — improving guesses, then one final version.
///
/// It ships in `PPInput` rather than a test target for the same reason
/// `RecordingLogSink` ships in `PPCore`: every app on this foundation needs it,
/// and four slightly different copies would be worse than one.
///
/// ```swift
/// let transcriber = InMemoryTranscriber(hears: ["Colosseum", "Colosseum at nine"])
/// ```
///
/// Safe to use from more than one task at a time.
public final class InMemoryTranscriber: Transcriber {
    private struct State {
        var isListening = false
        var timesStopped = 0
        var timesPrepared = 0
        var readiness: TranscriberReadiness
    }

    private let phrases: [String]
    private let failure: InputFailure?
    private let state: OSAllocatedUnfairLock<State>

    /// - Parameters:
    ///   - phrases: What it hears, in order. The last one is the final
    ///     transcript; everything before it is a guess along the way.
    ///   - failure: When set, starting throws this instead of listening —
    ///     which is how the "you said no to the microphone" screen gets built.
    ///   - readiness: Where it starts. Use ``TranscriberReadiness/needsPreparing``
    ///     to build the first-run screen, which is otherwise reachable exactly
    ///     once per device and impossible to get back to.
    public init(
        hears phrases: [String] = [],
        failsWith failure: InputFailure? = nil,
        readiness: TranscriberReadiness = .ready
    ) {
        self.phrases = phrases
        self.failure = failure
        state = OSAllocatedUnfairLock(initialState: State(readiness: readiness))
    }

    /// Whether it is listening right now.
    public var isListening: Bool {
        state.withLock { $0.isListening }
    }

    /// How many times it has been asked to stop.
    ///
    /// A view that forgets to stop dictation leaves a microphone open, which is
    /// both a battery problem and the kind of thing that frightens people. This
    /// is here so a test can prove the view remembered.
    public var timesStopped: Int {
        state.withLock { $0.timesStopped }
    }

    /// How many times it has been asked to fetch its language model.
    ///
    /// Fetching twice is a wasted download on somebody's cellular connection,
    /// so this is here for a test to prove it happened once.
    public var timesPrepared: Int {
        state.withLock { $0.timesPrepared }
    }

    public func readiness() async -> TranscriberReadiness {
        state.withLock { $0.readiness }
    }

    public func prepare() async throws {
        if let failure {
            throw failure
        }
        state.withLock {
            $0.timesPrepared += 1
            $0.readiness = .ready
        }
    }

    public func startDictation() async throws -> AsyncStream<Transcript> {
        if let failure {
            throw failure
        }

        state.withLock { $0.isListening = true }

        let phrases = phrases
        return AsyncStream { continuation in
            for (index, phrase) in phrases.enumerated() {
                continuation.yield(
                    Transcript(text: phrase, isFinal: index == phrases.count - 1)
                )
            }
            continuation.finish()
        }
    }

    public func stopDictation() {
        state.withLock {
            $0.isListening = false
            $0.timesStopped += 1
        }
    }
}
