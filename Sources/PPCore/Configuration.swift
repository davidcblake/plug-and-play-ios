/// Names a configured value.
///
/// A type rather than a bare string so a typo is a compile error in the place
/// that defines the key, not a silent `nil` at the place that reads it.
public struct ConfigurationKey: Hashable, Sendable, ExpressibleByStringLiteral {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }

    public init(stringLiteral value: String) {
        self.name = value
    }
}

/// Where an app's settings come from.
///
/// Deliberately one requirement. Everything useful is built on top of it in the
/// extension below, so a fake in a test only has to answer one question, and so
/// a new source (a plist, a debug menu, a test double) is a few lines rather
/// than a class.
public protocol ConfigurationSource: Sendable {
    /// The raw value for a key, or `nil` when this source has no opinion.
    func value(for key: ConfigurationKey) -> String?
}

extension ConfigurationSource {
    /// The configured text, or `defaultValue` when it is absent.
    public func string(_ key: ConfigurationKey, default defaultValue: String) -> String {
        value(for: key) ?? defaultValue
    }

    /// The configured whole number, or `defaultValue` when it is absent or is
    /// not a number.
    public func int(_ key: ConfigurationKey, default defaultValue: Int) -> Int {
        value(for: key).flatMap(Int.init) ?? defaultValue
    }

    /// The configured yes-or-no, or `defaultValue` when it is absent or is not
    /// something recognisable as a yes or a no.
    ///
    /// Accepts what the various places these values come from actually produce:
    /// `true`/`false` from Swift, `YES`/`NO` from a property list, and `1`/`0`
    /// from a command line argument. Anything else is treated as absent rather
    /// than quietly read as false, because a misspelled flag silently meaning
    /// "off" is how a feature ships turned off without anyone noticing.
    public func bool(_ key: ConfigurationKey, default defaultValue: Bool) -> Bool {
        guard let raw = value(for: key)?.lowercased() else { return defaultValue }
        switch raw {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: return defaultValue
        }
    }
}
