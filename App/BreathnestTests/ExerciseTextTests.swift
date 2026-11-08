import BreathnestKit
import Foundation
import Testing

@testable import Breathnest

@Suite struct ExerciseTextTests {
    private let english = Locale(identifier: "en_US")

    @Test func clockShowsMinutesAndTwoDigitSeconds() {
        #expect(ExerciseText.clock(.seconds(304)) == "5:04")
        #expect(ExerciseText.clock(.seconds(75)) == "1:15")
        #expect(ExerciseText.clock(.seconds(120)) == "2:00")
        #expect(ExerciseText.clock(.seconds(1200)) == "20:00")
    }

    @Test func patternNumbersAreJoinedWithMiddleDots() {
        #expect(ExerciseText.patternNumbers(Exercise.box.pattern, locale: english) == "4 · 4 · 4 · 4")
        #expect(ExerciseText.patternNumbers(Exercise.fourSevenEight.pattern, locale: english) == "4 · 7 · 8")
        #expect(ExerciseText.patternNumbers(Exercise.coherent.pattern, locale: english) == "5.5 · 5.5")
        #expect(ExerciseText.patternNumbers(Exercise.physiologicalSigh.pattern, locale: english) == "2 · 1 · 6")
    }

    @Test func patternNumbersFollowTheDecimalSeparatorOfTheLocale() {
        let german = Locale(identifier: "de_DE")
        #expect(ExerciseText.patternNumbers(Exercise.coherent.pattern, locale: german) == "5,5 · 5,5")
    }

    @Test func spokenSecondsUseWholeWords() {
        #expect(ExerciseText.spokenSeconds(.seconds(4), locale: english) == "4 seconds")
        #expect(ExerciseText.spokenSeconds(.seconds(1), locale: english) == "1 second")
        #expect(ExerciseText.spokenSeconds(.seconds(5.5), locale: english) == "5.5 seconds")
    }

    @Test func spokenLengthNamesMinutesAndSeconds() {
        #expect(ExerciseText.spokenLength(.seconds(300), locale: english) == "5 minutes")
        #expect(ExerciseText.spokenLength(.seconds(60), locale: english) == "1 minute")
        #expect(ExerciseText.spokenLength(.seconds(75), locale: english) == "1 minute, 15 seconds")
    }

    @Test func rowIsSpokenWithItsPhasesAndTheHintOpensDetails() {
        #expect(
            ExerciseText.spokenRow(of: .box, locale: english)
                == "Box breathing, inhale 4 seconds, hold 4 seconds, exhale 4 seconds, hold 4 seconds"
        )
        #expect(
            ExerciseText.spokenRow(of: .coherent, locale: english)
                == "Coherent breathing, inhale 5.5 seconds, exhale 5.5 seconds"
        )
        #expect(ExerciseText.rowHint == "Opens details")
    }

    @Test func resultLineReadsCyclesAndTheExactLength() {
        let length = Exercise.box.sessionLength(for: .seconds(300))
        #expect(ExerciseText.result(length) == "19 Cycles · 5:04")
        #expect(ExerciseText.result(Exercise.box.sessionLength(for: .seconds(1))) == "1 Cycle · 0:16")
    }

    @Test func optionsReadAsMinutesOrAsClock() {
        #expect(ExerciseText.option(.seconds(300), wholeMinutes: true) == "5 min")
        #expect(ExerciseText.option(.seconds(75), wholeMinutes: false) == "1:15")
        #expect(ExerciseText.option(.seconds(120), wholeMinutes: false) == "2:00")
    }
}
