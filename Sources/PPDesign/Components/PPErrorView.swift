import PPCore
import SwiftUI

/// What a screen shows when something failed.
///
/// ```swift
/// PPErrorView(error: failure) { retry() }
/// ```
///
/// **It shows `userMessage` and never `logMessage`.** That split is the whole
/// point of `PPError` in `PPCore`: one string is written for a person, the
/// other names types and error codes for a log. This component is where the
/// rule is enforced rather than remembered — a screen that gets its failure
/// text from here cannot accidentally put "SQLITE_FULL: disk image is
/// malformed" in front of someone.
///
/// In a local-first app most failures are worth retrying, because most of them
/// were nothing to do with the network. Pass `retry` whenever trying again
/// could plausibly work.
public struct PPErrorView: View {
    let message: String
    let retryTitle: String
    let retry: (() -> Void)?

    /// - Parameters:
    ///   - error: The failure. Only its `userMessage` is ever shown.
    ///   - retryTitle: The words on the retry button. Translate before passing.
    ///   - retry: What trying again does, or `nil` when there is nothing to try.
    public init(
        error: any PPError,
        retryTitle: String = "Try again",
        retry: (() -> Void)? = nil
    ) {
        self.message = error.userMessage
        self.retryTitle = retryTitle
        self.retry = retry
    }

    public var body: some View {
        PPEmptyState(
            symbolName: "exclamationmark.triangle",
            title: message,
            action: retryAction
        )
    }

    private var retryAction: PPEmptyState.Action? {
        guard let retry else { return nil }
        return PPEmptyState.Action(title: retryTitle, handler: retry)
    }
}
