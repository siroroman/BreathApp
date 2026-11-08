import Foundation

public extension Pattern {
    /// How full the lungs are, from 0 (empty) to 1 (full), at `position` into one Cycle.
    ///
    /// Inhale rises and exhale falls on a sine ease-in-out. A run of Phases of the same kind
    /// is one curve across the whole run. A `position` outside the Cycle is clamped to it.
    /// The Session engine decides the level in the Lead-in and after the end (0); it does not ask here.
    func breathLevel(at position: Duration) -> Double {
        let seconds = min(max(position.seconds, 0), cycleLength.seconds)
        let runs = runs
        let index = runs.firstIndex { seconds <= $0.end } ?? runs.count - 1
        let run = runs[index]
        let fraction = (seconds - run.start) / (run.end - run.start)
        switch run.kind {
        case .inhale: return ease(fraction)
        case .exhale: return 1 - ease(fraction)
        case .hold, .rest: return levelHeld(by: index, in: runs)
        }
    }
}

private struct Run {
    let kind: PhaseKind
    let start: Double
    let end: Double
}

private extension Pattern {
    /// The Phases grouped into runs of the same kind, in order.
    var runs: [Run] {
        var runs: [Run] = []
        var start = 0.0
        for phase in phases {
            let end = start + phase.duration.seconds
            if let last = runs.last, last.kind == phase.kind {
                runs[runs.count - 1] = Run(kind: last.kind, start: last.start, end: end)
            } else {
                runs.append(Run(kind: phase.kind, start: start, end: end))
            }
            start = end
        }
        return runs
    }
}

/// The level a hold or rest run keeps: where the nearest inhale or exhale before it ended, looking
/// back into the Cycle before when the Cycle starts with a hold. 0 when there is no inhale or exhale.
private func levelHeld(by index: Int, in runs: [Run]) -> Double {
    for step in 1 ..< runs.count {
        switch runs[(index - step + runs.count) % runs.count].kind {
        case .inhale: return 1
        case .exhale: return 0
        case .hold, .rest: continue
        }
    }
    return 0
}

/// Sine ease-in-out from 0 to 1.
private func ease(_ fraction: Double) -> Double {
    (1 - cos(.pi * fraction)) / 2
}

private extension Duration {
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}
