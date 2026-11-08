import SwiftUI

@main
struct BreathnestApp: App {
    @State private var navigation = AppNavigation()

    var body: some Scene {
        WindowGroup {
            ExercisesView(navigation: navigation)
                .tint(Color(.ring))
        }
    }
}
