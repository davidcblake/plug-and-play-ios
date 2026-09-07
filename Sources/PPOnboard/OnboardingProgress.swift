import Foundation
import os

/// One thing a person is shown or asked once.
///
/// Named rather than numbered, because onboarding steps get reordered and a
/// step remembered as "number three" becomes the wrong step the moment
/// somebody inserts a screen.
public struct OnboardingStep: Hashable, Sendable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }

    /// The first-run welcome. Every app has one.
    public static let welcome = OnboardingStep("welcome")
}

/// What this person has already been through.
///
/// The seam, so a test can start somebody halfway through and an app can decide
/// where this is written down.
public protocol OnboardingProgress: Sendable {
    /// Whether this step is already done.
    func hasCompleted(_ step: OnboardingStep) -> Bool
    /// Remember that it is done. Doing this twice is harmless.
    func markCompleted(_ step: OnboardingStep)
}

extension OnboardingProgress {
    /// Whether this person has never opened the app before.
    public var isFirstRun: Bool {
        hasCompleted(.welcome) == false
    }
}

/// Progress held in memory, gone when the app closes.
///
/// For tests and previews, and the way the "somebody halfway through
/// onboarding" screen gets built without a device that is halfway through.
///
/// Safe to use from more than one task at a time.
public final class InMemoryOnboardingProgress: OnboardingProgress {
    private let state: OSAllocatedUnfairLock<Set<OnboardingStep>>

    /// - Parameter completed: What is already done. Empty means a fresh install.
    public init(completed: Set<OnboardingStep> = []) {
        state = OSAllocatedUnfairLock(initialState: completed)
    }

    public func hasCompleted(_ step: OnboardingStep) -> Bool {
        state.withLock { $0.contains(step) }
    }

    public func markCompleted(_ step: OnboardingStep) {
        state.withLock { $0.insert(step) }
    }
}

/// Progress written to the phone's own settings store, where it survives the
/// app closing.
///
/// **Only ever holds "this was shown".** `docs/security.md` rule 2 keeps
/// anything that proves who somebody is out of here — this store is not
/// encrypted and is readable from a device backup. A flag saying somebody saw a
/// welcome screen is not worth protecting; a token is, and belongs in the
/// Keychain.
///
/// Known limitation, stated rather than hidden: this does not travel between a
/// person's devices, so somebody who onboarded on their phone will onboard
/// again on an iPad.
public struct DefaultsOnboardingProgress: OnboardingProgress {
    private static let prefix = "pp.onboarding."

    private let suiteName: String?

    /// - Parameter suiteName: Which settings store to use. The app's own by
    ///   default; a test passes its own so it does not scribble on it.
    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        guard let suiteName, let suite = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return suite
    }

    public func hasCompleted(_ step: OnboardingStep) -> Bool {
        defaults.bool(forKey: Self.prefix + step.name)
    }

    public func markCompleted(_ step: OnboardingStep) {
        defaults.set(true, forKey: Self.prefix + step.name)
    }
}
