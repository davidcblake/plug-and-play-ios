import SwiftUI

private struct RemindersKey: EnvironmentKey {
    /// Reminds nobody of anything. An app that has not wired this up is not
    /// scheduling reminders, and the default says so rather than pretending.
    static let defaultValue: any Reminders = NoReminders()
}

extension EnvironmentValues {
    /// What schedules reminders for this part of the view tree.
    public var reminders: any Reminders {
        get { self[RemindersKey.self] }
        set { self[RemindersKey.self] = newValue }
    }
}

extension View {
    /// Inject reminders for this view and everything below it.
    public func reminders(_ reminders: any Reminders) -> some View {
        environment(\.reminders, reminders)
    }
}
