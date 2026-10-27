// PROTOTYPE (issue #13). One clock: a display link evaluates the position in the Pattern from elapsed time.
import SwiftUI
import QuartzCore

struct Frame {
    var level = 0.0
    var kind: PhaseKind = .inhale
    var spanIndex = 0
    var elapsedInSpan = 0.0
    var spanSeconds = 1.0
    var cycle = 0
    var time = 0.0
    var u: Double { min(elapsedInSpan / spanSeconds, 1) }
    var remaining: Double { max(spanSeconds - elapsedInSpan, 0) }
}

@MainActor
final class LinkTarget: NSObject {
    var handler: (() -> Void)?
    @objc func fire() { handler?() }
}

@MainActor @Observable
final class Runner {
    var pattern: Pattern = Patterns.all[0] { didSet { reset() } }
    var motion = MotionPreset.all[0].config
    var haptic = HapticPreset.all[0].config
    var hapticsEnabled = true
    private(set) var running = false
    private(set) var frame = Frame()
    @ObservationIgnored let haptics = Haptics()
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private let target = LinkTarget()
    @ObservationIgnored private var anchor: CFTimeInterval = 0
    @ObservationIgnored private var accumulated = 0.0
    @ObservationIgnored private var lastKey: Int?

    init() {
        target.handler = { [weak self] in self?.tick() }
        reset()
    }

    func toggle() { running ? pause() : start() }

    func start() {
        guard !running else { return }
        running = true
        anchor = CACurrentMediaTime()
        UIApplication.shared.isIdleTimerDisabled = true
        if hapticsEnabled { haptics.start() }
        let l = CADisplayLink(target: target, selector: #selector(LinkTarget.fire))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        l.add(to: .main, forMode: .common)
        link = l
    }

    func pause() {
        guard running else { return }
        accumulated += CACurrentMediaTime() - anchor
        running = false
        link?.invalidate()
        link = nil
        haptics.stop()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func reset() {
        if running { pause() }
        accumulated = 0
        lastKey = nil
        frame = Frame(level: 0, kind: pattern.spans[0].kind, spanIndex: 0,
                      elapsedInSpan: 0, spanSeconds: pattern.spans[0].seconds, cycle: 0, time: 0)
    }

    func setHapticsEnabled(_ on: Bool) {
        hapticsEnabled = on
        guard running else { return }
        on ? haptics.start() : haptics.stop()
    }

    private func tick() {
        let t = accumulated + (CACurrentMediaTime() - anchor)
        let cycle = Int(t / pattern.cycleSeconds)
        let ct = t - Double(cycle) * pattern.cycleSeconds
        let idx = pattern.spanIndex(at: ct)
        let span = pattern.spans[idx]
        let p = pattern, m = motion
        if lastKey != cycle * 100 + idx {
            lastKey = cycle * 100 + idx
            if hapticsEnabled {
                haptics.play(span, config: haptic) { rel in
                    p.level(at: span.t0 + rel, inhale: m.inhaleCurve, exhale: m.exhaleCurve)
                }
            }
        }
        frame = Frame(level: p.level(at: ct, inhale: m.inhaleCurve, exhale: m.exhaleCurve),
                      kind: span.kind, spanIndex: idx, elapsedInSpan: ct - span.t0,
                      spanSeconds: span.seconds, cycle: cycle, time: t)
    }
}
