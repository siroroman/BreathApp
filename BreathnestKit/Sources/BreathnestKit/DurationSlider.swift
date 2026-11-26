public extension Exercise {
    /// The lengths the Duration slider steps through, shortest first.
    ///
    /// Every Exercise but 4-7-8 slides from 1 to 60 minutes in whole minutes. 4-7-8 slides in Cycle steps, limited
    /// to its shortest and longest chip (1:15 to 2:30, 4 to 8 Cycles), so a beginner is never offered a longer
    /// Session (#53, proposal for design point 6).
    var sliderDurations: [Duration] {
        if id == Exercise.fourSevenEight.id, let shortest = durationOptions.min(), let longest = durationOptions.max() {
            let first = sessionLength(for: shortest).cycleCount
            let last = sessionLength(for: longest).cycleCount
            // The ends are the chips' own lengths, so the slider and the chips read the same at 1:15 and 2:30.
            return (first ... last).map { count in
                count == first ? shortest : count == last ? longest : pattern.cycleLength * count
            }
        }
        return (1 ... 60).map { .seconds($0 * 60) }
    }
}
