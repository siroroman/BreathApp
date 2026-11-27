import BreathnestKit
import BreathnestKitTesting
import Foundation
import Synchronization
import Testing

@testable import Breathnest

private final class StubNotifier: ReminderNotifier {
    private struct State {
        var permission: NotificationPermission
        var grants: Bool
        var requestCount = 0
        var scheduled: [ReminderRequest] = []
        var cancelled: [String] = []
    }

    private let state: Mutex<State>

    init(permission: NotificationPermission = .allowed, grants: Bool = true) {
        state = Mutex(State(permission: permission, grants: grants))
    }

    var requestCount: Int { state.withLock { $0.requestCount } }
    var scheduled: [ReminderRequest] { state.withLock { $0.scheduled } }
    var cancelled: [String] { state.withLock { $0.cancelled } }
    func set(permission: NotificationPermission) { state.withLock { $0.permission = permission } }

    func permission() async -> NotificationPermission { state.withLock { $0.permission } }
    func requestPermission() async -> Bool {
        state.withLock { state in
            state.requestCount += 1
            if state.permission == .notDetermined { state.permission = state.grants ? .allowed : .denied }
            return state.permission == .allowed
        }
    }

    func schedule(_ requests: [ReminderRequest]) async { state.withLock { $0.scheduled += requests } }
    func cancel(identifiers: [String]) async { state.withLock { $0.cancelled += identifiers } }
}

@MainActor
@Suite struct RemindersViewModelTests {
    private let bytes = InMemoryDocumentStore()

    private func model(_ notifier: StubNotifier) -> RemindersViewModel {
        RemindersViewModel(
            store: bytes, notifier: notifier, knownExerciseIDs: { Set(Exercise.builtIn.map(\.id)) }
        )
    }

    @Test func addingSavesTheReminderAndSchedulesOneRequestPerDay() async {
        let notifier = StubNotifier()
        let model = model(notifier)
        let added = await model.add(hour: 7, minute: 30, weekdays: [2, 3], exerciseID: "box")
        #expect(added)
        #expect(model.reminders.count == 1)
        #expect(notifier.scheduled.map(\.weekday) == [2, 3])
        #expect(notifier.scheduled.allSatisfy { $0.hour == 7 && $0.minute == 30 && $0.exerciseID == "box" })
    }

    @Test func theFirstAddAsksForPermissionAndAGrantSchedules() async {
        let notifier = StubNotifier(permission: .notDetermined, grants: true)
        let model = model(notifier)
        let added = await model.add(hour: 8, minute: 0, weekdays: [1], exerciseID: "box")
        #expect(added)
        #expect(notifier.requestCount == 1)
        #expect(model.permission == .allowed)
    }

    @Test func aDeniedPermissionSavesAndSchedulesNothingAndIsShown() async {
        let notifier = StubNotifier(permission: .notDetermined, grants: false)
        let model = model(notifier)
        let added = await model.add(hour: 8, minute: 0, weekdays: [1], exerciseID: "box")
        #expect(!added)
        #expect(model.permission == .denied)
        #expect(model.reminders.isEmpty)
        #expect(notifier.scheduled.isEmpty)
    }

    @Test func anAlreadyDeniedPermissionIsNotAskedAgain() async {
        let notifier = StubNotifier(permission: .denied)
        let model = model(notifier)
        _ = await model.add(hour: 8, minute: 0, weekdays: [1], exerciseID: "box")
        #expect(notifier.requestCount == 0)
        #expect(model.permission == .denied)
    }

    @Test func anInvalidReminderIsNotAdded() async {
        let notifier = StubNotifier()
        let model = model(notifier)
        let added = await model.add(hour: 8, minute: 0, weekdays: [], exerciseID: "box")
        #expect(!added)
        #expect(model.reminders.isEmpty)
    }

    @Test func theSwitchCancelsAndSchedulesAgain() async throws {
        let notifier = StubNotifier()
        let model = model(notifier)
        _ = await model.add(hour: 7, minute: 30, weekdays: [2], exerciseID: "box")
        let id = try #require(model.reminders.first?.id)
        let before = notifier.scheduled.count
        await model.setEnabled(false, for: id)
        #expect(model.reminders.first?.isEnabled == false)
        #expect(notifier.scheduled.count == before)
        #expect(notifier.cancelled.contains("\(id).2"))
        await model.setEnabled(true, for: id)
        #expect(model.reminders.first?.isEnabled == true)
        #expect(notifier.scheduled.count == before + 1)
    }

    @Test func turningOnWhileDeniedChangesNothingAndShowsTheDeniedState() async throws {
        let notifier = StubNotifier()
        let model = model(notifier)
        _ = await model.add(hour: 7, minute: 30, weekdays: [2], exerciseID: "box")
        let id = try #require(model.reminders.first?.id)
        await model.setEnabled(false, for: id)
        notifier.set(permission: .denied)
        await model.setEnabled(true, for: id)
        #expect(model.reminders.first?.isEnabled == false)
        #expect(model.permission == .denied)
    }

    @Test func remindersSurviveARelaunchAndAreScheduledAgain() async {
        let first = StubNotifier()
        _ = await model(first).add(hour: 7, minute: 30, weekdays: [2, 4], exerciseID: "box")
        let second = StubNotifier()
        let relaunched = model(second)
        #expect(relaunched.reminders.count == 1)
        await relaunched.start()
        #expect(second.scheduled.map(\.weekday) == [2, 4])
    }

    @Test func startReadsThePermissionSoACoveredBannerCanClear() async {
        let notifier = StubNotifier(permission: .denied)
        let model = model(notifier)
        await model.start()
        #expect(model.permission == .denied)
        notifier.set(permission: .allowed)
        await model.start()
        #expect(model.permission == .allowed)
    }
}
