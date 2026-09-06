import Foundation
import SwiftUI

/// A color with a light-appearance value and a dark-appearance value, written
/// the way a designer writes one: `0xRRGGBB`.
///
/// Every color in this foundation is a pair. There is no such thing here as a
/// color that only works in one appearance — the compiler makes you supply
/// both, because "we forgot dark mode on that one screen" is the most common
/// way an otherwise finished app looks unfinished.
///
/// **Why plain numbers rather than an asset catalogue.** Apple's asset
/// catalogue is the usual home for colors, and it is the right answer for an
/// app. For a shared foundation it is the wrong one: a color set is opaque
/// binary-ish JSON that nobody reviews in a pull request, it needs a resource
/// bundle in the package, and — the deciding reason — a test cannot read it.
/// Written as numbers, the palette is legible in a diff and a test can check
/// every text color is actually readable on the background it sits on. See
/// `docs/decisions/0007-ppdesign-tokens-and-components.md`.
///
/// Use it anywhere SwiftUI takes a style:
///
/// ```swift
/// Text("Rome").foregroundStyle(theme.textPrimary)
/// ```
public struct PPColor: ShapeStyle, Hashable, Sendable {
    /// The value used in light appearance, as `0xRRGGBB`.
    public let light: UInt32
    /// The value used in dark appearance, as `0xRRGGBB`.
    public let dark: UInt32

    /// - Parameters:
    ///   - light: Six hex digits, `0xRRGGBB`. Anything above the low 24 bits is
    ///     ignored, so write all six digits — `0xFFF` is not white here.
    ///   - dark: The same, for dark appearance.
    public init(light: UInt32, dark: UInt32) {
        // Anything above six digits is a typo, and a silent one: the extra bits
        // shift out during `channels(of:)` and the app draws a colour nobody
        // chose. `assert` rather than `precondition` on purpose — this should
        // stop whoever typed it, not crash an app in someone's hand over a
        // colour.
        assert(light <= 0xFFFFFF, "A color is six hex digits: \(String(light, radix: 16))")
        assert(dark <= 0xFFFFFF, "A color is six hex digits: \(String(dark, radix: 16))")
        self.light = light
        self.dark = dark
    }

    /// The value this color takes in one appearance.
    public func hex(for scheme: ColorScheme) -> UInt32 {
        // Compared against `.dark` rather than switched on, so an appearance
        // Apple adds later behaves like light rather than failing to compile.
        scheme == .dark ? dark : light
    }

    /// This color in one appearance, as SwiftUI's own color type.
    ///
    /// Reach for this only where something insists on a `Color` — `.tint(_:)`
    /// is the common one. Everywhere else pass the `PPColor` itself, and it
    /// picks its own appearance from the environment.
    public func color(for scheme: ColorScheme) -> Color {
        let (red, green, blue) = Self.channels(of: hex(for: scheme))
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    /// Picks the appearance from wherever this style is being drawn.
    ///
    /// This is what lets a `PPColor` be handed straight to `foregroundStyle`,
    /// `background`, or `fill` without the caller reading the color scheme.
    public func resolve(in environment: EnvironmentValues) -> Color {
        color(for: environment.colorScheme)
    }

    /// How readable this color is on top of `background`, as the WCAG contrast
    /// ratio: 1 is invisible, 21 is black on white.
    ///
    /// The thresholds worth knowing: **4.5** is the accessibility standard for
    /// normal text, **3** for large text and for the outline of a control,
    /// **7** is the stricter standard. The palette's own tests hold every text
    /// color in this foundation to at least 4.5 against every surface it is
    /// drawn on.
    public func contrastRatio(against background: PPColor, in scheme: ColorScheme) -> Double {
        let mine = Self.relativeLuminance(of: hex(for: scheme))
        let theirs = Self.relativeLuminance(of: background.hex(for: scheme))
        return (max(mine, theirs) + 0.05) / (min(mine, theirs) + 0.05)
    }

    /// The red, green and blue parts of a color, each from 0 to 1.
    static func channels(of hex: UInt32) -> (red: Double, green: Double, blue: Double) {
        (
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// How much light a color appears to give off, from 0 (black) to 1 (white).
    ///
    /// This is WCAG's definition, not a plain average: our eyes read green as
    /// far brighter than blue at the same number, and the curve undoes the way
    /// screens encode brightness. Copied from the specification rather than
    /// invented, because a "close enough" version would quietly pass colors
    /// that people cannot read.
    static func relativeLuminance(of hex: UInt32) -> Double {
        let (red, green, blue) = channels(of: hex)
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    private static func linear(_ channel: Double) -> Double {
        channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }
}
