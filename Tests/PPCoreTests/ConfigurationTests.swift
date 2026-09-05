import Testing
@testable import PPCore

@Suite("Configuration")
struct ConfigurationTests {
    private let config = InMemoryConfiguration([
        "greeting": "hello",
        "retries": "3",
        "notANumber": "soon",
        "swiftStyle": "true",
        "plistStyle": "YES",
        "argumentStyle": "1",
        "offSwiftStyle": "false",
        "offPlistStyle": "NO",
        "offArgumentStyle": "0",
        "shouty": "TRUE",
        "nonsense": "banana",
    ])

    @Test("Reads text that is there")
    func readsPresentText() {
        #expect(config.string("greeting", default: "nothing") == "hello")
    }

    @Test("Falls back to the default when a key is missing")
    func fallsBackWhenMissing() {
        #expect(config.string("absent", default: "nothing") == "nothing")
        #expect(config.int("absent", default: 7) == 7)
        #expect(config.bool("absent", default: true) == true)
    }

    @Test("Reads whole numbers, and ignores things that are not numbers")
    func readsNumbers() {
        #expect(config.int("retries", default: 0) == 3)
        #expect(config.int("notANumber", default: 9) == 9)
    }

    @Test(
        "Reads yes in every spelling these values actually arrive in",
        arguments: ["swiftStyle", "plistStyle", "argumentStyle", "shouty"]
    )
    func readsTruthyValues(key: ConfigurationKey) {
        #expect(config.bool(key, default: false) == true)
    }

    @Test(
        "Reads no in every spelling too",
        arguments: ["offSwiftStyle", "offPlistStyle", "offArgumentStyle"]
    )
    func readsFalsyValues(key: ConfigurationKey) {
        #expect(config.bool(key, default: true) == false)
    }

    @Test("An unreadable yes-or-no keeps the default rather than becoming false")
    func unparseableBoolKeepsDefault() {
        // The point of the rule: a misspelled flag must not quietly mean "off",
        // which is how a feature ships disabled without anyone noticing.
        #expect(config.bool("nonsense", default: true) == true)
        #expect(config.bool("nonsense", default: false) == false)
    }

    @Test("The empty source has no opinion about anything")
    func emptySourceHasNoOpinions() {
        let empty = EmptyConfiguration()
        #expect(empty.value(for: "anything") == nil)
        #expect(empty.string("anything", default: "default") == "default")
    }
}
