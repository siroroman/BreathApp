import BreathnestKit
import Testing

@testable import Breathnest

@MainActor
@Suite struct AppNavigationTests {
    @Test func startsWithNoDetailOpen() {
        #expect(AppNavigation().openExercise == nil)
    }

    @Test func openingAnExerciseByItsIDShowsItsDetail() {
        let navigation = AppNavigation()
        navigation.openDetail(of: Exercise.coherent.id)
        #expect(navigation.openExercise == .coherent)
    }

    @Test func anUnknownIDOpensNothing() {
        let navigation = AppNavigation()
        navigation.openDetail(of: "no-such-exercise")
        #expect(navigation.openExercise == nil)
    }

    @Test func closingTheDetailClearsIt() {
        let navigation = AppNavigation()
        navigation.openDetail(of: Exercise.box.id)
        navigation.closeDetail()
        #expect(navigation.openExercise == nil)
    }

    @Test func selectingATabChangesTheTab() {
        let navigation = AppNavigation()
        #expect(navigation.tab == .exercises)
        navigation.select(.stats)
        #expect(navigation.tab == .stats)
    }

    @Test func openingADetailFromAnotherTabShowsTheExercisesTab() {
        let navigation = AppNavigation()
        navigation.select(.stats)
        navigation.openDetail(of: Exercise.box.id)
        #expect(navigation.tab == .exercises)
        #expect(navigation.openExercise == .box)
    }

    @Test func anUnknownIDLeavesTheTabAlone() {
        let navigation = AppNavigation()
        navigation.select(.stats)
        navigation.openDetail(of: "no-such-exercise")
        #expect(navigation.tab == .stats)
    }
}
