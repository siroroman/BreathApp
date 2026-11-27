import BreathnestKit
import UIKit
import UserNotifications

/// Yields the time once per screen frame (ADR 0002). The display link lives on the main run loop and stops when
/// the consumer's task is cancelled.
struct DisplayLinkTicker: Ticker {
    func ticks() -> AsyncStream<ContinuousClock.Instant> {
        AsyncStream { continuation in
            let driver = Task { @MainActor in
                let driver = DisplayLinkDriver(continuation: continuation)
                driver.start()
                return driver
            }
            continuation.onTermination = { _ in
                Task { @MainActor in await driver.value.stop() }
            }
        }
    }
}

@MainActor
private final class DisplayLinkDriver: NSObject {
    private let continuation: AsyncStream<ContinuousClock.Instant>.Continuation
    private var link: CADisplayLink?

    init(continuation: AsyncStream<ContinuousClock.Instant>.Continuation) {
        self.continuation = continuation
    }

    func start() {
        let link = CADisplayLink(target: self, selector: #selector(fire))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func fire() {
        continuation.yield(.now)
    }
}

/// Keeps the screen on through the idle timer.
struct IdleTimerScreenAwake: ScreenAwake {
    func setAwake(_ isAwake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = isAwake
    }
}

/// The real seams, built once by `BreathnestApp` and handed to the screens that create ViewModels (ADR 0002).
struct AppDependencies {
    let ticker: any Ticker
    let screenAwake: any ScreenAwake
    let haptics: any HapticPlayer
    let sounds: any SoundPlayer
    /// Apple Health: the Settings row asks for access, a completed Session writes Mindful Minutes.
    let health: any HealthAccess
    /// Scales the time fed to the Session engine. 1 in a release build; a DEBUG launch argument can raise it.
    let sessionSpeed: Double
    /// Sound, the chosen sound and Haptics: saved, and shared by every screen that shows them.
    let settings: AppSettingsStore
    /// The last Session that started, which the Quick Start card offers again.
    let lastSession: LastSessionStore
    let customExercises: CustomExercisesViewModel
    /// The Reminders, their notifications and the permission.
    let reminders: RemindersViewModel
    /// Shows a Reminder that arrives while the app is open and routes a tap on one. The center holds it weakly, so
    /// the app keeps it.
    let notificationRouter: NotificationRouter
    /// One entry per completed Session (#58).
    let log: LogStore

    @MainActor
    static func live(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        let customExercises = CustomExercisesViewModel(store: CustomExerciseStore(backing: FileDocumentStore
                .customExercises))
        let notifier = UserNotificationReminderNotifier { id in
            await MainActor.run {
                Exercise.builtIn.first { $0.id == id }.map { ExerciseText.name(of: $0) }
                    ?? customExercises.record(withID: id)?.name ?? id
            }
        }
        let router = NotificationRouter()
        UNUserNotificationCenter.current().delegate = router
        return AppDependencies(
            ticker: DisplayLinkTicker(), screenAwake: IdleTimerScreenAwake(), haptics: CoreHapticsPlayer(),
            sounds: AVSoundPlayer(), health: HealthKitAccess(),
            sessionSpeed: speed(in: arguments),
            settings: AppSettingsStore(store: store(key: "breathnest.settings", arguments: arguments)),
            lastSession: LastSessionStore(store: store(key: "breathnest.lastSession", arguments: arguments)),
            customExercises: customExercises,
            reminders: RemindersViewModel(
                store: remindersStore(arguments: arguments), notifier: notifier,
                knownExerciseIDs: { Set(Exercise.builtIn.map(\.id) + customExercises.records.map(\.id)) }
            ),
            notificationRouter: router,
            log: LogStore(store: logStore(arguments: arguments))
        )
    }

    /// A new Session for `exercise`, with the seams of the app and the saved settings, which it reads live.
    @MainActor
    func makeSession(exercise: Exercise, requested: Duration) -> SessionViewModel {
        SessionViewModel(
            exercise: exercise, requested: requested, screenAwake: screenAwake, haptics: haptics,
            sounds: sounds, settings: settings, health: HealthRecording(access: health, now: { .now }),
            speed: sessionSpeed, startedAt: .now,
            onCompleted: { [log, customExercises] length in
                log.recordCompleted(
                    exercise: exercise, length: length, customName: customExercises.record(withID: exercise.id)?.name
                )
            }
        )
    }

    /// The file store of the Log. `-ResetSavedData` deletes the file first, like the `UserDefaults` documents.
    private static func logStore(arguments: [String]) -> FileDocumentStore {
        let store = FileDocumentStore.log
        #if DEBUG
            if arguments.contains("-ResetSavedData") { try? FileManager.default.removeItem(at: store.url) }
        #endif
        return store
    }

    /// The `UserDefaults` store of one document. The DEBUG launch argument `-ResetSavedData` clears it first, so
    /// a UI test starts from the defaults.
    private static func store(key: String, arguments: [String]) -> UserDefaultsDocumentStore {
        #if DEBUG
            if arguments.contains("-ResetSavedData") {
                UserDefaults.standard.removeObject(forKey: key)
                UserDefaults.standard.removeObject(forKey: key + ".unreadable")
            }
        #endif
        return UserDefaultsDocumentStore(defaults: .standard, key: key)
    }

    private static func remindersStore(arguments: [String]) -> FileDocumentStore {
        let store = FileDocumentStore.reminders
        #if DEBUG
            if arguments.contains("-ResetSavedData") { try? FileManager.default.removeItem(at: store.url) }
        #endif
        return store
    }

    private static func speed(in arguments: [String]) -> Double {
        #if DEBUG
            if let index = arguments.firstIndex(of: "-SessionSpeed"), arguments.indices.contains(index + 1),
               let value = Double(arguments[index + 1]), value > 0
            {
                return value
            }
        #endif
        return 1
    }
}
