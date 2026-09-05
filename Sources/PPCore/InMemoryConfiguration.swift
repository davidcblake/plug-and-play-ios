/// Settings held in memory, given to it up front.
///
/// For tests, SwiftUI previews, and anywhere else a known set of values beats
/// whatever the surrounding environment happens to hold.
public struct InMemoryConfiguration: ConfigurationSource {
    private let values: [ConfigurationKey: String]

    public init(_ values: [ConfigurationKey: String] = [:]) {
        self.values = values
    }

    public func value(for key: ConfigurationKey) -> String? {
        values[key]
    }
}

/// Answers `nil` to everything, so every reader falls back to its default.
///
/// The default source. An app that has not configured anything should behave
/// like an app with default settings, not crash and not read someone else's.
public struct EmptyConfiguration: ConfigurationSource {
    public init() {}

    public func value(for key: ConfigurationKey) -> String? { nil }
}
