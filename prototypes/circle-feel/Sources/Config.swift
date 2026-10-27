// PROTOTYPE (issue #13). Motion and haptic knobs, plus three presets of each.
import Foundation

enum Curve: String, CaseIterable, Identifiable {
    case linear, sine, easeOut, easeIn, smoother
    var id: String { rawValue }

    func apply(_ u: Double) -> Double {
        switch self {
        case .linear: u
        case .sine: (1 - cos(.pi * u)) / 2
        case .easeOut: 1 - (1 - u) * (1 - u)
        case .easeIn: u * u
        case .smoother: u * u * u * (u * (u * 6 - 15) + 10)
        }
    }
}

/// How a Phase that does not move (hold, rest) shows that time is passing.
enum StillStyle: String, CaseIterable, Identifiable {
    case still, pulse, ring, orbit
    var id: String { rawValue }
}

struct MotionConfig: Equatable {
    var inhaleCurve: Curve
    var exhaleCurve: Curve
    var minScale: Double
    var maxScale: Double
    var holdStyle: StillStyle
    var restStyle: StillStyle
    var pulseAmount: Double = 0.03
    var guideRings: Bool
}

struct MotionPreset {
    let name: String
    let config: MotionConfig

    static let all: [MotionPreset] = [
        MotionPreset(name: "Organic", config: MotionConfig(
            inhaleCurve: .sine, exhaleCurve: .sine, minScale: 0.45, maxScale: 1.0,
            holdStyle: .ring, restStyle: .still, guideRings: true)),
        MotionPreset(name: "Linear", config: MotionConfig(
            inhaleCurve: .linear, exhaleCurve: .linear, minScale: 0.30, maxScale: 1.0,
            holdStyle: .pulse, restStyle: .pulse, guideRings: false)),
        MotionPreset(name: "Wave", config: MotionConfig(
            inhaleCurve: .easeOut, exhaleCurve: .easeIn, minScale: 0.60, maxScale: 1.0,
            holdStyle: .orbit, restStyle: .still, guideRings: true)),
    ]
}

enum HapticStyle: String, CaseIterable, Identifiable {
    case off      // nothing
    case tap      // one transient at the Phase start
    case seconds  // one light transient every second
    case ramp     // continuous, intensity follows the circle
    case pulses   // transients every pulseEvery seconds, intensity follows the circle
    case hum      // continuous, steady and low
    var id: String { rawValue }
}

struct HapticConfig: Equatable {
    var inhale: HapticStyle
    var hold: HapticStyle
    var exhale: HapticStyle
    var rest: HapticStyle
    var strength: Double = 0.8
    var pulseEvery: Double = 0.6

    func style(for kind: PhaseKind) -> HapticStyle {
        switch kind {
        case .inhale: inhale
        case .hold: hold
        case .exhale: exhale
        case .rest: rest
        }
    }
}

struct HapticPreset {
    let name: String
    let config: HapticConfig

    static let all: [HapticPreset] = [
        HapticPreset(name: "Follow", config: HapticConfig(
            inhale: .ramp, hold: .tap, exhale: .ramp, rest: .off)),
        HapticPreset(name: "Ticks", config: HapticConfig(
            inhale: .tap, hold: .seconds, exhale: .tap, rest: .off)),
        HapticPreset(name: "Pulse", config: HapticConfig(
            inhale: .pulses, hold: .hum, exhale: .pulses, rest: .off, strength: 0.7)),
    ]
}
