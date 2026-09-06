import SwiftUI

/// What a screen shows when there is nothing on it yet.
///
/// ```swift
/// PPEmptyState(
///     symbolName: "suitcase",
///     title: "No trips yet",
///     message: "Add your first trip and it will show up here.",
///     action: .init(title: "Add a trip") { addTrip() }
/// )
/// ```
///
/// **This is deliberately a thin wrapper around Apple's
/// `ContentUnavailableView`.** Apple's version already handles the layout, the
/// type scaling and the way it centers itself, and it is what people are used
/// to seeing across iOS. All this adds is the family's button on the action, so
/// the way out of an empty screen looks the same in every app. If this ever
/// grows past that, the honest thing is to ask whether it should exist at all
/// rather than to keep re-styling Apple's component.
///
/// Text is shown exactly as given. Translate before passing it in.
public struct PPEmptyState: View {
    /// The way out of the empty screen.
    public struct Action {
        /// The words on the button.
        public let title: String
        /// What tapping it does.
        public let handler: () -> Void

        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    let symbolName: String
    let title: String
    let message: String?
    let action: Action?

    /// - Parameters:
    ///   - symbolName: An SF Symbol name. Pick one that says what is missing —
    ///     a suitcase, a book, a dumbbell — not a generic exclamation mark.
    ///   - title: A short line saying what is not here.
    ///   - message: One sentence on how to change that. Optional, but a title
    ///     with no way forward is a dead end.
    ///   - action: The button that does it, when there is one obvious next step.
    public init(
        symbolName: String,
        title: String,
        message: String? = nil,
        action: Action? = nil
    ) {
        self.symbolName = symbolName
        self.title = title
        self.message = message
        self.action = action
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbolName)
        } description: {
            if let message {
                Text(message)
            }
        } actions: {
            if let action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.ppProminent)
            }
        }
    }
}
