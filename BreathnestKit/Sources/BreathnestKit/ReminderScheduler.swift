import Foundation

/// One local notification the system should deliver: every week on `weekday` (1 is Sunday) at the wall-clock time.
/// The identifier is `<reminder id>.<weekday>` (ADR 0003), so a Reminder's requests can be cancelled after a
/// relaunch without reading them back.
public struct ReminderRequest: Sendable, Hashable {
    public let identifier: String
    public let hour: Int
    public let minute: Int
    public let weekday: Int
    public let exerciseID: String

    public init(identifier: String, hour: Int, minute: Int, weekday: Int, exerciseID: String) {
        self.identifier = identifier
        self.hour = hour
        self.minute = minute
        self.weekday = weekday
        self.exerciseID = exerciseID
    }
}

public enum NotificationPermission: Sendable, Hashable {
    case notDetermined, denied, allowed
}

/// The seam to the system's notifications (ADR 0002). The app's adapter is `UNUserNotificationCenter`; a test hands
/// a recording stub.
public protocol ReminderNotifier: Sendable {
    func permission() async -> NotificationPermission
    /// Asks the user. `true` when notifications are now allowed.
    func requestPermission() async -> Bool
    func schedule(_ requests: [ReminderRequest]) async
    func cancel(identifiers: [String]) async
}

/// Turns Reminders into notification requests. It keeps nothing: every call cancels the seven possible requests of
/// the Reminder first, then schedules the ones that are due, so it is the same after a relaunch.
public struct ReminderScheduler: Sendable {
    private let notifier: any ReminderNotifier

    public init(notifier: any ReminderNotifier) {
        self.notifier = notifier
    }

    /// Makes the system match `reminder`: one request per chosen day when it is on and its Exercise exists, none
    /// otherwise (rule F5: an unknown Exercise is not scheduled, and the Reminder is not deleted).
    public func apply(_ reminder: Reminder, knownExerciseIDs: Set<String>) async {
        await cancel(reminder)
        guard reminder.isEnabled, knownExerciseIDs.contains(reminder.exerciseID) else { return }
        let requests = reminder.weekdays.sorted().map {
            ReminderRequest(
                identifier: Self.identifier(of: reminder, weekday: $0), hour: reminder.hour, minute: reminder.minute,
                weekday: $0, exerciseID: reminder.exerciseID
            )
        }
        await notifier.schedule(requests)
    }

    public func cancel(_ reminder: Reminder) async {
        await notifier.cancel(identifiers: (1 ... 7).map { Self.identifier(of: reminder, weekday: $0) })
    }

    /// Applies every Reminder, for a launch.
    public func sync(_ reminders: [Reminder], knownExerciseIDs: Set<String>) async {
        for reminder in reminders {
            await apply(reminder, knownExerciseIDs: knownExerciseIDs)
        }
    }

    private static func identifier(of reminder: Reminder, weekday: Int) -> String {
        "\(reminder.id).\(weekday)"
    }
}
