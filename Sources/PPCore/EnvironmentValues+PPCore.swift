import SwiftUI

/// Carries the log sink down the view tree.
///
/// This is how `AGENTS.md` says dependencies travel: through the SwiftUI
/// environment, never through a singleton. An app injects its real sink once at
/// the root, a test injects a `RecordingLogSink`, and no view in between knows
/// or cares which it got.
///
/// Written as an explicit `EnvironmentKey` rather than with the `@Entry` macro
/// on purpose — see the hard-won facts in `AGENTS.md`.
private struct LogSinkKey: EnvironmentKey {
    /// Deliberately does nothing. A view that logs before anyone injected a
    /// real sink should be silent, not crash and not invent a subsystem name.
    static let defaultValue: any LogSink = NoOpLogSink()
}

extension EnvironmentValues {
    /// Where this part of the view tree writes its logs.
    public var logSink: any LogSink {
        get { self[LogSinkKey.self] }
        set { self[LogSinkKey.self] = newValue }
    }
}

extension View {
    /// Inject the log sink for this view and everything below it.
    ///
    /// Call once at the app's root with a `SystemLogSink`, or in a test with a
    /// `RecordingLogSink`.
    public func logSink(_ sink: any LogSink) -> some View {
        environment(\.logSink, sink)
    }
}

/// Throws every entry away.
///
/// The default, so that a view logging before anything is wired up is harmless
/// rather than a crash. Also useful in a test that does not care about logging.
public struct NoOpLogSink: LogSink {
    public init() {}
    public func write(_ entry: LogEntry) {}
}
