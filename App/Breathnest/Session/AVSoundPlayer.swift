import AVFoundation
import BreathnestKit

/// Where the bundled file of a sound cue is. The files are made by `scripts/generate-sounds.py`, one per sound and
/// cue: `soft-bell-inhale.caf`, `soft-bell-exhale.caf`, `soft-bell-tick.caf`.
enum SoundFile {
    static func url(for sound: SoundID, cue: SoundCue, in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: "\(sound.rawValue)-\(cue.rawValue)", withExtension: "caf")
    }
}

/// Plays the Session cues with `AVAudioPlayer` (research note `session-sound-sources.md`, section 4, and the
/// decisions in #49). The audio session is `.playback` with `.mixWithOthers`: a cue is heard with the Silent
/// switch on and does not stop the user's music. It is activated at the first cue, not at launch, and released
/// when the last cue ends or is stopped. An interruption or a lost route stops the cue and nothing resumes it.
@MainActor
final class AVSoundPlayer: NSObject, SoundPlayer, AVAudioPlayerDelegate {
    /// Starts this long after the call, so the first cue is scheduled on the audio clock and not late.
    private static let lead: TimeInterval = 0.03
    /// A hold longer than this has its last ticks left out.
    private static let maxEvents = 40

    private let session: AVAudioSession
    private let bundle: Bundle
    /// One player per file and slot: two ticks of a hold at once need two players.
    private var pool: [String: [AVAudioPlayer]] = [:]
    private var active: [AVAudioPlayer] = []

    init(session: AVAudioSession = .sharedInstance(), bundle: Bundle = .main) {
        self.session = session
        self.bundle = bundle
        super.init()
        let center = NotificationCenter.default
        // The player lives as long as the app, so the observers are never removed.
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) {
            [weak self] note in
            let began = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                == AVAudioSession.InterruptionType.began.rawValue
            if began { MainActor.assumeIsolated { self?.stop() } }
        }
        center.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: .main) {
            [weak self] note in
            let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt)
                .flatMap(AVAudioSession.RouteChangeReason.init(rawValue:))
            if reason == .oldDeviceUnavailable { MainActor.assumeIsolated { self?.stop() } }
        }
    }

    /// Schedules every event on the audio clock, `time` after now, so the ticks of a hold keep the beat of the
    /// haptic ticks. A new call silences what is still playing.
    func play(_ sound: SoundID, events: [SoundEvent]) {
        halt()
        let scheduled = events.prefix(Self.maxEvents)
        var next: [SoundCue: Int] = [:]
        let players = scheduled.compactMap { event -> (AVAudioPlayer, SoundEvent)? in
            let slot = next[event.cue, default: 0]
            next[event.cue] = slot + 1
            return player(for: sound, cue: event.cue, slot: slot).map { ($0, event) }
        }
        guard !players.isEmpty else { return }
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }
        for (player, event) in players {
            player.currentTime = 0
            let seconds = Double(event.time.components.seconds) + Double(event.time.components.attoseconds) / 1e18
            if player.play(atTime: player.deviceCurrentTime + Self.lead + seconds) { active.append(player) }
        }
        if active.isEmpty { release() }
    }

    func stop() {
        halt()
        release()
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        let finished = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self else { return }
            active.removeAll { ObjectIdentifier($0) == finished }
            if active.isEmpty { release() }
        }
    }

    private func halt() {
        active.forEach { $0.stop() }
        active = []
    }

    private func player(for sound: SoundID, cue: SoundCue, slot: Int) -> AVAudioPlayer? {
        let key = "\(sound.rawValue)-\(cue.rawValue)"
        if let cached = pool[key]?[safe: slot] { return cached }
        guard let url = SoundFile.url(for: sound, cue: cue, in: bundle), let made = try? AVAudioPlayer(contentsOf: url)
        else { return nil }
        made.delegate = self
        made.prepareToPlay()
        pool[key, default: []].append(made)
        return made
    }

    private func release() {
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
