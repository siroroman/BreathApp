import BreathnestKit
import BreathnestKitTesting
import Foundation
import Testing

@testable import Breathnest

@MainActor
@Suite struct QuickStartViewModelTests {
    private func makeViewModel() -> (QuickStartViewModel, AppSettingsStore, LastSessionStore) {
        let settings = AppSettingsStore(store: InMemoryDocumentStore())
        let lastSession = LastSessionStore(store: InMemoryDocumentStore())
        return (QuickStartViewModel(settings: settings, lastSession: lastSession), settings, lastSession)
    }

    @Test func showsBoxBreathingAtFiveMinutesWithHapticsOnBeforeAnySession() {
        let (viewModel, _, _) = makeViewModel()
        #expect(viewModel.exercise == .box)
        #expect(viewModel.requested == .seconds(300))
        #expect(viewModel.isHapticsOn)
    }

    @Test func followsTheLastSessionThatStarted() {
        let (viewModel, _, lastSession) = makeViewModel()
        lastSession.record(exercise: .coherent, requested: .seconds(600))
        #expect(viewModel.exercise == .coherent)
        #expect(viewModel.requested == .seconds(600))
    }

    @Test func followsAHapticsChangeMadeOnTheDetail() {
        let (viewModel, settings, _) = makeViewModel()
        settings.setHaptics(isOn: false)
        #expect(viewModel.isHapticsOn == false)
    }

    @Test func startingRecordsTheChoiceAgain() {
        let (viewModel, _, lastSession) = makeViewModel()
        lastSession.record(exercise: .physiologicalSigh, requested: .seconds(60))
        viewModel.started()
        #expect(lastSession.quickStart == QuickStart(exercise: .physiologicalSigh, requested: .seconds(60)))
    }

    @Test func theSummaryReadsMinutesOrClockAndTheHapticsState() {
        #expect(ExerciseText.quickStartSummary(requested: .seconds(300), isHapticsOn: true) == "5 min · Haptics on")
        #expect(ExerciseText.quickStartSummary(requested: .seconds(75), isHapticsOn: false) == "1:15 · Haptics off")
    }

    @Test func theSpokenCardNamesTheExerciseLengthAndHaptics() {
        let spoken = ExerciseText.spokenQuickStart(exercise: .box, requested: .seconds(300), isHapticsOn: false,
                                                   locale: Locale(identifier: "en_US"))
        #expect(spoken == "Box breathing, 5 minutes, Haptics off")
    }

    @Test func soundNamesComeFromTheCatalog() {
        #expect(SoundID.allCases.map { ExerciseText.soundName($0) }
            == ["Soft bell", "Singing bowl", "Chime", "Wood block", "Pulse"])
    }
}
