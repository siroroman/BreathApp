import AVFoundation
import BreathnestKit
import Testing

@testable import Breathnest

@Suite struct SoundFileTests {
    @Test(arguments: SoundID.allCases, SoundCue.allCases)
    func everySoundHasABundledFileForEveryCue(_ sound: SoundID, _ cue: SoundCue) throws {
        let url = try #require(SoundFile.url(for: sound, cue: cue))
        let file = try AVAudioFile(forReading: url)
        let seconds = Double(file.length) / file.processingFormat.sampleRate
        #expect(file.processingFormat.channelCount == 1)
        #expect(seconds > 0.1)
        #expect(seconds < 6)
    }

    @Test(arguments: SoundID.allCases)
    func aTickIsShorterThanItsTones(_ sound: SoundID) throws {
        func length(_ cue: SoundCue) throws -> Int64 {
            try AVAudioFile(forReading: #require(SoundFile.url(for: sound, cue: cue))).length
        }
        let tick = try length(.tick)
        let inhale = try length(.inhale)
        let exhale = try length(.exhale)
        #expect(tick <= inhale)
        #expect(tick <= exhale)
    }
}
