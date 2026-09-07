import Foundation
import os

/// Remembers an unfinished deletion in memory, for tests and previews.
///
/// Safe to use from more than one task at a time.
public final class InMemoryErasureMemory: RemembersErasure {
    private let state: OSAllocatedUnfairLock<Bool>

    /// - Parameter isUnfinished: Whether somebody is already part-deleted,
    ///   which is how the "app was killed halfway" case gets built.
    public init(isUnfinished: Bool = false) {
        state = OSAllocatedUnfairLock(initialState: isUnfinished)
    }

    public var isErasureUnfinished: Bool {
        state.withLock { $0 }
    }

    public func rememberErasureStarted() {
        state.withLock { $0 = true }
    }

    public func rememberErasureFinished() {
        state.withLock { $0 = false }
    }
}

/// Remembers an unfinished deletion where it survives the app closing.
///
/// **Holds one flag and nothing else.** `docs/security.md` rule 2 keeps
/// anything proving who somebody is out of this store — it is not encrypted and
/// is readable from a backup. "Somebody asked to be deleted" is not a secret;
/// it is the opposite of one, and it needs to survive being killed mid-delete
/// far more than it needs protecting.
public struct DefaultsErasureMemory: RemembersErasure {
    private static let key = "pp.erasure.unfinished"

    private let suiteName: String?

    /// - Parameter suiteName: Which settings store to use. The app's own by
    ///   default; a test passes its own.
    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        guard let suiteName, let suite = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return suite
    }

    public var isErasureUnfinished: Bool {
        defaults.bool(forKey: Self.key)
    }

    public func rememberErasureStarted() {
        defaults.set(true, forKey: Self.key)
    }

    public func rememberErasureFinished() {
        defaults.set(false, forKey: Self.key)
    }
}
