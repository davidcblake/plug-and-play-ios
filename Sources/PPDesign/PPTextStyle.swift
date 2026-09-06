import SwiftUI

/// One of the handful of ways text is allowed to look in these apps.
///
/// A design system's real job is subtraction: seven named styles, and no view
/// anywhere writing `.font(.system(size: 17))`. When every app picks from the
/// same seven, four apps look related without anyone maintaining a style guide.
///
/// **Every style is built from one of Apple's text styles**, never a fixed
/// point size. That is what makes the text grow when someone turns type size up
/// in Settings — which a meaningful share of people have done, and which is the
/// single most common way an app becomes unusable for them.
///
/// Use it through ``SwiftUI/View/ppText(_:)``:
///
/// ```swift
/// Text("Day 3 — Rome").ppText(.sectionTitle)
/// ```
///
/// Deliberately not `Sendable`. These values are only ever read while drawing,
/// which happens on the main actor, and the conformance would tie this type to
/// SwiftUI's own concurrency annotations on `Font.Weight` and `Font.Design` for
/// no benefit anybody could point at.
public struct PPTextStyle: Hashable {
    /// Apple's text style this is built on. Decides how it scales when someone
    /// changes their type size.
    public let textStyle: Font.TextStyle
    /// How heavy the letters are.
    public let weight: Font.Weight
    /// Which of Apple's system typefaces it uses.
    public let design: Font.Design
    /// Whether every digit takes the same width.
    public let usesMonospacedDigits: Bool

    public init(
        textStyle: Font.TextStyle,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        usesMonospacedDigits: Bool = false
    ) {
        self.textStyle = textStyle
        self.weight = weight
        self.design = design
        self.usesMonospacedDigits = usesMonospacedDigits
    }

    /// This style as a SwiftUI font.
    public var font: Font {
        let base = Font.system(textStyle, design: design, weight: weight)
        return usesMonospacedDigits ? base.monospacedDigit() : base
    }
}

extension PPTextStyle {
    /// The name of a screen, at the top of it.
    public static var screenTitle: PPTextStyle {
        PPTextStyle(textStyle: .largeTitle, weight: .bold, design: .rounded)
    }

    /// The heading on a group of things below it.
    public static var sectionTitle: PPTextStyle {
        PPTextStyle(textStyle: .title3, weight: .semibold, design: .rounded)
    }

    /// The title of one card or row.
    public static var cardTitle: PPTextStyle {
        PPTextStyle(textStyle: .headline, weight: .semibold, design: .rounded)
    }

    /// Ordinary reading text. The one people spend the most time looking at.
    public static var body: PPTextStyle {
        PPTextStyle(textStyle: .body)
    }

    /// Small supporting text: a date, a label above a number, a hint.
    public static var caption: PPTextStyle {
        PPTextStyle(textStyle: .footnote)
    }

    /// A number worth looking at on its own — a distance, a total, a streak.
    ///
    /// Monospaced digits, so a number that is counting or ticking upward does
    /// not jitter sideways as its digits change width.
    public static var number: PPTextStyle {
        PPTextStyle(
            textStyle: .title,
            weight: .bold,
            design: .rounded,
            usesMonospacedDigits: true
        )
    }

    /// The words on a button.
    ///
    /// Deliberately a notch below ``cardTitle``: a button sitting under a card
    /// title should not compete with it for attention.
    public static var buttonLabel: PPTextStyle {
        PPTextStyle(textStyle: .body, weight: .semibold, design: .rounded)
    }

    /// Every style there is, so a test can check the whole set rather than the
    /// ones somebody remembered.
    static var all: [(name: String, style: PPTextStyle)] {
        [
            ("screenTitle", .screenTitle),
            ("sectionTitle", .sectionTitle),
            ("cardTitle", .cardTitle),
            ("body", .body),
            ("caption", .caption),
            ("number", .number),
            ("buttonLabel", .buttonLabel)
        ]
    }

    /// The styles used for text people read at length, as opposed to the
    /// headings, numbers and buttons that make up the furniture of a screen.
    ///
    /// These deliberately use Apple's default typeface rather than the rounded
    /// one. Rounded suits a heading or a big number; a screen of scripture or a
    /// page of lecture notes set in it is tiring to read, and two of the four
    /// planned apps are mostly reading.
    static var readingStyles: [(name: String, style: PPTextStyle)] {
        [
            ("body", .body),
            ("caption", .caption)
        ]
    }
}

extension View {
    /// Draw this text in one of the family's styles.
    ///
    /// Sets the font only. Color stays a separate decision, because the same
    /// style is drawn in primary text on a card and in white on a button.
    public func ppText(_ style: PPTextStyle) -> some View {
        font(style.font)
    }
}
