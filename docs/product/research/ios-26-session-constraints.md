# iOS 26 constraints for a timed breathing session

Research for issue #10 (part of the map in issue #8). Researched 2026-10-23.

## Question

What does iOS 26 impose on a timed, animated breathing Session? Cover: keeping the screen awake (idle timer), what happens when the app is backgrounded or the screen locks, interruptions (phone call, Siri, notification, audio route change), Core Haptics availability and limits (Simulator, `CHHapticEngine` lifecycle and reset handling, fallback to `UIFeedbackGenerator`), timing accuracy for Phase transitions (display link vs timer vs clock), and SwiftUI animation tools suited to a looping scale driven by Phase (`PhaseAnimator`, `TimelineView`, keyframes). Primary sources only: Apple documentation, WWDC sessions, Apple sample code, SDK headers.

## Short answer

- **A Session is a foreground-only activity.** Without audio playback or another listed background mode, the app gets no execution time once it leaves the foreground, and Core Haptics stops with it. Lock, Home, call, app switcher: anything that makes the scene not `.active` must pause the Session. Keeping the screen on is allowed and appropriate (`UIApplication.isIdleTimerDisabled`), but only while the Session is running, and it must be reset afterwards.
- **Time must come from a clock, not from counting ticks.** Apple documents that `Timer` is not a real-time mechanism and gives no latency figures for clocks or display links, so their jitter has to be measured on a device. Position in the Pattern should be a pure function of elapsed time since an anchor, evaluated each frame. Drift over 5 minutes then cannot accumulate by construction. The only drift risk left is the haptic timeline, whose alignment with UI time Apple does not specify.
- **Haptics: write for a device, test on a device.** Apple says the Simulator does not play Core Haptics. The engine can stop at any time (background, call, error) and must be restarted; its handlers arrive off the main thread. `UIFeedbackGenerator` and SwiftUI `sensoryFeedback` are a reasonable fallback but give discrete taps only.
- **For the circle, a clock-driven `TimelineView` evaluating a `KeyframeTimeline` (or a plain easing function) looks like a better fit than `PhaseAnimator` (my reading of the docs; nothing was built or measured).** It keeps animation, haptics and pause/resume on one timeline. `PhaseAnimator` is the simplest but chains animations from view appearance and has no documented pause or seek.
- **Reduce Motion needs a real alternative.** Apple's guidance names zooming and scaling as the things to reduce, and the scaling circle is also the main cue of the app. It cannot simply be turned off; it needs a non-moving equivalent (and a text cue).
- Several behaviours are **not documented by Apple** and are marked unverified below: which interruptions (Siri, banners) move the scene to `.inactive`, whether the Simulator reports `supportsHaptics == false`, how the Silent switch and System Haptics setting affect Core Haptics, and haptic-to-frame alignment.

## Terms

`GLOSSARY.md` terms are used as defined there: **Exercise**, **Pattern** (ordered Phases), **Phase** (kind + seconds, fractional allowed), **Cycle**, **Session**.

Name clash to watch: SwiftUI's `PhaseAnimator` uses "phase" for its own animation states. In this file "Phase" always means the glossary term, and "animator phase" means the SwiftUI one. Keep them apart in code too.

## Source quality key

- **Doc page**: an Apple Developer Documentation page (read through the documentation JSON feed that backs developer.apple.com/documentation, on 2026-10-23, so it describes the current SDK).
- **WWDC**: a transcript on developer.apple.com/videos.
- **Header**: a file in the Xcode SDK (checked in the Xcode beta bundle on this Mac, iPhoneOS 27.0 SDK).
- **Sample**: Apple sample code documentation page.
- **Own check**: something I ran myself, flagged as such. Not an Apple statement.

The current docs already describe iOS 27 in places. Where that matters for an iOS 26 floor it is called out.

## 1. Keeping the screen awake (idle timer)

**Constraint**

- By default the system dims the screen and then sleeps the device after a short time without touches. `UIApplication.isIdleTimerDisabled` (iOS 2.0+, not marked deprecated on its page) turns that off for the app. Doc page.
- Apple's guidance on the same page: set it only if necessary, reset it to `false` when the need ends, most apps (audio apps included) should let the screen turn off, and only mapping apps, games, or programs that must keep displaying content with minimal interaction should disable it. A guided Session (eyes on a circle, no touches for minutes) fits the last description, but Apple does not name breathing apps, so this is my reading.
- Screen on at full brightness for 5 minutes or more has a battery cost. Apple states the "only if necessary" rule for that reason; it gives no numbers.

**Recommended approach**

