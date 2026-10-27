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

enum MotionShape: String, CaseIterable, Identifiable {
    case circle, torus, solid, sphere
    var id: String { rawValue }
}

struct MotionConfig: Equatable {
    var shape: MotionShape = .circle
    var tilt = 0.0        // torus: tilt away from face-on, radians
    var colors = false    // torus: coloured dots
    var spinSpeed = 0.35  // torus, solid, sphere: rotation in rad/s, 0 = no rotation
    var holdReverse = false  // hold progress counts down from 100% to 0 instead of up
    var cycleRing = false    // white progress ring around the shape: one Cycle, arcs sized by Phase seconds
    var inhaleCurve: Curve
    var exhaleCurve: Curve
    var minScale: Double
    var maxScale: Double
    var holdStyle: StillStyle
    var restStyle: StillStyle
    var pulseAmount: Double = 0.03
    var guideRings: Bool

    func holdProgress(_ u: Double) -> Double { holdReverse ? 1 - u : u }
}

struct MotionPreset {
    let key: String
    let name: String
    let config: MotionConfig

    private static let sphere = MotionConfig(
        shape: .sphere, tilt: 0.3, colors: true, spinSpeed: 0.12, cycleRing: true,
        inhaleCurve: .sine, exhaleCurve: .sine, minScale: 0.50, maxScale: 0.85,
        holdStyle: .ring, restStyle: .still, guideRings: false)
    private static let torusStill = MotionConfig(
        shape: .torus, tilt: 0.4, colors: true, spinSpeed: 0, cycleRing: true,
        inhaleCurve: .sine, exhaleCurve: .sine, minScale: 0.64, maxScale: 0.80,
        holdStyle: .still, restStyle: .still, guideRings: false)

    /// F and G keep their letters from the earlier list of variants; F2 and G2 are the same without the ring, G3 is G seen straight on.
    static let all: [MotionPreset] = [
        MotionPreset(key: "F", name: "Sphere", config: sphere),
        MotionPreset(key: "G", name: "Torus still", config: torusStill),
        MotionPreset(key: "F2", name: "Sphere, no ring", config: {
            var c = sphere; c.cycleRing = false; return c }()),
        MotionPreset(key: "G2", name: "Torus still, no ring", config: {
            var c = torusStill; c.cycleRing = false; c.holdStyle = .ring; return c }()),
        MotionPreset(key: "G3", name: "Torus still, face-on", config: {
            var c = torusStill; c.tilt = 0; return c }()),
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
    var exhaleFloor: Double = 0.12     // same as rampFloor, for exhale only
    var rampFloor: Double = 0.12       // intensity at an empty circle for .ramp (0...1)
    var inhaleSharpness: Double = 0.2  // 0 soft and rumbly ... 1 crisp
    var exhaleSharpness: Double = 0.2
    var tickStrength: Double = 0.7     // .seconds ticks, as a share of strength
    var tickBoost = false              // stack a short full-power buzz under each tick

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
            inhale: .ramp, hold: .seconds, exhale: .ramp, rest: .seconds,
            strength: 1.0, exhaleFloor: 0.65, rampFloor: 0.35, inhaleSharpness: 0.7, exhaleSharpness: 0.25,
            tickStrength: 1.0, tickBoost: false)),
        HapticPreset(name: "Ticks", config: HapticConfig(
            inhale: .tap, hold: .seconds, exhale: .tap, rest: .off)),
        HapticPreset(name: "Pulse", config: HapticConfig(
            inhale: .pulses, hold: .hum, exhale: .pulses, rest: .off, strength: 0.7)),
    ]
}
