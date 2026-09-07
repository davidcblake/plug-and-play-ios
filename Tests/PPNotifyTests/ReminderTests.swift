import Foundation
import Testing
@testable import PPNotify

@Suite("When a reminder fires")
struct ReminderScheduleTests {
    @Test("A real time of day is valid")
    func acceptsRealTimes() {
        #expect(ReminderSchedule.everyDay(hour: 0, minute: 0).isValid)
        #expect(ReminderSchedule.everyDay(hour: 7, minute: 30).isValid)
        #expect(ReminderSchedule.everyDay(hour: 23, minute: 59).isValid)
        #expect(ReminderSchedule.once(at: Date()).isValid)
    }

    @Test("A time of day that does not exist is not")
    func rejectsImpossibleTimes() {
        #expect(ReminderSchedule.everyDay(hour: 24, minute: 0).isValid == false)
        #expect(ReminderSchedule.everyDay(hour: -1, minute: 0).isValid == false)
        #expect(ReminderSchedule.everyDay(hour: 7, minute: 60).isValid == false)
    }
}

@Suite("Scheduling reminders")
struct InMemoryRemindersTests {
    private let dailyStudy = Reminder(
        id: "daily-study",
        title: "Time to study",
        body: "Alma 32 is waiting.",
        schedule: .everyDay(hour: 6, minute: 30)
    )

    @Test("Nothing is pending until something is scheduled")
    func startsEmpty() async {
        let pending = await InMemoryReminders().pending()

        #expect(pending.isEmpty)
    }

    @Test("What was scheduled can be read back")
    func schedulesAndReadsBack() async throws {
        let reminders = InMemoryReminders()

        try await reminders.schedule(dailyStudy)
        let pending = await reminders.pending()

        #expect(pending == [dailyStudy])
    }

    @Test("Scheduling the same id twice replaces rather than duplicates")
    func replacesByIdentifier() async throws {
        // The bug this prevents: rescheduling a daily reminder on every launch
        // and giving somebody forty identical notifications.
        let reminders = InMemoryReminders()
        let moved = Reminder(
            id: "daily-study",
            title: "Time to study",
            schedule: .everyDay(hour: 21, minute: 0)
        )

        try await reminders.schedule(dailyStudy)
        try await reminders.schedule(moved)
        let pending = await reminders.pending()

        #expect(pending.count == 1)
        #expect(pending.first?.schedule == .everyDay(hour: 21, minute: 0))
    }

    @Test("A time of day that does not exist is refused")
    func refusesImpossibleTimes() async throws {
        let reminders = InMemoryReminders()
        let wrong = Reminder(id: "x", title: "x", schedule: .everyDay(hour: 25, minute: 0))

        do {
            try await reminders.schedule(wrong)
            Issue.record("An impossible time was accepted")
        } catch let failure as NotifyFailure {
            #expect(failure == .impossibleTime)
        }

        let pending = await reminders.pending()
        #expect(pending.isEmpty)
    }

    @Test("Cancelling removes one; cancelling something unknown is harmless")
    func cancels() async throws {
        let reminders = InMemoryReminders()
        try await reminders.schedule(dailyStudy)

        await reminders.cancel(id: "never-scheduled")
        let stillThere = await reminders.pending()
        await reminders.cancel(id: "daily-study")
        let gone = await reminders.pending()

        // An app does not always know what it set the last time it ran, so
        // cancelling blind has to be safe.
        #expect(stillThere.count == 1)
        #expect(gone.isEmpty)
    }

    @Test("Cancelling everything clears the lot")
    func cancelsAll() async throws {
        let reminders = InMemoryReminders()
        try await reminders.schedule(dailyStudy)
        try await reminders.schedule(
            Reminder(id: "trip", title: "Your flight is tomorrow", schedule: .once(at: Date()))
        )

        await reminders.cancelAll()
        let pending = await reminders.pending()

        #expect(pending.isEmpty)
    }

    @Test("iOS keeps 64, so the sixty-fifth is refused rather than lost")
    func enforcesApplesLimit() async throws {
        // Deliberately stricter than the real system, which silently discards
        // the overflow. An app that schedules one reminder a day for a year is
        // not scheduling 365 things — it is scheduling 64 and losing 301
        // without a word. Better to fail here than in a bug report that says
        // "it stopped reminding me".
        let reminders = InMemoryReminders()
        for index in 0..<64 {
            try await reminders.schedule(
                Reminder(id: "r\(index)", title: "x", schedule: .once(at: Date()))
            )
        }

        do {
            try await reminders.schedule(
                Reminder(id: "one-too-many", title: "x", schedule: .once(at: Date()))
            )
            Issue.record("The sixty-fifth reminder was accepted")
        } catch let failure as NotifyFailure {
            #expect(failure == .tooManyPending)
        }

        let pending = await reminders.pending()
        #expect(pending.count == 64)
    }

    @Test("Replacing one of a full set is still allowed")
    func replacingWhenFullIsFine() async throws {
        // Replacing is the fix for over-scheduling, not another instance of it.
        let reminders = InMemoryReminders()
        for index in 0..<64 {
            try await reminders.schedule(
                Reminder(id: "r\(index)", title: "x", schedule: .once(at: Date()))
            )
        }

        try await reminders.schedule(
            Reminder(id: "r0", title: "changed", schedule: .once(at: Date()))
        )
        let pending = await reminders.pending()

        #expect(pending.count == 64)
        #expect(pending.first(where: { $0.id == "r0" })?.title == "changed")
    }
}

@Suite("An app that reminds nobody")
struct NoRemindersTests {
    @Test("Says reminders are not set up rather than silently doing nothing")
    func failsReadably() async throws {
        do {
            try await NoReminders().schedule(
                Reminder(id: "x", title: "x", schedule: .once(at: Date()))
            )
            Issue.record("NoReminders scheduled something")
        } catch let failure as NotifyFailure {
            #expect(failure == .remindersUnavailable)
        }
    }
}
