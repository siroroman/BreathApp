// PROTOTYPE (issue #13), watchOS probe. Throwaway. Shares Model.swift and Config.swift with the iPhone app.
// Core Haptics does not exist on watchOS, so haptics are the fixed taps of WKInterfaceDevice.
import SwiftUI
import WatchKit

struct WFrame {
    var level = 0.0
    var kind: PhaseKind = .inhale
    var cycleTime = 0.0
}

/// An extended runtime session only needs a delegate; nothing is done with its callbacks here.
final class SessionDelegate: NSObject, WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {}
}

@MainActor @Observable
final class WatchRunner {
    var pattern: Pattern = Patterns.all[0] { didSet { reset() } }
    var pulses = true
    private(set) var running = false
    private(set) var frame = WFrame()
    /// G3: still torus seen face-on, the motion chosen in #13.
    let motion = MotionPreset.all.first { $0.key == "G3" }!.config

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var anchor = 0.0
    @ObservationIgnored private var accumulated = 0.0
    @ObservationIgnored private var lastKey: Int?
    @ObservationIgnored private var lastSub = -1
    @ObservationIgnored private var session: WKExtendedRuntimeSession?
    @ObservationIgnored private let delegate = SessionDelegate()

    init() { reset() }

    var hasStarted: Bool { accumulated > 0 || running }

    func toggle() { running ? pause() : start() }

    func start() {
        guard !running else { return }
        running = true
        anchor = ProcessInfo.processInfo.systemUptime
        // Keeps the app running and haptics playing with the wrist down.
        let s = WKExtendedRuntimeSession()
        s.delegate = delegate
        s.start()
        session = s
        let t = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func pause() {
        guard running else { return }
        accumulated += ProcessInfo.processInfo.systemUptime - anchor
        running = false
        timer?.invalidate()
        timer = nil
        session?.invalidate()
        session = nil
    }

    func reset() {
        if running { pause() }
        accumulated = 0
        lastKey = nil
        lastSub = -1
        frame = WFrame(level: 0, kind: pattern.spans[0].kind, cycleTime: 0)
    }

    private func tick() {
        let t = accumulated + (ProcessInfo.processInfo.systemUptime - anchor)
        let cycle = Int(t / pattern.cycleSeconds)
        let ct = t - Double(cycle) * pattern.cycleSeconds
        let idx = pattern.spanIndex(at: ct)
        let span = pattern.spans[idx]
        let elapsed = ct - span.t0
        let device = WKInterfaceDevice.current()
        if lastKey != cycle * 100 + idx {
            lastKey = cycle * 100 + idx
            lastSub = 0
            switch span.kind {
            case .inhale: device.play(.directionUp)
            case .exhale: device.play(.directionDown)
            case .hold, .rest: device.play(.click)
            }
        } else if span.kind == .hold || span.kind == .rest {
            let sub = Int(elapsed)   // a tick every second, like A Follow
            if sub != lastSub { lastSub = sub; device.play(.click) }
        } else if pulses {
            let sub = Int(elapsed / 0.6)   // light pulses along inhale and exhale
            if sub != lastSub { lastSub = sub; device.play(.click) }
        }
        frame = WFrame(level: pattern.level(at: ct, inhale: motion.inhaleCurve, exhale: motion.exhaleCurve),
                       kind: span.kind, cycleTime: ct)
    }
}
