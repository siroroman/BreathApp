import BreathnestKit
import SwiftUI

/// Screens 1 to 4 of the design: the Session as full-screen cover, in text, with the gear and its Settings menu.
struct SessionView: View {
    let viewModel: SessionViewModel
    let dependencies: AppDependencies
    /// The saved record when the Exercise is a custom one, for its name.
    var custom: CustomExerciseRecord?
    /// Closes the cover: Stop and Done both call it.
    let close: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isMenuOpen = false
    @AccessibilityFocusState private var isGearFocused: Bool

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
        .onChange(of: viewModel.stage) {
            if viewModel.stage == .completed { isMenuOpen = false }
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active { viewModel.sceneBecameInactive(now: .now) }
        }
    }

    private func runningScreen(scale: DesignScale) -> some View {
        ZStack {
            // The centre content sits on the middle of the screen, not between the header and the buttons, whose
            // heights differ.
            ProgressRingView(ring: viewModel.ring, fills: viewModel.ringFills)
                .frame(width: scale(330, 230), height: scale(330, 230))
            if viewModel.stage == .leadIn {
                Text(verbatim: "\(viewModel.leadInDigit)")
                    // The design draws the digit at 180 (130 at AX5), larger than any text style, so it takes a
                    // size from the scale and no longer follows the system curve.
                    .font(.system(size: scale(180, 130), weight: .semibold))
                    .monospacedDigit()
                    .accessibilityIdentifier("session.digit")
                    .onChange(of: viewModel.leadInDigit) {
                        AccessibilityNotification.Announcement(String(viewModel.leadInDigit)).post()
                    }
            } else {
                torus(level: viewModel.breathLevel, side: scale(278, 194))
            }
            VStack(spacing: 0) {
                timeBlock
                phaseBlock.padding(.top, 24)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 64)
            .padding(.bottom, 34)
            // A tap outside the menu closes it. The layer sits under the buttons, so Pause and Stop stay
            // reachable with the menu open.
            if isMenuOpen {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { closeMenu() }
                    .accessibilityHidden(true)
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                buttons(scale: scale)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 34)
            gear(scale: scale)
        }
        .ignoresSafeArea()
    }

    /// The gear at the top right, and under it the menu while it is open. Present in the Lead-in, while breathing
    /// and while paused; the end screen has none.
    private func gear(scale: DesignScale) -> some View {
        let side = scale(44, 64)
        return ZStack(alignment: .topTrailing) {
            Color.clear
            Button {
                if isMenuOpen { closeMenu() } else { isMenuOpen = true }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: scale(26, 38)))
                    .foregroundStyle(Color(isMenuOpen ? .ring : .fg2))
                    .frame(width: side, height: side)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("session.settings"))
            .accessibilityAddTraits(isMenuOpen ? .isSelected : [])
            .accessibilityFocused($isGearFocused)
            .accessibilityIdentifier("session.gearButton")
            .padding(.top, 56)
            .padding(.trailing, 16)

            if isMenuOpen {
                SessionMenu(settings: dependencies.settings, scale: scale)
                    .padding(.top, 110 - 9)
                    .padding(.horizontal, 16)
                    .accessibilityAction(.escape) { closeMenu() }
            }
        }
    }

    /// Closes the menu and hands the VoiceOver focus back to the gear.
    private func closeMenu() {
        isMenuOpen = false
        isGearFocused = true
    }

    private func torus(level: Double, side: CGFloat) -> some View {
        TorusView(level: level, reduceMotion: reduceMotion)
            .frame(width: side, height: side)
            .accessibilityIdentifier("session.torus")
    }

    private var timeBlock: some View {
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

    private var phaseBlock: some View {
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
        guard let kind = viewModel.phaseKind else {
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
            torus(level: 0, side: scale(240, 190))
                .padding(.bottom, 24)
            VStack(spacing: 8) {
                Text("session.complete")
                    .designFont(.title, 32, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("session.completeTitle")
                Text(verbatim: SessionText.summary(
                    of: viewModel.exercise,
                    custom: custom,
                    length: viewModel.sessionLength
                ))
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
