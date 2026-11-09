/// Yields the current time once per screen frame while a Session runs (ADR 0002). The app's adapter is a display
/// link; a test hands its own stream. The Kit holds no timer.
public protocol Ticker: Sendable {
    /// A new stream each call. It ends when the consuming task is cancelled.
    func ticks() -> AsyncStream<ContinuousClock.Instant>
}

/// Keeps the screen on while a Session runs. `setAwake(false)` releases it and is safe to call twice.
@MainActor
public protocol ScreenAwake {
    func setAwake(_ isAwake: Bool)
}
