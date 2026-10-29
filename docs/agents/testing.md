# Testing

## TDD loop

Work in vertical red-green slices (`/tdd`): one failing test for one behaviour, the least code to pass it, then refactor. One commit per slice, each commit builds and passes `make test`.

```bash
make test-kit
```

That is the inner loop: `swift test` in `BreathnestKit/`, a few seconds, no simulator. Only run `make test` (adds the simulator) when you touch the app target.

## Where tests live

- **`BreathnestKit/Tests/BreathnestKitTests/`** is the default home. Everything that can be decided without UIKit, SwiftUI or the system is tested here: the Session engine, Exercise data, Breath level curve, Haptic plan.
- **`App/BreathnestTests/`** is for the thin glue only (adapters, view models that need app types). Keep it small, it is slow.
- UI checks are done by looking at a screenshot (`make run screenshot`), not by UI tests. See [definition of done](definition-of-done.md).

## Conventions

- Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`), not XCTest. `@testable import BreathnestKit` is fine.
- Test names say the behaviour in glossary terms: `lastCycleEndsAfterRequestedDuration`, not `testSession1`.
- Test through the public interface of a module, not its private helpers.
- Test files mirror source files: `Sources/BreathnestKit/Foo.swift` has `Tests/BreathnestKitTests/FooTests.swift`.

## Time

Anything that depends on time takes a `Clock` from the caller (`some Clock<Duration>`). Never call `Date()`, `ContinuousClock()` or `Task.sleep` inside logic. Tests pass a manual test clock they advance by hand, so a 10 minute Session runs in microseconds and there is no flakiness and no `sleep` in a test. The app injects `ContinuousClock` at the edge.

## Reading failures

`make test-kit` prints the failing `#expect` with both values. `make test-app` prints the errors through `xcbeautify`. For the full log, run `xcodebuild` without the pipe (`make -n test-app` shows the exact command).
