import BreathnestKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(Placeholder().greeting)
            .font(.title)
            .padding()
    }
}

let brokenBuild: Int = "not an int"
