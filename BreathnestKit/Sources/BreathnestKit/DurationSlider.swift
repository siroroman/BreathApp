public extension Exercise {
    /// The lengths the Duration slider steps through, shortest first.
    ///
    /// Every Exercise but 4-7-8 slides from 1 to 60 minutes in whole minutes. 4-7-8 slides only through 4 to 8
    /// Cycles, the range its chips offer, so a beginner is never offered a longer Session (#53).
    var sliderDurations: [Duration] {
        if id == Exercise.fourSevenEight.id {
            return (4 ... 8).map { pattern.cycleLength * $0 }
        }
        return (1 ... 60).map { .seconds($0 * 60) }
    }
}
