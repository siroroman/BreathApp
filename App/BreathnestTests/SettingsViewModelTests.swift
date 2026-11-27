import BreathnestKit
import BreathnestKitTesting
import Testing

@testable import Breathnest

@MainActor
@Suite struct SettingsViewModelTests {
    private func make(
        _ state: HealthAccessState,
        answer: HealthAccessState = .allowed,
        version: AppVersion = AppVersion(version: "1.0", build: "1")
    ) -> (SettingsViewModel, FakeHealthAccess) {
        let health = FakeHealthAccess(state: state, answer: answer)
        return (SettingsViewModel(health: health, version: version), health)
    }

    @Test func theVersionIsTheBundleLine() {
        let (viewModel, _) = make(.allowed, version: AppVersion(version: "0.1.0", build: "3"))
        #expect(viewModel.versionText == "0.1.0 (3)")
    }

    @Test func theRowFollowsTheHealthState() {
        #expect(make(.allowed).0.healthState == .allowed)
        #expect(make(.denied).0.healthState == .denied)
    }

    @Test func tappingHealthWhenUndecidedAsksTheSystemAndShowsTheAnswer() async {
        let (viewModel, health) = make(.notDetermined, answer: .allowed)
        let outcome = await viewModel.healthTapped()
        #expect(outcome == .requested)
        #expect(health.requestCount == 1)
        #expect(viewModel.healthState == .allowed)
    }

    @Test func tappingHealthAfterADenialOpensTheSystemSettings() async {
        let (viewModel, health) = make(.denied)
        #expectawait (viewModel.healthTapped() == .opensSystemSettings)
        #expect(health.requestCount == 0)
    }

    @Test func tappingHealthWhenAllowedOpensTheSystemSettings() async {
        let (viewModel, _) = make(.allowed)
        #expectawait (viewModel.healthTapped() == .opensSystemSettings)
    }

    @Test func tappingHealthWhereItIsUnavailableDoesNothing() async {
        let (viewModel, health) = make(.unavailable)
        #expectawait (viewModel.healthTapped() == .nothing)
        #expect(health.requestCount == 0)
    }

    @Test func appearanceOffersAuroraOnly() {
        let (viewModel, _) = make(.allowed)
        #expect(viewModel.appearances == [.aurora])
        #expect(viewModel.appearance == .aurora)
    }
}
