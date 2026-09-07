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

@Suite("Getting ready to listen")
struct TranscriberReadinessTests {
    @Test("Ready by default, because that is every use after the first")
    func readyUnlessToldOtherwise() async {
        let readiness = await InMemoryTranscriber().readiness()

        #expect(readiness == .ready)
    }

    @Test("Preparing fetches the language model once and then it is ready")
    func preparingMakesItReady() async throws {
        let transcriber = InMemoryTranscriber(hears: ["a note"], readiness: .needsPreparing)
        let before = await transcriber.readiness()

        try await transcriber.prepare()
        let after = await transcriber.readiness()

        #expect(before == .needsPreparing)
        #expect(after == .ready)
        #expect(transcriber.timesPrepared == 1)
    }

    @Test("Preparing something already ready does not fetch again")
    func doesNotRefetch() async throws {
        // A second download is somebody's cellular allowance spent on nothing.
        let transcriber = InMemoryTranscriber()

        try await transcriber.prepare()
        let readiness = await transcriber.readiness()

        #expect(readiness == .ready)
        #expect(transcriber.timesPrepared == 1)
    }

    @Test("A model that cannot be fetched fails with something readable")
    func preparingCanFail() async throws {
        let transcriber = InMemoryTranscriber(
            failsWith: .notPermitted,
            readiness: .needsPreparing
        )

        do {
            try await transcriber.prepare()
            Issue.record("Preparing succeeded when it should have failed")
        } catch let failure as InputFailure {
            #expect(failure == .notPermitted)
        }

        // Still not ready, so an app cannot mistake a failed download for a
        // working microphone.
        let readiness = await transcriber.readiness()
        #expect(readiness == .needsPreparing)
    }
}

@Suite("An app that does not dictate")
struct NoTranscriberTests {
    @Test("Is unavailable rather than merely not ready")
    func isUnavailableNotPending() async {
        // The difference matters: "not ready" invites an app to show a
        // "preparing" screen forever. "unavailable" tells it to stop offering.
        let readiness = await NoTranscriber().readiness()

        #expect(readiness == .unavailable)
    }

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
