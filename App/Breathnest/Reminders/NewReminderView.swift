import BreathnestKit
import SwiftUI

/// Screen 12 of the design: the New reminder sheet. Time on the system wheel, the Exercise in a menu, the Repeat days
/// and the Add reminder button. `add` returns `false` when nothing was saved (the permission is denied), and the
/// sheet then closes so the Reminder screen can explain it.
struct NewReminderView: View {
    let dependencies: AppDependencies
    let add: (_ time: (hour: Int, minute: Int), _ exerciseID: String, _ weekdays: Set<Int>) async -> Bool

    @State private var viewModel = NewReminderViewModel()
    /// True from the first tap on Add reminder, so a second tap cannot save another Reminder.
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    private var exercises: [Exercise] {
        dependencies.customExercises.exercises + Exercise.builtIn
    }

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Button { dismiss() } label: {
                    Text("common.cancel")
                        .designFont(.body, 17, weight: .medium)
                        .foregroundStyle(Color(.ring))
                        .frame(minHeight: 44, alignment: .leading)
                }
                .accessibilityIdentifier("newReminder.cancelButton")
                Text("newReminder.title")
                    .designFont(.title, 30, weight: .bold, tracking: -0.02, lineHeight: 1.15)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("newReminder.title")
                timeSection(scale: scale)
                exerciseRow(scale: scale)
                repeatSection(scale: scale)
                Text("newReminder.footnote")
                    .designFont(.footnote, 13)
                    .foregroundStyle(Color(.fg2))
                    .padding(.horizontal, 4)
                addButton(scale: scale)
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .foregroundStyle(Color(.fg))
        .background(Color(.bg))
        .presentationDetents([.large])
        .presentationCornerRadius(38)
        .presentationBackground(Color(.bg))
    }

    private func label(_ key: LocalizedStringKey) -> some View {
        Text(key).designFont(.subheadline, 15, weight: .semibold).foregroundStyle(Color(.fg2))
    }

    private func timeSection(scale: DesignScale) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                label("newReminder.time")
                Spacer(minLength: 8)
                Text(verbatim: ReminderText.time(hour: viewModel.hour, minute: viewModel.minute))
                    .designFont(.subheadline, 15, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color(.fg2))
                    .accessibilityIdentifier("newReminder.timeValue")
            }
            DatePicker("newReminder.time", selection: $viewModel.time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: scale(190, 380))
                .clipped()
                .background(Color(.surface))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityIdentifier("newReminder.timePicker")
        }
    }

    private func exerciseRow(scale: DesignScale) -> some View {
        let selected = exercises.first { $0.id == viewModel.exerciseID } ?? .coherent
        return Menu {
            ForEach(exercises) { exercise in
                Button {
                    viewModel.exerciseID = exercise.id
                } label: {
                    let name = ExerciseText.name(of: exercise, custom: dependencies.customExercises
                        .record(withID: exercise.id))
                    if exercise.id == viewModel.exerciseID {
                        Label(name, systemImage: "checkmark")
                    } else {
                        Text(verbatim: name)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("newReminder.exercise")
                    .designFont(.body, 17, weight: .medium)
                    .foregroundStyle(Color(.fg))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: ExerciseText.name(
                    of: selected, custom: dependencies.customExercises.record(withID: selected.id)
                ))
                .designFont(.body, 17)
                .foregroundStyle(Color(.fg2))
                .accessibilityIdentifier("newReminder.exerciseValue")
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.fg2))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: scale(52, 88))
            .background(Color(.surface))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityIdentifier("newReminder.exerciseRow")
    }

    private func repeatSection(scale: DesignScale) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                label("newReminder.repeat")
                Spacer(minLength: 8)
                Text(verbatim: ReminderText.summary(viewModel.summary))
                    .designFont(.subheadline, 15, weight: .semibold)
                    .foregroundStyle(Color(.fg2))
                    .accessibilityIdentifier("newReminder.repeatSummary")
            }
            let side = scale(44, 88)
            let circles = ForEach(Reminder.displayOrder, id: \.self) { day in
                let isOn = viewModel.weekdays.contains(day)
                Button { viewModel.toggle(day) } label: {
                    Text(verbatim: ReminderText.letter(of: day))
                        .designFont(.body, 17, weight: isOn ? .bold : .medium)
                        .foregroundStyle(Color(isOn ? .bg : .fg2))
                        .frame(width: side, height: side)
                        .background(Circle().fill(isOn ? Color(.fg) : .clear))
                        .overlay(Circle().strokeBorder(
                            Color(.outline), style: StrokeStyle(lineWidth: 2, dash: isOn ? [] : [3, 3])
                        ).opacity(isOn ? 0 : 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ReminderText.dayName(of: day))
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("newReminder.day.\(day)")
            }
            if scale.isAccessibility {
                WrappingLayout(spacing: 8) { circles }
            } else {
                HStack { circles.frame(maxWidth: .infinity) }
            }
        }
    }

    private func addButton(scale: DesignScale) -> some View {
        Button {
            guard !isSaving else { return }
            isSaving = true
            Task {
                _ = await add((viewModel.hour, viewModel.minute), viewModel.exerciseID, viewModel.weekdays)
                dismiss()
            }
        } label: {
            Text("newReminder.add")
                .designFont(.title3, 19, weight: .semibold)
                .foregroundStyle(Color(.bg))
                .frame(maxWidth: .infinity, minHeight: scale(54, 96))
                .background(Capsule().fill(Color(.fg)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAdd || isSaving)
        .opacity(viewModel.canAdd && !isSaving ? 1 : 0.4)
        .padding(.top, 8)
        .accessibilityIdentifier("newReminder.addButton")
    }
}
