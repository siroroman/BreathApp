import SwiftUI

/// The Quick Start card of the Exercises screen (design screen 5): "Quick Start", the Exercise name, the length
/// and the Haptics state, and a Start pill. At AX sizes the pill drops below, full width.
struct QuickStartCard: View {
    let viewModel: QuickStartViewModel
    let scale: DesignScale
    let onStart: () -> Void

    var body: some View {
        let layout = scale.isAccessibility ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            texts
            if !scale.isAccessibility { Spacer(minLength: 0) }
            startButton
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.surface))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("quickStart.title")
                .designFont(.footnote, 13, lineHeight: 1.25)
                .foregroundStyle(Color(.fg2))
            Text(verbatim: ExerciseText.name(of: viewModel.exercise))
                .designFont(.body, 17, weight: .semibold, lineHeight: 1.25)
                .foregroundStyle(Color(.fg))
            Text(verbatim: ExerciseText.quickStartSummary(
                requested: viewModel.requested, isHapticsOn: viewModel.isHapticsOn
            ))
            .designFont(.subheadline, 15, lineHeight: 1.25)
            .monospacedDigit()
            .foregroundStyle(Color(.fg2))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(String(localized: "quickStart.title")), "
                + ExerciseText.spokenQuickStart(
                    exercise: viewModel.exercise, requested: viewModel.requested,
                    isHapticsOn: viewModel.isHapticsOn
                )))
        .accessibilityIdentifier("quickStart.summary")
    }

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .accessibilityHidden(true)
                Text("detail.start")
                    .designFont(.body, 17, weight: .semibold)
            }
            .foregroundStyle(Color(.bg))
            .padding(.horizontal, 22)
            .frame(maxWidth: scale.isAccessibility ? .infinity : nil, minHeight: scale(44, 84))
            .background(Capsule().fill(Color(.fg)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quickStart.startButton")
    }
}
