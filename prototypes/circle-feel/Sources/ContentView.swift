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
            Spacer(minLength: 0)
            BreathCircle(frame: runner.frame, motion: runner.motion, pattern: runner.pattern)
                .aspectRatio(runner.motion.cycleRing ? 1 : nil, contentMode: .fit)
                .padding(.horizontal, 16)
            if showHUD || runner.motion.cycleRing {
                Text(runner.frame.kind.label)
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .padding(.top, runner.motion.cycleRing ? -14 : 0)
            }
            Spacer(minLength: 0)
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
        motion preset \(MotionPreset.all[motionIdx].name)\(motionEdited ? " (edited)" : ""): shape \(m.shape.rawValue) tilt \(String(format: "%.2f", m.tilt)) colours \(m.colors) spin \(String(format: "%.2f", m.spinSpeed)) holdReverse \(m.holdReverse) cycleRing \(m.cycleRing), \
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
    let pattern: Pattern

    var body: some View {
        ZStack {
            shapeView
            if motion.cycleRing { cycleRing }
        }
    }

    /// One Cycle as a circle, clockwise from the top. A Phase takes the share of the circle that its seconds
    /// take of the Cycle (4:4:4:4 gives quarters). Inhale and exhale fill smoothly; hold and rest are
    /// split into one segment per second that light up one by one.
    private var cycleRing: some View {
        Canvas { ctx, size in
            let radius = min(size.width, size.height) * 0.86 / 2 * 0.99
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let gap = 0.012
            // same hue formula as the torus and sphere dots, so the ring wears the shape's colours
            func color(_ f: Double) -> Color {
                guard motion.colors else { return .white }
                let hue = 0.62 - 0.17 * frame.level + 0.10 * sin(2 * .pi * f + frame.time * motion.spinSpeed * 0.86)
                return Color(hue: hue, saturation: 0.55, brightness: 1)
            }
            func arc(_ f0: Double, _ f1: Double, _ opacity: Double) {
                guard f1 > f0 else { return }
                var p = Path()
                p.addArc(center: c, radius: radius, startAngle: .degrees(-90 + f0 * 360),
                         endAngle: .degrees(-90 + f1 * 360), clockwise: false)
                ctx.stroke(p, with: .color(color((f0 + f1) / 2).opacity(opacity)), style: StrokeStyle(lineWidth: 5, lineCap: .butt))
            }
            for s in pattern.spans {
                let f0 = s.t0 / pattern.cycleSeconds, f1 = (s.t0 + s.seconds) / pattern.cycleSeconds
                if s.kind == .hold || s.kind == .rest {
                    let segs = max(1, Int(s.seconds.rounded(.up)))
                    for k in 0..<segs {
                        let a0 = f0 + (f1 - f0) * Double(k) / Double(segs)
                        let a1 = f0 + (f1 - f0) * Double(k + 1) / Double(segs)
                        let lit = frame.cycleTime >= s.t0 + s.seconds * Double(k) / Double(segs)
                        arc(a0 + gap / 4, a1 - gap / 4, lit ? 1 : 0.2)
                    }
                } else {
                    arc(f0 + gap / 2, f1 - gap / 2, 0.2)
                    let p = min(max((frame.cycleTime - s.t0) / s.seconds, 0), 1)
                    arc(f0 + gap / 2, f0 + gap / 2 + (f1 - f0 - gap) * p, 1)
                }
            }
        }
    }

    @ViewBuilder
    private var shapeView: some View {
        switch motion.shape {
        case .torus: torus
        case .solid: solid
        case .sphere: sphere
        case .circle: circle
        }
    }

    /// Dot cloud torus seen face-on: scale and dot size follow the breath, the tube thickens on inhale, it spins slowly.
    private var torus: some View {
        Canvas { ctx, size in
            let full = min(size.width, size.height) * 0.86
            let level = frame.level
            let base = motion.minScale + (motion.maxScale - motion.minScale) * level
            let style = style(for: frame.kind)
            let wobble = style == .pulse ? 1 + motion.pulseAmount * sin(2 * .pi * frame.elapsedInSpan / 2) : 1
            let bigR = 1.0, r = 0.42 + 0.22 * level
            let spin = frame.time * motion.spinSpeed
            let cam = 3.0
            let cosT = cos(motion.tilt), sinT = sin(motion.tilt), roll = 0.6
            let k = full / 2 * base * wobble / (bigR + 0.64) * 0.95
            let n = 72, m = 24
            for i in 0..<n {
                let a = Double(i) / Double(n)
                let lit = style != .ring || a < motion.holdProgress(frame.u)
                let u = a * 2 * .pi + spin
                for j in 0..<m {
                    let v = Double(j) / Double(m) * 2 * .pi + Double(i % 2) * .pi / Double(m)
                    let rr = bigR + r * cos(v)
                    let x = rr * cos(u), y = rr * sin(u), z = r * sin(v)
                    let y2 = y * cosT - z * sinT, z2 = y * sinT + z * cosT
                    let p = cam / (cam - z2)
                    let rad = (1.0 + 1.6 * (p - 0.6)) * base * wobble
                    let alpha = (lit ? 1.0 : 0.3) * min(max(0.35 + 0.65 * (p - 0.7) / 0.7, 0.2), 1)
                    let xr = x * cos(roll) - y2 * sin(roll), yr = x * sin(roll) + y2 * cos(roll)
                    let cx = size.width / 2 + xr * p * k, cy = size.height / 2 + yr * p * k
                    // colour: blue when empty, towards teal when full, shifting around the ring and over time
                    let hue = 0.62 - 0.17 * level + 0.10 * sin(2 * .pi * a + spin * 0.86)
                    let color = motion.colors ? Color(hue: hue, saturation: 0.55, brightness: 1) : .white
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - rad, y: cy - rad, width: rad * 2, height: rad * 2)),
                             with: .color(color.opacity(alpha)))
                }
            }
        }
    }

    /// Solid torus surface: shaded quads sorted far to near, hue runs through the spectrum around the ring.
    private var solid: some View {
        Canvas { ctx, size in
            let full = min(size.width, size.height) * 0.86
            let level = frame.level
            let base = motion.minScale + (motion.maxScale - motion.minScale) * level
            let style = style(for: frame.kind)
            let wobble = style == .pulse ? 1 + motion.pulseAmount * sin(2 * .pi * frame.elapsedInSpan / 2) : 1
            let bigR = 1.0, r = 0.45 + 0.22 * level
            let spin = frame.time * motion.spinSpeed
            let cam = 3.0
            let cosT = cos(motion.tilt), sinT = sin(motion.tilt), roll = 0.6
            let k = full / 2 * base * wobble / (bigR + 0.67) * 0.95
            let n = 64, m = 28
            struct Vertex { var pt: CGPoint; var z: Double; var shade: Double }
            func vertex(_ i: Int, _ j: Int) -> Vertex {
                let u = Double(i) / Double(n) * 2 * .pi + spin, v = Double(j) / Double(m) * 2 * .pi
                let rr = bigR + r * cos(v)
                let x = rr * cos(u), y = rr * sin(u), z = r * sin(v)
                let y2 = y * cosT - z * sinT, z2 = y * sinT + z * cosT
                let nx = cos(v) * cos(u), ny = cos(v) * sin(u), nz = sin(v)
                let ny2 = ny * cosT - nz * sinT, nz2 = ny * sinT + nz * cosT
                let shade = max(0, nx * 0.35 + ny2 * -0.45 + nz2 * 0.82)
                let p = cam / (cam - z2)
                let xr = x * cos(roll) - y2 * sin(roll), yr = x * sin(roll) + y2 * cos(roll)
                return Vertex(pt: CGPoint(x: size.width / 2 + xr * p * k, y: size.height / 2 + yr * p * k), z: z2, shade: shade)
            }
            let grid = (0...n).map { i in (0...m).map { j in vertex(i, j) } }
            var quads: [(z: Double, i: Int, j: Int)] = []
            quads.reserveCapacity(n * m)
            for i in 0..<n {
                for j in 0..<m {
                    quads.append(((grid[i][j].z + grid[i + 1][j + 1].z) / 2, i, j))
                }
            }
            quads.sort { $0.z < $1.z }
            for q in quads {
                let a = grid[q.i][q.j], b = grid[q.i + 1][q.j], c = grid[q.i + 1][q.j + 1], d = grid[q.i][q.j + 1]
                var path = Path()
                path.move(to: a.pt); path.addLine(to: b.pt); path.addLine(to: c.pt); path.addLine(to: d.pt); path.closeSubpath()
                let frac = (Double(q.i) + 0.5) / Double(n)
                let lit = style != .ring || frac < motion.holdProgress(frame.u)
                let hue = (0.55 + frac + spin / (2 * .pi) + 0.12 * Double(q.j) / Double(m) + 0.15 * level)
                    .truncatingRemainder(dividingBy: 1)
                let shade = (a.shade + c.shade) / 2
                let color = motion.colors
                    ? Color(hue: hue, saturation: 0.6, brightness: 0.35 + 0.65 * shade)
                    : Color(white: 0.3 + 0.7 * shade)
                ctx.fill(path, with: .color(color.opacity(lit ? 1 : 0.35)))
                ctx.stroke(path, with: .color(color.opacity(lit ? 1 : 0.35)), lineWidth: 0.5)
            }
        }
    }

    /// Dot cloud sphere (Fibonacci lattice), same look as the torus: spins around the vertical axis,
    /// dot size and scale follow the breath, hue runs around the azimuth.
    private var sphere: some View {
        Canvas { ctx, size in
            let full = min(size.width, size.height) * 0.86
            let level = frame.level
            let base = motion.minScale + (motion.maxScale - motion.minScale) * level
            let style = style(for: frame.kind)
            let wobble = style == .pulse ? 1 + motion.pulseAmount * sin(2 * .pi * frame.elapsedInSpan / 2) : 1
            let spin = frame.time * motion.spinSpeed
            let cam = 3.0
            let cosT = cos(motion.tilt), sinT = sin(motion.tilt)
            let k = full / 2 * base * wobble / 1.1 * 0.95
            let n = 1600
            let golden = Double.pi * (3 - 5.0.squareRoot())
            for i in 0..<n {
                let y = 1 - 2 * (Double(i) + 0.5) / Double(n)
                let ring = (1 - y * y).squareRoot()
                let theta = Double(i) * golden
                let x0 = cos(theta) * ring, z0 = sin(theta) * ring
                let x = x0 * cos(spin) + z0 * sin(spin), z = -x0 * sin(spin) + z0 * cos(spin)
                let y2 = y * cosT - z * sinT, z2 = y * sinT + z * cosT
                let p = cam / (cam - z2)
                let a = (theta / (2 * .pi)).truncatingRemainder(dividingBy: 1)
                let az = (a + spin / (2 * .pi)).truncatingRemainder(dividingBy: 1)
                let lit = style != .ring || (x + 1) / 2 <= motion.holdProgress(frame.u)  // front sweeps left to right
                let rad = (0.9 + 1.7 * (p - 0.6)) * base * wobble
                let alpha = (lit ? 1.0 : 0.3) * (0.2 + 0.8 * (z2 + 1) / 2)
                let hue = 0.62 - 0.17 * level + 0.10 * sin(2 * .pi * az + spin * 0.86)
                let color = motion.colors ? Color(hue: hue, saturation: 0.55, brightness: 1) : .white
                let cx = size.width / 2 + x * p * k, cy = size.height / 2 + y2 * p * k
                ctx.fill(Path(ellipseIn: CGRect(x: cx - rad, y: cy - rad, width: rad * 2, height: rad * 2)),
                         with: .color(color.opacity(alpha)))
            }
        }
    }

    private var circle: some View {
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
                    Circle().trim(from: 0, to: motion.holdProgress(frame.u))
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
                Section("Motion: shape") {
                    Picker("Shape", selection: $runner.motion.shape) {
                        ForEach(MotionShape.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Motion: torus") {
                    slider("Tilt (rad)", $runner.motion.tilt, 0...1.2)
                    slider("Spin (rad/s)", $runner.motion.spinSpeed, 0...1.0)
                    Toggle("Colours", isOn: $runner.motion.colors)
                }
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
                    Toggle("Hold progress reversed", isOn: $runner.motion.holdReverse)
                    Toggle("Cycle ring (white progress)", isOn: $runner.motion.cycleRing)
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
