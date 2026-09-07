import Foundation
import PPCore

/// Something the phone shows later, whether or not the app is running.
///
/// **Local, not push.** Nothing here needs a server, an account, or a network.
/// The phone is told once and does the rest by itself, which is exactly the
/// shape a local-first app wants: a daily study reminder keeps arriving on a
/// plane, in a canyon, with the phone in airplane mode for a week.
public struct Reminder: Sendable, Equatable, Identifiable {
    /// What this reminder is, so it can be replaced rather than duplicated.
    ///
    /// **Scheduling the same id twice replaces it.** That is the whole reason
    /// this is here: the classic bug is rescheduling a daily reminder on every
    /// launch and giving somebody forty identical notifications. An id makes
    /// that impossible rather than merely discouraged.
    public let id: String
    /// The line somebody reads on the lock screen. Short.
    public let title: String
    /// The second line, when there is more worth saying.
    public let body: String?
    /// When it fires.
    public let schedule: ReminderSchedule

    public init(id: String, title: String, body: String? = nil, schedule: ReminderSchedule) {
        self.id = id
        self.title = title
        self.body = body
        self.schedule = schedule
    }
}

/// When a reminder fires.
public enum ReminderSchedule: Sendable, Equatable {
    /// Once, at a moment, and then never again.
    case once(at: Date)
    /// Every day at a time, in the person's own timezone — so it stays at
    /// eight in the morning when they fly somewhere, rather than following
    /// them across timezones as a fixed instant would.
    ///
    /// - Parameters:
    ///   - hour: 0 to 23.
    ///   - minute: 0 to 59.
    case everyDay(hour: Int, minute: Int)

    /// Whether this describes a real time of day.
    ///
    /// Out-of-range values are a programming mistake rather than something a
    /// person did, so this is here for the fake to catch during a test rather
    /// than for an app to check at runtime.
    public var isValid: Bool {
        switch self {
        case .once:
            true
        case .everyDay(let hour, let minute):
            (0...23).contains(hour) && (0...59).contains(minute)
        }
    }
}

/// Why a reminder could not be scheduled.
public struct NotifyFailure: PPError, Equatable {
    public let userMessage: String
    public let logMessage: String

    public init(userMessage: String, logMessage: String? = nil) {
        self.userMessage = userMessage
        self.logMessage = logMessage ?? userMessage
    }

    /// Nothing has been wired up to schedule anything.
    public static let remindersUnavailable = NotifyFailure(
        userMessage: "Reminders aren't set up in this app.",
        logMessage: "No Reminders was injected, so NoReminders answered."
    )

    /// A time of day that does not exist.
    public static let impossibleTime = NotifyFailure(
        userMessage: "That isn't a time of day.",
        logMessage: "ReminderSchedule.everyDay was given an hour or minute out of range."
    )

    /// More reminders than iOS will keep. See ``Reminders/maximumPending``.
    public static let tooManyPending = NotifyFailure(
        userMessage: "There are too many reminders set already.",
        logMessage: """
            More than 64 pending local notifications. iOS keeps the soonest 64 and \
            silently discards the rest.
            """
    )
}
