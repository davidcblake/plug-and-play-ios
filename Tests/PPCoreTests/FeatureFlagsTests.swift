import Testing
@testable import PPCore

private let offlineMaps = FeatureFlag("offlineMaps")
private let tripSharing = FeatureFlag("tripSharing", default: true)

@Suite("Feature flags")
struct FeatureFlagTests {
    @Test("A new flag is off unless it says otherwise")
    func defaultsToOff() {
        #expect(offlineMaps.defaultValue == false)
        #expect(DefaultFeatureFlags().isEnabled(offlineMaps) == false)
    }

    @Test("A flag declared on stays on when nobody overrides it")
    func respectsDeclaredDefault() {
        #expect(DefaultFeatureFlags().isEnabled(tripSharing) == true)
    }

    @Test("An override wins over the flag's own default, both directions")
    func overrideWins() {
        let flags = InMemoryFeatureFlags([offlineMaps: true, tripSharing: false])

        #expect(flags.isEnabled(offlineMaps) == true)
        #expect(flags.isEnabled(tripSharing) == false)
    }

    @Test("No opinion is not the same as off")
    func noOpinionIsNotOff() {
        // A source that says nothing about tripSharing must leave it on,
        // rather than answering false because it had nothing to say.
        let flags = InMemoryFeatureFlags([offlineMaps: true])

        #expect(flags.override(for: tripSharing) == nil)
        #expect(flags.isEnabled(tripSharing) == true)
    }
}

@Suite("Flags read from configuration")
struct ConfigurationFeatureFlagsTests {
    private func flags(_ values: [ConfigurationKey: String]) -> ConfigurationFeatureFlags {
        ConfigurationFeatureFlags(configuration: InMemoryConfiguration(values))
    }

    @Test("Turns a flag on from a shipped setting")
    func readsOnFromConfiguration() {
        #expect(flags(["offlineMaps": "true"]).isEnabled(offlineMaps) == true)
        #expect(flags(["offlineMaps": "YES"]).isEnabled(offlineMaps) == true)
    }

    @Test("Turns a flag off from a shipped setting")
    func readsOffFromConfiguration() {
        #expect(flags(["tripSharing": "false"]).isEnabled(tripSharing) == false)
        #expect(flags(["tripSharing": "0"]).isEnabled(tripSharing) == false)
    }

    @Test("A setting that isn't there leaves the flag at its default")
    func absentSettingLeavesDefault() {
        #expect(flags([:]).isEnabled(tripSharing) == true)
        #expect(flags([:]).isEnabled(offlineMaps) == false)
    }

    @Test("A misspelled setting leaves the flag alone rather than forcing it off")
    func unreadableSettingLeavesDefault() {
        let misspelled = flags(["tripSharing": "ture"])

        #expect(misspelled.override(for: tripSharing) == nil)
        #expect(misspelled.isEnabled(tripSharing) == true)
    }
}
