import BreathnestKit
import BreathnestKitTesting
import Testing

@testable import Breathnest

@MainActor
private final class FakeScreenAwake: ScreenAwake {
    private(set) var isAwake = false
    func setAwake(_ isAwake: Bool) {
        self.isAwake = isAwake
    }
}

@MainActor
private final class RecordingHaptics: HapticPlayer {
    private(set) var played: [[HapticEvent]] = []
    private(set) var stopCount = 0
    func play(_ events: [HapticEvent]) {
        played.append(events)
    }

    func stop() {
        stopCount += 1
    }
}

@MainActor
@Suite struct SessionViewModelTests {
    private let origin = ContinuousClock.now

    private func at(_ seconds: Double) -> ContinuousClock.Instant {
        origin.advanced(by: .seconds(seconds))
    }

    private func make(
        _ exercise: Exercise = .box, requested: Duration = .seconds(60), speed: Double = 1
    ) -> (SessionViewModel, FakeScreenAwake) {
        let awake = FakeScreenAwake()
        let viewModel = SessionViewModel(
            exercise: exercise, requested: requested, screenAwake: awake, haptics: RecordingHaptics(),
            settings: AppSettingsStore(store: InMemoryDocumentStore()), speed: speed, startedAt: origin
        )
        return (viewModel, awake)
    }

    private func makeWithHaptics(
        _ exercise: Exercise = .box, requested: Duration = .seconds(60), isHapticsOn: Bool = true, speed: Double = 1
    ) -> (SessionViewModel, RecordingHaptics) {
        let (viewModel, haptics, _) = makeWithSettings(
            exercise, requested: requested, isHapticsOn: isHapticsOn, speed: speed
        )
        return (viewModel, haptics)
    }

    private func makeWithSettings(
        _ exercise: Exercise = .box, requested: Duration = .seconds(60), isHapticsOn: Bool = true, speed: Double = 1
    ) -> (SessionViewModel, RecordingHaptics, AppSettingsStore) {
        let haptics = RecordingHaptics()
        let settings = AppSettingsStore(store: InMemoryDocumentStore())
        settings.setHaptics(isOn: isHapticsOn)
        let viewModel = SessionViewModel(
            exercise: exercise, requested: requested, screenAwake: FakeScreenAwake(), haptics: haptics,
            settings: settings, speed: speed, startedAt: origin
        )
        return (viewModel, haptics, settings)
    }

    /// What the Kit's Haptic plan asks for at the start of the box Phase at `index`.
    private func plan(_ index: Int) -> [HapticEvent] {
        let pattern = Exercise.box.pattern
        return pattern.hapticEvents(for: .phaseStarted(pattern.phases[index].kind), phaseIndex: index)
    }

    @Test func opensInTheLeadInShowingTheFullLengthAndTheDigitThree() {
        let (viewModel, _) = make()
        #expect(viewModel.stage == .leadIn)
        #expect(viewModel.timeLeft == .seconds(64))
        #expect(viewModel.leadInDigit == 3)
        #expect(viewModel.phaseKind == nil)
    }

    @Test func theDigitIsTheLeadInTimeLeftRoundedUp() {
        let (viewModel, _) = make()
        viewModel.tick(now: at(0.5))
        #expect(viewModel.leadInDigit == 3)
        viewModel.tick(now: at(1.5))
        #expect(viewModel.leadInDigit == 2)
        viewModel.tick(now: at(2.5))
        #expect(viewModel.leadInDigit == 1)
    }

    @Test func theBreathLevelIsZeroInTheLeadInRisesOnInhaleAndIsZeroAfterTheEnd() {
        let (viewModel, _) = make()
        #expect(viewModel.breathLevel == 0)
        viewModel.tick(now: at(5.5))
        #expect(viewModel.breathLevel > 0)
        #expect(viewModel.breathLevel < 1)
        viewModel.tick(now: at(600))
        #expect(viewModel.stage == .completed)
        #expect(viewModel.breathLevel == 0)
    }

    @Test func afterTheLeadInThePhasesFollowThePattern() {
        let (viewModel, _) = make()
        viewModel.tick(now: at(3.5))
        #expect(viewModel.stage == .breathing)
        #expect(viewModel.phaseKind == .inhale)
        viewModel.tick(now: at(7.5))
        #expect(viewModel.phaseKind == .hold)
        #expect(viewModel.timeLeft == .seconds(59.5))
    }

