---
status: accepted
---

# The apps follow MVVM over a UI-free Kit, with constructor injection and one composition root

Every screen is a SwiftUI view that reads an `@Observable` ViewModel, and the ViewModel calls pure logic in `BreathnestKit`. The Kit also declares the protocols of every seam to the system (ticker, haptics, screen awake, scene phase, notifications, stored settings); the apps own the adapters. Dependencies reach a ViewModel through its initialiser, from one composition root. This extends [ADR 0001](0001-domain-logic-in-a-ui-free-swift-package.md) and amends one point of it: the drawing and the Session ViewModel that the iPhone and the Watch share live in `BreathnestUI`, not in the app target. ADR 0001 says so too. It is decided before the first screen ticket (#28, #29) so that parallel agents do not each invent an architecture.

Decided in [#68](https://github.com/siroroman/BreathApp/issues/68), on top of the Implementation Decisions of the spec [#22](https://github.com/siroroman/BreathApp/issues/22).

## Modules

| Module | What it is | What is in it | May import |
|---|---|---|---|
| `BreathnestKit` | local Swift package | Domain types, the Session engine, Breath level, Haptic plan, the **protocols of the seams**. No text, no `Observation`. | Foundation, Synchronization, Swift |
| `BreathnestKitTesting` | second product of the Kit package | Fakes of the seams: `ManualClock`, a manual ticker, a recording `HapticPlayer`, an in-memory store. Used only by tests and previews, never linked into a release build. | the Kit |
| `BreathnestUI` | second local package, created by its own setup ticket before #29 | The ViewModels and drawing shared by iPhone and Watch: the Session ViewModel, the torus, the progress ring. | SwiftUI, Observation, Foundation, Synchronization, Swift, the Kit |
| `Breathnest` | iPhone app target | The composition root, the adapters (Core Haptics, `CADisplayLink`, UIKit, `UserNotifications`), the navigation model, the ViewModels and views that exist only on the iPhone. | everything |
| Watch app target | standalone watchOS target, set up in #40 | The same rules, its own adapters, its own navigation (`docs/product/watch-design.md`). | everything |

Dependencies point one way: app, then `BreathnestUI`, then the Kit. The Kit depends on nothing.

## Decisions

### MVVM

- **Model** is the Kit (`Exercise`, `Pattern`, the Session engine, Breath level, Haptic plan). **ViewModel** is a `@MainActor` `@Observable` class for one screen. **View** is a SwiftUI view.
- ViewModel types end in `ViewModel` (`SessionViewModel`, `ExerciseDetailViewModel`). The word "model" alone means the domain. **Session** is a domain term in `GLOSSARY.md`: a "Session model" could mean the engine or the ViewModel. `ViewModel` is a technical term and does not go into the glossary.
- A screen gets a ViewModel when it needs at least one of: values derived from the Kit, a side effect (haptics, time, storage, notifications), or state shared with another view. Otherwise a view uses `@State` and `@Binding`.
- A ViewModel imports no view type (`Color`, `Image`, `View`), so it is tested without rendering.
- A ViewModel holds no text that the app writes. It exposes values and small enums (`cycleCount`, `totalLength` as `Duration`, the Phase kind); the view builds the text from the String Catalog. This is the rule of ADR 0001 ("no text in the Kit") one layer up, and plurals and languages stay in one place. Text the user typed is data, not app text: the name and description of a custom Exercise (#57) pass through a ViewModel as a `String` and the view shows them as they are, with no catalog key.
- State is read-only from outside (`private(set)`). A change goes through a named method (`select(duration:)`, `start()`, `pause()`). A view writes a ViewModel property directly only through `@Bindable`, for a field the ViewModel validates.
- Ownership: the root view of a screen receives `AppDependencies` as a plain parameter (not from the environment) and creates its ViewModel with `@State private var viewModel`. Child views get it as a `let`, or `@Bindable` where they need a binding. No `ObservableObject`, `@StateObject` or `@ObservedObject`. Previews and UI tests build a ViewModel with fakes from `BreathnestKitTesting`.

### Seams

- The protocols live in the Kit, because they are plain Swift and the Watch uses them too: `HapticPlayer` (one method, takes the Haptic plan), a ticker that yields `ContinuousClock.Instant` as an `AsyncSequence`, screen awake, scene phase, the notification scheduler, and the stores of the saved settings.
- The adapters live in the app targets. A fake lives in `BreathnestKitTesting` when more than one test target needs it.
- `BreathnestKitTesting` is outside the 80% coverage floor of the Kit.

### Dependency injection

- Constructor injection. No singleton and no global: `static let shared` and `static var shared` are not used.
- The composition root is `BreathnestApp`. It builds one `AppDependencies` value from the real adapters, once, and hands it to the screens that create ViewModels.
- The SwiftUI environment carries only what many views read at once: the saved settings and the navigation model.
- A launch argument available only in `DEBUG` builds swaps adapters for fakes (UI tests without real haptics or notifications) and scales the time fed to the engine. Neither exists in a release build.

### Concurrency

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` for the app target and for `BreathnestUI`. Whatever runs off the main actor says so (`nonisolated` or an actor).
- The Session ViewModel owns one `Task` that reads the ticker and calls `tick(now:)`, which advances the engine. The Task is cancelled on Pause, on Stop, on completion and in `deinit`, so nothing runs or plays after a Session ends.
- The Kit stays free of tasks and timers (ADR 0001). All concurrency is in the apps.

### Navigation

- One root `@Observable` navigation model for the iPhone: the selected tab, the Exercise whose detail is open (by its ID), and whether a Session is open. Views read it and change it.
- A tap on a Reminder notification (the delegate lives in the app target) sets the Exercise ID in that model, so the detail opens along the same path as a tap on a row.
- Local `@State` stays for purely visual state (an open menu, a picker choice).
- The Watch has its own navigation, as designed in `docs/product/watch-design.md`.

### Sharing code with the Watch

- The Session ViewModel, the torus and the progress ring live in `BreathnestUI`, so the Watch reuses them and `swift test` covers the ViewModel on macOS without a simulator. A folder compiled into both targets is not used: it compiles twice and cannot be tested on its own.
- A ViewModel or view that exists on one platform only stays in that app target.
- The first ticket that needs the package is #29 (the Session ViewModel). A small setup ticket before #29 creates it.

### Commit scopes (#145)

A scope is optional. When given, it is one of the scopes in `docs/agents/git.md`. The code scopes follow the module map: `kit`, `shared-ui`, `phone`, `watch`, `l10n`. The others name an area that already appears in the history: `product`, `research`, `agents`, `guardrails`, `process`, `git`.

## Considered options

- **Views on the stores, no ViewModel.** Simpler, but the Session screen would mix time, haptics and screen awake into a view, which cannot be tested without a simulator.
- **A third-party architecture library (TCA and similar).** Rules out itself: no third-party dependency without an ADR, and it is heavy for three screens.
- **A folder of shared SwiftUI compiled into both app targets.** No new package, but it builds twice and has no tests of its own.
- **Protocols of the seams in the app targets.** Each platform would declare its own, and the Watch could not reuse the ViewModel against fakes.

## Consequences

- `docs/agents/ios.md` links here and carries the module map. Its convention "a type that needs SwiftUI belongs in the app target" now reads "UIKit, Core Haptics and UserNotifications belong in the app target; SwiftUI shared with the Watch belongs in `BreathnestUI`".
- Tickets #29 and #45 say the Session "model" is in the app target and tested as app unit tests; #30, #31, #44 put the torus and ring where the sharing is still open; #32 and #47 test the haptics through app unit tests; #35 describes the test layers. All are commented: the ViewModel is `SessionViewModel` in `BreathnestUI` and tested by `swift test`, the drawing is in `BreathnestUI`, the stubs come from `BreathnestKitTesting`. #28, #54 to #60 do not contradict this ADR. `BreathnestUI` tests need macOS (SwiftUI does not build on the Ubuntu job), so they run in the `Build, app tests, lint` job, not in `Kit tests`.
- `scripts/check-architecture.sh` today allows only the package `BreathnestKit` in `project.yml`. It must learn `BreathnestUI` and its list of allowed imports.
- Checks to add, each with a test and a row in `docs/agents/rules-enforcement.md`: `BreathnestUI` imports only SwiftUI, Observation, Foundation, Synchronization, Swift and the Kit (no UIKit, Core Haptics, WatchKit or UserNotifications); no `static let shared` or `static var shared` in `App/` and `BreathnestUI/`; `SWIFT_DEFAULT_ACTOR_ISOLATION` is set in `project.yml`; a scope in a commit header or PR title is in the list of `docs/agents/git.md`.
- The rest are process rules for the `code-reviewer`: ViewModels are `@MainActor`, a view holds no I/O or logic, dependencies come through `init`, the seams are Kit protocols, a ViewModel has no view types or user text.
- Two places route by path and do not know `BreathnestUI` yet. The setup ticket for the package changes both, or code in it would go untested and unflagged: `scripts/ci-scope.sh` runs the macOS job only for `App/*`, `BreathnestKit/*` and `project.yml`, and a skipped job counts as passed, so it gets `BreathnestUI/*` (with a case in `scripts/test-ci-scope.sh`); the globs of `docs/agents/critical-paths.md` cover only `BreathnestKit/Sources/` and `App/Breathnest/`, so the Session, Ticker, Haptic and the other areas get their `BreathnestUI` paths, which `scripts/check-critical-paths.sh` and `scripts/pr-facts.sh` then see.
- Follow-up tickets, not part of this decision: create `BreathnestUI` (before #29, with the two path changes above), check the scopes (#145), add `BreathnestKitTesting` with the coverage exclusion.
- Persistence (#69, ADR 0003) decides what sits behind the store protocols; this ADR only fixes where the protocols live.
