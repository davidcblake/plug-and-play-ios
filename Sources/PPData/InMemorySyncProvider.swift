import Foundation

/// A sync provider whose status you set yourself.
///
/// This is how a test gets at the states that are otherwise almost impossible
/// to produce on demand: signed out, restricted, failing. `docs/decisions/0002`
/// names that as a reason the seam exists at all — "a fake provider can
/// simulate sync failing, which cannot be done against CloudKit directly."
///
/// It ships in `PPData` rather than in a test target for the same reason
/// `RecordingLogSink` ships in `PPCore`: every app on this foundation needs it,
/// and four slightly different copies would be worse than one.
///
/// Safe to use from more than one task at a time.
public final class InMemorySyncProvider: SyncProvider {
    private let broadcaster: SyncStatusBroadcaster

    public init(status: SyncStatus = SyncStatus(availability: .ready, activity: .idle)) {
        broadcaster = SyncStatusBroadcaster(status)
    }

    public var status: SyncStatus {
        broadcaster.current
    }

    /// Change what this provider reports, and tell everyone watching.
    public func update(to newStatus: SyncStatus) {
        broadcaster.update(to: newStatus)
    }

    /// Report that syncing failed, without disturbing the rest of the status.
    public func fail(_ failure: SyncFailure) {
        var next = status
        next.activity = .failed(failure)
        update(to: next)
    }

    public func statusUpdates() -> AsyncStream<SyncStatus> {
        broadcaster.updates()
    }
}
