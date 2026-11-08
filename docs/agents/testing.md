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
- **`App/BreathnestUITests/`** is the UI test target: one smoke test per screen that launches the app and runs the accessibility audit ([UI tests](#ui-tests)). Whether a screen looks right is still checked by looking at a screenshot (`make run screenshot`), see [definition of done](definition-of-done.md).

## Conventions

- Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`), not XCTest. `@testable import BreathnestKit` is fine. The one exception is the UI test target, see [UI tests](#ui-tests).
- Test names say the behaviour in glossary terms: `lastCycleEndsAfterRequestedDuration`, not `testSession1`.
- Test through the public interface of a module, not its private helpers.
- Test files mirror source files: `Sources/BreathnestKit/Foo.swift` has `Tests/BreathnestKitTests/FooTests.swift`.

## UI tests

`make test-ui` runs the `BreathnestUITests` target on the simulator with its own scheme `BreathnestUI`, so `make test` and the Stop hook do not run it. Run it by hand when a screen changes. It is not in CI yet (#35).

- **XCTest, not Swift Testing.** `XCUIApplication` and `performAccessibilityAudit()` are XCTest APIs. This is the only XCTest in the repo, `@MainActor final class <Screen>UITests: XCTestCase`.
- **Naming.** One file and one class per screen: `App/BreathnestUITests/<Screen>UITests.swift`, `ExercisesScreenUITests`. A test method starts with `test` and says the behaviour: `testChangingTheChipUpdatesTheResultLine`, not `testScreen1`. `launchApp()` (`UITestSupport.swift`) starts the app in English with US formats: a test never reads text in the language of the simulator.
- **Accessibility identifiers** are `<screen>.<element>` in lowerCamelCase, set on the view with `.accessibilityIdentifier("exercises.title")`: `session.pauseButton`, `settings.hapticsToggle`. An identifier finds an element in a test and never replaces its accessibility label, which is localized and read aloud.
- **Dynamic Type in the audit.** The audit reports "Dynamic Type font sizes are partially unsupported" for a fixed font (`.system(size:)`) and for a text style pinned with `.dynamicTypeSize(...)`. Use a text style (`.font(.body)`) and let it scale; sizes that must follow the design are layout metrics, not text.
- **What XCUITest cannot read.** An accessibility hint is not exposed, so its text is checked in an app unit test through the function that builds it (`ExerciseTextTests`).
- **The smoke test and the audit grow with each screen.** A pull request that adds a screen adds, in the same pull request, a test that launches the app, reaches the screen, checks one identifier and runs `performAccessibilityAudit()` on it. An audit issue is fixed in the view, not by excluding the issue type in the test.

## Localization catalog

User-facing strings live in `App/Breathnest/Localizable.xcstrings`. `scripts/check-catalogs.sh` (in `make lint` and `make test-catalogs`, so also in `make test`) fails on:

- a string with no translator comment, or a blank one (a string with `"shouldTranslate": false`, such as an exercise name that is never translated, needs the comment too)
- an entry or variation in the state `needs_review`, in any language
- a translation with an empty value, in any language
- a string that is missing or not translated yet in a **required language**
- a plural that lacks a category of a required language: en and de `one other`, cs and sk `one few many other`, fr and es `one many other`

Required languages are the setting `CATALOG_REQUIRED_LANGUAGES` (space separated, from `en cs sk de fr es`), default `en`. Only English is filled in today, so the other five are declared as entries in the state `new` whose value is the English text (XcodeGen reads the languages of the catalog into `knownRegions`). The value is never empty: an empty value compiles to a blank string and does not fall back to English, so the screen would show nothing in that language. The check fails on an empty value in any language. #34 changes the default in the script to all six when the translations land. Try a language early with `CATALOG_REQUIRED_LANGUAGES="en cs" make test-catalogs`. `scripts/test-check-catalogs.sh` tests the script and runs in the `Script tests` job of CI. `Safety.xcstrings` and its rule are #34's.

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
