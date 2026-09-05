/// A switch for a piece of the app, and what it does when nobody has said
/// otherwise.
///
/// The default travels with the flag rather than living in whatever asked about
/// it. That way a half-built feature is off everywhere by definition, instead of
/// off in the three places somebody remembered to write `?? false`.
public struct FeatureFlag: Hashable, Sendable {
    public let name: String
    /// What this flag means when no source overrides it. Default `false`:
    /// a new flag should be dark until switched on deliberately.
    public let defaultValue: Bool

    public init(_ name: String, default defaultValue: Bool = false) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

/// Something that can have an opinion about whether a flag is on.
///
/// Returning `nil` means "no opinion", which is different from "off" — it lets
/// the flag's own default stand, and lets sources be layered later without each
/// one having to know what every flag's default is.
public protocol FeatureFlagSource: Sendable {
    func override(for flag: FeatureFlag) -> Bool?
}

extension FeatureFlagSource {
    /// Whether the feature is on: this source's opinion if it has one, and the
    /// flag's own default if it does not.
    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        override(for: flag) ?? flag.defaultValue
    }
}

/// Overrides held in memory, given to it up front.
///
/// For tests that need a feature on or off regardless of how the app ships, and
/// for previews.
public struct InMemoryFeatureFlags: FeatureFlagSource {
    private let overrides: [FeatureFlag: Bool]

    public init(_ overrides: [FeatureFlag: Bool] = [:]) {
        self.overrides = overrides
    }

    public func override(for flag: FeatureFlag) -> Bool? {
        overrides[flag]
    }
}

/// Has no opinion about anything, so every flag sits at its own default.
///
/// The default source, and the correct behaviour for an app that has not set
/// any flags up.
public struct DefaultFeatureFlags: FeatureFlagSource {
    public init() {}

    public func override(for flag: FeatureFlag) -> Bool? { nil }
}

/// Reads flag overrides out of configuration.
///
/// This is how a flag actually gets flipped in a shipped build: the value lands
/// in `Info.plist` at build time and is read back here, with no new machinery
/// and no network call. Local-first — the phone decides, in airplane mode, with
/// no server asked.
///
/// Keys are looked up by the flag's name, so a flag called `offlineMaps` reads
/// the `offlineMaps` entry.
public struct ConfigurationFeatureFlags: FeatureFlagSource {
    private let configuration: any ConfigurationSource

    public init(configuration: any ConfigurationSource) {
        self.configuration = configuration
    }

    public func override(for flag: FeatureFlag) -> Bool? {
        // Absent, or present but unreadable, both come back nil — so a typo
        // leaves the flag at its default rather than silently forcing it off.
        // Parsing lives in one place (`asConfiguredBool`) so this and
        // `ConfigurationSource.bool(_:default:)` cannot drift apart on what
        // counts as "yes".
        configuration.value(for: ConfigurationKey(flag.name))?.asConfiguredBool
    }
}
