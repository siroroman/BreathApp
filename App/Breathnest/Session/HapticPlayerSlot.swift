import os

/// Counts the players a slot has held, so a stop that arrives late can tell whether it is still about the current
/// one.
final class PlayerGeneration: Sendable {
    private let value = OSAllocatedUnfairLock(initialState: 0)

    var current: Int { value.withLock { $0 } }

    func advance() { value.withLock { $0 += 1 } }

    func isCurrent(_ generation: Int) -> Bool { current == generation }
}

/// Holds the player an engine is playing. The engine reports a stop off the main thread and the main actor hears of
/// it later: a new player may have started in between, and that stop must not clear it. `stopReported()` is called
/// when the engine reports, and the closure it returns runs on the main actor later.
@MainActor
final class HapticPlayerSlot<Player> {
    private(set) var player: Player?
    private let generation = PlayerGeneration()

    func hold(_ player: Player) {
        generation.advance()
        self.player = player
    }

    /// Empties the slot and hands the player back, so the caller can stop it.
    func release() -> Player? {
        generation.advance()
        defer { player = nil }
        return player
    }

    /// Call it when the engine reports a stop, on any thread. The returned closure clears the slot, unless a player
    /// was held or released after this call.
    nonisolated func stopReported() -> @MainActor () -> Void {
        let stopped = generation.current
        return { [weak self] in
            guard let self, generation.isCurrent(stopped) else { return }
            player = nil
        }
    }
}
