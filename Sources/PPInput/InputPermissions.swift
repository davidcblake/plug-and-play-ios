import Foundation
import os

/// Something the phone will not let an app do until the person agrees.
public enum InputPermission: String, Sendable, CaseIterable {
    /// Hearing anything at all.
    case microphone
    /// Turning what was heard into words. Separate from the microphone on
    /// purpose — iOS asks for these one at a time, and a person can say yes to
    /// one and no to the other.
    case speechRecognition
    /// Taking a picture now.
    case camera
    /// Choosing a picture already taken.
    case photoLibrary
}

/// Where a permission stands.
public enum PermissionStatus: Sendable, Equatable {
    /// Nobody has asked yet. The only state from which asking is possible.
    case notAsked
    /// Yes.
    case granted
    /// No. **iOS will not ask again** — from here the only route is the
    /// Settings app, so an app that spends this answer carelessly has spent it
    /// for good.
    case denied
    /// Something outside the person's control forbids it: a managed device,
    /// parental controls. Asking will not help and the app should stop
    /// offering.
    case restricted

    /// Whether the thing can actually be done right now.
    public var isUsable: Bool { self == .granted }

    /// Whether asking would do anything.
    ///
    /// This is the check that keeps an app from throwing a permission sheet at
    /// somebody who already said no, which is the fastest way to get an app
    /// deleted.
    public var isWorthAsking: Bool { self == .notAsked }
}

/// Asking the person for permission.
///
/// **`docs/security.md` rule 4: ask at the moment it makes sense, never on
/// launch.** An app that asks for a microphone before showing anything gets
/// refused, and iOS gives exactly one chance. Ask when somebody taps the
/// microphone button, having already told them what it is for.
public protocol InputPermissions: Sendable {
    /// Where a permission stands, without asking for anything.
    ///
    /// Safe to call whenever, including on launch — this is looking, not
    /// asking.
    func status(of permission: InputPermission) -> PermissionStatus

    /// Ask. Shows the system prompt if it has never been shown.
    func request(_ permission: InputPermission) async -> PermissionStatus
}

/// Has never been asked and cannot ask.
///
/// The default. An app that has not wired permissions up has not been granted
/// anything, and this says so rather than claiming a yes nobody gave.
public struct NoInputPermissions: InputPermissions {
    public init() {}

    public func status(of permission: InputPermission) -> PermissionStatus { .notAsked }

    public func request(_ permission: InputPermission) async -> PermissionStatus { .denied }
}

/// Permissions that answer however a test needs them to, and remember what was
/// asked.
///
/// The remembering is the useful part: `docs/security.md` rule 4 says never ask
/// on launch, and `asked` is what lets a test prove an app did not.
///
/// Safe to use from more than one task at a time.
public final class InMemoryInputPermissions: InputPermissions {
    private struct State {
        var statuses: [InputPermission: PermissionStatus]
        var asked: [InputPermission] = []
    }

    private let answersWhenAsked: PermissionStatus
    private let state: OSAllocatedUnfairLock<State>

    /// - Parameters:
    ///   - statuses: Where each permission starts. Anything left out starts at
    ///     ``PermissionStatus/notAsked``.
    ///   - answersWhenAsked: What the person says when the prompt appears.
    public init(
        _ statuses: [InputPermission: PermissionStatus] = [:],
        answersWhenAsked: PermissionStatus = .granted
    ) {
        self.answersWhenAsked = answersWhenAsked
        state = OSAllocatedUnfairLock(initialState: State(statuses: statuses))
    }

    /// Everything that has been asked for, in order.
    public var asked: [InputPermission] {
        state.withLock { $0.asked }
    }

    public func status(of permission: InputPermission) -> PermissionStatus {
        state.withLock { $0.statuses[permission] ?? .notAsked }
    }

    public func request(_ permission: InputPermission) async -> PermissionStatus {
        state.withLock { state in
            state.asked.append(permission)
            // A permission already settled does not reopen. iOS asks once, and
            // a fake that forgot this would let tests pass on a flow that stalls
            // in somebody's hand.
            let current = state.statuses[permission] ?? .notAsked
            guard current == .notAsked else { return current }
            state.statuses[permission] = answersWhenAsked
            return answersWhenAsked
        }
    }
}
