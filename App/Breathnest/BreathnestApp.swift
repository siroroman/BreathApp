import SwiftUI

@main
struct BreathnestApp: App {
    @State private var navigation = AppNavigation()

    var body: some Scene {
        WindowGroup {
            ExercisesView(navigation: navigation)
                .tint(Color(.ring))
                // Only dark is drawn. Light follows the decision of #53, which has `line`, `pop` and `scrim` no light
                // value yet.
                .preferredColorScheme(.dark)
        }
    }
}
