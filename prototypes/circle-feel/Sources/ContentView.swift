// PROTOTYPE (issue #13). Plain shapes only: no colours, layout or style decisions live here.
import SwiftUI

struct ContentView: View {
    @State private var runner = Runner()
    @State private var motionIdx = 0
    @State private var hapticIdx = 0
    @State private var showTweak = false
    @State private var showHUD = true
    @Environment(\.scenePhase) private var scenePhase

    private var motionEdited: Bool { runner.motion != MotionPreset.all[motionIdx].config }
    private var hapticEdited: Bool { runner.haptic != HapticPreset.all[hapticIdx].config }

    var body: some View {
        VStack(spacing: 12) {
            header
            BreathCircle(frame: runner.frame, motion: runner.motion)
                .padding(.horizontal, 16)
            if showHUD { hud }
            controls
        }
        .padding(.vertical, 8)
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showTweak) { TweakSheet(runner: runner, summary: summary) }
        .onChange(of: scenePhase) { _, phase in if phase != .active { runner.pause() } }
    }

    private var header: some View {
        HStack {
            Menu {
                ForEach(Patterns.all) { p in Button(p.name) { runner.pattern = p } }
            } label: {
                Label(runner.pattern.name, systemImage: "list.bullet").lineLimit(1)
            }
            Spacer()
            Button("Tweak") { showTweak = true }
        }
        .padding(.horizontal, 16)
    }

    private var hud: some View {
        VStack(spacing: 2) {
            Text("\(runner.frame.kind.label)  \(runner.frame.remaining, specifier: "%.1f") s")
                .font(.system(.title3, design: .monospaced))
            Text("cycle \(runner.frame.cycle + 1) · scale \(scale, specifier: "%.2f")")
                .font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
            if !runner.haptics.supported {
                Text("No haptic engine here (Simulator or iPad): visuals only")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private var scale: Double {
        runner.motion.minScale + (runner.motion.maxScale - runner.motion.minScale) * runner.frame.level
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Switcher(title: "Motion", name: MotionPreset.all[motionIdx].name, edited: motionEdited,
                     count: MotionPreset.all.count, index: $motionIdx) {
                runner.motion = MotionPreset.all[motionIdx].config
            }
            Switcher(title: "Haptics", name: HapticPreset.all[hapticIdx].name, edited: hapticEdited,
                     count: HapticPreset.all.count, index: $hapticIdx) {
                runner.haptic = HapticPreset.all[hapticIdx].config
            }
            HStack {
                Toggle("Haptics", isOn: Binding(get: { runner.hapticsEnabled },
                                                set: { runner.setHapticsEnabled($0) }))
                    .fixedSize()
                Toggle("HUD", isOn: $showHUD).fixedSize()
                Spacer()
                Button(runner.running ? "Pause" : "Start") { runner.toggle() }
                    .buttonStyle(.borderedProminent).controlSize(.large)
            }
            .padding(.horizontal, 16)
        }
    }

    private var summary: String {
        let m = runner.motion, h = runner.haptic
        return """
        #13 circle feel — pattern: \(runner.pattern.name)
        motion preset \(MotionPreset.all[motionIdx].name)\(motionEdited ? " (edited)" : ""): \
        inhale \(m.inhaleCurve.rawValue), exhale \(m.exhaleCurve.rawValue), \
        scale \(String(format: "%.2f", m.minScale))–\(String(format: "%.2f", m.maxScale)), \
        hold \(m.holdStyle.rawValue), rest \(m.restStyle.rawValue), guide rings \(m.guideRings), \
        pulse \(String(format: "%.3f", m.pulseAmount))
        haptic preset \(HapticPreset.all[hapticIdx].name)\(hapticEdited ? " (edited)" : ""): \
        inhale \(h.inhale.rawValue), hold \(h.hold.rawValue), exhale \(h.exhale.rawValue), \
        rest \(h.rest.rawValue), strength \(String(format: "%.2f", h.strength)), \
        pulseEvery \(String(format: "%.2f", h.pulseEvery)) s, \
        rampFloor \(String(format: "%.2f", h.rampFloor)) exhaleFloor \(String(format: "%.2f", h.exhaleFloor)), tick \(String(format: "%.2f", h.tickStrength)) boost \(h.tickBoost), \
        sharpness in/out \(String(format: "%.2f", h.inhaleSharpness))/\(String(format: "%.2f", h.exhaleSharpness)), enabled \(runner.hapticsEnabled)
        """
    }
}

/// Floating-bar style variant switcher: ◀ A (Name) ▶
struct Switcher: View {
    let title: String
    let name: String
    let edited: Bool
    let count: Int
    @Binding var index: Int
    let onChange: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.caption).foregroundStyle(.secondary).frame(width: 56, alignment: .leading)
            Button { step(-1) } label: { Image(systemName: "chevron.left") }
            Text("\(letter) \(name)\(edited ? " *" : "")")
                .font(.headline).frame(maxWidth: .infinity)
            Button { step(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Capsule().fill(Color.white.opacity(0.14)))
        .padding(.horizontal, 16)
    }

    private var letter: String { String(UnicodeScalar(UInt8(65 + index))) }

    private func step(_ d: Int) {
        index = (index + d + count) % count
        onChange()
    }
}

