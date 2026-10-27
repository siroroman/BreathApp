// PROTOTYPE (issue #13). Throwaway: no tests, no error handling, not for production.
import Foundation

enum PhaseKind: String, CaseIterable, Identifiable {
    case inhale, hold, exhale, rest
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct Phase {
    var kind: PhaseKind
    var seconds: Double
}

/// One Phase placed on the Cycle timeline. Consecutive inhales (or exhales) form a "run":
/// the circle level moves through the whole run with ONE curve, so a double inhale
/// does not stall in the middle.
struct Span {
    let index: Int
    let kind: PhaseKind
    let t0: Double
    let seconds: Double
    let runT0: Double
    let runSeconds: Double
    let runFrom: Double
    let runTo: Double
}

struct Pattern: Identifiable {
    let id: String
    let name: String
    let phases: [Phase]
    let spans: [Span]
    let cycleSeconds: Double

    init(id: String, name: String, phases: [Phase]) {
        self.id = id
        self.name = name
        self.phases = phases
        var spans: [Span] = []
        var t = 0.0, level = 0.0, i = 0
        while i < phases.count {
            let kind = phases[i].kind
            if kind == .inhale || kind == .exhale {
                var j = i, total = 0.0
                while j < phases.count, phases[j].kind == kind { total += phases[j].seconds; j += 1 }
                let target = kind == .inhale ? 1.0 : 0.0
                let runT0 = t
                for k in i..<j {
                    spans.append(Span(index: k, kind: kind, t0: t, seconds: phases[k].seconds,
                                      runT0: runT0, runSeconds: total, runFrom: level, runTo: target))
                    t += phases[k].seconds
                }
                level = target
                i = j
            } else {
                spans.append(Span(index: i, kind: kind, t0: t, seconds: phases[i].seconds,
                                  runT0: t, runSeconds: phases[i].seconds, runFrom: level, runTo: level))
                t += phases[i].seconds
                i += 1
            }
        }
        self.spans = spans
        self.cycleSeconds = t
    }

    func spanIndex(at cycleT: Double) -> Int {
        for s in spans where cycleT < s.t0 + s.seconds { return s.index }
        return spans.count - 1
    }

    /// Circle level 0...1 (0 = empty lungs, 1 = full) at a time within the Cycle.
    func level(at cycleT: Double, inhale: Curve, exhale: Curve) -> Double {
        let s = spans[spanIndex(at: cycleT)]
        if s.runFrom == s.runTo { return s.runFrom }
        let u = min(max((cycleT - s.runT0) / s.runSeconds, 0), 1)
        let curve = s.kind == .inhale ? inhale : exhale
        return s.runFrom + (s.runTo - s.runFrom) * curve.apply(u)
    }
}

enum Patterns {
    static let all: [Pattern] = [
        Pattern(id: "box", name: "Box 4·4·4·4 (hold, hold)", phases: [
            Phase(kind: .inhale, seconds: 4), Phase(kind: .hold, seconds: 4),
            Phase(kind: .exhale, seconds: 4), Phase(kind: .hold, seconds: 4)]),
        Pattern(id: "box-rest", name: "Box 4·4·4·4 (hold, rest)", phases: [
            Phase(kind: .inhale, seconds: 4), Phase(kind: .hold, seconds: 4),
            Phase(kind: .exhale, seconds: 4), Phase(kind: .rest, seconds: 4)]),
        Pattern(id: "478", name: "4-7-8", phases: [
            Phase(kind: .inhale, seconds: 4), Phase(kind: .hold, seconds: 7),
            Phase(kind: .exhale, seconds: 8)]),
        Pattern(id: "coherent", name: "Coherent 5.5·5.5", phases: [
            Phase(kind: .inhale, seconds: 5.5), Phase(kind: .exhale, seconds: 5.5)]),
        Pattern(id: "sigh", name: "Sigh 2+1·6 (double inhale)", phases: [
            Phase(kind: .inhale, seconds: 2), Phase(kind: .inhale, seconds: 1),
            Phase(kind: .exhale, seconds: 6)]),
        Pattern(id: "calm-rest", name: "Calm 4·6·rest 2", phases: [
            Phase(kind: .inhale, seconds: 4), Phase(kind: .exhale, seconds: 6),
            Phase(kind: .rest, seconds: 2)]),
    ]
}
