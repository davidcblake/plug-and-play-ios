import Foundation
import SwiftUI

/// One number worth looking at, with the word for what it is.
///
/// ```swift
/// PPMetric(value: "12,340", label: "Steps", caption: "Today")
/// ```
///
/// The number is passed in already written out. Turning 12340 into "12,340" —
/// or into "12.340" for someone in Germany, or into miles rather than
/// kilometres — depends on the person's settings and on what the number means,
/// and neither of those is something a design component can know. Format with
/// Apple's `FormatStyle` at the call site and hand the text over.
///
/// Digits are monospaced (see ``PPTextStyle/number``), so a value that ticks
/// upward does not shuffle sideways as its digits change.
public struct PPMetric: View {
    @Environment(\.ppTheme) private var theme

    let value: String
    let label: String
    let caption: String?

    /// - Parameters:
    ///   - value: The number, already formatted for this person's locale.
    ///   - label: What the number is: "Steps", "Days away", "Chapters read".
    ///   - caption: Optional context: "Today", "This week", "Since January".
    public init(value: String, label: String, caption: String? = nil) {
        self.value = value
        self.label = label
        self.caption = caption
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
            Text(label)
                .ppText(.caption)
                .foregroundStyle(theme.textSecondary)
            Text(value)
                .ppText(.number)
                .foregroundStyle(theme.textPrimary)
            if let caption {
                Text(caption)
                    .ppText(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        // Read as one thing. Left as three, VoiceOver stops on "Steps", then
        // "12,340", then "Today" as if they were unrelated.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenDescription)
    }

    /// What VoiceOver says: the label first, because "Steps, 12,340" tells you
    /// what you are hearing before it tells you the number.
    var spokenDescription: String {
        let parts: [String?] = [label, value, caption]
        return parts
            .compactMap { $0 }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")
    }
}