- Set the flag to `true` when a Session starts running, and back to `false` on pause, stop, natural end, and whenever the scene is not active. Never leave it set while the Session screen is not visible.
- Drive it from the same state machine that drives the Session (one owner), not from view lifecycle alone.
- I found no SwiftUI-native idle-timer API in the documentation I read. The property is on `UIApplication`, so a small UIKit adapter is needed (unverified that none exists; I did not exhaustively search).

**Apple source**: UIApplication `isIdleTimerDisabled`.

**Unverified**: whether the system itself clears the flag when the app goes to the background (the page says nothing); interaction with Low Power Mode auto-lock; Guided Access or Screen Time overrides.

## 2. Backgrounding and screen lock

**Constraint**

- Locking the device makes the app lose focus. The `willResignActiveNotification` page lists "the device is locked" explicitly, alongside overlays. Pressing Home or switching apps does the same and then moves the scene to the background. Doc pages: `willResignActiveNotification`, "Preparing your UI to run in the background".
- In SwiftUI the scene phases are `.active`, `.inactive`, `.background`. `.inactive` means the scene should pause timers and free what it does not need; `.background` means do as little as possible and expect termination. Doc pages: `ScenePhase`, `.inactive`, `.background`.
- After the background transition callback returns, the app is suspended shortly after. Callbacks get about five seconds. `beginBackgroundTask` can extend that to finish critical work; it is for finishing tasks, not for running a timer. Doc pages: "Extending your app's background execution time", `backgroundTimeRemaining` (system conditions may end it earlier).
- Background execution time is only granted to apps with specific capabilities (audio, location, VoIP, accessories, and so on). A breathing timer is not on the list; audio playback is. Doc page: "Preparing your UI to run in the background". With the `playback` audio category plus the `audio` value in `UIBackgroundModes`, audio continues when the screen locks; with the `ambient` category the screen lock silences it. Doc pages: `AVAudioSession.Category.playback`, `.ambient`.
- App Review Guideline 2.5.4 says background services may only be used for their intended purposes (VoIP, audio playback, location, task completion, local notifications and so on). A silent timer with an audio background mode would be a review risk (my inference from this guideline, not an Apple statement).
- The tracer bullet has no sound, so the Session cannot continue in the background.
- A background app can be terminated at any time. State preservation data may also be discarded by the system. Doc page: "Preserving your app's UI across launches".
- The page for `applicationWillResignActive(_:)` marks it deprecated as of iOS 26 and says to use the scene delegate method when scenes are in use. SwiftUI apps use `ScenePhase`, so nothing extra is needed. I checked only that one method, not the rest of the app-delegate lifecycle. Doc page: `applicationWillResignActive(_:)`.

**Recommended approach**

- Treat the Session as foreground-only. Observe `scenePhase`; when it is anything other than `.active`: freeze the Session clock (pause), stop the haptic engine, clear the idle-timer flag.
- On return to `.active`, show the Session in a paused state and let the person resume. Do not auto-resume (see section 3).
- Do not use a background task or audio mode to "keep the timer alive".
- A local notification is not useful as a substitute: the visual and haptic experience cannot run in the background, so there is nothing to wait for.
- Live Activities are out of scope for v1 per the brief.

**Apple sources**: pages above.

**Unverified**: that every lock path goes through `.inactive` and then `.background` in that order and what the Always-On display does to a locked foreground app (the docs say lock causes resign-active; they do not give the full sequence); whether `TimelineView` stops updating while the scene is inactive (docs do not say, so pause explicitly).

## 3. Interruptions

