---
status: accepted
---

# Domain logic lives in a UI-free Swift package

The Session engine, the Exercise data and the pure feel logic (Breath level and Haptic plan) live in a local Swift package, `BreathnestKit`, that imports only the Swift standard library and Foundation. The app target keeps everything that touches the system: the ticker, Core Haptics, drawing, keeping the screen awake and noticing that the app left the foreground. This looks heavy for an app with three screens, but it lets `swift test` cover the timing and the feel numbers in seconds without a simulator, keeps AFK tickets in the cloud testable, and leaves the logic reusable for the Apple Watch later.

Decided in [#12](https://github.com/siroroman/BreathApp/issues/12), amended by [#19](https://github.com/siroroman/BreathApp/issues/19) and [#20](https://github.com/siroroman/BreathApp/issues/20).

## Considered options

- **Everything in the app target.** Simplest, but the engine could only be tested through a simulator build, and the Watch would need the logic pulled out later anyway.

## Consequences

- **No text in the Kit.** `Exercise` carries its fixed ID, Pattern and Duration options. Names, Phase names and spoken strings are looked up in the String Catalog by the app.
- **Feel numbers are Kit data.** The Breath level curve is a pure function and the Haptic plan is plain data, both tested by `swift test`, although a Watch would play its own haptics. The Watch can ignore the plan and reuse the level curve. A thin adapter in the app turns the plan into `CHHapticPattern`.
- **Wiring.** `BreathnestKit/` is a local package (`Package.swift`) that the app target depends on through `project.yml`. `make test-kit` runs `swift test` on it without a simulator, which is the inner loop of every Kit ticket. The Kit declares iOS, macOS and watchOS 26 as platforms so the Watch can reuse it.
