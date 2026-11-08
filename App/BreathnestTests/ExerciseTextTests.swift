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
}
