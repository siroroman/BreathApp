/// A breathing technique: a fixed text ID, a Pattern and its Duration options.
///
/// Holds no text (ADR-0001): the app looks up names and descriptions by `id`.
public struct Exercise: Sendable, Hashable, Identifiable {
    public let id: String
    public let pattern: Pattern
    /// The Session lengths offered for this Exercise.
    public let durationOptions: [Duration]
    /// The one of `durationOptions` that is selected first.
    public let defaultDuration: Duration
}

public extension Exercise {
    /// The four built-in Exercises in the order the Exercises list shows them.
    static let builtIn: [Exercise] = [box, fourSevenEight, coherent, physiologicalSigh]

    static let box = Exercise(
        id: "box",
        pattern: Pattern(validated: [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(4)),
            Phase(kind: .exhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(4)),
        ]),
        durationOptions: [.seconds(60), .seconds(180), .seconds(300), .seconds(600)],
        defaultDuration: .seconds(300)
    )

    /// Its options are 4, 6 and 8 Cycles, so a beginner is never offered a longer Session.
    static let fourSevenEight = Exercise(
        id: "four-seven-eight",
        pattern: Pattern(validated: [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(7)),
            Phase(kind: .exhale, duration: .seconds(8)),
        ]),
        durationOptions: [.seconds(75), .seconds(120), .seconds(150)],
        defaultDuration: .seconds(75)
    )

    static let coherent = Exercise(
        id: "coherent",
        pattern: Pattern(validated: [
            Phase(kind: .inhale, duration: .seconds(5.5)),
            Phase(kind: .exhale, duration: .seconds(5.5)),
        ]),
        durationOptions: [.seconds(60), .seconds(300), .seconds(600), .seconds(1200)],
        defaultDuration: .seconds(300)
    )

    /// Two inhales in a row, then one long exhale.
    static let physiologicalSigh = Exercise(
        id: "physiological-sigh",
        pattern: Pattern(validated: [
            Phase(kind: .inhale, duration: .seconds(2)),
            Phase(kind: .inhale, duration: .seconds(1)),
            Phase(kind: .exhale, duration: .seconds(6)),
        ]),
        durationOptions: [.seconds(60), .seconds(300), .seconds(600)],
        defaultDuration: .seconds(300)
    )
}
