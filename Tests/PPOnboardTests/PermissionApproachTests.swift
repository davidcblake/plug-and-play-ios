import PPCore
import Testing
@testable import PPOnboard

@Suite("What to do about a permission")
struct PermissionApproachTests {
    @Test("Never asked means explain first, then ask")
    func explainsBeforeAsking() {
        // The rule this type exists for. iOS shows its prompt once, so an app
        // that fires it cold spends its single chance on a stranger's guess.
        #expect(PermissionStatus.notAsked.approach == .explainThenAsk)
    }

    @Test("Already granted means get on with it")
    func grantedJustProceeds() {
        #expect(PermissionStatus.granted.approach == .proceed)
    }

    @Test("A refusal sends people to Settings, because iOS will not ask again")
    func deniedOffersSettings() {
        #expect(PermissionStatus.denied.approach == .offerSettings)
    }

    @Test("Restricted means stop offering the feature entirely")
    func restrictedStopsOffering() {
        // Different from denied on purpose: a managed device will never say
        // yes, so a Settings link is a dead end and a nag.
        #expect(PermissionStatus.restricted.approach == .stopOffering)
    }

    @Test("Every status has an answer, and only one leads to a system prompt")
    func exactlyOneStatusAsks() {
        let asks = PermissionStatus.allCases.filter { $0.approach == .explainThenAsk }

        #expect(asks == [.notAsked])
        #expect(PermissionStatus.allCases.count == 4)
    }
}
