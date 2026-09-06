import SwiftUI

/// The way buttons look in every app on this foundation.
///
/// ```swift
/// Button("Save trip") { save() }
///     .buttonStyle(.ppProminent)
/// ```
///
/// **Why not Apple's `.borderedProminent`.** Apple's built-in styles take a
/// tint and decide everything else themselves, and what they decide changes
/// with control size and with the iOS version. Four apps shipping on four
/// schedules would drift apart on button height, corner radius and label
/// weight — the exact things that make apps look related. This fixes those
/// three and keeps a guaranteed 44-point tap target, which
/// `.borderedProminent` does not promise at its default size. Reasoning in
/// `docs/decisions/0007-ppdesign-tokens-and-components.md`.
public struct PPButtonStyle: ButtonStyle {
    /// What a button is for, which decides how loud it looks.
    public enum Kind: Hashable, Sendable, CaseIterable {
        /// The one thing this screen is for. One per screen, at most.
        case prominent
        /// A real action, but not the main one.
        case quiet
        /// Deletes something, or cannot be undone.
        case destructive
    }

    private let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public func makeBody(configuration: Configuration) -> some View {
        // The style itself is not a view, so it cannot read the environment.
        // An inner view can, which is how the theme reaches the button.
        ButtonBody(kind: kind, configuration: configuration)
    }

    private struct ButtonBody: View {
        @Environment(\.ppTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled

        let kind: Kind
        let configuration: ButtonStyleConfiguration

        var body: some View {
            configuration.label
                .ppText(.buttonLabel)
                .foregroundStyle(kind.labelColor(in: theme))
                .padding(.horizontal, PPSpacing.medium)
                .padding(.vertical, PPSpacing.small)
                .frame(minHeight: PPButtonStyle.minimumHeight)
                .background(
                    kind.fillColor(in: theme),
                    in: RoundedRectangle(
                        cornerRadius: PPButtonStyle.cornerRadius,
                        style: .continuous
                    )
                )
                // The whole rounded rectangle is tappable, including the padding
                // around a short label. Without this, "OK" is a 20-point target.
                .contentShape(Rectangle())
                .opacity(opacity)
        }

        /// Pressed dims a little; disabled dims a lot. One value rather than
        /// two stacked modifiers, so the two states cannot multiply into
        /// something nearly invisible.
        private var opacity: Double {
            if !isEnabled { return 0.4 }
            return configuration.isPressed ? 0.85 : 1
        }
    }

    /// The smallest a button is allowed to be, however short its label.
    static var minimumHeight: CGFloat { PPSpacing.minimumTapTarget }

    /// How rounded a button's corners are.
    static var cornerRadius: CGFloat { PPRadius.medium }
}

extension PPButtonStyle.Kind {
    /// What the words on the button are drawn in.
    func labelColor(in theme: PPTheme) -> PPColor {
        switch self {
        case .prominent: theme.textOnAccent
        case .quiet: theme.accent
        case .destructive: theme.danger
        }
    }

    /// What sits behind them.
    ///
    /// Only the prominent button is a solid fill. The other two are a wash of
    /// their own color: loud enough to read as a button, quiet enough that a
    /// screen with three of them still has one obvious next step.
    func fillColor(in theme: PPTheme) -> PPColor {
        switch self {
        case .prominent: theme.accent
        case .quiet: theme.accentSoft
        case .destructive: theme.dangerSoft
        }
    }
}

extension ButtonStyle where Self == PPButtonStyle {
    /// The one thing this screen is for.
    public static var ppProminent: PPButtonStyle { PPButtonStyle(.prominent) }
    /// A real action, but not the main one.
    public static var ppQuiet: PPButtonStyle { PPButtonStyle(.quiet) }
    /// Deletes something, or cannot be undone.
    public static var ppDestructive: PPButtonStyle { PPButtonStyle(.destructive) }
}
