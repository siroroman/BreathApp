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

Anything that depends on time takes a `Clock` from the caller (`some Clock<Duration>`). Never call `Date()`, `ContinuousClock()` or `Task.sleep` inside logic: `make lint` fails on them in `BreathnestKit/Sources` (rule `time_from_injected_clock` in `.swiftlint.yml`). Tests pass a manual test clock they advance by hand, so a 10 minute Session runs in microseconds and there is no flakiness and no `sleep` in a test. The app injects `ContinuousClock` at the edge.

## Coverage

`make coverage` runs the Kit tests with code coverage and prints the line coverage of every file in `BreathnestKit/Sources` and the total. The `Kit tests` job in CI does the same, shows the table in the job summary of the run and fails when a file or the total is under the floor. Test files and `Support/` are not counted, the App target is not measured.

- Read it per file, not only the total: a new file with a low percentage means a path no test runs (pause, resume, an error case).
- The floor is 80% line coverage, per file and for the total. `scripts/coverage.sh` hands the table to `scripts/check-coverage.sh`, which names every line under the floor on stderr and fails (the job summary lists them under the table). A file with no lines is skipped.
- A failure means a path no test runs. Write the test for it, do not lower the floor to pass. The number is `floor=` at the top of `scripts/check-coverage.sh`; changing it is a change of a guardrail ([guardrail paths](guardrail-paths.md)): say why in the pull request and write the reason here.
- 100% does not mean the behaviour is checked, only that every line ran. Write the test for the behaviour first ([TDD loop](#tdd-loop)), then look at the number.

## Reading failures

`make test-kit` prints the failing `#expect` with both values. `make test-app` prints the errors through `xcbeautify`. For the full log, run `xcodebuild` without the pipe (`make -n test-app` shows the exact command).
