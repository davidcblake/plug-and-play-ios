import SwiftUI

// How dependencies travel in this foundation: down the view tree, never through
// a singleton (`AGENTS.md`). An app injects the real thing once at its root, a
// test injects a fake, and no view in between knows which it got.
//
// Written as explicit `EnvironmentKey` types rather than with the `@Entry`
// macro on purpose — see the hard-won facts in `AGENTS.md`.

private struct LogSinkKey: EnvironmentKey {
    /// Deliberately does nothing. A view that logs before anyone injected a
    /// real sink should be silent, not crash and not invent a subsystem name.
    static let defaultValue: any LogSink = NoOpLogSink()
}

private struct ConfigurationKeyKey: EnvironmentKey {
    /// No opinion about anything, so every reader gets its own default.
    static let defaultValue: any ConfigurationSource = EmptyConfiguration()
}

private struct FeatureFlagsKey: EnvironmentKey {
    /// No overrides, so every flag sits at the default it was declared with.
    static let defaultValue: any FeatureFlagSource = DefaultFeatureFlags()
}

extension EnvironmentValues {
    /// Where this part of the view tree writes its logs.
    public var logSink: any LogSink {
        get { self[LogSinkKey.self] }
        set { self[LogSinkKey.self] = newValue }
    }

    /// Where this part of the view tree reads its settings.
    public var configuration: any ConfigurationSource {
        get { self[ConfigurationKeyKey.self] }
        set { self[ConfigurationKeyKey.self] = newValue }
    }

    /// Which features are switched on for this part of the view tree.
    public var featureFlags: any FeatureFlagSource {
        get { self[FeatureFlagsKey.self] }
        set { self[FeatureFlagsKey.self] = newValue }
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

    /// Inject the settings for this view and everything below it.
    ///
    /// Call once at the app's root with a `BundleConfiguration`, or in a test or
    /// preview with an `InMemoryConfiguration`.
    public func configuration(_ source: any ConfigurationSource) -> some View {
        environment(\.configuration, source)
    }

    /// Inject the feature flags for this view and everything below it.
    ///
    /// Call once at the app's root — usually with `ConfigurationFeatureFlags`
    /// so flags come from the same place as the rest of the settings — or in a
    /// test with `InMemoryFeatureFlags`.
    public func featureFlags(_ source: any FeatureFlagSource) -> some View {
        environment(\.featureFlags, source)
    }
}
