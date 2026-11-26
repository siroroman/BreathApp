import AVFoundation
import BreathnestKit
import Testing

@testable import Breathnest

@Suite struct SoundFileTests {
    @Test(arguments: SoundID.allCases)
    func everySoundHasABundledFileOfAFewSeconds(_ sound: SoundID) throws {
        let url = try #require(SoundFile.url(for: sound))
        let file = try AVAudioFile(forReading: url)
        let seconds = Double(file.length) / file.processingFormat.sampleRate
        #expect(file.processingFormat.channelCount == 1)
        #expect(seconds > 0.2)
        #expect(seconds < 6)
    }
}
