import Testing

@testable import BreathnestKit

@Suite struct BreathLevelTests {
    @Test func inhaleRunsFromEmptyToFullAndExhaleBack() {
        let pattern = Exercise.coherent.pattern
        #expect(pattern.breathLevel(at: .zero) == 0)
        #expect(pattern.breathLevel(at: .seconds(5.5)) == 1)
        #expect(pattern.breathLevel(at: .seconds(11)) == 0)
    }

    @Test func inhaleRisesAndExhaleFallsStepByStep() {
        let pattern = Exercise.coherent.pattern
        let levels = (0 ... 220).map { pattern.breathLevel(at: .seconds(Double($0) * 0.05)) }
        #expect(zip(levels[0 ... 110], levels[1 ... 110]).allSatisfy { $0 < $1 })
        #expect(zip(levels[110 ... 219], levels[111 ... 220]).allSatisfy { $0 > $1 })
    }

    @Test func holdKeepsTheLevelItStartedAt() {
        let box = Exercise.box.pattern
        // Box: inhale 0-4, hold 4-8 (full), exhale 8-12, hold 12-16 (empty).
        #expect([4.0, 5, 6.5, 8].allSatisfy { box.breathLevel(at: .seconds($0)) == 1 })
        #expect([12.0, 13, 14.5, 16].allSatisfy { box.breathLevel(at: .seconds($0)) == 0 })
    }

    @Test func restKeepsTheLevelItStartedAt() throws {
        let pattern = try #require(Pattern(phases: [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .exhale, duration: .seconds(4)),
            Phase(kind: .rest, duration: .seconds(2)),
        ]))
        #expect([8.0, 9, 10].allSatisfy { pattern.breathLevel(at: .seconds($0)) == 0 })
    }

    @Test func holdAfterTheWholeCycleStartsFromTheLastPhaseOfTheCycleBefore() throws {
        let pattern = try #require(Pattern(phases: [
            Phase(kind: .hold, duration: .seconds(2)),
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .exhale, duration: .seconds(4)),
        ]))
        #expect(pattern.breathLevel(at: .seconds(1)) == 0)
    }

    @Test(arguments: Exercise.builtIn)
    func levelIsContinuousAtEveryPhaseBoundary(exercise: Exercise) {
        let pattern = exercise.pattern
        let step = 1e-6
        var boundary = 0.0
        for phase in pattern.phases {
            boundary += phase.duration / .seconds(1)
            let before = pattern.breathLevel(at: .seconds(boundary - step))
            let after = pattern.breathLevel(at: .seconds(boundary + step))
            #expect(abs(after - before) < 1e-5, "\(exercise.id) jumps at \(boundary) s")
        }
        // The Cycle ends where the next one starts.
        #expect(abs(pattern.breathLevel(at: pattern.cycleLength) - pattern.breathLevel(at: .zero)) < 1e-12)
    }

    @Test func physiologicalSighInhalesAreOneCurve() {
        let sigh = Exercise.physiologicalSigh.pattern
        // Inhale 0-2 s and 2-3 s: one ease over 3 s, so 2 s in is 2/3 of the way: (1 - cos(2π/3)) / 2 = 0.75.
        #expect(abs(sigh.breathLevel(at: .seconds(2)) - 0.75) < 1e-12)
        #expect(sigh.breathLevel(at: .seconds(3)) == 1)
    }

    @Test func physiologicalSighDoesNotStallBetweenItsInhales() {
        let sigh = Exercise.physiologicalSigh.pattern
        let levels = (190 ... 210).map { sigh.breathLevel(at: .seconds(Double($0) * 0.01)) }
        #expect(zip(levels, levels.dropFirst()).allSatisfy { $1 - $0 > 0.0003 })
    }

    @Test func endsAreEasedNotLinear() {
        let pattern = Exercise.coherent.pattern
        // Linear would be 0.1 / 5.5 = 0.018 after 0.1 s; an ease-in-out has barely left 0.
        #expect(pattern.breathLevel(at: .seconds(0.1)) < 0.002)
        #expect(pattern.breathLevel(at: .seconds(5.4)) > 0.998)
        #expect(pattern.breathLevel(at: .seconds(5.6)) > 0.998)
        #expect(pattern.breathLevel(at: .seconds(10.9)) < 0.002)
    }
}
