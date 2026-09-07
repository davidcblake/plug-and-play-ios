import Foundation
import Testing
@testable import PPInput

@Suite("Words heard")
struct TranscriptTests {
    @Test("A transcript is a guess unless it says otherwise")
    func defaultsToNotFinal() {
        #expect(Transcript(text: "Colosseum").isFinal == false)
        #expect(Transcript(text: "Colosseum at nine", isFinal: true).isFinal)
    }
}

@Suite("Dictation")
struct InMemoryTranscriberTests {
    @Test("Delivers what it heard, improving until the last one")
    func deliversPhrasesInOrder() async throws {
        let transcriber = InMemoryTranscriber(hears: ["Colosseum", "Colosseum at nine"])

        let stream = try await transcriber.startDictation()
        var heard: [Transcript] = []
        for await transcript in stream {
            heard.append(transcript)
        }

        #expect(heard.map(\.text) == ["Colosseum", "Colosseum at nine"])
        // Exactly one final, and it is the last. A view that redraws on every
        // transcript settles when this arrives.
        #expect(heard.map(\.isFinal) == [false, true])
    }

    @Test("Hearing nothing still finishes")
    func silenceStillEnds() async throws {
        let stream = try await InMemoryTranscriber().startDictation()

        var heard: [Transcript] = []
        for await transcript in stream {
            heard.append(transcript)
        }

        // Somebody will tap the microphone and say nothing. A stream that hung
        // open there would freeze the screen rather than fail it.
        #expect(heard.isEmpty)
    }

    @Test("A refused microphone throws instead of listening silently")
    func failsWhenItCannotListen() async throws {
        let transcriber = InMemoryTranscriber(failsWith: .notPermitted)

        do {
            _ = try await transcriber.startDictation()
            Issue.record("Dictation started when it should have failed")
        } catch let failure as InputFailure {
            #expect(failure == .notPermitted)
        }

        #expect(transcriber.isListening == false)
    }

    @Test("Starting listens, stopping stops")
    func tracksWhetherItIsListening() async throws {
        let transcriber = InMemoryTranscriber(hears: ["a note"])
        #expect(transcriber.isListening == false)

        _ = try await transcriber.startDictation()
        #expect(transcriber.isListening)

        transcriber.stopDictation()
        #expect(transcriber.isListening == false)
        #expect(transcriber.timesStopped == 1)
    }

    @Test("Stopping when nothing is listening is harmless")
    func stoppingTwiceIsFine() {
        let transcriber = InMemoryTranscriber()

        transcriber.stopDictation()
        transcriber.stopDictation()

        // A view dismissed halfway does not know what state it was in, so this
        // has to be safe rather than clever.
        #expect(transcriber.timesStopped == 2)
        #expect(transcriber.isListening == false)
    }
}

@Suite("An app that does not dictate")
struct NoTranscriberTests {
    @Test("Says dictation is not set up rather than appearing to listen")
    func failsWithSomethingReadable() async throws {
        do {
            _ = try await NoTranscriber().startDictation()
            Issue.record("NoTranscriber started listening")
        } catch let failure as InputFailure {
            #expect(failure == .dictationUnavailable)
            // The person is told something plain; the log gets the detail.
            #expect(failure.userMessage.contains("isn't set up"))
            #expect(failure.logMessage.contains("NoTranscriber"))
            #expect(failure.userMessage != failure.logMessage)
        }
    }
}
