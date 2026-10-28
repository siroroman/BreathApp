// PROTOTYPE (issue #13), watchOS probe. Throwaway.
import SwiftUI

@main
struct CircleFeelWatchApp: App {
    var body: some Scene {
        WindowGroup { WatchContentView() }
    }
}

struct WatchContentView: View {
    @State private var runner = WatchRunner()

    var body: some View {
        TabView {
            session
            settings
        }
        .tabViewStyle(.page)
    }

    private var session: some View {
        VStack(spacing: 0) {
            Text(runner.hasStarted ? runner.frame.kind.label : "Tap to start")
                .font(.system(size: 20, weight: .light, design: .rounded))
            WatchTorus(frame: runner.frame, motion: runner.motion, pattern: runner.pattern)
                .aspectRatio(1, contentMode: .fit)
        }
        .contentShape(Rectangle())
        .onTapGesture { runner.toggle() }
    }

    private var settings: some View {
        Form {
            Picker("Pattern", selection: Binding(get: { runner.pattern.id },
                                                  set: { id in runner.pattern = Patterns.all.first { $0.id == id }! })) {
                ForEach(Patterns.all) { Text($0.name).tag($0.id) }
            }
            Toggle("Pulses in inhale and exhale", isOn: $runner.pulses)
        }
    }
}

/// G3 on a small screen: face-on dot torus plus the Cycle progress ring, same maths as the iPhone app.
struct WatchTorus: View {
    let frame: WFrame
    let motion: MotionConfig
    let pattern: Pattern

    var body: some View {
        Canvas { ctx, size in
            let full = min(size.width, size.height) * 0.94
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let level = frame.level
            func color(_ f: Double) -> Color {
                Color(hue: 0.62 - 0.17 * level + 0.10 * sin(2 * .pi * f), saturation: 0.55, brightness: 1)
            }

            // Cycle ring: arcs sized by Phase seconds, hold and rest as one segment per second.
            let radius = full / 2 * 0.99
            let gap = 0.016
            func arc(_ f0: Double, _ f1: Double, _ opacity: Double) {
                guard f1 > f0 else { return }
                var p = Path()
                p.addArc(center: c, radius: radius, startAngle: .degrees(-90 + f0 * 360),
                         endAngle: .degrees(-90 + f1 * 360), clockwise: false)
                ctx.stroke(p, with: .color(color((f0 + f1) / 2).opacity(opacity)),
                           style: StrokeStyle(lineWidth: 4, lineCap: .butt))
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

            // Torus: scale and dot size follow the breath, the tube thickens on inhale.
            let base = motion.minScale + (motion.maxScale - motion.minScale) * level
            let bigR = 1.0, r = 0.42 + 0.22 * level, cam = 3.0
            let k = full / 2 * base / (bigR + 0.64) * 0.95
            let n = 60, m = 20
            for i in 0..<n {
                let a = Double(i) / Double(n)
                let u = a * 2 * .pi
                for j in 0..<m {
                    let v = Double(j) / Double(m) * 2 * .pi + Double(i % 2) * .pi / Double(m)
                    let rr = bigR + r * cos(v)
                    let x = rr * cos(u), y = rr * sin(u), z = r * sin(v)
                    let p = cam / (cam - z)
                    let rad = (0.8 + 1.2 * (p - 0.6)) * base
                    let alpha = min(max(0.35 + 0.65 * (p - 0.7) / 0.7, 0.2), 1)
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x + x * p * k - rad, y: c.y + y * p * k - rad,
                                                    width: rad * 2, height: rad * 2)),
                             with: .color(color(a).opacity(alpha)))
                }
            }
        }
    }
}
