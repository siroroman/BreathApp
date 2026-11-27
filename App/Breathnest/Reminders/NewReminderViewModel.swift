import BreathnestKit
import Foundation
import Observation

/// The draft of the New reminder sheet: the time, the Exercise and the days. Starts as the design draws it, 7:30 AM,
/// Coherent breathing, Monday to Friday.
@MainActor
@Observable
final class NewReminderViewModel {
    var time: Date
    var exerciseID: Exercise.ID
    private(set) var weekdays: Set<Int> = [2, 3, 4, 5, 6]
    @ObservationIgnored private let calendar: Calendar

    init(calendar: Calendar = .current, exerciseID: Exercise.ID = Exercise.coherent.id) {
        self.calendar = calendar
        self.exerciseID = exerciseID
        time = calendar.date(from: DateComponents(hour: 7, minute: 30)) ?? .now
    }

    var hour: Int { calendar.component(.hour, from: time) }
    var minute: Int { calendar.component(.minute, from: time) }
    var summary: WeekdaySummary { Reminder.summary(of: weekdays) }
    var canAdd: Bool { !weekdays.isEmpty }

    func toggle(_ weekday: Int) {
        if weekdays.contains(weekday) { weekdays.remove(weekday) } else { weekdays.insert(weekday) }
    }
}
