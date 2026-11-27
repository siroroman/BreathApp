import SwiftUI

@main
struct BreathnestApp: App {
    @State private var navigation: AppNavigation
    private let dependencies: AppDependencies

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        let navigation = AppNavigation(customExercises: dependencies.customExercises)
        _navigation = State(initialValue: navigation)
        // A tap on a Reminder opens the detail of its Exercise, the way a tap on a row does.
        dependencies.notificationRouter.route { navigation.openDetail(of: $0) }
    }

    var body: some Scene {
        WindowGroup {
            RootView(navigation: navigation, dependencies: dependencies)
                .tint(Color(.ring))
                // Only dark is drawn. Light follows the decision of #53, which has `line`, `pop` and `scrim` no light
                // value yet.
                .preferredColorScheme(.dark)
                .task { await dependencies.reminders.start() }
        }
    }
}
