import SwiftUI
import Testing
@testable import PPDesign

/// The readability standard every text color in the family look has to meet:
/// WCAG AA for normal text.
private let readableEnough = 4.5

/// The stricter standard, which the main reading color is held to because it
/// is the one people look at for minutes at a time.
private let comfortablyReadable = 7.0

/// Text color, the surface it is drawn on, and how readable it has to be.
/// Every pairing the shared components actually draw is in here.
private let pairings: [(text: String, on: String, atLeast: Double)] = [
    ("textPrimary", "background", comfortablyReadable),
    ("textPrimary", "surface", comfortablyReadable),
    ("textSecondary", "background", readableEnough),
    ("textSecondary", "surface", readableEnough),
    ("accent", "background", readableEnough),
    ("accent", "surface", readableEnough),
    ("accent", "accentSoft", readableEnough),
    ("textOnAccent", "accent", readableEnough),
    ("positive", "background", readableEnough),
    ("positive", "surface", readableEnough),
    ("danger", "background", readableEnough),
    ("danger", "surface", readableEnough),
    ("danger", "dangerSoft", readableEnough)
]

@Suite("The family look is readable")
struct PPThemeReadabilityTests {
    @Test("Every text color is readable on every surface it is drawn on")
    func meetsContrastStandard() {
        let theme = PPTheme.plugAndPlay
        let colors = Dictionary(
            uniqueKeysWithValues: theme.allColors.map { ($0.name, $0.color) }
        )

        for pairing in pairings {
            guard let text = colors[pairing.text], let surface = colors[pairing.on] else {
                Issue.record("The palette has no color called \(pairing.text) or \(pairing.on)")
                continue
            }

            for scheme in [ColorScheme.light, .dark] {
                let ratio = text.contrastRatio(against: surface, in: scheme)
                #expect(
                    ratio >= pairing.atLeast,
                    """
                    \(pairing.text) on \(pairing.on) in \(scheme) is \(ratio), \
                    which is below the \(pairing.atLeast) it has to clear
                    """
                )
            }
        }
    }

    @Test("No color forgot its dark appearance")
    func everyColorHasBothAppearances() {
        for (name, color) in PPTheme.plugAndPlay.allColors {
            #expect(color.light != color.dark, "\(name) uses the same value in both appearances")
        }
    }

    @Test("The palette is eleven colors, and the readability test covers them")
    func paletteSizeIsWhatWeThink() {
        // A guard against a twelfth color arriving without anyone deciding
        // what it has to be readable against. If this fails, add the new
        // color to `pairings` — or say in the pull request why it never has
        // text on it.
        #expect(PPTheme.plugAndPlay.allColors.count == 11)
    }
}

@Suite("An app makes the family look its own")
struct PPThemeCustomisationTests {
    @Test("Changing the accent leaves everything else alone")
    func accentIsTheOnePieceAppsChange() {
        var theme = PPTheme.plugAndPlay
        theme.accent = PPColor(light: 0x1D4ED8, dark: 0x93C5FD)

        #expect(theme.accent.light == 0x1D4ED8)
        #expect(theme.background == PPTheme.plugAndPlay.background)
        #expect(theme.textPrimary == PPTheme.plugAndPlay.textPrimary)
    }

    @Test("A view with nothing injected still gets the family look")
    func environmentDefaultsToTheFamilyLook() {
        #expect(EnvironmentValues().ppTheme == PPTheme.plugAndPlay)
    }

    @Test("An injected theme is what the view tree reads")
    func environmentCarriesAnInjectedTheme() {
        var theme = PPTheme.plugAndPlay
        theme.accent = PPColor(light: 0x7C3AED, dark: 0xC4B5FD)

        var environment = EnvironmentValues()
        environment.ppTheme = theme

        #expect(environment.ppTheme.accent.light == 0x7C3AED)
    }
}
