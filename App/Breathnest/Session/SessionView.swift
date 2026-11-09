import BreathnestKit
import SwiftUI

/// Screens 1 to 3 of the design: the Session as full-screen cover, in text. The gear and its menu come with #56,
/// the shape with #30 and the ring with #31, so the middle is empty after the Lead-in.
struct SessionView: View {
    let viewModel: SessionViewModel
    let dependencies: AppDependencies
    /// Closes the cover: Stop and Done both call it.
    let close: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        Group {
            if viewModel.stage == .completed {
                completeScreen(scale: scale)
            } else {
                runningScreen(scale: scale)
            }
        }
        .foregroundStyle(Color(.fg))
        .background(Color(.bg))
        .interactiveDismissDisabled()
        .onAppear {
            viewModel.begin()
            viewModel.run(ticker: dependencies.ticker)
        }
        .onDisappear { viewModel.end() }
        .onChange(of: scenePhase) {
            if scenePhase != .active { viewModel.sceneBecameInactive(now: .now) }
        }
    }

    private func runningScreen(scale: DesignScale) -> some View {
        VStack(spacing: 0) {
            timeBlock(scale: scale)
            phaseBlock(scale: scale).padding(.top, 24)
            Spacer(minLength: 0)
            if viewModel.stage == .leadIn {
                Text(verbatim: "\(viewModel.leadInDigit)")
                    .designFont(.largeTitle, 180, weight: .semibold)
                    .minimumScaleFactor(0.3)
                    .monospacedDigit()
                    .accessibilityIdentifier("session.digit")
                    .onChange(of: viewModel.leadInDigit) {
                        AccessibilityNotification.Announcement(String(viewModel.leadInDigit)).post()
                    }
            }
            Spacer(minLength: 0)
            buttons(scale: scale)
        }
        .padding(.horizontal, 16)
        .padding(.top, 64)
        .padding(.bottom, 34)
        .ignoresSafeArea()
    }

    private func timeBlock(scale: DesignScale) -> some View {
        VStack(spacing: 0) {
            Text(verbatim: SessionText.remaining(viewModel.timeLeft))
                .designFont(.title, 32, weight: .semibold)
                .monospacedDigit()
                .accessibilityIdentifier("session.time")
            Text("session.remaining")
                .designFont(.footnote, 13)
                .foregroundStyle(Color(.fg2))
        }
        .accessibilityElement(children: .combine)
    }

    private func phaseBlock(scale: DesignScale) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .designFont(.largeTitle, 44, weight: .semibold, tracking: -0.01)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("session.title")
            Text(viewModel.isPaused ? "session.paused" : "")
                .designFont(.body, 17)
                .foregroundStyle(Color(.fg2))
                .frame(minHeight: 24)
                .accessibilityIdentifier("session.pausedLine")
        }
    }

    private var title: LocalizedStringKey {
        guard viewModel.stage == .breathing || viewModel.phaseKind != nil, let kind = viewModel.phaseKind else {
            return "session.leadIn.title"
        }
        return switch kind {
        case .inhale: "phase.inhale"
        case .hold: "phase.hold"
        case .exhale: "phase.exhale"
        case .rest: "phase.rest"
        }
    }

    @ViewBuilder
    private func buttons(scale: DesignScale) -> some View {
        let layout = scale.isAccessibility ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Button {
                if viewModel.isPaused {
                    viewModel.resume(now: .now)
                } else {
                    viewModel.pause(now: .now)
                }
            } label: {
                Text(viewModel.isPaused ? "session.resume" : "session.pause")
                    .designFont(.title3, 19, weight: .semibold)
                    .foregroundStyle(Color(.bg))
                    .frame(maxWidth: .infinity, minHeight: scale(54, 76))
                    .background(Capsule().fill(Color(.fg)))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("session.pauseButton")

            Button {
                viewModel.stop(now: .now)
                close()
            } label: {
                Text("session.stop")
                    .designFont(.title3, 19, weight: .semibold)
                    .foregroundStyle(Color(.fg))
                    .frame(maxWidth: .infinity, minHeight: scale(54, 76))
                    .overlay(Capsule().strokeBorder(Color(.fg2), lineWidth: 2))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("session.stopButton")
        }
    }

    private func completeScreen(scale: DesignScale) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                Text("session.complete")
                    .designFont(.title, 32, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("session.completeTitle")
                Text(verbatim: SessionText.summary(of: viewModel.exercise, length: viewModel.sessionLength))
                    .designFont(.body, 17)
                    .foregroundStyle(Color(.fg2))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("session.summary")
            }
            Spacer(minLength: 0)
            Button(action: close) {
                Text("session.done")
                    .designFont(.title3, 19, weight: .semibold)
                    .foregroundStyle(Color(.bg))
                    .frame(maxWidth: .infinity, minHeight: scale(54, 76))
                    .background(Capsule().fill(Color(.fg)))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("session.doneButton")
        }
        .padding(.horizontal, 16)
        .padding(.top, 64)
        .padding(.bottom, 34)
        .ignoresSafeArea()
    }
}
