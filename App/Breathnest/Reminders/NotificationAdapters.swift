import BreathnestKit
import Foundation
import Synchronization
import UserNotifications

/// `UNUserNotificationCenter` behind the Kit's seam: one repeating weekly calendar trigger per request. The Exercise
/// ID goes in `userInfo` so a tap can open its detail. The text is written here from the String Catalog and the name
/// of the Exercise, which `exerciseName` looks up.
struct UserNotificationReminderNotifier: ReminderNotifier {
    static let exerciseIDKey = "exerciseID"
    let exerciseName: @Sendable (String) async -> String

    private var center: UNUserNotificationCenter { .current() }

    func permission() async -> NotificationPermission {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .allowed
        }
    }

    func requestPermission() async -> Bool {
        await (try? center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ requests: [ReminderRequest]) async {
        for request in requests {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "reminders.notification.title")
            content.body = await exerciseName(request.exerciseID)
            content.sound = .default
            content.userInfo = [Self.exerciseIDKey: request.exerciseID]
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: request.hour, minute: request.minute, weekday: request.weekday),
                repeats: true
            )
            try? await center.add(UNNotificationRequest(
                identifier: request.identifier,
                content: content,
                trigger: trigger
            ))
        }
    }

    func cancel(identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}

/// Shows a Reminder that arrives while the app is open and sends a tap on one to `open` with its Exercise ID, so it
/// opens the same detail sheet a tap on a row does (ADR 0002).
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate, Sendable {
    private let destination = Mutex < (@MainActor @Sendable (String) -> Void)? > nil

    /// Where a tap goes. Set once the navigation exists; the app does that in its first moments.
    func route(to open: @escaping @MainActor @Sendable (String) -> Void) {
        destination.withLock { $0 = open }
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter, willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              let id = response.notification.request.content.userInfo[UserNotificationReminderNotifier.exerciseIDKey]
              as? String
        else { return }
        let open = destination.withLock { $0 }
        await open?(id)
    }
}
