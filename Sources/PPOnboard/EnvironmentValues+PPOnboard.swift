import SwiftUI

private struct OnboardingProgressKey: EnvironmentKey {
    /// Nothing remembered, so every launch is a first run. Correct for a
    /// preview, and obviously wrong in a shipping app — which is the point: an
    /// app that forgot to inject this notices immediately.
    static let defaultValue: any OnboardingProgress = InMemoryOnboardingProgress()
}

extension EnvironmentValues {
    /// What this person has already been through.
    public var onboardingProgress: any OnboardingProgress {
        get { self[OnboardingProgressKey.self] }
        set { self[OnboardingProgressKey.self] = newValue }
    }
}

extension View {
    /// Inject onboarding progress for this view and everything below it.
    public func onboardingProgress(_ progress: any OnboardingProgress) -> some View {
        environment(\.onboardingProgress, progress)
    }
}
