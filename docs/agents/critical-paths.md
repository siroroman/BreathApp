# Critical paths

The parts of Breathnest where a mistake costs the user a Session, their data or the feel of the app. A pull request that touches one of them says so under **Critical paths touched** in its body ([pull requests](pull-requests.md)), and the reviewer checks that evidence for it exists.

`scripts/pr-facts.sh` matches the changed files against the `Paths:` lines below. The code base is young, so the globs follow the names in `GLOSSARY.md` and the module map of [ADR 0001](../adr/0001-domain-logic-in-a-ui-free-swift-package.md). **Whoever adds a module in one of these areas adds or fixes its glob in the same pull request.** A glob is a shell `case` pattern on the repo-relative path, `*` also matches `/`. Write it with the full directory prefix: the module and app names (`BreathnestKit`, `Breathnest`) contain words like `Breath`, so `*Breath*` alone would match every file.

A path that is not listed can still be critical. If the diff changes behaviour from the list below through a file the globs miss, name it by hand in the PR.

### Session engine and timing

Paths: `BreathnestKit/Sources/BreathnestKit/*Session*` `BreathnestKit/Sources/BreathnestKit/*Cycle*` `BreathnestKit/Sources/BreathnestKit/*Pattern*` `BreathnestKit/Sources/BreathnestKit/*Phase*` `BreathnestKit/Sources/BreathnestKit/*Lead*`

What breaks: a Session ends at the wrong time or with the wrong number of Cycles, the Lead-in counts toward the length, a Phase is skipped or doubled. The user notices by feel, a test with a wrong number is the only early signal. Time must come from the injected `Clock` ([testing](testing.md)); `Date()`, `ContinuousClock()` or `Task.sleep` in logic is a finding.

### Exercise data and identity

Paths: `BreathnestKit/Sources/BreathnestKit/*Exercise*` `BreathnestKit/Sources/BreathnestKit/*Duration*`

What breaks: an Exercise has a fixed ID that the Log, Quick Start and Reminders refer to. Changing or reusing an ID, or a Pattern or default Duration option, silently changes what old Sessions and Reminders mean. This is a one-way door once the app has users.

### Breath level and Haptic plan

Paths: `BreathnestKit/Sources/BreathnestKit/*Breath*` `BreathnestKit/Sources/BreathnestKit/*Haptic*` `App/Breathnest/*Haptic*` `App/Breathnest/*BreathLevel*`

What breaks: the circle and the haptics fall out of step with the Phase, the curve jumps at a Phase boundary. Pure numbers are covered by `make test-kit`; how it feels is not, say that in Reviewer notes.

### Foreground, background and screen

Paths: `App/Breathnest/*Ticker*` `App/Breathnest/*Scene*` `App/Breathnest/*Lifecycle*` `App/Breathnest/*Awake*` `App/Breathnest/BreathnestApp.swift`

What breaks: the Session drifts or stops when the app leaves the foreground or the screen locks, the screen sleeps mid-Session. Only the simulator or a device shows it; a Kit test cannot.

### Log, Reminders and stored data

Paths: `BreathnestKit/Sources/BreathnestKit/*Log*` `BreathnestKit/Sources/BreathnestKit/*Reminder*` `BreathnestKit/Sources/BreathnestKit/*Persist*` `BreathnestKit/Sources/BreathnestKit/*Migration*` `App/Breathnest/*Log*` `App/Breathnest/*Reminder*` `App/Breathnest/*Persist*` `App/Breathnest/*Store*` `App/Breathnest/*Migration*`

What breaks: the user loses their Log, Custom exercises or Reminders, or a Reminder stops firing. The app is offline and keeps everything on the device, so there is no backup. A change to a stored shape without a migration is a one-way door.

### Build, project and CI

Paths: `project.yml` `BreathnestKit/Package.swift` `Makefile` `.github/*` `.githooks/*` `.claude/settings.json` `.claude/hooks/*` `scripts/*`

What breaks: every later pull request, every agent session and the hooks that guard `main`. Changing a check so it passes is never the fix ([definition of done](definition-of-done.md)).
