import Foundation
import Testing
@testable import PPOnboard

@Suite("What somebody has already been through")
struct InMemoryOnboardingProgressTests {
    @Test("A fresh install has done nothing")
    func startsEmpty() {
        let progress = InMemoryOnboardingProgress()

        #expect(progress.hasCompleted(.welcome) == false)
        #expect(progress.isFirstRun)
    }

    @Test("Finishing the welcome means it is no longer a first run")
    func completingWelcomeEndsFirstRun() {
        let progress = InMemoryOnboardingProgress()

        progress.markCompleted(.welcome)

        #expect(progress.hasCompleted(.welcome))
        #expect(progress.isFirstRun == false)
    }

    @Test("Somebody can start halfway through")
    func canStartPartWayThrough() {
        // The screen nobody can reach twice on a real device, reachable here.
        let progress = InMemoryOnboardingProgress(completed: [.welcome])

        #expect(progress.isFirstRun == false)
        #expect(progress.hasCompleted(OnboardingStep("microphone")) == false)
    }

    @Test("Marking the same step twice is harmless")
    func markingTwiceIsFine() {
        let progress = InMemoryOnboardingProgress()

        progress.markCompleted(.welcome)
        progress.markCompleted(.welcome)

        #expect(progress.hasCompleted(.welcome))
    }

    @Test("Steps are told apart by name, not by order")
    func stepsAreNamed() {
        // Onboarding screens get reordered. A step remembered as "number three"
        // becomes the wrong step the moment somebody inserts a screen.
        let progress = InMemoryOnboardingProgress(completed: [OnboardingStep("microphone")])

        #expect(progress.hasCompleted(OnboardingStep("microphone")))
        #expect(progress.hasCompleted(OnboardingStep("notifications")) == false)
    }
}

@Suite("Progress that survives the app closing")
struct DefaultsOnboardingProgressTests {
    /// Its own settings store per test, removed afterwards, so these never
    /// touch the real one or each other.
    private func withOwnStore(_ body: (DefaultsOnboardingProgress) -> Void) {
        let suiteName = "pp.onboarding.tests.\(UUID().uuidString)"
        defer { UserDefaults.standard.removeSuite(named: suiteName) }

        body(DefaultsOnboardingProgress(suiteName: suiteName))
    }

    @Test("Remembers across two readers of the same store")
    func remembersWhatWasWritten() {
        withOwnStore { progress in
            #expect(progress.isFirstRun)

            progress.markCompleted(.welcome)

            // A second reader is what "the app was closed and reopened" looks
            // like from here.
            #expect(progress.hasCompleted(.welcome))
        }
    }

    @Test("One app's store is not another's")
    func storesAreSeparate() {
        withOwnStore { first in
            first.markCompleted(.welcome)

            withOwnStore { second in
                #expect(second.isFirstRun)
            }
        }
    }
}
