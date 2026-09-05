import os

/// Writes log entries to Apple's unified logging system.
///
/// This is the sink the apps use in production. Apple's system is the
/// Apple-first choice: no dependency, no log files to manage, viewable in
/// Console.app and in Xcode, and it costs almost nothing when nobody is
/// looking.
///
/// **Message contents are treated as private.** Apple's logger redacts
/// interpolated values in released builds unless they are explicitly marked
/// public, and this deliberately does not mark them. Level and category stay
/// visible, so a log is still readable in shape, while the contents of a
/// journal entry or a trip note never leak into a device log. See
/// `docs/security.md`.
public struct SystemLogSink: LogSink {
    private let subsystem: String

    /// - Parameter subsystem: Normally the app's bundle identifier. Passed in
    ///   rather than guessed, because each app on this foundation has its own.
    public init(subsystem: String) {
        self.subsystem = subsystem
    }

    public func write(_ entry: LogEntry) {
        // A `Logger` is made per call rather than cached per category. It is a thin
        // wrapper over a handle and cheap to create, and caching would mean a lock on
        // the logging path — paying a synchronisation cost on every call to avoid an
        // allocation cost on some of them. Revisit only with a profile showing this
        // matters.
        let logger = Logger(subsystem: subsystem, category: entry.category)
        let message = entry.message
        switch entry.level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        }
    }
}
