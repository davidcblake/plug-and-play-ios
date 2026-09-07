import Foundation
import Testing
@testable import PPAuth

@Suite("Somebody signed in")
struct SignedInPersonTests {
    @Test("Signed out has nobody; signed in has somebody")
    func stateCarriesThePerson() {
        let person = SignedInPerson(id: "000123.abc", name: "Dave")

        #expect(SignInState.signedOut.person == nil)
        #expect(SignInState.signedOut.isSignedIn == false)
        #expect(SignInState.signedIn(person).person == person)
        #expect(SignInState.signedIn(person).isSignedIn)
    }

    @Test("Cancelling is not worth showing anybody")
    func cancellingIsNotAnError() {
        // Somebody who dismissed the sheet knows what they did. Showing them an
        // error calls their deliberate choice a problem.
        #expect(AuthFailure.cancelled.isWorthShowing == false)
        #expect(AuthFailure.failed.isWorthShowing)
        #expect(AuthFailure.unavailable.isWorthShowing)
    }
}

@Suite("Signing in")
struct InMemoryAuthenticationTests {
    @Test("Starts signed out, because every app must work that way")
    func startsSignedOut() {
        #expect(InMemoryAuthentication().state == .signedOut)
    }

    @Test("Signing in gives back the person, name and all — once")
    func firstSignInHasEverything() async throws {
        let auth = InMemoryAuthentication()

        let person = try await auth.signIn()

        #expect(person.name == "Dave")
        #expect(person.email == "dave@example.com")
        #expect(auth.state.isSignedIn)
    }

    @Test("The second sign-in gives back the identifier and nothing else")
    func laterSignInsWithholdTheName() async throws {
        // Apple gives the name exactly once, on the very first sign-in, and
        // never again. An app that did not save it the first time has lost it
        // forever — and this is where it finds out.
        let auth = InMemoryAuthentication()

        _ = try await auth.signIn()
        await auth.signOut()
        let second = try await auth.signIn()

        #expect(second.id == "000123.abc")
        #expect(second.name == nil)
        #expect(second.email == nil)
    }

    @Test("An app that was already signed in never gets the name at all")
    func returningPersonHasNoName() {
        // The second launch. Whatever was not saved the first time is gone.
        let auth = InMemoryAuthentication(startsSignedIn: true)

        #expect(auth.state.isSignedIn)
        #expect(auth.state.person?.name == nil)
    }

    @Test("Backing out of the sheet throws something not worth showing")
    func cancellingLeavesThemSignedOut() async throws {
        let auth = InMemoryAuthentication(failsWith: .cancelled)

        do {
            _ = try await auth.signIn()
            Issue.record("Signing in succeeded when it was cancelled")
        } catch let failure as AuthFailure {
            #expect(failure.isWorthShowing == false)
        }

        #expect(auth.state == .signedOut)
    }

    @Test("Signing out forgets them on this device")
    func signsOut() async throws {
        let auth = InMemoryAuthentication()
        _ = try await auth.signIn()

        await auth.signOut()

        #expect(auth.state == .signedOut)
    }

    @Test("Somebody who revoked the app from Settings comes back signed out")
    func revocationIsNoticedOnRefresh() async throws {
        // There is no way to cause this from inside an app, which is why it
        // needs faking: it is the state an app is most likely to handle badly
        // and least likely to have ever seen.
        let auth = InMemoryAuthentication()
        _ = try await auth.signIn()

        auth.revokeFromOutside()
        let refreshed = await auth.refresh()

        #expect(refreshed == .signedOut)
    }

    @Test("Refreshing an ordinary signed-in person changes nothing")
    func refreshIsHarmlessWhenNothingChanged() async throws {
        let auth = InMemoryAuthentication()
        _ = try await auth.signIn()

        let refreshed = await auth.refresh()

        #expect(refreshed.isSignedIn)
    }
}

@Suite("An app that signs nobody in")
struct NoAuthenticationTests {
    @Test("Is signed out and says signing in is not set up")
    func failsReadably() async throws {
        let auth = NoAuthentication()
        #expect(auth.state == .signedOut)

        do {
            _ = try await auth.signIn()
            Issue.record("NoAuthentication signed somebody in")
        } catch let failure as AuthFailure {
            #expect(failure == .unavailable)
        }
    }
}
