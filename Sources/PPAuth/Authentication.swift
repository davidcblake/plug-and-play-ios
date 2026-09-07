import Foundation
import PPCore

/// Signing in and out.
///
/// The seam. Nothing above it mentions Apple, which is what `AGENTS.md` asks
/// for and what would make a second sign-in method a change in one place.
///
/// **Signing in is never required to use these apps.** Everything is stored on
/// the phone and works with nobody signed in at all; signing in is what makes a
/// person's own devices agree and lets them share something. An app that puts a
/// sign-in wall in front of its first screen has misunderstood the foundation
/// it is built on.
public protocol Authentication: Sendable {
    /// Who is signed in, as far as this device last knew.
    ///
    /// Cheap and local. Safe to read while drawing a screen.
    var state: SignInState { get }

    /// Show the sign-in sheet.
    ///
    /// - Throws: ``AuthFailure``. Check ``AuthFailure/isWorthShowing`` before
    ///   putting anything on screen — somebody who cancelled does not need to
    ///   be told they cancelled.
    func signIn() async throws -> SignedInPerson

    /// Forget this person on this device.
    ///
    /// Does not reach Apple: a person revokes an app from their Apple ID
    /// settings, not from inside it.
    func signOut() async

    /// Delete this person's account and stop being able to recognise them.
    ///
    /// **Apple requires this** of any app offering account creation, and for
    /// Sign in with Apple it means more than signing out: the token has to be
    /// revoked, so Apple stops treating this person as a returning user of the
    /// app. Signing out and calling it deletion is the thing that gets an app
    /// rejected — and, worse, is a lie told to somebody who asked to be
    /// forgotten.
    ///
    /// **This deletes the account, not the person's data.** Their notes live in
    /// storage, not here. Deleting everything is the app's job, because only
    /// the app knows every place it put something — see
    /// ``PPCore/PersonalData/erase(from:)``, and do this one **last**, since
    /// revoking an identity first can take away the access needed to delete
    /// what it was protecting.
    ///
    /// - Throws: ``AuthFailure`` when the account could not be deleted. An app
    ///   must not tell somebody they are gone when this throws.
    func deleteAccount() async throws

    /// Ask whether this person is still really signed in.
    ///
    /// **Worth doing on launch.** Somebody can revoke an app from their Apple
    /// ID settings at any time, and the first an app hears of it is when it
    /// asks. Without this an app can show a signed-in screen to somebody Apple
    /// no longer recognises.
    func refresh() async -> SignInState
}

/// Signs nobody in, and says so.
///
/// The default. Correct for an app that does not sign anybody in — which,
/// given everything works locally without an account, is a legitimate way for
/// an app to ship.
public struct NoAuthentication: Authentication {
    public init() {}

    public var state: SignInState { .signedOut }

    public func signIn() async throws -> SignedInPerson {
        throw AuthFailure.unavailable
    }

    public func signOut() async {}

    public func deleteAccount() async throws {
        // Nobody was ever signed in, so there is nothing to delete and nothing
        // to lie about. Succeeding is correct: an app deleting everything
        // should not fail because one of the things was already empty.
    }

    public func refresh() async -> SignInState { .signedOut }
}

extension NoAuthentication: HoldsPersonalData {
    public var whatItHolds: String { "your sign-in" }

    public func erasePersonalData() async throws {
        try await deleteAccount()
    }
}
