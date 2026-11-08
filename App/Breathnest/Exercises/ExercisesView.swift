import BreathnestKit
import SwiftUI

/// Screen 5 of the design: the Exercises list. The Quick Start card, the Custom exercise row and the tab bar
/// come with #54, #57 and #58.
struct ExercisesView: View {
    let navigation: AppNavigation

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("exercises.title")
                        .designFont(.largeTitle, 34, weight: .bold, tracking: -0.02, lineHeight: 1.1)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 20)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("exercises.title")
                    VStack(spacing: 0) {
                        ForEach(Array(Exercise.builtIn.enumerated()), id: \.element.id) { index, exercise in
                            if index > 0 {
                                Rectangle().fill(Color(.line)).frame(height: 1)
                            }
                            ExerciseRow(exercise: exercise, scale: scale) {
                                navigation.openDetail(of: exercise.id)
                            }
                        }
                    }
                    .background(Color(.surface))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 16)
                // The design puts the title 64 pt from the top of the screen, the status bar included.
                .padding(.top, max(0, 64 - proxy.safeAreaInsets.top))
                .padding(.bottom, 34)
            }
        }
        .background(Color(.bg))
        .sheet(item: openExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    private var openExercise: Binding<Exercise?> {
        Binding(
            get: { navigation.openExercise },
            set: { if $0 == nil { navigation.closeDetail() } }
        )
    }
}

/// One row: the glyph of the Pattern, the name and the Pattern as numbers. The whole row is one button.
private struct ExerciseRow: View {
    let exercise: Exercise
    let scale: DesignScale
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if !scale.isAccessibility {
                    PatternGlyph(pattern: exercise.pattern)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: ExerciseText.name(of: exercise))
                        .designFont(.body, 17, weight: .semibold, lineHeight: 1.25)
                        .foregroundStyle(Color(.fg))
                    Text(verbatim: ExerciseText.patternNumbers(exercise.pattern))
                        .designFont(.subheadline, 15, lineHeight: 1.25)
                        .monospacedDigit()
                        .foregroundStyle(Color(.fg2))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, scale(14, 22))
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ExerciseText.spokenRow(of: exercise))
        .accessibilityHint(ExerciseText.rowHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("exercises.row.\(exercise.id)")
    }
}
