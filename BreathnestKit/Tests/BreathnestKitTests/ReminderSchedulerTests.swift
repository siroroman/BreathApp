import BreathnestKitTesting
import Foundation
import Synchronization
import Testing

@testable import BreathnestKit

/// Records what the scheduler asks of the system, in order.
private final class RecordingNotifier: ReminderNotifier {
    enum Call: Equatable {
        case schedule([ReminderRequest])
        case cancel([String])
    }

    private let log = Mutex<[Call]>([])
    var calls: [Call] { log.withLock { $0 } }
    var scheduled: [ReminderRequest] {
        var all: [ReminderRequest] = []
        for case let .schedule(requests) in calls { all += requests }
        return all
    }

    func permission() async -> NotificationPermission { .allowed }
    func requestPermission() async -> Bool { true }
    func schedule(_ requests: [ReminderRequest]) async { log.withLock { $0.append(.schedule(requests)) } }
    func cancel(identifiers: [String]) async { log.withLock { $0.append(.cancel(identifiers)) } }
}

@Suite struct ReminderSchedulerTests {
    private let known: Set<String> = ["box", "four-seven-eight"]

    private func reminder(
        _ days: Set<Int> = [2, 4], exercise: String = "box", enabled: Bool = true
    ) throws -> Reminder {
        try #require(Reminder(
            id: "r1", hour: 7, minute: 30, weekdays: days, exerciseID: exercise, isEnabled: enabled
        ))
    }

    @Test func anEnabledReminderSchedulesOneRequestPerChosenDay() async throws {
        let notifier = RecordingNotifier()
        try await ReminderScheduler(notifier: notifier).apply(reminder([2, 4]), knownExerciseIDs: known)
        let expected = [
            ReminderRequest(identifier: "r1.2", hour: 7, minute: 30, weekday: 2, exerciseID: "box"),
            ReminderRequest(identifier: "r1.4", hour: 7, minute: 30, weekday: 4, exerciseID: "box"),
        ]
        #expect(notifier.scheduled == expected)
    }

    @Test func applyingFirstClearsEveryDayOfTheReminder() async throws {
        let notifier = RecordingNotifier()
        try await ReminderScheduler(notifier: notifier).apply(reminder([2]), knownExerciseIDs: known)
        #expect(notifier.calls.first == .cancel((1 ... 7).map { "r1.\($0)" }))
    }

    @Test func aSwitchedOffReminderOnlyCancels() async throws {
        let notifier = RecordingNotifier()
        try await ReminderScheduler(notifier: notifier).apply(reminder(enabled: false), knownExerciseIDs: known)
        #expect(notifier.scheduled.isEmpty)
        #expect(notifier.calls.count == 1)
    }

    @Test func aReminderWithAnUnknownExerciseIsNotScheduled() async throws {
        let notifier = RecordingNotifier()
        try await ReminderScheduler(notifier: notifier).apply(reminder(exercise: "gone"), knownExerciseIDs: known)
        #expect(notifier.scheduled.isEmpty)
    }

    @Test func cancelRemovesAllSevenIdentifiersAndSchedulesNothing() async throws {
        let notifier = RecordingNotifier()
        try await ReminderScheduler(notifier: notifier).cancel(reminder())
        #expect(notifier.calls == [.cancel((1 ... 7).map { "r1.\($0)" })])
    }

    @Test func reschedulingAfterAChangeLeavesOnlyTheNewDays() async throws {
        let notifier = RecordingNotifier()
        let scheduler = ReminderScheduler(notifier: notifier)
        try await scheduler.apply(reminder([2, 4]), knownExerciseIDs: known)
        try await scheduler.apply(reminder([6]), knownExerciseIDs: known)
        let last = try #require(notifier.calls.last)
        #expect(last == .schedule([
            ReminderRequest(identifier: "r1.6", hour: 7, minute: 30, weekday: 6, exerciseID: "box"),
        ]))
    }

    @Test func syncAppliesEveryReminder() async throws {
        let notifier = RecordingNotifier()
        let other = try #require(Reminder(
            id: "r2", hour: 13, minute: 0, weekdays: [3], exerciseID: "four-seven-eight", isEnabled: true
        ))
        try await ReminderScheduler(notifier: notifier).sync([reminder([2]), other], knownExerciseIDs: known)
        #expect(notifier.scheduled.map(\.identifier) == ["r1.2", "r2.3"])
    }
}
