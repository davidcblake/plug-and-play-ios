import SwiftUI

/// A block of content on its own surface: a trip day, a saved passage, a
/// workout, a lecture.
///
/// ```swift
/// PPCard {
///     Text("Day 3 — Rome").ppText(.cardTitle)
///     Text("Colosseum at 9am").ppText(.body)
/// }
/// ```
///
/// It sets the surface, the inset and the corner. It does not lay out what is
/// inside it — that is the caller's, because a card of text and a card of
/// numbers want different arrangements and a card component that tried to
/// decide would be wrong for one of them.
public struct PPCard<Content: View>: View {
    @Environment(\.ppTheme) private var theme

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Self.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                theme.surface,
                in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
            )
            // A hairline rather than a shadow. A white card on a warm off-white
            // background needs an edge to be seen at all, and a shadow is the
            // expensive way to draw one: it costs an offscreen pass per card in
            // a scrolling list, and it disappears in dark mode exactly when the
            // edge is needed most.
            .overlay {
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .strokeBorder(theme.separator, lineWidth: 1)
            }
    }

    /// The inset between the card's edge and what is inside it.
    static var padding: CGFloat { PPSpacing.medium }

    /// How rounded the card's corners are.
    static var cornerRadius: CGFloat { PPRadius.medium }
}
