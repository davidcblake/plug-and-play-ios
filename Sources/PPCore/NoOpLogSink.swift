/// Throws every entry away.
///
/// The default sink, so that a view logging before anything is wired up is
/// harmless rather than a crash. Also useful in a test that does not care about
/// logging and does not want to assert on it.
public struct NoOpLogSink: LogSink {
    public init() {}
    public func write(_ entry: LogEntry) {}
}
