import BreathnestKit
import SwiftUI

/// Screen 6 of the design: the Exercise detail bottom sheet. The slider comes with #55.
struct ExerciseDetailView: View {
    @State private var viewModel: ExerciseDetailViewModel
    @State private var session: SessionViewModel?
    @State private var isSoundsOpen = false
    private let dependencies: AppDependencies

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.locale) private var locale

    init(exercise: Exercise, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: ExerciseDetailViewModel(
            exercise: exercise, settings: dependencies.settings, lastSession: dependencies.lastSession
        ))
    }

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: scale(14, 22)) {
                    Capsule()
                        .fill(Color(.outline))
                        .frame(width: 36, height: 5)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                    cancelButton
                    header
                    durationSection(scale: scale)
                    SafetyNote(showsHoldLine: showsHoldLine)
                    settingsGroup(scale: scale)
                    Spacer(minLength: 0)
                    startButton(scale: scale)
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(Color(.fg))
        .background(Color(.bg))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(38)
        .presentationBackground(Color(.bg))
        // Closing the cover leaves the sheet as it was, with the same Duration chip and Haptics choice.
        .fullScreenCover(item: $session) { session in
            SessionView(viewModel: session, dependencies: dependencies) { self.session = nil }
        }
    }

    /// Box and 4-7-8 are the Exercises with a long hold.
    private var showsHoldLine: Bool {
        viewModel.exercise.pattern.phases.contains { $0.kind == .hold && $0.duration >= .seconds(4) }
    }

    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("common.cancel")
                .designFont(.body, 17, weight: .medium)
                .foregroundStyle(Color(.ring))
                .frame(minHeight: 44, alignment: .leading)
        }
        .accessibilityIdentifier("detail.cancelButton")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: ExerciseText.name(of: viewModel.exercise))
                .designFont(.title, 30, weight: .bold, tracking: -0.02, lineHeight: 1.15)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("detail.title")
            Text(verbatim: ExerciseText.patternWithNames(viewModel.exercise.pattern, locale: locale))
                .designFont(.callout, 16, lineHeight: 1.35)
                .foregroundStyle(Color(.fg2))
                .padding(.top, 6)
                .accessibilityIdentifier("detail.pattern")
            Text(verbatim: ExerciseText.description(of: viewModel.exercise))
                .designFont(.subheadline, 15, lineHeight: 1.4)
                .foregroundStyle(Color(.fg2))
                .padding(.top, 10)
                .accessibilityIdentifier("detail.description")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func durationSection(scale: DesignScale) -> some View {
        let wholeMinutes = viewModel.optionsAreWholeMinutes
        let result = ExerciseText.result(viewModel.sessionLength)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("detail.duration")
                    .foregroundStyle(Color(.fg2))
                Spacer(minLength: 0)
                Text(verbatim: ExerciseText.option(viewModel.selectedDuration, wholeMinutes: wholeMinutes))
                    .monospacedDigit()
                    .accessibilityIdentifier("detail.durationValue")
            }
            .designFont(.subheadline, 15, weight: .semibold, lineHeight: 1.3)
            .padding(.bottom, 10)
            .accessibilityElement(children: .combine)

            WrappingLayout(spacing: 10) {
                ForEach(viewModel.durationOptions, id: \.self) { option in
                    chip(option, wholeMinutes: wholeMinutes, scale: scale)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("detail.duration.options"))

            Text(verbatim: result)
                .designFont(.title2, 22, weight: .semibold, lineHeight: 1.25)
                .monospacedDigit()
                .padding(.top, 14)
                .accessibilityIdentifier("detail.result")
        }
        .onChange(of: viewModel.selectedDuration) {
            AccessibilityNotification.Announcement(result).post()
        }
    }

    private func chip(_ option: Duration, wholeMinutes: Bool, scale: DesignScale) -> some View {
        let isSelected = option == viewModel.selectedDuration
        return Button {
            viewModel.select(duration: option)
        } label: {
            Text(verbatim: ExerciseText.option(option, wholeMinutes: wholeMinutes))
                .designFont(.body, 17, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color(isSelected ? .bg : .fg))
                .padding(.horizontal, scale(20, 28))
                .frame(minHeight: scale(44, 76))
                .background(Capsule().fill(Color(isSelected ? .fg : .surface)))
                .overlay(Capsule().strokeBorder(Color(isSelected ? .fg : .outline), lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ExerciseText.spokenLength(option, locale: locale))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("detail.chip.\(Int((option / .seconds(1)).rounded()))")
    }

    /// Sounds, Sound and Haptics: one group of three rows (design screen 6).
    private func settingsGroup(scale: DesignScale) -> some View {
        VStack(spacing: 0) {
            soundsRow(scale: scale)
            switchRow("detail.sound", isOn: viewModel.isSoundOn, id: "detail.soundToggle", scale: scale) {
                viewModel.setSound(isOn: $0)
            }
            switchRow("detail.haptics", isOn: viewModel.isHapticsOn, id: "detail.hapticsToggle", scale: scale) {
                viewModel.setHaptics(isOn: $0)
            }
        }
        .background(Color(.surface))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func soundsRow(scale: DesignScale) -> some View {
        let tint = Color(isSoundsOpen ? .ring : .fg)
        return Button {
            isSoundsOpen = true
        } label: {
            HStack(spacing: 8) {
                Text("detail.sounds")
                    .designFont(.body, 17, weight: .medium)
                Spacer(minLength: 8)
                Text(verbatim: ExerciseText.soundName(viewModel.soundID))
                    .designFont(.body, 17, weight: .medium)
                    .foregroundStyle(Color(isSoundsOpen ? .ring : .fg2))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(isSoundsOpen ? .ring : .fg2))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 16)
            .padding(.vertical, scale(10, 18))
            .frame(minHeight: scale(44, 88))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("detail.sounds"))
        .accessibilityValue(ExerciseText.soundName(viewModel.soundID))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("detail.soundsRow")
        .popover(isPresented: $isSoundsOpen, arrowEdge: .top) {
            SoundsList(chosen: viewModel.soundID, scale: scale) { sound in
                viewModel.select(sound: sound)
                isSoundsOpen = false
            }
            .frame(width: scale.isAccessibility ? nil : 260)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color(.line), lineWidth: 1))
            .presentationCompactAdaptation(.popover)
            .presentationBackground(Color(.pop))
        }
    }

    private func switchRow(
        _ title: LocalizedStringKey, isOn: Bool, id: String, scale: DesignScale, set: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(isOn: Binding(get: { isOn }, set: set)) {
            Text(title)
                .designFont(.body, 17, weight: .medium)
        }
        .tint(Color(.ring))
        .padding(.horizontal, 16)
        .padding(.vertical, scale(10, 18))
        .frame(minHeight: scale(44, 88))
        .accessibilityIdentifier(id)
    }

    private func startButton(scale: DesignScale) -> some View {
        Button {
            viewModel.sessionStarted()
            session = dependencies.makeSession(exercise: viewModel.exercise, requested: viewModel.selectedDuration)
        } label: {
            Text("detail.start")
                .designFont(.title3, 19, weight: .semibold)
                .foregroundStyle(Color(.bg))
                .frame(maxWidth: .infinity, minHeight: scale(54, 96))
                .background(Capsule().fill(Color(.fg)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("detail.startButton")
    }
}
