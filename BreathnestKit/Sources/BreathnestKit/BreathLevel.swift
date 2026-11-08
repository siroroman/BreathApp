import Foundation

public extension Pattern {
    /// How full the lungs are, from 0 (empty) to 1 (full), at `position` into one Cycle.
    ///
    /// Inhale rises and exhale falls on a sine ease-in-out. A run of Phases of the same kind
    /// is one curve across the whole run. A `position` outside the Cycle is clamped to it.
    /// The Session engine decides the level in the Lead-in and after the end (0); it does not ask here.
    func breathLevel(at position: Duration) -> Double {
        let seconds = min(max(position.seconds, 0), cycleLength.seconds)
        let run = run(containing: seconds)
        let fraction = (seconds - run.start) / (run.end - run.start)
        switch run.kind {
        case .inhale: return ease(fraction)
        case .exhale: return 1 - ease(fraction)
        case .hold, .rest: return 0
        }
    }
}

private struct Run {
    let kind: PhaseKind
    let start: Double
    let end: Double
}

private extension Pattern {
    /// The run of same-kind Phases that holds `seconds`; on a boundary, the run that ends there.
    func run(containing seconds: Double) -> Run {
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
        return runs.first { seconds <= $0.end } ?? runs[runs.count - 1]
    }
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
