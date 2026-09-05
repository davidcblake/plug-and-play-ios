/// How serious a log entry is.
///
/// Ordered, so a sink can drop anything below a threshold: `.debug` is the
/// chattiest, `.error` the most severe.
public enum LogLevel: Int, Sendable, Comparable, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// One thing worth writing down.
///
/// `category` groups entries by the part of the app they came from ("sync",
/// "paywall"), which is what makes a log readable when something goes wrong at
/// three in the morning.
public struct LogEntry: Sendable, Equatable {
    public let level: LogLevel
    public let category: String
    public let message: String

    public init(level: LogLevel, category: String, message: String) {
        self.level = level
        self.category = category
        self.message = message
    }
}

/// Where log entries go.
///
/// This is a seam: the apps log through this, and what sits behind it can be
/// Apple's logging system in production and a recorder in a test. Nothing in a
/// feature module should ever reach past this to a concrete logger.
public protocol LogSink: Sendable {
    func write(_ entry: LogEntry)
}

extension LogSink {
    /// Log at `.debug` — the running commentary you want while developing and
    /// almost never in production.
    public func debug(_ message: String, category: String) {
        write(LogEntry(level: .debug, category: category, message: message))
    }

    /// Log at `.info` — something happened that a person reading the log later
    /// would want to know about.
    public func info(_ message: String, category: String) {
        write(LogEntry(level: .info, category: category, message: message))
    }

    /// Log at `.warning` — recoverable, but somebody should look at it.
    public func warning(_ message: String, category: String) {
        write(LogEntry(level: .warning, category: category, message: message))
    }

    /// Log at `.error` — something failed that the user probably noticed.
    public func error(_ message: String, category: String) {
        write(LogEntry(level: .error, category: category, message: message))
    }
}
