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

/// Plays the Sound plan of one Phase with the chosen sound: each event is the tone of its cue, played `time` after
/// the call, so the ticks of a hold land with the haptic ticks. A new `play` replaces what is still playing. `stop`
/// silences everything and releases the audio session, for Pause, Stop and Done. The app's adapter is
/// `AVAudioPlayer`; it does nothing when no audio route is available.
@MainActor
public protocol SoundPlayer {
    func play(_ sound: SoundID, events: [SoundEvent])
    func stop()
}

/// Plays the Haptic plan on the phone. `play` starts one Phase's haptic; `stop` silences what is playing, for
/// Pause, Stop and Done. The app's adapter is Core Haptics and does nothing where it is unsupported.
@MainActor
public protocol HapticPlayer {
    func play(_ events: [HapticEvent])
    func stop()
}
