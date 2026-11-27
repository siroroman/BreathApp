import BreathnestKit
import SwiftUI

/// Screen 9 of the design: the Settings sheet. Done at the top right, the title and four groups of one row:
/// Appearance, Health access, Share the app and Version (#60).
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var isAppearanceOpen = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    init(dependencies: AppDependencies, bundle: Bundle = .main) {
        let info = bundle.infoDictionary
        _viewModel = State(initialValue: SettingsViewModel(
            health: dependencies.health,
            version: AppVersion(
                version: info?["CFBundleShortVersionString"] as? String,
                build: info?["CFBundleVersion"] as? String
            )
        ))
    }

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Capsule()
                    .fill(Color(.outline))
                    .frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                if isAppearanceOpen {
                    appearancePage(scale: scale)
                } else {
                    mainPage(scale: scale)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .scrollBounceBehavior(.basedOnSize)
        .foregroundStyle(Color(.fg))
        .background(Color(.bg))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(38)
        .presentationBackground(Color(.bg))
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refreshHealth() }
        }
    }

    private func mainPage(scale: DesignScale) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                dismiss()
            } label: {
                Text("settings.done")
                    .designFont(.body, 17, weight: .semibold)
                    .foregroundStyle(Color(.ring))
                    .frame(minHeight: 44)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityIdentifier("settings.doneButton")

            Text("settings.title")
                .designFont(.title, 30, weight: .bold, tracking: -0.02, lineHeight: 1.15)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("settings.title")

            group {
                Button {
                    withAnimation(.snappy) { isAppearanceOpen = true }
                } label: {
                    row("settings.appearance", value: Text("settings.appearance.aurora"), chevron: true, scale: scale)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("settings.appearanceRow")
            }
            group {
                Button {
                    Task {
                        if await viewModel.healthTapped() == .opensSystemSettings,
                           let url = URL(string: "app-settings:")
                        {
                            openURL(url)
                        }
                    }
                } label: {
                    row("settings.health", value: Text(Self.healthText(viewModel.healthState)), chevron: true, scale: scale)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text(Self.healthHint(viewModel.healthState)))
                .accessibilityIdentifier("settings.healthRow")
            }
            group {
                ShareLink(item: Self.shareText) {
                    row("settings.share", value: nil, chevron: false, scale: scale, shareIcon: true)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.shareRow")
            }
            group {
                row("settings.version", value: Text(verbatim: viewModel.versionText), chevron: false, scale: scale)
                    .accessibilityIdentifier("settings.versionRow")
            }
        }
    }

    /// The single-choice list of the looks, one step in from Settings.
    private func appearancePage(scale: DesignScale) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.snappy) { isAppearanceOpen = false }
            } label: {
                Text("settings.title")
                    .designFont(.body, 17, weight: .medium)
                    .foregroundStyle(Color(.ring))
                    .frame(minHeight: 44, alignment: .leading)
            }
            .accessibilityIdentifier("settings.backButton")
            Text("settings.appearance")
                .designFont(.title, 30, weight: .bold, tracking: -0.02, lineHeight: 1.15)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("settings.appearanceTitle")
            group {
                ForEach(viewModel.appearances, id: \.self) { appearance in
                    let isChosen = appearance == viewModel.appearance
                    Button {
                        viewModel.choose(appearance)
                    } label: {
                        HStack {
                            Text("settings.appearance.aurora")
                                .designFont(.body, 17, weight: .medium)
                            Spacer(minLength: 8)
                            if isChosen {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .accessibilityHidden(true)
                            }
                        }
                        .foregroundStyle(Color(isChosen ? .ring : .fg))
                        .padding(.horizontal, 16)
                        .frame(minHeight: scale(52, 92))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isChosen ? .isSelected : [])
                    .accessibilityIdentifier("settings.appearance.aurora")
                }
            }
        }
    }

    private func group(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .background(Color(.surface))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func row(
        _ title: LocalizedStringKey, value: Text?, chevron: Bool, scale: DesignScale, shareIcon: Bool = false
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .designFont(.body, 17, weight: .medium)
                .foregroundStyle(Color(.fg))
                .frame(maxWidth: .infinity, alignment: .leading)
            if let value {
                value
                    .designFont(.body, 17, weight: .medium)
                    .foregroundStyle(Color(.fg2))
                    .multilineTextAlignment(.trailing)
            }
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.fg2))
                    .accessibilityHidden(true)
            }
            if shareIcon {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(.ring))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: scale(52, 92))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private static func healthText(_ state: HealthAccessState) -> LocalizedStringKey {
        switch state {
        case .allowed: "settings.health.allowed"
        case .denied: "settings.health.denied"
        case .notDetermined: "settings.health.notSet"
        case .unavailable: "settings.health.unavailable"
        }
    }

    private static func healthHint(_ state: HealthAccessState) -> LocalizedStringKey {
        switch state {
        case .notDetermined: "settings.health.hint.ask"
        case .allowed, .denied: "settings.health.hint.settings"
        case .unavailable: "settings.health.hint.unavailable"
        }
    }

    /// No link until the app has an App Store page.
    private static let shareText = String(localized: "settings.share.message")
}
