import Foundation
import PPCore

/// Somebody signed in.
public struct SignedInPerson: Sendable, Equatable, Identifiable {
    /// Apple's stable identifier for this person **in this app**.
    ///
    /// Not an email, not reused between apps, and it does not change when they
    /// change their Apple ID email. This is the only thing worth storing to
    /// recognise somebody, and it belongs in the Keychain — `docs/security.md`
    /// rule 2.
    public let id: String

    /// What they chose to be called, if they shared it.
    ///
    /// **Apple gives this exactly once**, at the very first sign-in on this
    /// device for this app, and never again — not on the second sign-in, not
    /// after a reinstall, not ever. An app that does not save it the first time
    /// has lost it permanently and will be showing "there" instead of a name
    /// forever.
    ///
    /// This is the single most common way apps get Sign in with Apple wrong,
    /// which is why ``InMemoryAuthentication`` reproduces it.
    public let name: String?

    /// Their email, if they shared it.
    ///
    /// May be one of Apple's private relay addresses, which forwards and can be
    /// switched off by the person at any time. Same one-time rule as `name`.
    public let email: String?

    public init(id: String, name: String? = nil, email: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
    }
}

/// Whether anybody is signed in.
public enum SignInState: Sendable, Equatable {
    /// Nobody. The state every app starts in and must work sensibly from.
    case signedOut
    /// This person.
    case signedIn(SignedInPerson)

    /// The person, when there is one.
    public var person: SignedInPerson? {
        switch self {
        case .signedOut: nil
        case .signedIn(let person): person
        }
    }

    public var isSignedIn: Bool { person != nil }
}

/// Why signing in did not happen.
public struct AuthFailure: PPError, Equatable {
    public let userMessage: String
    public let logMessage: String
    /// Whether this is worth putting on screen.
    ///
    /// Somebody who backed out of the sign-in sheet knows what they did.
    /// Showing them an error for it is the app calling their deliberate choice
    /// a problem.
    public let isWorthShowing: Bool

    public init(
        userMessage: String,
        logMessage: String? = nil,
        isWorthShowing: Bool = true
    ) {
        self.userMessage = userMessage
        self.logMessage = logMessage ?? userMessage
        self.isWorthShowing = isWorthShowing
    }

    /// They changed their mind and closed the sheet. Not an error.
    public static let cancelled = AuthFailure(
        // Carries real words even though it should never be shown: an app that
        // ignores `isWorthShowing` puts up a blank alert, which is worse than a
        // redundant one.
        userMessage: "Signing in was cancelled.",
        logMessage: "The person dismissed the Sign in with Apple sheet.",
        isWorthShowing: false
    )

    /// Nothing has been wired up to sign anybody in.
    public static let unavailable = AuthFailure(
        userMessage: "Signing in isn't set up in this app.",
        logMessage: "No Authentication was injected, so NoAuthentication answered."
    )

    /// It went wrong for a reason worth telling somebody about.
    public static let failed = AuthFailure(
        userMessage: "Signing in didn't work. Please try again.",
        logMessage: "Sign in with Apple returned an error."
    )
}
