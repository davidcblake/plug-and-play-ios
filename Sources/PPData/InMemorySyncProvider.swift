import Foundation
import os

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
    private struct State {
        var status: SyncStatus
        var listeners: [UUID: AsyncStream<SyncStatus>.Continuation]
    }

    private let state: OSAllocatedUnfairLock<State>

    public init(status: SyncStatus = SyncStatus(availability: .ready, activity: .idle)) {
        state = OSAllocatedUnfairLock(initialState: State(status: status, listeners: [:]))
    }

    public var status: SyncStatus {
        state.withLock { $0.status }
    }

    /// Change what this provider reports, and tell everyone watching.
    public func update(to newStatus: SyncStatus) {
        let listeners = state.withLock { state -> [AsyncStream<SyncStatus>.Continuation] in
            state.status = newStatus
            return Array(state.listeners.values)
        }
        // Yielded outside the lock. A continuation can run arbitrary code on
        // the other end, and doing that while holding a lock is how a deadlock
        // gets built by accident.
        for listener in listeners {
            listener.yield(newStatus)
        }
    }

    /// Report that syncing failed, without disturbing the rest of the status.
    public func fail(_ failure: SyncFailure) {
        var next = status
        next.activity = .failed(failure)
        update(to: next)
    }

    public func statusUpdates() -> AsyncStream<SyncStatus> {
        let id = UUID()
        return AsyncStream { continuation in
            let current = state.withLock { state -> SyncStatus in
                state.listeners[id] = continuation
                return state.status
            }
            continuation.yield(current)
            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { $0.listeners[id] = nil }
            }
        }
    }
}
