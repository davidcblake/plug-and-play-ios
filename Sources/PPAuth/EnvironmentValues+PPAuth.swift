import SwiftUI

private struct AuthenticationKey: EnvironmentKey {
    /// Nobody signed in, and no way to sign in. Correct for an app that has
    /// not wired this up — and a legitimate way for an app to ship, since
    /// everything on this foundation works without an account.
    static let defaultValue: any Authentication = NoAuthentication()
}

extension EnvironmentValues {
    /// Signing in and out, for this part of the view tree.
    public var authentication: any Authentication {
        get { self[AuthenticationKey.self] }
        set { self[AuthenticationKey.self] = newValue }
    }
}

extension View {
    /// Inject sign-in for this view and everything below it.
    public func authentication(_ authentication: any Authentication) -> some View {
        environment(\.authentication, authentication)
    }
}
