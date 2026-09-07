import Foundation
import os

/// Reminders held in memory, so a test can see what an app scheduled.
///
/// The point is that scheduling is otherwise unobservable: a real reminder
/// proves itself by waking somebody up tomorrow morning, which is not a test
/// anybody runs. This one can be read immediately.
///
/// **Deliberately stricter than the real thing in one place.** iOS keeps the
/// soonest 64 pending notifications and silently discards the rest. This throws
/// instead, so an app that over-schedules finds out in a test rather than in a
/// bug report six months later that says "it stopped reminding me".
///
/// Safe to use from more than one task at a time.
public final class InMemoryReminders: Reminders {
    private let state = OSAllocatedUnfairLock(initialState: [String: Reminder]())

    public init() {}

    public func pending() async -> [Reminder] {
        state.withLock { $0 }
            .values
            .sorted { $0.id < $1.id }
    }

    public func schedule(_ reminder: Reminder) async throws {
        guard reminder.schedule.isValid else {
            throw NotifyFailure.impossibleTime
        }

        try state.withLock { scheduled in
            // Replacing an existing id is always allowed — it is the fix for
            // over-scheduling, not another instance of it.
            let isReplacement = scheduled[reminder.id] != nil
            guard isReplacement || scheduled.count < Self.maximumPending else {
                throw NotifyFailure.tooManyPending
            }
            scheduled[reminder.id] = reminder
        }
    }

    public func cancel(id: String) async {
        state.withLock { $0[id] = nil }
    }

    public func cancelAll() async {
        state.withLock { $0.removeAll() }
    }
}