    @Test func pauseFreezesTheLeadInAndResumeContinuesFromThere() {
        let (viewModel, _) = make()
        viewModel.tick(now: at(1))
        viewModel.pause(now: at(1))
        viewModel.tick(now: at(30))
        #expect(viewModel.isPaused)
        #expect(viewModel.leadInDigit == 2)
        viewModel.resume(now: at(30))
        viewModel.tick(now: at(30.5))
        #expect(!viewModel.isPaused)
        #expect(viewModel.leadInDigit == 2)
        viewModel.tick(now: at(32))
        #expect(viewModel.stage == .breathing)
    }

    @Test func pauseFreezesAPhaseExactly() {
        let (viewModel, _) = make()
        viewModel.tick(now: at(8))
        viewModel.pause(now: at(8))
        let frozen = viewModel.timeLeft
        viewModel.tick(now: at(500))
        #expect(viewModel.timeLeft == frozen)
        #expect(viewModel.phaseKind == .hold)
    }

    @Test func leavingTheActiveSceneAutoPausesAndNeverAdvancesUntilResume() {
        let (viewModel, _) = make()
        viewModel.tick(now: at(8))
        viewModel.sceneBecameInactive(now: at(8))
        #expect(viewModel.isPaused)
        viewModel.tick(now: at(1000))
        #expect(viewModel.stage == .breathing)
        #expect(viewModel.isPaused)
        viewModel.resume(now: at(1000))
        viewModel.tick(now: at(1000))
        #expect(viewModel.timeLeft == .seconds(64 - 5))
    }

    @Test func theScreenStaysAwakeFromStartThroughPauseAndLeadIn() {
        let (viewModel, awake) = make()
        viewModel.begin()
        #expect(awake.isAwake)
        viewModel.pause(now: at(1))
        #expect(awake.isAwake)
    }

    @Test func theScreenIsReleasedWhenTheSessionCompletes() {
        let (viewModel, awake) = make()
        viewModel.begin()
        viewModel.tick(now: at(3 + 64))
        #expect(viewModel.stage == .completed)
        #expect(!awake.isAwake)
    }

    @Test func theScreenIsReleasedWhenTheSessionIsStopped() {
        let (viewModel, awake) = make()
        viewModel.begin()
        viewModel.tick(now: at(10))
        viewModel.stop(now: at(10))
        #expect(viewModel.stage == .stopped)
        #expect(!awake.isAwake)
    }

    @Test func theSpeedScalesTheTimeFedToTheEngine() {
        let (viewModel, _) = make(speed: 10)
        viewModel.tick(now: at(0.3))
        #expect(viewModel.stage == .breathing)
        viewModel.tick(now: at(0.3 + 6.4))
        #expect(viewModel.stage == .completed)
    }

    @Test func theSummaryNamesTheCyclesAndTheExactLength() {
        let (viewModel, _) = make(requested: .seconds(300))
        #expect(viewModel.cycleCount == 19)
        #expect(viewModel.totalLength == .seconds(304))
    }

    // MARK: Haptics

