import Foundation

/// Reminders the phone will show on its own.
///
/// The seam every app schedules through. Nothing above this line knows whether
/// the phone was actually told, which is what lets a test check that an app
/// scheduled the right thing without a device that fires it tomorrow morning.
public protocol Reminders: Sendable {
    /// Everything waiting to fire, in a stable order by id.
    ///
    /// Deliberately not "soonest first": a repeating reminder has no single
    /// next moment without knowing the person's calendar and timezone, and a
    /// list that silently reorders itself is worse than one that does not
    /// pretend to be chronological.
    func pending() async -> [Reminder]

    /// Schedule one, replacing any reminder with the same id.
    ///
    /// - Throws: ``NotifyFailure`` when it cannot be scheduled.
    func schedule(_ reminder: Reminder) async throws

    /// Cancel one by id. Cancelling something that was never scheduled is
    /// harmless — an app does not always know what it set last time it ran.
    func cancel(id: String) async

    /// Cancel everything this app scheduled.
    func cancelAll() async
}

extension Reminders {
    /// **iOS keeps at most 64 pending local notifications per app.**
    ///
    /// Not a suggestion and not this foundation's rule — it is the system's,
    /// and it is enforced by silently discarding the rest. An app that
    /// schedules one reminder a day for a year is not scheduling 365 things,
    /// it is scheduling 64 and losing the other 301 without a word.
    ///
    /// The way out is a repeating schedule rather than many single ones, which
    /// is why ``ReminderSchedule/everyDay(hour:minute:)`` exists and costs one.
    public static var maximumPending: Int { 64 }
}

/// Schedules nothing, and says so.
///
/// The default. An app that has not wired reminders up is not going to remind
/// anybody, and this reports that rather than appearing to work and staying
/// silent until somebody notices months later.
public struct NoReminders: Reminders {
    public init() {}

    public func pending() async -> [Reminder] { [] }

    public func schedule(_ reminder: Reminder) async throws {
        throw NotifyFailure.remindersUnavailable
    }

    public func cancel(id: String) async {}

    public func cancelAll() async {}
}
