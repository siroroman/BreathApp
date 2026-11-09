import BreathnestKit
import UIKit

/// Yields the time once per screen frame (ADR 0002). The display link lives on the main run loop and stops when
/// the consumer's task is cancelled.
struct DisplayLinkTicker: Ticker {
    func ticks() -> AsyncStream<ContinuousClock.Instant> {
        AsyncStream { continuation in
            let driver = Task { @MainActor in
                let driver = DisplayLinkDriver(continuation: continuation)
                driver.start()
                return driver
            }
            continuation.onTermination = { _ in
                Task { @MainActor in await driver.value.stop() }
            }
        }
    }
}

@MainActor
private final class DisplayLinkDriver: NSObject {
    private let continuation: AsyncStream<ContinuousClock.Instant>.Continuation
    private var link: CADisplayLink?

    init(continuation: AsyncStream<ContinuousClock.Instant>.Continuation) {
        self.continuation = continuation
    }

    func start() {
        let link = CADisplayLink(target: self, selector: #selector(fire))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func fire() {
        continuation.yield(.now)
    }
}

/// Keeps the screen on through the idle timer.
struct IdleTimerScreenAwake: ScreenAwake {
    func setAwake(_ isAwake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = isAwake
    }
}

/// The real seams, built once by `BreathnestApp` and handed to the screens that create ViewModels (ADR 0002).
struct AppDependencies {
    let ticker: any Ticker
    let screenAwake: any ScreenAwake
    /// Scales the time fed to the Session engine. 1 in a release build; a DEBUG launch argument can raise it.
    let sessionSpeed: Double

    @MainActor
    static func live(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        AppDependencies(
            ticker: DisplayLinkTicker(), screenAwake: IdleTimerScreenAwake(), sessionSpeed: speed(in: arguments)
        )
    }

    private static func speed(in arguments: [String]) -> Double {
        #if DEBUG
            if let index = arguments.firstIndex(of: "-SessionSpeed"), arguments.indices.contains(index + 1),
               let value = Double(arguments[index + 1]), value > 0
            {
                return value
            }
        #endif
        return 1
    }
}
