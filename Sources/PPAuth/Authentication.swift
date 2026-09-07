import Foundation

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

    public func refresh() async -> SignInState { .signedOut }
}
