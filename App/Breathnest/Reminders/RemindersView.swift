import BreathnestKit
import SwiftUI

/// Screen 11 of the design: the Reminder section. The intro, the Reminders, the Add reminder row and the footnote. It
/// is the content of the Reminder segment of the Stats tab; it scrolls on its own.
struct RemindersView: View {
    let dependencies: AppDependencies

    @State private var isAdding = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    private var model: RemindersViewModel { dependencies.reminders }

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        VStack(alignment: .leading, spacing: 16) {
                Text("reminders.intro")
                    .designFont(.subheadline, 15)
                    .foregroundStyle(Color(.fg2))
                    .padding(.horizontal, 4)
                if model.permission == .denied { deniedNotice }
                if !model.reminders.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(model.reminders.enumerated()), id: \.element.id) { index, reminder in
                            if index > 0 { Rectangle().fill(Color(.line)).frame(height: 1) }
                            ReminderRow(reminder: reminder, scale: scale, dependencies: dependencies)
                        }
                    }
                    .background(Color(.surface))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                addRow(scale: scale)
                Text("reminders.footnote")
                    .designFont(.footnote, 13)
                    .foregroundStyle(Color(.fg2))
                    .padding(.horizontal, 4)
                    .accessibilityIdentifier("reminders.footnote")
        }
        .task { await model.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.start() } }
        }
        .sheet(isPresented: $isAdding) {
            NewReminderView(dependencies: dependencies) { time, exerciseID, weekdays in
                await model.add(hour: time.hour, minute: time.minute, weekdays: weekdays, exerciseID: exerciseID)
            }
        }
    }

    private var deniedNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("reminders.denied.message")
                .designFont(.subheadline, 15)
                .foregroundStyle(Color(.fg))
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                Text("reminders.denied.open")
                    .designFont(.body, 17, weight: .semibold)
                    .foregroundStyle(Color(.ring))
                    .frame(minHeight: 44, alignment: .leading)
            }
            .accessibilityIdentifier("reminders.openSettingsButton")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.surface))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityIdentifier("reminders.deniedNotice")
    }

    private func addRow(scale: DesignScale) -> some View {
        Button { isAdding = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus").font(.system(size: 22)).accessibilityHidden(true)
                Text("reminders.add")
                    .designFont(.body, 17, weight: .semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(Color(.ring))
            .padding(.horizontal, 16)
            .frame(minHeight: scale(52, 88))
            .background(Color(.surface))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("reminders.addRow")
    }
}

/// One Reminder: the time and Exercise with the switch, and the seven day circles under them.
private struct ReminderRow: View {
    let reminder: Reminder
    let scale: DesignScale
    let dependencies: AppDependencies

    var body: some View {
        let name = exerciseName
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: ReminderText.time(hour: reminder.hour, minute: reminder.minute))
                        .designFont(.title, 26, weight: .semibold)
                        .monospacedDigit()
                        .foregroundStyle(Color(reminder.isEnabled ? .fg : .fg2))
                        .accessibilityIdentifier("reminders.time.\(reminder.id)")
                    Text(verbatim: name)
                        .designFont(.footnote, 14)
                        .foregroundStyle(Color(.fg2))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
                Toggle("", isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { value in Task { await dependencies.reminders.setEnabled(value, for: reminder.id) } }
                ))
                .labelsHidden()
                .accessibilityLabel(ReminderText.switchLabel(reminder, exerciseName: name))
                .accessibilityIdentifier("reminders.switch.\(reminder.id)")
            }
            DayCircles(weekdays: reminder.weekdays, scale: scale)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(ReminderText.spokenDays(reminder.weekdays))
                .accessibilityIdentifier("reminders.days.\(reminder.id)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(reminder.isEnabled ? 1 : 0.75)
    }

    private var exerciseName: String {
        if let builtIn = Exercise.builtIn.first(where: { $0.id == reminder.exerciseID }) {
            return ExerciseText.name(of: builtIn)
        }
        return dependencies.customExercises.record(withID: reminder.exerciseID)?.name
            ?? String(localized: "reminders.exercise.missing")
    }
}

/// The seven small circles M to S of a Reminder: chosen days filled, the others a ring.
private struct DayCircles: View {
    let weekdays: Set<Int>
    let scale: DesignScale

    var body: some View {
        let side = scale(30, 64)
        let circles = ForEach(Reminder.displayOrder, id: \.self) { day in
            let isChosen = weekdays.contains(day)
            Text(verbatim: ReminderText.letter(of: day))
                .designFont(.footnote, 12, weight: isChosen ? .bold : .medium)
                .foregroundStyle(Color(isChosen ? .bg : .fg2))
                .frame(width: side, height: side)
                .background(Circle().fill(isChosen ? Color(.fg) : .clear))
                .overlay(Circle().strokeBorder(Color(.outline), lineWidth: isChosen ? 0 : 1.5))
        }
        // At accessibility sizes the circles wrap onto a second row instead of touching.
        if scale.isAccessibility {
            WrappingLayout(spacing: 8) { circles }
        } else {
            HStack(spacing: 8) { circles }
        }
    }
}
