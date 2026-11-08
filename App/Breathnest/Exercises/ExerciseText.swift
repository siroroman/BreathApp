import BreathnestKit
import Foundation

/// The text of the Exercises screens, built from the String Catalog and the Kit's numbers. The ViewModels hold
/// none of it (ADR 0002). Functions that format numbers take the locale so a test can name it.
enum ExerciseText {
    static func name(of exercise: Exercise) -> String {
        Bundle.main.localizedString(forKey: "exercise.\(exercise.id).name", value: nil, table: nil)
    }

    static func description(of exercise: Exercise) -> String {
        Bundle.main.localizedString(forKey: "exercise.\(exercise.id).description", value: nil, table: nil)
    }

    static func phaseName(_ kind: PhaseKind) -> String {
        switch kind {
        case .inhale: String(localized: "phase.inhale")
        case .hold: String(localized: "phase.hold")
        case .exhale: String(localized: "phase.exhale")
        case .rest: String(localized: "phase.rest")
        }
    }

    /// The Pattern as plain numbers: `4 · 7 · 8`.
    static func patternNumbers(_ pattern: Pattern, locale: Locale = .current) -> String {
        pattern.phases.map { seconds($0.duration, locale: locale) }.joined(separator: separator)
    }

    /// The Pattern with Phase names: `Inhale 4 · Hold 7 · Exhale 8`.
    static func patternWithNames(_ pattern: Pattern, locale: Locale = .current) -> String {
        pattern.phases.map { phase in
            let name = phaseName(phase.kind)
            let number = seconds(phase.duration, locale: locale)
            return String(localized: "detail.pattern.phase \(name) \(number)")
        }.joined(separator: separator)
    }

    /// What VoiceOver reads for a row: `Box breathing, inhale 4 seconds, hold 4 seconds, ...`.
    static func spokenRow(of exercise: Exercise, locale: Locale = .current) -> String {
        let phases = exercise.pattern.phases.map { phase in
            let spoken = spokenSeconds(phase.duration, locale: locale)
            return switch phase.kind {
            case .inhale: String(localized: "a11y.phase.inhale \(spoken)")
            case .hold: String(localized: "a11y.phase.hold \(spoken)")
            case .exhale: String(localized: "a11y.phase.exhale \(spoken)")
            case .rest: String(localized: "a11y.phase.rest \(spoken)")
            }
        }
        return ([name(of: exercise)] + phases).joined(separator: ", ")
    }

    /// `m:ss`, the form the result line and the 4-7-8 chips use.
    static func clock(_ duration: Duration) -> String {
        let total = Int((duration / .seconds(1)).rounded())
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }

    /// A Duration option as a chip or the Duration value: `5 min`, or `1:15` when the Exercise has options that
    /// are not whole minutes.
    static func option(_ duration: Duration, wholeMinutes: Bool) -> String {
        if wholeMinutes {
            let minutes = Int((duration / .seconds(60)).rounded())
            return String(localized: "duration.minutes \(minutes)")
        }
        return clock(duration)
    }

    /// `19 Cycles · 5:04`.
    static func result(_ length: SessionLength) -> String {
        let cycles = length.cycleCount
        let total = clock(length.totalLength)
        return String(localized: "detail.result \(cycles) \(total)")
    }

    static func spokenSeconds(_ duration: Duration, locale: Locale = .current) -> String {
        Measurement(value: duration / .seconds(1), unit: UnitDuration.seconds)
            .formatted(.measurement(width: .wide, usage: .asProvided).locale(locale))
    }

    /// `5 minutes`, `1 minute, 15 seconds`.
    static func spokenLength(_ duration: Duration, locale: Locale = .current) -> String {
        duration.formatted(.units(allowed: [.minutes, .seconds], width: .wide).locale(locale))
    }

    private static let separator = " · "

    private static func seconds(_ duration: Duration, locale: Locale) -> String {
        (duration / .seconds(1)).formatted(.number.precision(.fractionLength(0 ... 1)).locale(locale))
    }
}
