import Foundation
import PPCore
import os

/// Signing in, faked, including the part Apple only does once.
///
/// **It withholds the name and email after the first sign-in, exactly as Apple
/// does.** That is the single most common way apps get Sign in with Apple
/// wrong: the name arrives once, on the very first sign-in, and an app that
/// does not save it there and then has lost it forever. Reproducing it here
/// means an app finds out in a test rather than from somebody who has been
/// greeted as "there" for six months.
///
/// Safe to use from more than one task at a time.
public final class InMemoryAuthentication: Authentication {
    private struct Stored {
        var state: SignInState
        var hasSignedInBefore: Bool
        var isRevoked: Bool
        var timesDeleted = 0
    }

    private let person: SignedInPerson
    private let failure: AuthFailure?
    private let stored: OSAllocatedUnfairLock<Stored>

    /// - Parameters:
    ///   - person: Who signs in. Give them a name and email — the fake decides
    ///     when to withhold them, the way Apple does.
    ///   - startsSignedIn: Whether somebody is already signed in, which is what
    ///     the second launch looks like.
    ///   - failure: When set, signing in throws this instead. Use
    ///     ``AuthFailure/cancelled`` to build the "they backed out" path, which
    ///     is the common one and the one apps forget.
    public init(
        person: SignedInPerson = SignedInPerson(
            id: "000123.abc",
            name: "Dave",
            email: "dave@example.com"
        ),
        startsSignedIn: Bool = false,
        failsWith failure: AuthFailure? = nil
    ) {
        self.person = person
        self.failure = failure
        stored = OSAllocatedUnfairLock(
            initialState: Stored(
                state: startsSignedIn ? .signedIn(Self.returning(person)) : .signedOut,
                hasSignedInBefore: startsSignedIn,
                isRevoked: false
            )
        )
    }

    /// The same person as Apple hands back on every sign-in after the first:
    /// the identifier, and nothing else.
    private static func returning(_ person: SignedInPerson) -> SignedInPerson {
        SignedInPerson(id: person.id)
    }

    public var state: SignInState {
        stored.withLock { $0.state }
    }

    public func signIn() async throws -> SignedInPerson {
        if let failure {
            throw failure
        }

        return stored.withLock { stored in
            let signingInPerson = stored.hasSignedInBefore ? Self.returning(person) : person
            stored.hasSignedInBefore = true
            stored.isRevoked = false
            stored.state = .signedIn(signingInPerson)
            return signingInPerson
        }
    }

    public func signOut() async {
        stored.withLock { $0.state = .signedOut }
    }

    /// How many times the account has been deleted.
    ///
    /// Here so a test can prove an app actually called it, rather than signing
    /// somebody out and telling them they were deleted.
    public var timesDeleted: Int {
        stored.withLock { $0.timesDeleted }
    }

    public func deleteAccount() async throws {
        if let failure {
            throw failure
        }

        stored.withLock {
            $0.timesDeleted += 1
            $0.state = .signedOut
            // Deletion is not a sign-out. Somebody who deletes and signs up
            // again is a new person as far as Apple is concerned, and gets
            // their name back — which an app that stored it under the old
            // identifier will not recognise.
            $0.hasSignedInBefore = false
            $0.isRevoked = true
        }
    }

    /// Pretend the person revoked this app from their Apple ID settings.
    ///
    /// There is no way to make this happen from inside an app, which is exactly
    /// why it needs faking: it is the state an app is most likely to handle
    /// badly and least likely to have ever seen.
    public func revokeFromOutside() {
        stored.withLock {
            $0.isRevoked = true
            $0.state = .signedOut
        }
    }

    public func refresh() async -> SignInState {
        stored.withLock { $0.isRevoked ? .signedOut : $0.state }
    }
}

extension InMemoryAuthentication: HoldsPersonalData {
    public var whatItHolds: String { "your sign-in" }

    /// One if somebody is signed in, none if not — which is also the check
    /// that proves the deletion happened.
    public func personalDataCount() async -> Int {
        state.isSignedIn ? 1 : 0
    }

    public func erasePersonalData() async throws {
        try await deleteAccount()
    }
}
