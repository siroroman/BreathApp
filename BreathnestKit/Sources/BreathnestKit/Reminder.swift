import Foundation

/// One Reminder as it is saved (ADR 0003): a wall-clock time with no zone, the days it repeats on and the Exercise
/// it opens. Days are calendar weekday numbers, 1 is Sunday, so the week start never changes what is stored.
public struct Reminder: Sendable, Hashable, Codable, Identifiable {
    public let id: String
    public let hour: Int
    public let minute: Int
    public let weekdays: Set<Int>
    public let exerciseID: String
    public var isEnabled: Bool

    /// The week as the screens draw it: Monday first.
    public static let displayOrder = [2, 3, 4, 5, 6, 7, 1]

    /// Returns `nil` for a time outside 00:00 to 23:59, a day outside 1 to 7 or no day at all.
    public init?(id: String = UUID().uuidString, hour: Int, minute: Int, weekdays: Set<Int>, exerciseID: String,
                 isEnabled: Bool)
    {
        guard (0 ... 23).contains(hour), (0 ... 59).contains(minute),
              !weekdays.isEmpty, weekdays.allSatisfy({ (1 ... 7).contains($0) })
        else { return nil }
        self.id = id
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.exerciseID = exerciseID
        self.isEnabled = isEnabled
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard let reminder = try Reminder(
            id: values.decode(String.self, forKey: .id),
            hour: values.decode(Int.self, forKey: .hour),
            minute: values.decode(Int.self, forKey: .minute),
            weekdays: Set(values.decode([Int].self, forKey: .weekdays)),
            exerciseID: values.decode(String.self, forKey: .exerciseID),
            isEnabled: values.decode(Bool.self, forKey: .isEnabled)
        ) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Out of range"))
        }
        self = reminder
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(hour, forKey: .hour)
        try container.encode(minute, forKey: .minute)
        try container.encode(weekdays.sorted(), forKey: .weekdays)
        try container.encode(exerciseID, forKey: .exerciseID)
        try container.encode(isEnabled, forKey: .isEnabled)
    }

    private enum CodingKeys: String, CodingKey {
        case id, hour, minute, weekdays, exerciseID, isEnabled
    }

    /// The chosen days in the words the Repeat row uses.
    public var weekdaySummary: WeekdaySummary {
        Self.summary(of: weekdays)
    }

    public static func summary(of weekdays: Set<Int>) -> WeekdaySummary {
        if weekdays.count == 7 { return .everyDay }
        if weekdays == [2, 3, 4, 5, 6] { return .weekdays }
        if weekdays == [1, 7] { return .weekends }
        return .days(displayOrder.filter(weekdays.contains))
    }
}

/// What the Repeat row says. `days` are calendar weekday numbers, Monday first. The app writes the words.
public enum WeekdaySummary: Sendable, Hashable {
    case everyDay, weekdays, weekends
    case days([Int])
}

/// The saved document of `reminders.json` (ADR 0003): `{"version": 1, "items": [...]}`. A Reminder that cannot be
/// read is dropped, the rest is kept (rule F4).
public struct RemindersDocument: StoredDocument {
    public var items: [Reminder]

    public init(items: [Reminder]) {
        self.items = items
    }

    public static let defaultValue = RemindersDocument(items: [])
    public static let currentVersion = 1

    private enum CodingKeys: String, CodingKey { case version, items }

    private struct Lossy: Decodable {
        let reminder: Reminder?
        init(from decoder: any Decoder) throws {
            reminder = try? Reminder(from: decoder)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([Lossy].self, forKey: .items).compactMap(\.reminder)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentVersion, forKey: .version)
        try container.encode(items, forKey: .items)
    }
}
