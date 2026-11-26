import AVFoundation
import BreathnestKit

/// Where the bundled file of a sound is. The files are made by `scripts/generate-sounds.py`.
enum SoundFile {
    static func url(for sound: SoundID, in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: sound.rawValue, withExtension: "caf")
    }
}

/// Plays the Session cues with `AVAudioPlayer` (research note `session-sound-sources.md`, section 4, and the
/// decisions in #49). The audio session is `.playback` with `.mixWithOthers`: a cue is heard with the Silent
/// switch on and does not stop the user's music. It is activated at the first cue, not at launch, and released
/// when the cue ends or is stopped. An interruption or a lost route stops the cue and nothing resumes it.
@MainActor
final class AVSoundPlayer: NSObject, SoundPlayer, AVAudioPlayerDelegate {
    private let session: AVAudioSession
    private let bundle: Bundle
    private var players: [SoundID: AVAudioPlayer] = [:]
    private var current: AVAudioPlayer?

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

    func play(_ sound: SoundID) {
        guard let player = player(for: sound) else { return }
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }
        current?.stop()
        player.currentTime = 0
        current = player
        if !player.play() { release() }
    }

    func stop() {
        current?.stop()
        release()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        if player === current { release() }
    }

    private func player(for sound: SoundID) -> AVAudioPlayer? {
        if let cached = players[sound] { return cached }
        guard let url = SoundFile.url(for: sound, in: bundle), let made = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        made.delegate = self
        made.prepareToPlay()
        players[sound] = made
        return made
    }

    private func release() {
        current = nil
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
