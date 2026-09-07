import PPDesign
import SwiftUI

/// Every piece of `PPDesign`, on one screen, so somebody can look at it.
///
/// The whole design system was built and merged without a human ever seeing it.
/// This is where that stops being true, and where "the contrast tests pass"
/// gets checked against "it actually looks right".
struct GalleryScreen: View {
    @Environment(\.ppTheme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PPSpacing.large) {
                    typeSection
                    colorSection
                    componentSection
                }
                .padding(PPSpacing.screenMargin)
            }
            .background(theme.background)
            .navigationTitle("Plug and Play")
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.small) {
            Text("Type").ppText(.sectionTitle).foregroundStyle(theme.textPrimary)
            Text("Day 3 — Rome").ppText(.screenTitle).foregroundStyle(theme.textPrimary)
            Text("Colosseum at nine").ppText(.cardTitle).foregroundStyle(theme.textPrimary)
            Text("Tickets are booked for the whole family, and the queue is shorter before ten.")
                .ppText(.body)
                .foregroundStyle(theme.textPrimary)
            Text("Added yesterday").ppText(.caption).foregroundStyle(theme.textSecondary)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.small) {
            Text("Color").ppText(.sectionTitle).foregroundStyle(theme.textPrimary)
            HStack(spacing: PPSpacing.small) {
                swatch(theme.accent, "accent")
                swatch(theme.positive, "positive")
                swatch(theme.danger, "danger")
                swatch(theme.separator, "separator")
            }
        }
    }

    private func swatch(_ color: PPColor, _ name: String) -> some View {
        VStack(spacing: PPSpacing.extraSmall) {
            RoundedRectangle(cornerRadius: PPRadius.small, style: .continuous)
                .fill(color)
                .frame(height: 44)
            Text(name).ppText(.caption).foregroundStyle(theme.textSecondary)
        }
    }

    private var componentSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.medium) {
            Text("Components").ppText(.sectionTitle).foregroundStyle(theme.textPrimary)

            PPCard {
                VStack(alignment: .leading, spacing: PPSpacing.small) {
                    Text("Day 3 — Rome").ppText(.cardTitle).foregroundStyle(theme.textPrimary)
                    Text("Colosseum, lunch near the forum, then the Pantheon.")
                        .ppText(.body)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            PPCard {
                HStack(spacing: PPSpacing.large) {
                    PPMetric(value: "12,340", label: "Steps", caption: "Today")
                    PPMetric(value: "3", label: "Days away")
                }
            }

            VStack(spacing: PPSpacing.small) {
                Button("Add a trip") {}.buttonStyle(.ppProminent)
                Button("Not now") {}.buttonStyle(.ppQuiet)
                Button("Delete trip") {}.buttonStyle(.ppDestructive)
            }

            PPCard {
                PPEmptyState(
                    symbolName: "suitcase",
                    title: "No trips yet",
                    message: "Add your first trip and it will show up here."
                )
            }
        }
    }
}

#Preview {
    GalleryScreen().ppTheme(.plugAndPlay)
}
