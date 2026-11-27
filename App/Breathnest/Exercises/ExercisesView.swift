import BreathnestKit
import SwiftUI

/// Screen 5 of the design: the Exercises list with the Quick Start card. The Custom exercise row and the tab bar
/// come with #57 and #58.
struct ExercisesView: View {
    let navigation: AppNavigation
    let dependencies: AppDependencies

    @State private var quickStart: QuickStartViewModel
    @State private var session: SessionViewModel?
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var isAddingExercise = false
    @State private var isSettingsOpen = false

    init(navigation: AppNavigation, dependencies: AppDependencies) {
        self.navigation = navigation
        self.dependencies = dependencies
        _quickStart = State(initialValue: QuickStartViewModel(
            settings: dependencies.settings, lastSession: dependencies.lastSession
        ))
    }

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("exercises.title")
                            .designFont(.largeTitle, 34, weight: .bold, tracking: -0.02, lineHeight: 1.1)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("exercises.title")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            isSettingsOpen = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: scale(26, 38)))
                                .foregroundStyle(Color(.fg2))
                                .frame(minWidth: scale(44, 64), minHeight: scale(44, 64))
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(Text("settings.title"))
                        .accessibilityIdentifier("exercises.settingsButton")
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 20)
                    QuickStartCard(viewModel: quickStart, scale: scale) {
                        quickStart.started()
                        session = dependencies.makeSession(
                            exercise: quickStart.exercise,
                            requested: quickStart.requested
                        )
                    }
                    .padding(.bottom, 16)
                    VStack(spacing: 0) {
                        CustomExerciseRow(scale: scale) { isAddingExercise = true }
                        ForEach(dependencies.customExercises.records) { record in
                            Rectangle().fill(Color(.line)).frame(height: 1)
                            ExerciseRow(exercise: record.exercise, custom: record, scale: scale) {
                                navigation.openDetail(of: record.id)
                            }
                        }
                        ForEach(Exercise.builtIn) { exercise in
                            Rectangle().fill(Color(.line)).frame(height: 1)
                            ExerciseRow(exercise: exercise, custom: nil, scale: scale) {
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
            ExerciseDetailView(
                exercise: exercise, custom: dependencies.customExercises.record(withID: exercise.id),
                dependencies: dependencies
            )
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView(dependencies: dependencies)
        }
        .sheet(isPresented: $isAddingExercise) {
            NewExerciseView { dependencies.customExercises.add($0) }
        }
        .fullScreenCover(item: $session) { session in
            SessionView(viewModel: session, dependencies: dependencies) { self.session = nil }
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
    /// The saved record of a custom Exercise: its name and icon.
    let custom: CustomExerciseRecord?
    let scale: DesignScale
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if !scale.isAccessibility {
                    if let custom {
                        Image(systemName: custom.icon.symbolName)
                            .font(.system(size: 22))
                            .foregroundStyle(Color(.ring))
                            .frame(width: PatternGlyph.side, height: PatternGlyph.side)
                            .accessibilityHidden(true)
                    } else {
                        PatternGlyph(pattern: exercise.pattern)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: ExerciseText.name(of: exercise, custom: custom))
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
        .accessibilityLabel(ExerciseText.spokenRow(of: exercise, custom: custom))
        .accessibilityHint(ExerciseText.rowHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("exercises.row.\(exercise.id)")
    }
}

/// The first row of the list: a dashed ring with a plus and the text, all in `ring`. Opens the New exercise sheet.
private struct CustomExerciseRow: View {
    let scale: DesignScale
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if !scale.isAccessibility {
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        var ring = Path()
                        ring.addArc(
                            center: center,
                            radius: 17,
                            startAngle: .zero,
                            endAngle: .degrees(360),
                            clockwise: false
                        )
                        context.stroke(ring, with: .color(Color(.ring)), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        var plus = Path()
                        plus.move(to: CGPoint(x: center.x - 7, y: center.y))
                        plus.addLine(to: CGPoint(x: center.x + 7, y: center.y))
                        plus.move(to: CGPoint(x: center.x, y: center.y - 7))
                        plus.addLine(to: CGPoint(x: center.x, y: center.y + 7))
                        context.stroke(
                            plus,
                            with: .color(Color(.ring)),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                    }
                    .frame(width: PatternGlyph.side, height: PatternGlyph.side)
                    .accessibilityHidden(true)
                }
                Text("exercises.custom.row")
                    .designFont(.body, 17, weight: .semibold, lineHeight: 1.25)
                    .foregroundStyle(Color(.ring))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, scale(14, 22))
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("exercises.custom.hint"))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("exercises.customRow")
    }
}