struct BreathCircle: View {
    let frame: Frame
    let motion: MotionConfig

    var body: some View {
        GeometryReader { geo in
            let full = min(geo.size.width, geo.size.height) * 0.86
            let level = frame.level
            let base = motion.minScale + (motion.maxScale - motion.minScale) * level
            let style = style(for: frame.kind)
            let wobble = style == .pulse ? 1 + motion.pulseAmount * sin(2 * .pi * frame.elapsedInSpan / 2) : 1
            let d = full * base * wobble
            ZStack {
                if motion.guideRings {
                    Circle().stroke(.white.opacity(0.22), lineWidth: 1.5).frame(width: full * motion.maxScale)
                    Circle().stroke(.white.opacity(0.22), style: StrokeStyle(lineWidth: 1.5, dash: [4, 6]))
                        .frame(width: full * motion.minScale)
                }
                Circle().fill(.white.opacity(0.9)).frame(width: d)
                if style == .ring {
                    Circle().trim(from: 0, to: frame.u)
                        .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: d + 30)
                }
                if style == .orbit {
                    ZStack(alignment: .top) {
                        Color.clear
                        Circle().fill(.white).frame(width: 14)
                    }
                    .frame(width: d + 30, height: d + 30)
                    .rotationEffect(.degrees(frame.u * 360))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func style(for kind: PhaseKind) -> StillStyle {
        switch kind {
        case .hold: motion.holdStyle
        case .rest: motion.restStyle
        default: .still
        }
    }
}

struct TweakSheet: View {
    @Bindable var runner: Runner
    let summary: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Motion: curves") {
                    Picker("Inhale", selection: $runner.motion.inhaleCurve) { curves }
                    Picker("Exhale", selection: $runner.motion.exhaleCurve) { curves }
                }
                Section("Motion: scale range") {
                    slider("Min (empty)", $runner.motion.minScale, 0.1...0.9)
                    slider("Max (full)", $runner.motion.maxScale, 0.5...1.0)
                }
                Section("Motion: still Phases") {
                    Picker("Hold", selection: $runner.motion.holdStyle) { stills }
                    Picker("Rest", selection: $runner.motion.restStyle) { stills }
                    slider("Pulse size", $runner.motion.pulseAmount, 0...0.1)
                    Toggle("Guide rings", isOn: $runner.motion.guideRings)
                }
                Section("Haptics per Phase kind") {
                    Picker("Inhale", selection: $runner.haptic.inhale) { styles }
                    Picker("Hold", selection: $runner.haptic.hold) { styles }
                    Picker("Exhale", selection: $runner.haptic.exhale) { styles }
                    Picker("Rest", selection: $runner.haptic.rest) { styles }
                    slider("Strength", $runner.haptic.strength, 0.1...1.0)
                    slider("Pulse every (s)", $runner.haptic.pulseEvery, 0.2...1.5)
                    slider("Tick strength", $runner.haptic.tickStrength, 0.2...1.0)
                    Toggle("Tick boost (buzz under tick)", isOn: $runner.haptic.tickBoost)
                    slider("Exhale floor", $runner.haptic.exhaleFloor, 0...0.9)
                    slider("Ramp floor", $runner.haptic.rampFloor, 0...0.8)
                    slider("Inhale sharp", $runner.haptic.inhaleSharpness, 0...1)
                    slider("Exhale sharp", $runner.haptic.exhaleSharpness, 0...1)
                }
                Section {
                    Text(summary).font(.system(.caption2, design: .monospaced))
                    Button("Copy settings") { UIPasteboard.general.string = summary }
                }
            }
            .navigationTitle("Tweak")
            .toolbar { Button("Done") { dismiss() } }
        }
        .presentationDetents([.medium, .large])
    }

    private var curves: some View { ForEach(Curve.allCases) { Text($0.rawValue).tag($0) } }
    private var stills: some View { ForEach(StillStyle.allCases) { Text($0.rawValue).tag($0) } }
    private var styles: some View { ForEach(HapticStyle.allCases) { Text($0.rawValue).tag($0) } }

    private func slider(_ label: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range)
            Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                .font(.system(.footnote, design: .monospaced)).frame(width: 40)
        }
    }
}
