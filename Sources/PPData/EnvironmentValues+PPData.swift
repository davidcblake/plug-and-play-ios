import SwiftUI

// Sync reaches views the way everything else in this foundation does: down the
// view tree (`AGENTS.md`: environment, never a singleton). The model container
// travels separately, through Apple's own `.modelContainer(_:)` — there is no
// reason to reinvent that.

private struct SyncProviderKey: EnvironmentKey {
    /// Not syncing, and honest about it. A view that asks before anything is
    /// wired up should be told sync is off, not told it is ready and then left
    /// waiting for something that will never happen.
    static let defaultValue: any SyncProvider = NoSyncProvider()
}

extension EnvironmentValues {
    /// What this part of the view tree can ask about syncing.
    public var syncProvider: any SyncProvider {
        get { self[SyncProviderKey.self] }
        set { self[SyncProviderKey.self] = newValue }
    }
}

extension View {
    /// Inject the sync provider for this view and everything below it.
    ///
    /// Call once at the app's root, or in a test with an
    /// ``InMemorySyncProvider`` set to whichever state the test is about.
    public func syncProvider(_ provider: any SyncProvider) -> some View {
        environment(\.syncProvider, provider)
    }
}
