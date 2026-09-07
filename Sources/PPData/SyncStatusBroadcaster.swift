import Foundation
import os

/// Keeps the current sync status and tells everyone watching when it changes.
///
/// Internal, and shared by ``InMemorySyncProvider`` and
/// ``CloudKitSyncProvider``. Both need the same small piece of bookkeeping, and
/// only one of them is easy to test — two copies would mean two places to get
/// the subtle part wrong. The subtle part: a continuation is yielded to
/// *outside* the lock, because the other end can run arbitrary code and doing
/// that while holding a lock is how a deadlock gets built by accident.
///
/// A class, so it has to say `Sendable` out loud. Swift infers it for structs
/// and enums and never for classes.
final class SyncStatusBroadcaster: Sendable {
    private struct State {
        var status: SyncStatus
        var listeners: [UUID: AsyncStream<SyncStatus>.Continuation]
    }

    private let state: OSAllocatedUnfairLock<State>

    init(_ status: SyncStatus) {
        state = OSAllocatedUnfairLock(initialState: State(status: status, listeners: [:]))
    }

    var current: SyncStatus {
        state.withLock { $0.status }
    }

    func update(to newStatus: SyncStatus) {
        let listeners = state.withLock { state -> [AsyncStream<SyncStatus>.Continuation] in
            state.status = newStatus
            return Array(state.listeners.values)
        }
        for listener in listeners {
            listener.yield(newStatus)
        }
    }

    /// A fresh stream for each caller, starting with the current status.
    ///
    /// Each caller gets its own because two views observing sync must both
    /// receive every change; a single shared stream would hand each value to
    /// whichever one asked first.
    func updates() -> AsyncStream<SyncStatus> {
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
