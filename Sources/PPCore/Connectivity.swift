import Foundation
import Network
import os

/// Whether the phone can reach the internet right now.
///
/// **Almost nothing should ask.** Every app on this foundation reads and writes
/// its own data on the device, and those screens do not care whether there is a
/// signal. This exists for the few places that genuinely cannot work without
/// one — preparing something on a server, sending something to somebody — so
/// they can say "no connection" plainly instead of showing a spinner that never
/// ends.
///
/// Extracted from Spindle, where it had been shipping to real people, and
/// generalised. See `docs/decisions/0023-knowing-whether-there-is-a-connection.md`.
public protocol Connectivity: Sendable {
    /// What the last answer was. Cheap to read; never blocks.
    var isOnline: Bool { get }

    /// Changes, beginning with the current answer.
    ///
    /// A function rather than a property because each caller gets its own
    /// stream — two views watching the connection must both be told.
    func changes() -> AsyncStream<Bool>
}

/// Assume there is a connection, and let the failure speak for itself.
///
/// The default, and the right one. Getting this wrong in the optimistic
/// direction costs a request that fails and says so. Getting it wrong in the
/// pessimistic direction greys out a button that would have worked, which is a
/// worse way to be wrong and much harder for a person to argue with.
public struct AlwaysOnline: Connectivity {
    public init() {}

    public var isOnline: Bool { true }

    public func changes() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            // One value, then done. A stream that stayed open waiting for
            // changes that cannot happen would hang every `for await` over it.
            continuation.yield(true)
            continuation.finish()
        }
    }
}

/// A connection a test switches on and off.
///
/// Being genuinely offline is not something a test can arrange, and putting a
/// phone in airplane mode is not a test anybody runs twice. This is how the
/// "no connection" screen gets built and checked.
public final class InMemoryConnectivity: Connectivity {
    private let signal: ConnectivitySignal

    public init(isOnline: Bool = true) {
        signal = ConnectivitySignal(isOnline)
    }

    public var isOnline: Bool { signal.current }

    /// Go offline, or come back, and tell everyone watching.
    public func set(isOnline: Bool) {
        signal.update(to: isOnline)
    }

    public func changes() -> AsyncStream<Bool> {
        signal.updates()
    }
}

/// The real one, watching the system's view of the network.
///
/// Built once at the app's root and kept for as long as the app runs.
public final class SystemConnectivity: Connectivity {
    private let signal: ConnectivitySignal

    // `NWPathMonitor` is designed to be used from the queue it is started on
    // and is safe to hold onto, but Apple does not mark it `Sendable`, so the
    // compiler cannot see that. Spelled out here rather than hidden behind
    // `@unchecked Sendable` on the whole type, which would switch the check off
    // for every future property too. Reasoning in `docs/decisions/0023`.
    nonisolated(unsafe) private let monitor = NWPathMonitor()

    /// Starts watching immediately. There is nothing to remember to call: a
    /// monitor somebody forgot to start would report "online" forever, which is
    /// the failure that looks like it is working.
    public init() {
        // Optimistic until the first answer arrives, for the reason on
        // ``AlwaysOnline``.
        signal = ConnectivitySignal(true)
        let signal = self.signal
        monitor.pathUpdateHandler = { @Sendable path in
            signal.update(to: path.status == .satisfied)
        }
        monitor.start(queue: DispatchQueue(label: "PPCore.SystemConnectivity"))
    }

    deinit {
        monitor.cancel()
    }

    public var isOnline: Bool { signal.current }

    public func changes() -> AsyncStream<Bool> {
        signal.updates()
    }
}

/// Keeps the current answer and tells everyone watching when it changes.
///
/// The one subtle part: a continuation is yielded to *outside* the lock,
/// because the other end can run arbitrary code and doing that while holding a
/// lock is how a deadlock gets built by accident.
final class ConnectivitySignal: Sendable {
    private struct State {
        var isOnline: Bool
        var listeners: [UUID: AsyncStream<Bool>.Continuation]
    }

    private let state: OSAllocatedUnfairLock<State>

    init(_ isOnline: Bool) {
        state = OSAllocatedUnfairLock(initialState: State(isOnline: isOnline, listeners: [:]))
    }

    var current: Bool {
        state.withLock { $0.isOnline }
    }

    func update(to isOnline: Bool) {
        let listeners = state.withLock { state -> [AsyncStream<Bool>.Continuation] in
            guard state.isOnline != isOnline else { return [] }
            state.isOnline = isOnline
            return Array(state.listeners.values)
        }
        for listener in listeners {
            listener.yield(isOnline)
        }
    }

    /// A fresh stream for each caller, starting with the current answer.
    ///
    /// **The order of the two steps below is load-bearing.** Registering the
    /// listener first and setting `onTermination` second looks like the window
    /// for a leak, and is the opposite: setting `onTermination` on an
    /// already-terminated continuation runs the handler immediately, so the
    /// entry is removed. Doing it the other way round would remove an id that
    /// has not been inserted yet and then insert it with nothing left to clean
    /// it up, which is the leak this ordering avoids.
    func updates() -> AsyncStream<Bool> {
        let id = UUID()
        return AsyncStream { continuation in
            let current = state.withLock { state -> Bool in
                state.listeners[id] = continuation
                return state.isOnline
            }
            continuation.yield(current)
            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { $0.listeners[id] = nil }
            }
        }
    }
}
