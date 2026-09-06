import PPCore
import SwiftUI
import Testing
@testable import PPDesign

@Suite("Buttons")
struct PPButtonStyleTests {
    @Test("Each kind draws in the colors it is meant to")
    func kindsUseTheRightColors() {
        let theme = PPTheme.plugAndPlay

        #expect(PPButtonStyle.Kind.prominent.fillColor(in: theme) == theme.accent)
        #expect(PPButtonStyle.Kind.prominent.labelColor(in: theme) == theme.textOnAccent)

        #expect(PPButtonStyle.Kind.quiet.fillColor(in: theme) == theme.accentSoft)
        #expect(PPButtonStyle.Kind.quiet.labelColor(in: theme) == theme.accent)

        #expect(PPButtonStyle.Kind.destructive.fillColor(in: theme) == theme.dangerSoft)
        #expect(PPButtonStyle.Kind.destructive.labelColor(in: theme) == theme.danger)
    }

    @Test("Only one kind is a solid fill, so a screen has one obvious next step")
    func onlyOneKindIsLoud() {
        let theme = PPTheme.plugAndPlay
        let solid = PPButtonStyle.Kind.allCases.filter { $0.fillColor(in: theme) == theme.accent }

        #expect(solid == [.prominent])
    }

    @Test("A button measures itself from the shared scale, not from typed-in numbers")
    func buttonUsesTheTokens() {
        // Note what this does and does not prove. It proves the component reads
        // the 44-point token rather than a number somebody typed. It does not
        // prove the rendered button is 44 points tall — that needs a rendering
        // test, which this module does not have.
        #expect(PPButtonStyle.minimumHeight == PPSpacing.minimumTapTarget)
        #expect(PPButtonStyle.cornerRadius == PPRadius.medium)
    }

    @Test("Every button's words are readable on its own background")
    func everyKindIsReadable() {
        // The pairing most likely to be got wrong when an app changes its
        // accent: a label on a fill made from the same color family.
        let theme = PPTheme.plugAndPlay

        for kind in PPButtonStyle.Kind.allCases {
            for scheme in [ColorScheme.light, .dark] {
                let ratio = kind.labelColor(in: theme)
                    .contrastRatio(against: kind.fillColor(in: theme), in: scheme)
                #expect(ratio >= 4.5, "\(kind) in \(scheme) is only \(ratio)")
            }
        }
    }
}

@MainActor
@Suite("Cards")
struct PPCardTests {
    @Test("A card measures itself from the shared scale, not from typed-in numbers")
    func cardUsesTheTokens() {
        #expect(PPCard<Text>.padding == PPSpacing.medium)
        #expect(PPCard<Text>.cornerRadius == PPRadius.medium)
    }
}

@MainActor
@Suite("Numbers on screen")
struct PPMetricTests {
    @Test("VoiceOver hears one thing, label first")
    func readsAsOnePhrase() {
        let metric = PPMetric(value: "12,340", label: "Steps", caption: "Today")

        #expect(metric.spokenDescription == "Steps, 12,340, Today")
    }

    @Test("A metric with no caption does not trail off")
    func skipsAMissingCaption() {
        let metric = PPMetric(value: "3", label: "Days away")

        #expect(metric.spokenDescription == "Days away, 3")
    }

    @Test("A caption of nothing but spaces is left out")
    func ignoresBlankText() {
        let metric = PPMetric(value: "12", label: "Chapters", caption: "   ")

        #expect(metric.spokenDescription == "Chapters, 12")
    }
}

/// A failure whose two messages are obviously different, so a test can tell
/// which one reached the screen.
private struct StorageFull: PPError {
    let userMessage = "There is no room left on your phone to save that."
    let logMessage = "SQLITE_FULL: disk image is malformed at /var/mobile/Containers/trips.sqlite"
}

@MainActor
@Suite("Showing a failure")
struct PPErrorViewTests {
    @Test("Shows what the failure says to a person")
    func showsTheUserMessage() {
        let view = PPErrorView(error: StorageFull())

        #expect(view.message == StorageFull().userMessage)
    }

    @Test("Never shows what the failure says to a log")
    func neverShowsTheLogMessage() {
        // The rule this component exists to enforce. `logMessage` names files,
        // types and error codes; it is written for an engineer reading a log,
        // and it must not reach a screen.
        let failure = StorageFull()
        let view = PPErrorView(error: failure)

        #expect(view.message != failure.logMessage)
        #expect(view.message.contains("SQLITE_FULL") == false)
    }

    @Test("Uses a general failure symbol unless the caller knows better")
    func symbolHasASensibleDefault() {
        #expect(PPErrorView(error: StorageFull()).symbolName == "exclamationmark.triangle")
        #expect(
            PPErrorView(error: StorageFull(), symbolName: "wifi.slash").symbolName == "wifi.slash"
        )
    }

    @Test("Offers a way to try again only when there is one")
    func retryIsOptional() {
        let withoutRetry = PPErrorView(error: StorageFull())
        let withRetry = PPErrorView(error: StorageFull(), retry: {})

        #expect(withoutRetry.retry == nil)
        #expect(withRetry.retry != nil)
        #expect(withoutRetry.retryTitle == "Try again")
    }
}
