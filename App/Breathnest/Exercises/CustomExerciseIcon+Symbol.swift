import BreathnestKit
import SwiftUI

extension CustomExerciseIcon {
    /// The SF Symbol that draws the icon. The design's stroke icons are not in the repo.
    var symbolName: String {
        switch self {
        case .ring: "circle"
        case .moon: "moon"
        case .sun: "sun.max"
        case .leaf: "leaf"
        case .wave: "water.waves"
        case .wind: "wind"
        }
    }

    var label: LocalizedStringKey {
        LocalizedStringKey("icon.\(rawValue)")
    }
}

extension NewExerciseViewModel.Field {
    var phaseKind: PhaseKind {
        switch self {
        case .inhale: .inhale
        case .holdAfterInhale, .holdAfterExhale: .hold
        case .exhale: .exhale
        }
    }

    /// The suffix of the accessibility catalog keys and identifiers.
    var key: String {
        switch self {
        case .inhale: "inhale"
        case .holdAfterInhale: "holdAfterInhale"
        case .exhale: "exhale"
        case .holdAfterExhale: "holdAfterExhale"
        }
    }
}