    @Test func theLeadInPlaysNoHaptic() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(1))
        viewModel.tick(now: at(2.9))
        #expect(haptics.played.isEmpty)
    }

    @Test func eachPhaseRequestsItsHapticExactlyOnceAtItsStart() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(3.5))
        #expect(haptics.played == [plan(0)])
        viewModel.tick(now: at(4))
        viewModel.tick(now: at(6.9))
        #expect(haptics.played == [plan(0)])
        viewModel.tick(now: at(7.5))
        #expect(haptics.played == [plan(0), plan(1)])
    }

    @Test func theSpeedScalesTheTimesAndDurationsOfTheHaptic() {
        let (viewModel, haptics) = makeWithHaptics(speed: 10)
        viewModel.tick(now: at(0.4))
        let inhale = plan(0).map { $0.sped(by: 10) }
        #expect(haptics.played == [inhale])
        #expect(inhale.first?.duration == plan(0).first.map { $0.duration / 10 })
        viewModel.tick(now: at(0.8))
        #expect(haptics.played == [inhale, plan(1).map { $0.sped(by: 10) }])
    }

    @Test func theHapticsFollowThePhasesAroundEveryCycle() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(3 + 16.5))
        #expect(haptics.played.count == 5)
        #expect(haptics.played.last == plan(0))
    }

    @Test func aLongGapPlaysEveryPhaseItCrossedOnce() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(3 + 8.5))
        #expect(haptics.played == [plan(0), plan(1), plan(2)])
    }

    @Test func completionPlaysNoHapticOfItsOwn() {
        let (viewModel, haptics) = makeWithHaptics()
        for second in 1 ... 67 {
            viewModel.tick(now: at(Double(second)))
        }
        #expect(viewModel.stage == .completed)
        #expect(haptics.played.count == 16)
    }

    @Test func pauseStopsTheHapticEngine() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(8))
        viewModel.pause(now: at(8))
        #expect(haptics.stopCount == 1)
    }

    @Test func anInactiveSceneStopsTheHapticEngine() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(8))
        viewModel.sceneBecameInactive(now: at(8))
        #expect(haptics.stopCount == 1)
    }

    @Test func resumeDoesNotReplayThePhaseInProgressAndTheNextPhasePlays() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(8))
        viewModel.pause(now: at(8))
        viewModel.resume(now: at(100))
        viewModel.tick(now: at(100))
        viewModel.tick(now: at(102))
        #expect(haptics.played == [plan(0), plan(1)])
        viewModel.tick(now: at(100 + 3.5))
        #expect(haptics.played == [plan(0), plan(1), plan(2)])
    }

    @Test func pausingAcrossAPhaseStartPlaysNothingForIt() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.pause(now: at(3.5))
        #expect(haptics.played.isEmpty)
        viewModel.resume(now: at(10))
        viewModel.tick(now: at(10 + 3.6))
        #expect(haptics.played == [plan(1)])
    }

    @Test func withTheSwitchOffNothingIsPlayed() {
        let (viewModel, haptics) = makeWithHaptics(isHapticsOn: false)
        viewModel.tick(now: at(3.5))
        viewModel.tick(now: at(3 + 8.5))
        viewModel.tick(now: at(3 + 64))
        #expect(haptics.played.isEmpty)
    }

    @Test func switchingHapticsOffMidSessionSilencesTheNextPhases() {
        let (viewModel, haptics, settings) = makeWithSettings()
        viewModel.tick(now: at(3.5))
        #expect(haptics.played == [plan(0)])
        settings.setHaptics(isOn: false)
        viewModel.tick(now: at(3 + 4.5))
        viewModel.tick(now: at(3 + 12.5))
        #expect(haptics.played == [plan(0)])
    }

    @Test func switchingHapticsBackOnMidSessionPlaysTheNextPhaseOnly() {
        let (viewModel, haptics, settings) = makeWithSettings(isHapticsOn: false)
        viewModel.tick(now: at(3.5))
        settings.setHaptics(isOn: true)
        viewModel.tick(now: at(3 + 4.5))
        #expect(haptics.played == [plan(1)])
    }

    @Test func changingSettingsDoesNotPauseTheSession() {
        let (viewModel, _, settings) = makeWithSettings()
        viewModel.tick(now: at(5))
        settings.setHaptics(isOn: false)
        settings.setSound(isOn: false)
        settings.setSound(.pulse)
        viewModel.tick(now: at(6))
        #expect(viewModel.isPaused == false)
        #expect(viewModel.stage == .breathing)
    }

    @Test func nothingPlaysAfterStop() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(8))
        viewModel.stop(now: at(8))
        viewModel.tick(now: at(30))
        #expect(haptics.played == [plan(0), plan(1)])
        #expect(haptics.stopCount >= 1)
    }

    @Test func stoppingAcrossAPhaseStartPlaysNothingForIt() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.stop(now: at(3.5))
        #expect(haptics.played.isEmpty)
        #expect(haptics.stopCount >= 1)
    }

    @Test func nothingPlaysAfterTheSessionIsDone() {
        let (viewModel, haptics) = makeWithHaptics()
        for second in 1 ... 67 {
            viewModel.tick(now: at(Double(second)))
        }
        viewModel.tick(now: at(100))
        #expect(haptics.played.count == 16)
        #expect(haptics.stopCount >= 1)
    }

    @Test func leavingTheCoverStopsTheHapticEngine() {
        let (viewModel, haptics) = makeWithHaptics()
        viewModel.tick(now: at(8))
        viewModel.end()
        #expect(haptics.stopCount == 1)
    }
}
