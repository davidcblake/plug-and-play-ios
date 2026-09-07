import Foundation
import PPCore
import Testing
@testable import PPInput

@Suite("Asking permission")
struct InMemoryInputPermissionsTests {
    @Test("Nothing has been asked until something asks")
    func startsHavingAskedNothing() {
        let permissions = InMemoryInputPermissions()

        // `docs/security.md` rule 4: never on launch. This is the assertion an
        // app's own tests can copy to prove it did not.
        #expect(permissions.asked.isEmpty)
        #expect(permissions.status(of: .microphone) == .notAsked)
    }

    @Test("Asking records what was asked, in order")
    func remembersWhatWasAsked() async {
        let permissions = InMemoryInputPermissions()

        _ = await permissions.request(.microphone)
        _ = await permissions.request(.speechRecognition)

        #expect(permissions.asked == [.microphone, .speechRecognition])
    }

    @Test("A yes sticks")
    func grantingIsRemembered() async {
        let permissions = InMemoryInputPermissions()

        let answer = await permissions.request(.camera)

        #expect(answer == .granted)
        #expect(permissions.status(of: .camera) == .granted)
    }

    @Test("A no cannot be turned into a yes by asking again")
    func askingAgainDoesNotReopenIt() async {
        let permissions = InMemoryInputPermissions(
            [.microphone: .denied],
            answersWhenAsked: .granted
        )

        let answer = await permissions.request(.microphone)

        // The real system will not re-prompt, so a fake that quietly granted
        // here would let a test pass on a flow that stalls in somebody's hand.
        #expect(answer == .denied)
        #expect(permissions.status(of: .microphone) == .denied)
    }

    @Test("A person who says no is taken at their word")
    func canRefuse() async {
        let permissions = InMemoryInputPermissions(answersWhenAsked: .denied)

        let answer = await permissions.request(.photoLibrary)

        #expect(answer == .denied)
        #expect(permissions.status(of: .photoLibrary) == .denied)
    }

    @Test("The four things an app has to ask for")
    func coversWhatTheAppsNeed() {
        // Microphone and speech are separate because iOS asks separately and a
        // person can say yes to one and no to the other.
        #expect(InputPermission.allCases.count == 4)
        #expect(InputPermission.allCases.contains(.microphone))
        #expect(InputPermission.allCases.contains(.speechRecognition))
    }
}

@Suite("An app that has wired nothing up")
struct NoInputPermissionsTests {
    @Test("Has been granted nothing, and does not pretend otherwise")
    func grantsNothing() async {
        let permissions = NoInputPermissions()

        let answer = await permissions.request(.microphone)

        #expect(permissions.status(of: .microphone) == .notAsked)
        #expect(answer == .denied)
    }
}
