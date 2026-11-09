import BreathnestKit
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
            exercise: exercise, requested: requested, screenAwake: awake, speed: speed, startedAt: origin
        )
        return (viewModel, awake)
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
}
