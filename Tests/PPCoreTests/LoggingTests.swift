import Testing
@testable import PPCore

@Suite("Log levels")
struct LogLevelTests {
    @Test("Levels order from chattiest to most severe")
    func ordering() {
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
    }

    @Test("A threshold filter keeps the severe entries and drops the chatty ones")
    func thresholdFiltering() {
        let kept = LogLevel.allCases.filter { $0 >= .warning }
        #expect(kept == [.warning, .error])
    }
}

@Suite("Recording sink")
struct RecordingLogSinkTests {
    @Test("Records what it is given, oldest first")
    func recordsInOrder() {
        let sink = RecordingLogSink()
        sink.info("first", category: "trip")
        sink.error("second", category: "sync")

        #expect(sink.entries.count == 2)
        #expect(sink.entries[0].message == "first")
        #expect(sink.entries[1].message == "second")
    }

    @Test("Convenience methods set the level the caller asked for")
    func convenienceMethodsSetLevels() {
        let sink = RecordingLogSink()
        sink.debug("d", category: "c")
        sink.info("i", category: "c")
        sink.warning("w", category: "c")
        sink.error("e", category: "c")

        #expect(sink.entries.map(\.level) == [.debug, .info, .warning, .error])
    }

    @Test("Category travels with the entry")
    func carriesCategory() {
        let sink = RecordingLogSink()
        sink.info("saved the trip", category: "storage")

        #expect(sink.entries.first?.category == "storage")
    }

    @Test("Filtering by level returns only that level")
    func filtersByLevel() {
        let sink = RecordingLogSink()
        sink.info("fine", category: "c")
        sink.error("broken", category: "c")
        sink.error("also broken", category: "c")

        #expect(sink.entries(at: .error).map(\.message) == ["broken", "also broken"])
        #expect(sink.entries(at: .warning).isEmpty)
    }

    @Test("Reset empties the recording")
    func resetClears() {
        let sink = RecordingLogSink()
        sink.info("before", category: "c")
        sink.reset()

        #expect(sink.entries.isEmpty)
    }

    @Test("Writing from many tasks at once loses nothing")
    func concurrentWritesAreSafe() async {
        let sink = RecordingLogSink()
        let writes = 500

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<writes {
                group.addTask { sink.info("entry \(index)", category: "concurrency") }
            }
        }

        #expect(sink.entries.count == writes)
    }
}

@Suite("No-op sink")
struct NoOpLogSinkTests {
    @Test("Accepts entries and keeps nothing")
    func swallowsEntries() {
        let sink = NoOpLogSink()
        sink.error("this goes nowhere", category: "c")
        // Nothing to assert beyond it not trapping: the point of the default
        // sink is that logging before anything is wired up is harmless.
    }
}
