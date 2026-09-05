import os

/// A sink that keeps everything it is given, so a test can assert on it.
///
/// This ships in `PPCore` rather than in the test target on purpose: every app
/// and every module built on this foundation needs it to test its own logging,
/// and one shared version beats each of them writing a slightly different fake.
///
/// Safe to use from more than one task at a time.
public final class RecordingLogSink: LogSink {
    private let storage = OSAllocatedUnfairLock(initialState: [LogEntry]())

    public init() {}

    public func write(_ entry: LogEntry) {
        storage.withLock { $0.append(entry) }
    }

    /// Everything written so far, oldest first.
    ///
    /// Hands back a copy on purpose. A test asserting against a snapshot that cannot
    /// change underneath it is worth more than avoiding the copy, and test assertion
    /// counts are never the thing that makes a suite slow.
    public var entries: [LogEntry] {
        storage.withLock { $0 }
    }

    /// Everything written at one level, oldest first.
    public func entries(at level: LogLevel) -> [LogEntry] {
        storage.withLock { $0.filter { $0.level == level } }
    }

    /// Throw away what has been recorded, so one test can reuse the sink
    /// across phases without seeing the earlier phase's entries.
    public func reset() {
        storage.withLock { $0.removeAll() }
    }
}
