import BreathnestKit
import Observation

/// The Reminders the user saved, the notification permission and the scheduling that follows them (ADR 0002,
/// ADR 0003). Loads once, writes through `SavedDocument` on each change and keeps the system's notifications in
/// step with the saved list. It holds no text: the view words the states.
@MainActor
@Observable
final class RemindersViewModel {
    private(set) var reminders: [Reminder]
    /// What the system says about notifications. The denied state is explained on the Reminder screen.
    private(set) var permission: NotificationPermission = .notDetermined
    @ObservationIgnored private let document: SavedDocument<RemindersDocument>
    @ObservationIgnored private let notifier: any ReminderNotifier
    @ObservationIgnored private let scheduler: ReminderScheduler
    @ObservationIgnored private let knownExerciseIDs: @MainActor () -> Set<String>

    init(
        store: any DocumentStore, notifier: any ReminderNotifier, knownExerciseIDs: @escaping @MainActor () -> Set<String>
    ) {
        document = SavedDocument(store: store)
        self.notifier = notifier
        scheduler = ReminderScheduler(notifier: notifier)
        self.knownExerciseIDs = knownExerciseIDs
        reminders = document.value.items
    }

    /// For a launch and for coming back to the app: reads the permission and schedules every Reminder again, so the
    /// system matches the saved list (after a relaunch, a custom Exercise that is gone, or a change in iOS Settings).
    func start() async {
        permission = await notifier.permission()
        await scheduler.sync(reminders, knownExerciseIDs: knownExerciseIDs())
    }

    /// Asks for permission the first time. Returns `false`, with nothing saved or scheduled, when the permission is
    /// denied or the values are not a Reminder.
    @discardableResult
    func add(hour: Int, minute: Int, weekdays: Set<Int>, exerciseID: String) async -> Bool {
        guard let reminder = Reminder(
            hour: hour, minute: minute, weekdays: weekdays, exerciseID: exerciseID, isEnabled: true
        ) else { return false }
        guard await isAllowed(asking: true) else { return false }
        reminders.append(reminder)
        document.update(RemindersDocument(items: reminders))
        await scheduler.apply(reminder, knownExerciseIDs: knownExerciseIDs())
        return true
    }

    /// Turning one on needs the permission; with it denied the switch stays off and the denied state shows.
    func setEnabled(_ isEnabled: Bool, for id: Reminder.ID) async {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        if isEnabled, !(await isAllowed(asking: false)) { return }
        reminders[index].isEnabled = isEnabled
        document.update(RemindersDocument(items: reminders))
        await scheduler.apply(reminders[index], knownExerciseIDs: knownExerciseIDs())
    }

    private func isAllowed(asking: Bool) async -> Bool {
        permission = await notifier.permission()
        if permission == .notDetermined, asking {
            _ = await notifier.requestPermission()
            permission = await notifier.permission()
        }
        return permission == .allowed
    }
}
