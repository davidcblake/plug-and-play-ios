import PPData
import PPDesign
import PPInput
import PPNotify
import PPOnboard
import SwiftUI

/// The first thing that has ever depended on this package.
///
/// Phase 0's definition of done says "an empty app can depend on this package
/// and it compiles". Until this existed, that had never been true — the package
/// compiled itself, which is not the same claim.
///
/// It is also the only place any of `PPDesign` has been seen by a person.
@main
struct ExampleApp: App {
    /// Everything is faked. This app has no account, no iCloud container and no
    /// microphone — it exists to prove the pieces fit together and to show what
    /// they look like.
    private let transcriber = InMemoryTranscriber(hears: ["Colosseum", "Colosseum at nine"])
    private let reminders = InMemoryReminders()

    var body: some Scene {
        WindowGroup {
            GalleryScreen()
                .ppTheme(.plugAndPlay)
                .transcriber(transcriber)
                .reminders(reminders)
                .onboardingProgress(InMemoryOnboardingProgress())
        }
    }
}