| Event | What Apple documents | Status |
|---|---|---|
| Incoming phone call | `applicationWillResignActive` and `sceneWillResignActive` list incoming calls and system alerts as reasons to go inactive. If an audio session is active, a call interrupts it; with the banner call style plus `setPrefersNoInterruptionsFromSystemAlerts(true)` the session is interrupted only if the user accepts. | Documented in general terms. Exact `scenePhase` sequence for a banner-style call is not documented: unverified. |
| Siri | No page I read mentions Siri. | Unverified. |
| Notification banner | Not mentioned. The `willResignActiveNotification` page says focus is lost "when an overlay window pops up". | Unverified whether a plain banner, Notification Center or Control Center changes `scenePhase`. |
| Audio route change (headphones, Bluetooth) | `AVAudioSession.routeChangeNotification` is posted on a secondary thread. It is an `AVAudioSession` notification, so it matters only to an app that uses an audio session (my reading; no page states this outright). | Irrelevant for the tracer bullet (no sound). |
| Audio interruption (other app's audio, call) | Same: only for an app with an active audio session. `interruptionNotification` is the iOS 26 mechanism. In iOS 27 and later the system adds `didBecomeInactiveNotification` and `resumptionRecommendationNotification` and deprecates the old one. Since iOS 10 the system deactivates the audio session when it suspends the app and you are told when you next run. | Deploying to iOS 26 means using the legacy notification; revisit when sound is added. |

**Constraint on Core Haptics**: the engine reports `audioSessionInterrupt` when its audio session is interrupted, using the phone call as the example. It also stops when the app is backgrounded. See section 4.

**Recommended approach**

- One code path: "scene is not active" means pause. Do not try to tell a call from Siri from a banner; the cause is not needed to decide what to do. Apple's pages say calls and system alerts make the app inactive and that timers should pause then; for Siri, banners and Control Center nothing is documented (table above), so pausing on any non-active scene is the conservative reading.
- Do not auto-resume after an interruption. The person may have missed several Phases; a silent restart mid-Phase is disorienting. Whether to resume mid-Phase, at the start of the Phase or at the start of the Cycle is a design question for #11.
- Keep the audio-session handling out of the tracer bullet. When sound is added, adopt the interruption and route-change notifications at that point.

**Apple sources**: `applicationWillResignActive(_:)`, `sceneWillResignActive(_:)`, `willResignActiveNotification`, "Handling audio interruptions", `AVAudioSession.interruptionNotification`, `routeChangeNotification`, `setPrefersNoInterruptionsFromSystemAlerts(_:)`.

## 4. Core Haptics

### Availability

- Core Haptics needs a device with a haptic engine. iPad, iPod touch and Apple Vision Pro do not support haptics. Check `CHHapticEngine.capabilitiesForHardware().supportsHaptics` before building an engine. The header also says engine creation fails with `CHHapticErrorCodeNotSupported` on systems without haptics hardware. The class is `API_UNAVAILABLE(watchos)`. Sources: "Preparing your app to play haptics", `CHHapticEngine.h`.
- Apple's Core Haptics material says iPhone 8 or later (WWDC19 520, WWDC21 10278, the HapticSampler and "Delivering rich app experiences with haptics" samples). I did not find an Apple page listing the hardware floor of iOS 26 itself. I expect every iOS 26 iPhone to be newer than iPhone 8, but that is not verified from a primary source.
- **The Simulator does not play haptics.** The HapticSampler sample says the Simulator does not support a haptic interface, and WWDC21 10278 says the Simulator does not work for haptics and a physical iPhone 8 or newer is needed, with the phone not silenced. Both are older than Xcode 27; I did not test the current Simulator. What `supportsHaptics` or `CHHapticEngine()` return in the Simulator is not documented: unverified.
- The system can override your haptics with its own, for example from system notifications (`CHHapticEngine` page).

### Engine lifecycle

From "Preparing your app to play haptics", the `CHHapticEngine` pages and the header:

- Create the engine early, keep a strong reference, set `stoppedHandler` and `resetHandler` before starting it. The engine is not a singleton and is thread-safe for player operations.
- `start()` blocks the calling thread until started; `start(completionHandler:)` (also `async`) does not. `stop` is also async.
- **`stoppedHandler`** fires when something outside your code stops the engine: audio session interrupted (a call), app suspended in the background, idle timeout (only when `isAutoShutdownEnabled`), system error, engine destroyed, game controller gone, or `notifyWhenPlayersFinished` returning stop. It is not called when you call `stop` yourself. Apple: stopping is a normal part of the life cycle; restart before the next haptic. For `applicationSuspended`, restart when the app returns to the foreground. For `audioSessionInterrupt`, restart before starting another player. For `systemError`, continue without haptics or fail, your choice.
- **`resetHandler`** fires after the haptic server has recovered from a failure. Release and recreate all pattern players, re-register audio resources, restart the engine. `CHHapticPattern` objects and engine properties are preserved. A restart can fail if the cause has not gone away.
- Both handlers arrive on a non-main (internal) queue. In the header they are plain blocks; the protocol does not mark them `@Sendable`. **Own check**: a `@MainActor` class assigning closures that touch `self` to both handlers type-checks with no diagnostic in Swift 6 mode against the Xcode beta SDK. So the compiler does not warn that Apple says the handlers run off the main thread. Whether that actually traps at runtime was not tested (needs a device). Plan on explicit, nonisolated handlers that only forward an event.
- `isAutoShutdownEnabled` defaults to `false`. When on, the engine stops after about two minutes idle and restarts on the next request, which can delay the start of a pattern. For a Session, leave it off and stop the engine explicitly at the end to save power (the page advises this).
- `playsHapticsOnly = true` ignores audio events and reduces start latency; it takes effect only after a stop and start. For an engine used only for haptics, Apple says to pass `nil` as the audio session in `init(audioSession:)`.

### What a pattern can do (relevant to a breathing guide)

- Events are `hapticTransient` (a tap) or `hapticContinuous` (a sustained vibration). **A continuous event is at most 30 seconds long.** Any Phase this app uses is shorter, but a Pattern validator should respect it.
- Intensity and sharpness are event parameters. During playback, dynamic parameters change them instantly, and parameter curves interpolate linearly between control points. A curve applies to all events in the pattern, not one event. Sources: `CHHapticParameterCurve`, `CHHapticEvent`.
- The standard player starts at `CHHapticTimeImmediate` or at an absolute engine time (`start(atTime:)`; a time in the past starts now). The advanced player adds loop, pause, resume and seek.
- `CHHapticEngine.currentTime` is the clock for scheduling. Apple says it does not correlate with media time in other frameworks (for example `AVAudioPlayer`). So the haptic timeline and the UI timeline are two clocks that need a one-off alignment at start and after every restart. How precise that alignment can be is not documented. WWDC19 520 says scheduled mode exists to line haptics up with other systems such as animation, and that UIKit feedback sits on the same low-latency stack. It gives no accuracy figure.

### Fallback

- `UIImpactFeedbackGenerator` / `UISelectionFeedbackGenerator` / `UINotificationFeedbackGenerator` produce a single predefined haptic each. No duration, no intensity curve (impact has an `intensity` value 0 to 1). `prepare()` readies the Taptic Engine for lower latency, but it idles again after a few seconds or after a trigger; repeated `prepare()` without ever triggering can be ignored. For Phases of 4 to 8 seconds, call `prepare()` shortly before each boundary.
- SwiftUI `sensoryFeedback(_:trigger:)` (iOS 17+) plays a `SensoryFeedback` when a value changes, with `.impact(weight:intensity:)`, `.selection`, `.start`, `.stop`, `.success`. Impact feedback plays on iOS and watchOS only, and Apple says it should supplement the experience. It is the least code for boundary ticks and needs no engine lifecycle.
- The fallback gives ticks at Phase boundaries, not a haptic that follows the Phase. If Core Haptics is unavailable or the engine fails to restart, ticks are the degraded mode.
- Whether the generators work in the Simulator is not stated on their pages: unverified.

### Design guidance from the HIG ("Playing haptics")

- Make haptics optional: the app must be fully usable with them off.
- Prefer short haptics for discrete events; long-running haptics can dilute meaning and distract. A breathing guide is long-running by nature, so this needs testing on a device rather than an assumption either way.
- Match the intensity and sharpness of a haptic to the animation it accompanies; keep a clear cause and effect; do not overuse.
- Haptics can disturb camera, gyroscope or microphone use.

**Unverified**: how the Ring/Silent switch and Settings > Sounds & Haptics > System Haptics affect Core Haptics. WWDC21 10278 only asks you to verify the phone is not silenced. Plan an in-app haptics toggle regardless.

## 5. Timing accuracy for Phase transitions

**What Apple documents**

| Mechanism | Documented behaviour |
|---|---|
| `Timer` | "Not a real-time mechanism": it fires late if the run loop is busy or in a mode that is not monitoring it. A repeating timer schedules from the original fire date, so it does not drift cumulatively. If delayed past a firing time, that firing is skipped, not made up. `tolerance` defaults to 0 but the system may add a small one; Apple recommends 10% or more of the interval for power. Invalidate timers when the app deactivates. |
| `CADisplayLink` | Fires in step with the display. `timestamp` is when the last frame was shown; `targetTimestamp` is when the next one will show, and Apple says to use it for what to draw next. Actual rates are factors of the maximum refresh rate. Since iOS 15 the rate can change with Low Power Mode, critical thermal state and accessibility settings. Use `preferredFrameRateRange`; the page for `preferredFramesPerSecond` marks it deprecated in a 27.x release. |
| `ContinuousClock` / `SuspendingClock` (iOS 16+) | Both are monotonic. `ContinuousClock` keeps counting while the system sleeps; `SuspendingClock` stops. Instants are only comparable within the same run (or boot session for the suspending clock). The `Clock` protocol exposes `minimumResolution`, and `sleep` takes a deadline plus a tolerance; the clock may move wake-ups inside the tolerance to save power. |
| `Task.sleep(until:tolerance:clock:)` | Suspends to a deadline without blocking a thread; defaults to the continuous clock; throws `CancellationError` on cancel. |
| `TimelineView` | Redraws on a schedule. Schedules: `.periodic(from:by:)`, `.explicit`, `.everyMinute`, and `.animation(minimumInterval:paused:)` (system picks the rate; can be paused). The context carries `date`. The system may use a slower cadence than requested. |

**Where drift comes from (my reasoning, consistent with the above)**

- Drift accumulates when each wait is computed relative to the previous one ("sleep for Phase.seconds, then the next") because every overshoot is added to the next wait. Counting display-link frames has the same problem if frames are dropped or the rate changes (Low Power Mode, thermal).
- It does not accumulate if every deadline is computed as an absolute instant from one anchor: `anchor + cumulative boundary`. Then each transition has jitter (lateness of that one wake-up) but jitter does not add up. Over 5 minutes, which is about 19 Cycles of box breathing, the last transition lands within the same jitter as the first.
- Apple gives no latency or jitter figures for `Task.sleep`, `Timer` or display links, so the size of the jitter has to be measured on a device. Unverified.

**Recommended approach**

- Anchor one monotonic instant (`ContinuousClock.now`) when the Session starts or resumes, and keep an `elapsedBeforePause` value. Everything else is a pure function of elapsed time: Cycle index, Phase index, progress inside the Phase, whether the Session is over. Precompute cumulative Phase boundaries with `Duration` (fractional seconds such as 5.5 are exact enough, and `Duration` avoids float accumulation for odd values).
- Render by reading that function each frame (`TimelineView(.animation)`); never advance state by counting frames or ticks.
- Fire discrete events (boundary tick, end-of-Session) from absolute deadlines (`Task.sleep(until:tolerance:clock:)` with a small tolerance), or better schedule them on the haptic engine's own timeline and rebuild after every restart.
- `ContinuousClock` is the better choice because it is not affected by system sleep; pause and resume are done by explicit bookkeeping of `elapsedBeforePause`, not by clock choice. Do not persist a clock instant across launches (instants are only comparable within one run). If a restorable record is ever needed, store elapsed seconds.
- Do not use `Date` as the Session clock. It is a wall clock that can jump when the time or time zone changes. That is my reasoning; I did not find an Apple page that compares it with the monotonic clocks.
- A display link is only needed if the circle is drawn outside SwiftUI. `TimelineView(.animation)` is the SwiftUI way to get frame-synchronous updates.
- Tests: make the clock injectable (the `Clock` protocol is a documented abstraction), so the Phase function and the boundary scheduling can be tested without waiting.

**Apple sources**: `Timer`, `Timer.tolerance`, `CADisplayLink` (and `timestamp`, `targetTimestamp`, `preferredFrameRateRange`, `preferredFramesPerSecond`), `ContinuousClock`, `SuspendingClock`, `Clock`, `Task.sleep(until:tolerance:clock:)`, `TimelineView`, `TimelineSchedule.animation(minimumInterval:paused:)`, `CHHapticEngine.currentTime`.

## 6. SwiftUI animation for a looping scale driven by Phase

### Options

| Tool | What it is (doc pages, WWDC23 10157) | Fit for a Session |
|---|---|---|
| State plus `.animation(_:value:)` or `withAnimation` (baseline) | The engine publishes the current Phase; the view animates the scale to the Phase target over `Phase.seconds` with `.linear` or an easing. Completion callbacks exist (`withAnimation(_:completionCriteria:_:completion:)`, iOS 17). | Simplest. Pausing, resuming mid-Phase and seeking all need manual work (restart the animation with the remaining time and the right starting value). |
| `PhaseAnimator` (iOS 17) | Cycles through animator phases; without a trigger it loops forever, with a trigger each change moves to the next animator phase. Each step animates with an `Animation` you return per animator phase, and per WWDC23 10157 SwiftUI advances when the animation finishes. | Good for a decorative loop. Timing comes from chained animation durations starting at view appearance, not from a Session clock, so drift against haptics and pause/seek are the engine's problem. No pause or seek API appears in the docs I read (unverified absence). The animator-phase vs Phase naming clash is a code-readability cost. |
| `keyframeAnimator` / `KeyframeAnimator` (iOS 17) | Defines the whole path of a value over time; loops with `repeating: true`; the content closure runs every frame, so keep it cheap. WWDC23 10157 compares keyframes to video clips and says they are not for interactive, fluid UI. | Good fit for a fixed breathing loop. As a modifier it still starts from view appearance and loops on its own. |
| `KeyframeTimeline` + `TimelineView` | `KeyframeTimeline.value(time:)` returns the interpolated value at any time within `duration`; you can scrub or evaluate it. WWDC23 10157 says explicitly that keyframes can be combined with `TimelineView` to update based on time. Supports fractional durations (`LinearKeyframe`, `CubicKeyframe`). | Best fit on paper for a Session: the visible scale is `timeline.value(time: elapsedInCycle)`, so it follows the same clock as everything else, and pause, resume and seek reduce to bookkeeping on one elapsed-time value (my reading; not built or measured). |
| `TimelineView(.animation(minimumInterval:paused:))` | Per-frame redraw with `paused`; `context.date` as input. | The driver for the row above. You can also skip keyframes and compute scale from an easing function of Phase progress. |

Notes common to all of them:

- Linear motion looks mechanical per the `Animation.linear(duration:)` page; easing between full and empty is a feel decision (#13).
- Per-frame evaluation runs your closure on the main thread each frame; keep the body to the circle (and a label). Frame rate may be reduced by Low Power Mode, thermal state and accessibility settings (CADisplayLink pages), which is another reason to evaluate by time, not by frame count.
- I did not build or measure any of these; the fit judgements come from the documented behaviour above.

### Reduce Motion

- `@Environment(\.accessibilityReduceMotion)` (iOS 13+) is `true` when Reduce Motion is on. The page says UI should avoid large animations, especially those that simulate a third dimension. UIKit equivalents: `UIAccessibility.isReduceMotionEnabled` and `reduceMotionStatusDidChangeNotification`; `prefersCrossFadeTransitions` is true when both Reduce Motion and Prefer Cross-Fade Transitions are on.
- HIG "Accessibility": with Reduce Motion on, reduce automatic and repetitive animations, including zooming, scaling and peripheral motion; replace x/y/z transitions with fades. The HIG "Motion" page also says to make motion optional and to supplement it with haptics or audio.
- App Store "Reduced Motion evaluation criteria" (for the Accessibility Nutrition Label): ongoing motion should be stopped or controllable; if motion carries meaning, do not just remove it, give it a replacement that avoids motion, such as a dissolve, highlight fade or colour shift.
- WWDC23 10034 (a visionOS session; I am assuming its Reduce Motion advice carries over to iPhone): zooming and rotating effects should have an alternative when Reduce Motion is on, and a crossfade is a good default.
- What this means here: a circle that grows and shrinks is both a repetitive zoom and the main meaning-carrying cue. It must not simply be disabled. Candidate replacements (design choice for #13, not stated by Apple): a fixed-size circle whose fill, opacity or brightness follows the Phase; a ring or bar that fills; a large text cue ("Breathe in", "Hold") that cross-fades; or a reduced-amplitude scale. Whether a reduced-amplitude scale passes Apple's label criteria is not stated, so treat it as unproven.
- Because haptics are optional (HIG) and sound is out of the tracer bullet, a person with Reduce Motion on and haptics off needs the text cue to follow the Pattern. The same text cue also helps VoiceOver users.

**Apple sources**: `PhaseAnimator`, `phaseAnimator(_:trigger:content:animation:)`, `KeyframeAnimator`, `keyframeAnimator(initialValue:repeating:content:keyframes:)`, `KeyframeTimeline` and `value(time:)`, `TimelineView`, `TimelineSchedule`, `animation(minimumInterval:paused:)`, `Animation.linear(duration:)`, `accessibilityReduceMotion`, HIG Accessibility and Motion, Reduced Motion evaluation criteria, WWDC23 10157, WWDC23 10034.

## Implications for the sibling tickets (input only, nothing decided)

**Input only.** This section lists what the research above implies for #11, #12 and #13. Nothing here is decided, and those tickets own the questions. (C) lines restate a documented platform constraint. (R) lines are this note's reading of the sources, not Apple statements, and each ticket is free to overrule them.

**#11 Ending, pause, stop, interruptions**

- (C) The Session runs only while the scene is `.active`. Without sound there is no way to run in the background, and Core Haptics stops when the app is suspended.
- (R) Any non-active scene phase pauses the Session (clock frozen, haptic engine stopped, screen-awake flag released). One code path for call, Siri, lock, Home, app switcher.
- (R) Do not auto-resume. Show a paused state and ask the person to resume. Open question for #11: resume mid-Phase, restart the Phase, or restart the Cycle.
- (Gap) Siri, banners and Control Center are not documented to change `scenePhase`. Test on a device and treat the result as input to #11.
- (R) Until then, design as if each of them could pause the Session.
- (C) If the system terminates the backgrounded app, the Session is lost. #11 must decide whether a partial Session is recorded in History and from what (elapsed seconds, not clock instants).
- (R) Natural end happens on a Cycle boundary (from #9), so the engine derives the end time from Pattern and chosen duration. The end cue must be visual and haptic only.
- (R) Stop and end release everything: idle-timer flag, haptic engine, scheduled deadlines.
- (C) The screen stays on only while running. Whether the paused state may dim (releases the flag) is a #11 choice.
- (R) No local notification for Session end or interruption; there is nothing the app could do in the background to make it meaningful.

**#12 Session engine and BreathnestKit boundary**

- (R) The engine in BreathnestKit is pure: given a Pattern, chosen duration and elapsed time, return Cycle index, Phase index, progress in Phase, and finished. No UIKit, SwiftUI, Core Haptics or `Date` inside it. `CHHapticEngine` is `API_UNAVAILABLE(watchos)`, which is one more reason to keep it outside the package that a future Watch app will share.
- (R) Inject a `Clock` (documented protocol) so tests run instantly. Live app uses `ContinuousClock`. Pause and resume are bookkeeping on `elapsedBeforePause`, owned by the engine.
- (R) Use `Duration` for Phase lengths and precompute cumulative boundaries from one anchor; never chain relative sleeps.
- (R) Adapters in the app target behind small protocols: haptics (Core Haptics implementation, `sensoryFeedback`/generator fallback, no-op for tests and the Simulator), idle timer, scene-phase source, and reduce-motion source.
- (C) Core Haptics handlers run off the main thread and are not Sendable-annotated; the haptics adapter needs its own isolation (an actor or a lock-protected class) and must be able to rebuild the engine and players on `reset` and on restart.
- (C) The haptic timeline is separate from UI time (`currentTime` is not media time). The adapter owns alignment and re-alignment after every restart; accuracy is unverified.
- (R) Validate Patterns at the boundary: every Phase seconds greater than 0, and a continuous haptic event never longer than 30 s.

**#13 Circle motion and haptic feel**

- (R) Drive the circle from the same elapsed-time function as everything else: `TimelineView(.animation)` plus either a `KeyframeTimeline` built from the Pattern or an easing function of Phase progress. Inhale grows, exhale shrinks, holds stay at the end values, `rest` stays at the empty value. Fractional seconds are fine.
- (C) Reduce Motion needs a non-moving or much reduced equivalent plus a text cue. Pick the replacement in #13; do not just disable the animation.
- (C) The Simulator cannot show haptics. Every haptic decision in #13 needs a physical iPhone, and the tracer-bullet QA plan should say so.
- (R) Offer a haptics setting (HIG). With eyes closed and no sound, haptics are the only cue, so they are not a nicety for this app; budget time for tuning on a device.
- Haptic feel options to put to the user, with what Apple documents for each: boundary ticks (generator or `sensoryFeedback`, simplest, robust); a continuous vibration whose intensity follows the Phase through a parameter curve (at most 30 s per event, curve applies to the whole pattern, so one pattern per Phase or per Cycle); or a hybrid. The HIG leans to short haptics for discrete events and warns about long ones; no Apple source says which suits a breathing guide.
- (C) Frame rate is not guaranteed (Low Power Mode, thermal state, accessibility settings). Time-based evaluation tolerates this; keep the per-frame view body tiny.

## Gaps and open items

- **Not documented, needs a device test**: which interruptions (Siri, banner, Notification Center, Control Center, banner-style call) change `scenePhase`, and in which order lock produces `.inactive` and `.background`.
- **Simulator**: only the HapticSampler note and a WWDC21 statement say it does not play haptics. I did not test the current Simulator, and I could not find what `supportsHaptics` returns there. Whether generators or `sensoryFeedback` do anything in the Simulator is not stated.
- **Haptic to frame alignment** and typical jitter of `Task.sleep`, `Timer` and display links: Apple gives no figures. Measure on a device with a 5 minute Session.
- **Ring/Silent switch and System Haptics setting** versus Core Haptics: no primary source found.
- **Swift 6 isolation of Core Haptics handlers**: only my own compile check (no diagnostic) plus Apple's statement that callbacks arrive off the main thread. Runtime behaviour not tested.
- **Hardware floor of iOS 26**: I did not find an Apple page that I could read confirming the supported iPhone list. Core Haptics' own floor is iPhone 8.
- **SwiftUI idle-timer API and `PhaseAnimator` pause/seek**: I found none, but this is absence of evidence only.
- **Whether a reduced-amplitude scale passes the Reduced Motion label criteria**: Apple does not say.
- **Docs describe iOS 27 in places** (new `AVAudioSession` lifecycle notifications, a 27.x deprecation note on `preferredFramesPerSecond`). The iOS 26 behaviour for those items is the legacy API, which I verified only through the same pages.
- **Out of scope here**: Live Activities, Apple Watch (`WKExtendedRuntimeSession`), sound and its audio session design. The brief puts the first two out of v1.
- **Hold kinds**: the glossary has `hold` and `rest`; this file assumes both are drawn as a flat scale at full or empty. #13 may want them visually distinct.

## Sources

All Apple. Developer documentation pages (https://developer.apple.com/documentation/...):

- UIKit: `uikit/uiapplication/isidletimerdisabled`; `uikit/uiapplication/willresignactivenotification`; `uikit/uiapplication/didenterbackgroundnotification`; `uikit/uiapplication/backgroundtimeremaining`; `uikit/uiapplicationdelegate/applicationwillresignactive(_:)`; `uikit/uiscenedelegate/scenewillresignactive(_:)`; `uikit/preparing-your-ui-to-run-in-the-background`; `uikit/managing-your-app-s-life-cycle`; `uikit/extending-your-app-s-background-execution-time`; `uikit/preserving-your-app-s-ui-across-launches`; `uikit/uifeedbackgenerator`; `uikit/uifeedbackgenerator/prepare()`; `uikit/uiimpactfeedbackgenerator`; `uikit/uiaccessibility/isreducemotionenabled`; `uikit/uiaccessibility/reducemotionstatusdidchangenotification`; `uikit/uiaccessibility/prefersCrossFadeTransitions`
- SwiftUI: `swiftui/scenephase` (and `/inactive`, `/background`); `swiftui/timelineview`; `swiftui/timelineschedule`; `swiftui/timelineschedule/animation(minimuminterval:paused:)`; `swiftui/phaseanimator`; `swiftui/view/phaseanimator(_:trigger:content:animation:)`; `swiftui/keyframeanimator`; `swiftui/view/keyframeanimator(initialvalue:repeating:content:keyframes:)`; `swiftui/keyframetimeline` (and `/value(time:)`); `swiftui/animation/linear(duration:)`; `swiftui/withanimation(_:completioncriteria:_:completion:)`; `swiftui/environmentvalues/accessibilityreducemotion`; `swiftui/sensoryfeedback` and `swiftui/view/sensoryfeedback(_:trigger:)`
- Core Haptics: `corehaptics`; `corehaptics/preparing-your-app-to-play-haptics`; `corehaptics/chhapticengine` and its `stoppedhandler`, `resethandler`, `stoppedreason` (and cases `applicationsuspended`, `audiosessioninterrupt`, `idletimeout`), `isautoshutdownenabled`, `playshapticsonly`, `currenttime`, `init(audiosession:)`, `start()`, `start(completionhandler:)`, `capabilitiesforhardware()`; `corehaptics/chhapticdevicecapability`; `corehaptics/chhapticevent` (and `/duration`, `/eventtype/hapticcontinuous`); `corehaptics/chhapticparametercurve`; `corehaptics/chhapticpatternplayer`; `corehaptics/chhapticadvancedpatternplayer`; `corehaptics/chhapticpatternplayer/start(attime:)`
- Sample code: `corehaptics/playing-a-custom-haptic-pattern-from-a-file` (HapticSampler); `corehaptics/delivering-rich-app-experiences-with-haptics`
- Timing: `foundation/timer` and `/tolerance`; `quartzcore/cadisplaylink` (and `timestamp`, `targettimestamp`, `preferredframeraterange`, `preferredframespersecond`); `swift/continuousclock`; `swift/suspendingclock`; `swift/clock`; `swift/task/sleep(until:tolerance:clock:)`; `quartzcore/cacurrentmediatime()`
- Audio and notifications: `avfaudio/handling-audio-interruptions`; `avfaudio/avaudiosession/interruptionnotification`; `avfaudio/avaudiosession/routechangenotification`; `avfaudio/avaudiosession/setprefersnointerruptionsfromsystemalerts(_:)`; `avfaudio/avaudiosession/category-swift.struct/playback` and `/ambient`; `bundleresources/information-property-list/uibackgroundmodes`; `usernotifications/scheduling-a-notification-locally-from-your-app`

Human Interface Guidelines

- Playing haptics: https://developer.apple.com/design/human-interface-guidelines/playing-haptics
- Motion: https://developer.apple.com/design/human-interface-guidelines/motion
- Accessibility: https://developer.apple.com/design/human-interface-guidelines/accessibility

Other Apple pages

- App Review Guidelines (2.5.4): https://developer.apple.com/app-store/review/guidelines/
- Reduced Motion evaluation criteria: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria

WWDC sessions

- Introducing Core Haptics (WWDC19 520): https://developer.apple.com/videos/play/wwdc2019/520/
- Practice audio haptic design (WWDC21 10278): https://developer.apple.com/videos/play/wwdc2021/10278/
- Wind your way through advanced animations in SwiftUI (WWDC23 10157): https://developer.apple.com/videos/play/wwdc2023/10157/
- Explore SwiftUI animation (WWDC23 10156): https://developer.apple.com/videos/play/wwdc2023/10156/ (read for background, nothing cited)
- Create accessible spatial experiences (WWDC23 10034): https://developer.apple.com/videos/play/wwdc2023/10034/

SDK headers (Xcode beta, iPhoneOS 27.0 SDK): `CoreHaptics.framework/Headers/CHHapticEngine.h`
