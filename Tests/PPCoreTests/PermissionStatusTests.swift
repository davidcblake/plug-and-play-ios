import Testing
@testable import PPCore

@Suite("Where a permission stands")
struct PermissionStatusTests {
    @Test("Only a yes is usable")
    func onlyGrantedWorks() {
        #expect(PermissionStatus.granted.isUsable)
        #expect(PermissionStatus.notAsked.isUsable == false)
        #expect(PermissionStatus.denied.isUsable == false)
        #expect(PermissionStatus.restricted.isUsable == false)
    }

    @Test("Only an unasked permission is worth asking for")
    func askingOnlyHelpsOnce() {
        // iOS asks once. Throwing a permission sheet at somebody who already
        // said no is the fastest way to get an app deleted.
        #expect(PermissionStatus.notAsked.isWorthAsking)
        #expect(PermissionStatus.denied.isWorthAsking == false)
        #expect(PermissionStatus.granted.isWorthAsking == false)
        #expect(PermissionStatus.restricted.isWorthAsking == false)
    }

    @Test("Exactly one status is both usable and settled")
    func theStatesAreDistinct() {
        let usable = PermissionStatus.allCases.filter(\.isUsable)
        let askable = PermissionStatus.allCases.filter(\.isWorthAsking)

        #expect(usable == [.granted])
        #expect(askable == [.notAsked])
    }
}
