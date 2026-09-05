import Foundation

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
    ///
    /// Returned exactly as configured, whitespace included — this is text, and
    /// trimming it would be this type deciding it knows better. The `int` and
    /// `bool` readers below do trim, because those parse a token rather than
    /// carry a value through.
    public func string(_ key: ConfigurationKey, default defaultValue: String) -> String {
        value(for: key) ?? defaultValue
    }

    /// The configured whole number, or `defaultValue` when it is absent or is
    /// not a number.
    ///
    /// Tolerates surrounding whitespace, which is easy to introduce when a
    /// build script writes a value into `Info.plist`.
    public func int(_ key: ConfigurationKey, default defaultValue: Int) -> Int {
        guard let raw = value(for: key)?.trimmed else { return defaultValue }
        return Int(raw) ?? defaultValue
    }

    /// The configured yes-or-no, or `defaultValue` when it is absent or is not
    /// something recognisable as a yes or a no.
    ///
    /// Anything unrecognisable is treated as absent rather than quietly read as
    /// false, because a misspelled flag silently meaning "off" is how a feature
    /// ships turned off without anyone noticing.
    public func bool(_ key: ConfigurationKey, default defaultValue: Bool) -> Bool {
        value(for: key)?.asConfiguredBool ?? defaultValue
    }
}

extension String {
    /// This value with surrounding whitespace and newlines removed.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Reads this as a yes-or-no, or `nil` when it is not recognisably either.
    ///
    /// Accepts the forms these values actually arrive in: `true`/`false` from
    /// Swift, `YES`/`NO` from a property list, and `1`/`0` from a command line
    /// argument, in any casing and with surrounding whitespace.
    ///
    /// One definition, used by both `ConfigurationSource.bool(_:default:)` and
    /// `ConfigurationFeatureFlags`, so the two can never drift into disagreeing
    /// about what "yes" means.
    var asConfiguredBool: Bool? {
        switch trimmed.lowercased() {
        case "true", "yes", "1": true
        case "false", "no", "0": false
        default: nil
        }
    }
}
