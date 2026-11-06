import BreathnestKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Breathe with \(Placeholder().name)")
            .font(.title)
            .padding()
            .accessibilityIdentifier("placeholder.greeting")
    }
}
