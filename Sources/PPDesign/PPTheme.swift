import SwiftUI

/// The family look: every color the shared components draw with, in one place.
///
/// An app takes the family look and changes what makes it its own — almost
/// always just the accent:
///
/// ```swift
/// var theme = PPTheme.plugAndPlay
/// theme.accent = PPColor(light: 0x1D4ED8, dark: 0x93C5FD)
///
/// WindowGroup {
///     ContentView().ppTheme(theme)
/// }
/// ```
///
/// **Colors are injected; spacing and type are not.** The apps genuinely
/// differ in color — a travel app and a scripture app should not share an
/// accent — and they do not differ in how far apart things sit or how large a
/// heading is. Those stay constants (`PPSpacing`, `PPTextStyle`), because a
/// value nobody varies gains nothing from being injectable and costs a
/// parameter on everything that reads it.
///
/// Every color here is held to a readability standard by this module's own
/// tests: each text color clears WCAG AA (4.5:1) against every surface it is
/// drawn on, in both light and dark. Change one and the test tells you if you
/// broke it. If you add an app accent of your own, test it the same way — see
/// `PPColor.contrastRatio(against:in:)`.
public struct PPTheme: Hashable, Sendable {
    /// Behind everything on a screen.
    public var background: PPColor
    /// A card, sheet or row sitting on top of the background.
    public var surface: PPColor
    /// Anything a person is meant to read: body text, headings, values.
    public var textPrimary: PPColor
    /// Supporting text — a label above a number, a date under a title.
    public var textSecondary: PPColor
    /// The app's own color. Buttons, links, selection. This is the one an app
    /// is expected to change.
    public var accent: PPColor
    /// A quiet wash of the accent, used behind an accent-colored label.
    public var accentSoft: PPColor
    /// Text drawn on top of a solid `accent` fill.
    public var textOnAccent: PPColor
    /// Something went well: a goal met, a trip booked, a chapter finished.
    public var positive: PPColor
    /// Something destructive or broken. Deleting, and failing.
    public var danger: PPColor
    /// A quiet wash of `danger`, used behind a danger-colored label.
    public var dangerSoft: PPColor
    /// Hairlines between rows. Decorative — never the only thing carrying
    /// meaning, because it is deliberately too faint to rely on.
    public var separator: PPColor

    /// Defaults are the family look, so an app overrides one color by naming
    /// one color rather than restating all eleven.
    public init(
        background: PPColor = PPColor(light: 0xFBF9F7, dark: 0x121212),
        surface: PPColor = PPColor(light: 0xFFFFFF, dark: 0x1E1E1E),
        textPrimary: PPColor = PPColor(light: 0x1A1A1A, dark: 0xF2F0EE),
        textSecondary: PPColor = PPColor(light: 0x5C5C5C, dark: 0xA8A8A8),
        accent: PPColor = PPColor(light: 0x0E6E62, dark: 0x4FD1C5),
        accentSoft: PPColor = PPColor(light: 0xE4F0EE, dark: 0x10322D),
        textOnAccent: PPColor = PPColor(light: 0xFFFFFF, dark: 0x08201D),
        positive: PPColor = PPColor(light: 0x1F7A43, dark: 0x4ADE80),
        danger: PPColor = PPColor(light: 0xB3261E, dark: 0xFF6B6B),
        dangerSoft: PPColor = PPColor(light: 0xFBE7E5, dark: 0x3A1A18),
        separator: PPColor = PPColor(light: 0xE2DED9, dark: 0x333333)
    ) {
        self.background = background
        self.surface = surface
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.accent = accent
        self.accentSoft = accentSoft
        self.textOnAccent = textOnAccent
        self.positive = positive
        self.danger = danger
        self.dangerSoft = dangerSoft
        self.separator = separator
    }

    /// The family look, unchanged. Warm off-white paper in light, near-black in
    /// dark, and a deep teal accent that stays readable in both.
    public static let plugAndPlay = PPTheme()

    /// Every color with the name it goes by, so a test can walk the whole
    /// palette instead of naming each one and missing the eleventh.
    var allColors: [(name: String, color: PPColor)] {
        [
            ("background", background),
            ("surface", surface),
            ("textPrimary", textPrimary),
            ("textSecondary", textSecondary),
            ("accent", accent),
            ("accentSoft", accentSoft),
            ("textOnAccent", textOnAccent),
            ("positive", positive),
            ("danger", danger),
            ("dangerSoft", dangerSoft),
            ("separator", separator)
        ]
    }
}

// Themes travel down the view tree, the same way everything else in this
// foundation is injected (`AGENTS.md`: environment, never a singleton).
//
// Written as an explicit `EnvironmentKey` to match `PPCore`, so both modules
// read the same way.
private struct PPThemeKey: EnvironmentKey {
    /// The family look, not a blank one. Unlike a log sink — where doing
    /// nothing until someone wires it up is correct — a view with no theme
    /// injected should still look right, because that is every SwiftUI preview
    /// anybody ever writes.
    static let defaultValue = PPTheme.plugAndPlay
}

extension EnvironmentValues {
    /// The colors this part of the view tree draws with.
    public var ppTheme: PPTheme {
        get { self[PPThemeKey.self] }
        set { self[PPThemeKey.self] = newValue }
    }
}

extension View {
    /// Set the colors for this view and everything below it.
    ///
    /// Call once at the app's root.
    public func ppTheme(_ theme: PPTheme) -> some View {
        environment(\.ppTheme, theme)
    }
}
