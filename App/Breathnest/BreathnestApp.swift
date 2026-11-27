import SwiftUI

@main
struct BreathnestApp: App {
    @State private var navigation: AppNavigation
    private let dependencies: AppDependencies

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        _navigation = State(initialValue: AppNavigation(customExercises: dependencies.customExercises))
    }

    var body: some Scene {
        WindowGroup {
            RootView(navigation: navigation, dependencies: dependencies)
                .tint(Color(.ring))
                // Only dark is drawn. Light follows the decision of #53, which has `line`, `pop` and `scrim` no light
                // value yet.
                .preferredColorScheme(.dark)
        }
    }
}
