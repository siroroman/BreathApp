# watchOS 26 constraints for a timed breathing session

Research for issue #38. Researched 2026-11-08.

## Question

What does watchOS 26 impose on a standalone Apple Watch app that runs a Session of up to 20 minutes (Cycles of Phases, with the Haptic plan as the only cue when the eyes are closed)? Six questions, from the ticket: (1) how a Session keeps running or pauses when the wrist drops, the screen dims or the app goes to the background, and whether an extended runtime session is enough or a workout session is needed; (2) whether Core Haptics exists on watchOS and, if not, what `WKInterfaceDevice` offers and how the Kit's Haptic plan can be mapped; (3) how the Digital Crown steps through the Duration options; (4) the audio session setup for a short sound; (5) what a standalone watchOS app needs; (6) case sizes, Simulator names, and whether `performAccessibilityAudit()` and XCUITest work on watchOS. Primary sources only: Apple documentation, WWDC, the HIG, SDK headers and templates on this Mac.

## Short answer

- **With the wrist down a foreground-only Session stops (documented).** The app goes inactive but stays frontmost for 2 minutes by default, then goes to the background and is suspended. The 2 minutes is the user's Return to Clock setting (Always, After 2 minutes, After 1 hour, with a per-app override); developers cannot extend it since watchOS 7 (`isFrontmostTimeoutExtended` is "No longer supported" in the header). So a 20-minute Session cannot depend on foreground state.
- **The least that is documented to keep the app running is a `WKExtendedRuntimeSession` of type mindfulness (documented).** Frontmost, 1 hour limit, `WKBackgroundModes` = `mindfulness` in the Info.plist, no HealthKit and no entitlement named in the docs. Self care is 10 minutes, too short for 20. It ends if the person presses the Digital Crown or leaves the app, and must be started while the app is active. Which type is allowed is chosen by the app's purpose, not by the features; App Review's view of a breathing app under "mindfulness" is not stated in any primary source (unconfirmed).
- **Open and decisive: whether `WKInterfaceDevice.play(_:)` actually plays with the wrist down under such a session (documented, in conflict).** The `play(_:)` page says it has no effect while the app is inactive or in the background, except in a workout session. The extended runtime pages say a session lets the app "play sounds or haptics, even after the watch's screen turns off". Only a real watch can settle this. If it fails, the documented fallback is a workout session, which pulls in HealthKit (capability, entitlement, usage strings, an authorization prompt, `workout-processing`). Do not build #47 as finished until this is run on a device.
- **The iOS rule "pause whenever the scene is not active" cannot be copied (my reading).** On the watch the scene goes inactive on every wrist drop, which is the case this app must survive. The rule has to become "pause when the extended runtime session ends (or never started) and the scene is not active".
- **There is no Core Haptics on watchOS (documented, own check).** `CHHapticEngine` is `API_UNAVAILABLE(watchos)` and `CoreHaptics.framework` is not in the watchOS 26.2 or 27.0 SDK. `WKInterfaceDevice.play(_:)` plays one of 9 general `WKHapticType` values with no intensity, sharpness or duration. A second call stops the first and the system imposes a minimum delay of 100 ms; Apple warns about battery. A continuous rise or fall cannot be expressed; it can be approximated with a series of `.click` taps whose spacing follows the Haptic plan's intensity (my reading, section 2, untested).
- **Digital Crown: use the `detent:` overload with an `Int` index (documented).** `digitalCrownRotation(detent:from:through:by:sensitivity:isContinuous:isHapticFeedbackEnabled:onChange:onIdle:)` (watchOS 9) with `by: 1` over an index into the Duration options, on a `.focusable()` view. Detent haptics are on by default. How to keep the system crown indicator visible is not documented (unconfirmed).
- **Audio: no primary source covers a short sound on the speaker (gap).** Documented: long-form playback needs a Bluetooth route, and on supported models with watchOS 11 or later the built-in speaker also satisfies it; background audio needs the `audio` background mode. Not documented: the default-policy route for a short sound, and what Silent Mode does to it.
- **Standalone app (documented, own check).** A watchOS `application` target; Xcode adds `WKApplication = true` by itself. `BreathnestKit` links into it and builds (own check). `WKWatchOnly`, `WKCompanionAppBundleIdentifier` and `WKRunsIndependentlyOfCompanionApp` are all still current; nothing replaced them. The repo already has an iPhone app in the same project, so the choice is "independent app embedded in the iPhone app" or "watch-only app with its own record"; that is a decision for the owner (section 5).
- **396 x 484 is the 45 mm size in pixels, not points (documented, own check).** In points it is 198 x 242. The design doc calls it pt, and a 256 wide ring box does not fit a 198 pt wide screen, so the design numbers read as px (my reading). This changes every watch UI ticket unless the design doc is corrected (section 6).
- **Testing (documented, own check).** `XCUIApplication` and `performAccessibilityAudit(for:_:)` are declared for watchOS 10 and later; `XCUIDevice.rotateDigitalCrown` exists on watchOS. I could not get a watch UI test to run on this Mac (it hung; cause not found), so whether the audit works on a watch is unverified. Only the watchOS 27.0 Simulator runtime is installed here, not 26.

## Terms

`GLOSSARY.md` terms are used as defined: **Exercise**, **Pattern**, **Phase**, **Cycle**, **Session**, **Duration option**, **Lead-in**, **Quick Start**, **Breath level**, **Haptic plan**.

Name clashes to watch:

- Apple's APIs use "session" for other things: `WKExtendedRuntimeSession`, `HKWorkoutSession`, `AVAudioSession`. In this file "Session" always means the glossary term; the others are written "extended runtime session", "workout session" and "audio session", in lower case.
- SwiftUI's `ScenePhase` is "scene phase", never "Phase".
- Swift's `Duration` type is not the glossary's **Duration option**; the Duration options are the lengths the crown steps through.
- The design doc says "standalone". Apple has two different things: an **independent** watchOS app (an iPhone app may exist, the watch app does not need it) and a **watch-only** app (no iPhone app at all). Section 5 uses Apple's words.
- WatchKit's `WKHapticType.start` and `.stop` are not the start or end of a Session; "Phase start" is the Kit's.

## Source quality key

- **Doc page**: an Apple Developer Documentation page, read through the documentation JSON feed on 2026-11-08 with WebFetch, which summarises. Text in quotation marks was returned as a quote; everything else is paraphrased. Some current pages already describe the OS 27 releases; where that matters it is called out.
- **HIG / Support / App Store Connect Help**: Apple pages read the same way. "Support" is the Apple Watch User Guide, user-facing, not developer documentation.
- **Header**: a file in the Xcode SDK on this Mac. Two Xcodes are installed: Xcode 26.2 (`/Applications/Xcode.app`, watchOS 26.2 SDK, no watchOS platform runtime installed) and an Xcode 27.0 beta (`/Users/romansiro/Downloads/Xcode-beta.app`, build 27A5209h, watchOS 27.0 SDK, the active developer directory, the only watchOS Simulator runtime). Headers and `.swiftinterface` files are cited as "Xcode 26.2, watchOS 26.2 SDK" unless said otherwise.
- **WWDC**: Apple's video pages returned only the index to my fetcher, so I read the transcripts of WWDC19 251, 208 and 716 and WWDC18 504 through the nonstrict.eu mirror of Apple's transcripts, which carries a warning about transcription errors. Treat those quotes as secondary. WWDC21 10208, WWDC22 10133 and WWDC19 219 were read on developer.apple.com.
- **Own check**: something I ran myself, flagged as such, not an Apple statement. All own checks ran in scratch directories outside the repo, on the Xcode 27.0 beta with the watchOS 27.0 SDK and Simulator runtime, with deployment target 26.0. The behaviour on a watchOS 26 runtime was not tested. Every Simulator I booted was shut down again; no repo file was changed.
- **Unconfirmed**: a statement I could not confirm from a primary source. Marked with that word.
- **(C)**, **(R)**: in the ticket section, a documented constraint and my reading, as in the iOS note.

## 1. Running with the wrist down

### What the system does

- **Lifecycle (documented).** On watchOS an app is not running, inactive, active, background or suspended. Inactive means it is in the foreground but not receiving controls or gestures. When the wrist drops the system calls `applicationWillResignActive()`, the app stays inactive for as long as it is the frontmost app (2 minutes by default), then it enters the background (`applicationDidEnterBackground()`) and is suspended. If the person presses the crown or covers the screen the app skips the inactive wait and goes to the background at once. Doc pages: "Life cycles", "Working with the watchOS app life cycle".
- **Frontmost app state (documented).** Frontmost apps stay in the foreground and "may respond to other events", can play haptics, receive notifications and get up to four background refresh tasks an hour. By default the app stays frontmost "for two minutes", set by the user under Settings > General > Return to Clock (a default for all apps, with a per-app override). Raising the wrist reactivates the frontmost app. Series 5 and later blur the UI and show the time; SE and Series 4 and earlier turn the screen off. Doc page: "Taking advantage of frontmost app state". Support page: "Adjust the display settings on Apple Watch" (Always, After 2 minutes, After 1 hour).
- **No way to extend it (documented).** `WKExtension.isFrontmostTimeoutExtended` is `WK_DEPRECATED_WATCHOS(4.0, 7.0, "No longer supported")`; the frontmost page says that since watchOS 7 the user controls the duration. Header: `WatchKit.framework/Headers/WKExtension.h`.
- **Haptics and the app state (documented, in conflict with the next point).** `WKInterfaceDevice.play(_:)` "has no effect when called while ... applicationState property is either background or inactive. By default, you cannot play haptic feedback in the background. The only exception are apps with an active workout session." Doc page: `WKInterfaceDevice.play(_:)`. The frontmost page, in contrast, lists "play haptic feedback" among the things a frontmost app can do.
- **Scene phase (documented in general, nothing watch-specific).** `.active`, `.inactive` ("in the foreground but should pause its work") and `.background` ("isn't currently visible in the UI"); `ScenePhase` is available from watchOS 7. The pages I read do not say how the wrist drop maps to a scene phase; the lifecycle page speaks only of delegate callbacks (`WKApplicationDelegate`, watchOS 7, header `WKApplication.h`; the docs mark the `WKExtensionDelegate` pages deprecated). I read "inactive, then background after the frontmost time" as the sequence, which is what the lifecycle page says. One page ("Handling common state transitions", as returned to me) says the app "enters the background state" on a wrist drop with no inactive wait, which disagrees with the lifecycle page; I took the lifecycle page, but the sequence on a real watch is unconfirmed. `SwiftUI` also offers `WKApplicationDelegateAdaptor` for delegate callbacks (Xcode 26.2 SwiftUI interface).
- **Always On (documented).** From watchOS 8 the system keeps the view on screen on wrist down by default and dims it; `isLuminanceReduced` (watchOS 8) is `true` then. The key `WKSupportsAlwaysOnDisplay` (default YES) says the app is shown in the Always On state "when the app is the frontmost app or running an active background session". Users can turn Always On off device-wide or per app, and Always On is not available in Low Power Mode (Support). Inactive apps' UI "doesn't update by default"; use a `TimelineView`, whose context carries a cadence (`.live`, `.seconds`, `.minutes`). Apps in a background session may keep updating but "the system reduces the update frequency". The page says to pause animation, show a final or static state and remove subsecond updates. Doc pages: `isLuminanceReduced`, `WKSupportsAlwaysOnDisplay`, "Designing your app for the Always On state"; HIG "Always On". Whether a frontmost extended runtime session counts as a "background session" for this is unconfirmed.

### The options for running with the wrist down

| Option | Keeps the Session alive with the wrist down | Limit | What it needs |
|---|---|---|---|
| Nothing (foreground only) | Frontmost-inactive for the Return to Clock time (2 minutes by default), then suspended | 2 minutes default, user setting | nothing |
| Extended runtime session: self care | yes, frontmost | 10 minutes | `WKBackgroundModes` = `self-care` |
| Extended runtime session: **mindfulness** | yes, frontmost | **1 hour** | `WKBackgroundModes` = `mindfulness` |
| Extended runtime session: physical therapy | yes, in the background | 1 hour | `physical-therapy`; intended for stretching and range-of-motion |
| Extended runtime session: smart alarm | yes, in the background, schedulable up to 36 hours ahead | 30 minutes | `alarm`; for waking the user, uses heart rate and motion |
| Workout session (`HKWorkoutSession`) | yes, in the background; haptics allowed | until ended | HealthKit capability, see below |
| Background audio | only while audio plays | as long as audio plays | `audio` background mode, an audio route, see section 4 |

Table sources: doc pages "Using extended runtime sessions" (types, runtime and limits), `WKBackgroundModes` (values; only one of `self-care`, `mindfulness`, `physical-therapy`, `alarm` at a time, combinable with `workout-processing`; `underwater-depth` is also listed), "Background execution".

### Extended runtime sessions in detail

- **Which exist on watchOS 26 (documented).** Four, as in the table: self care, mindfulness, physical therapy, smart alarm. `WKBackgroundModes` also lists `underwater-depth`. I found nothing new for watchOS 26 in the watchOS 26 release notes. Each app supports one type. `WKExtendedRuntimeSession` exists since watchOS 6.0.
- **Which fits (my reading).** Mindfulness is the only frontmost type with a limit over 20 minutes; its description is "Help users start and end silent meditation sessions" and Apple's the WWDC19 251 transcript (mirror only, unconfirmed) says it "provides runtime for meditations where audio is not played continuously". A guided breathing Session with haptics and short sounds is close; the docs say to pick by intended use, not by features, and give no list of what App Review accepts. Self care ("relatively brief activities") would be the closer wording for a short exercise but 10 minutes is too short. Physical therapy and smart alarm are for other purposes and should not be chosen to get runtime (my reading from "select a session type based on the app's intended use").
- **What a frontmost session does (documented).** The app keeps running "in the foreground. The watch screen doesn't need to remain on to keep your app alive." It ends when the time limit expires, the app invalidates it, or "the user explicitly leaves your app (for example, by pressing the digital crown or switching to a different app)". Unconfirmed (mirror transcript of WWDC19 251 only): the session, speaking of the self care type, says the screen turns off on wrist drop while the session continues; another speaker says the app "will remain frontmost for some time after", so it becomes active again on a wrist raise (I take the mindfulness type to behave the same, since both are frontmost: my reading). Header `WKExtendedRuntimeSession.h` gives `ResignedFrontmost` as an invalidation reason, with the examples of pressing the crown, tapping a notification, switching apps in the Dock, or another app coming to the front.
- **What it does to the frontmost timeout (unconfirmed).** No page says whether the 2-minute Return to Clock timer still applies to a running frontmost session. The text says the session continues until the limit, invalidation or the person leaves; so my reading is that the timer does not end it. A device test is needed.
- **Start rules (documented).** Start it only while the app is active (`WKExtendedRuntimeSessionErrorMustBeActiveToStartOrSchedule`); set the delegate before `start()`; one session at a time per app (`SessionInProgress`); `invalidate()` ends it early. Other error codes worth handling: `NotApprovedToStartSession` ("the app is missing a valid plist key or entitlement"), `BARDisabled` ("the BAR switch for the application is disabled", that is Background App Refresh off for this app), `ExceededResourceLimits`, and the invalidation reason `SuppressedBySystem`. Header: `WKExtendedRuntimeSession.h`.
- **CPU (documented).** Sustained high CPU may get the session cancelled; Apple points to Xcode's CPU report and Instruments. A Session that wakes a few times a second is a small load (my reading, not measured).
- **Haptics while it runs (documented, conflicting).** Extended runtime sessions "let the app continue to communicate with a Bluetooth device, process data, or play sounds or haptics, even after the watch's screen turns off" (docs, "Using extended runtime sessions" and "Background execution"). Against that the `play(_:)` page above. Both are Apple pages and I found no page that reconciles them. **Unconfirmed; needs a device.**
- **`notifyUser(hapticType:repeatHandler:)` is not a fit (documented).** The header says it works only on a session scheduled with `startAtDate:` and currently running, that is the smart alarm type, and is ignored otherwise; it repeats a haptic until the person stops it. The doc page's warning that failing to play a haptic makes the system "display a warning and offer to disable future sessions" appears in the smart-alarm passage; it does not name a type, so whether it applies to mindfulness is unconfirmed.
- **Simulator (own check, negative).** In the watchOS 27.0 Simulator (Series 11, 46 mm) a minimal app with `WKBackgroundModes` = [`mindfulness`] (verified in the built Info.plist), started from the foreground, got `didInvalidate` at once with reason `.error` and `WKExtendedRuntimeSessionErrorCode` 1 (`unknown`), and `state` was invalid (3) three seconds later with `expirationDate` nil. An app without the key was invalid at once too. So I could not run an extended runtime session in the Simulator, and I do not know whether the Simulator supports them at all or the key was not enough; a real watch is needed, and the app must treat a failed start as "no background runtime".
- **Time limit expiry.** `extendedRuntimeSessionWillExpire(_:)` is called before it ends and `expirationDate` says when. A 20-minute Session fits inside 1 hour, but the limit counts from the start of the extended runtime session, not from the Session's running time; a long pause could outlast it (my reading).

### Would a workout session be needed?

- **What it gives (documented).** An active `HKWorkoutSession` lets the app run in the background for the whole session, and is the one documented exception that lets `play(_:)` work in the background. The page "Running workout sessions" also says apps that play audio or provide haptic feedback during the session must add the **Audio** background mode as well as Workout processing. The mindfulness page itself points walking meditation to `HKWorkoutSession`.
- **What it requires (documented).** The HealthKit capability (`com.apple.developer.healthkit`), `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` in the WatchKit app, `WKBackgroundModes` = `workout-processing` (plus `audio` as above), and an authorization request for at least the workout type before the session starts; the permission prompt appears on the watch. Only one workout session runs at a time (a second one ends yours). Doc pages: "Running workout sessions", "Setting up HealthKit", `HKWorkoutSession`. The page for `play(_:)` also warns that calling it while gathering heart rate data with HealthKit stops the heart rate gathering until the haptic finishes.
- **App Review (documented text, my reading of its fit).** Guideline 2.5.1: "HealthKit should be used for health and fitness purposes and integrate with the Health app". 5.1.3 limits use of the data gathered. A workout session for a breathing exercise that records nothing is an unusual use; whether App Review accepts it is not stated (unconfirmed). Workout sessions are also out of scope for this project (HealthKit is out of scope).
- **Guideline for extended runtime (documented text).** 2.5.4: "Multitasking apps may only use background services for their intended purposes: VoIP, audio playback, location, task completion, local notifications, etc." Extended runtime sessions are not named there; the docs' own rule is "select a session type based on the app's intended use".

### Recommended approach

- Use a **mindfulness `WKExtendedRuntimeSession`** for the Session, start it when the person taps Start (the app is active), invalidate it on Stop, on Done and at natural end, and set `WKBackgroundModes` = [`mindfulness`] in the watch target. The docs name only the Info.plist key for it, no HealthKit and no entitlement; the header's `NotApprovedToStartSession` comment says "plist key or entitlement", so whether any entitlement applies to this type is unconfirmed.
- Treat the extended runtime session as the owner of "may run without being active": while it runs, an inactive scene does not pause the Session. Pause (and stop haptics) when the session invalidates for any reason other than the Session finishing, and when it never started (for example `BARDisabled`) and the scene is not active. This is a product change from the iPhone rule (see #45).
- **Before #47 and #45 are called done, test on a real watch with the screen off:** does `WKInterfaceDevice.play(_:)` play while the scene is inactive inside the extended runtime session; does the session survive 20 minutes with the wrist down and with Always On off; what does `scenePhase` report; what the Return to Clock setting does; and whether Always On keeps the Progress screen updating. If `play(_:)` is dropped, the options are the workout session (HealthKit, out of scope without a decision) or accepting that haptics work only while the screen is active (a design change, since eyes-closed use is the point).
- Do not use `notifyUser`, the physical therapy or smart alarm types, or the audio mode just to keep running.

**Apple sources**: pages named above; headers `WKExtendedRuntimeSession.h`, `WKApplication.h`, `WKExtension.h`, `WKInterfaceDevice.h`.

**Unverified**: all items marked unconfirmed above, the `scenePhase` values on wrist drop, App Review's position on a breathing app using the mindfulness type.

## 2. Haptics

### Availability

- **Core Haptics is not on watchOS (documented, own check).** The framework page and the `CHHapticEngine` page list iOS 13, iPadOS 13, Mac Catalyst 13, macOS 10.15 (engine only), tvOS 14 and visionOS 1.0, and no watchOS. Header: `CHHapticEngine.h` in the iPhoneOS 26.2 SDK marks the class `API_UNAVAILABLE(watchos)`. **Own check:** `ls` of `System/Library/Frameworks` in the watchOS 26.2 SDK (`/Applications/Xcode.app/Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS26.2.sdk`) and the watchOS 27.0 SDK in the Xcode beta shows no `CoreHaptics.framework`.
- This agrees with the iOS note, which recorded `CHHapticEngine` as `API_UNAVAILABLE(watchos)`, and with ADR 0001: the Kit has no Core Haptics, and the adapter is per platform.

### What watchOS offers

- **`WKInterfaceDevice.current().play(_:)` (documented).** `func play(_ type: WKHapticType)`, watchOS 2.0. "Use this method to engage the haptic engine in Apple Watch." The header spells it `playHaptic:`. There is no intensity, sharpness or duration parameter (header `WKInterfaceDevice.h`).
- **`WKHapticType` (documented; header `WKInterfaceDevice.h`, doc page).** `notification`, `directionUp`, `directionDown`, `success`, `failure`, `retry`, `start`, `stop`, `click` (the general set), plus `navigationLeftTurn`, `navigationRightTurn`, `navigationGenericManeuver` (the header says only usable "while the app has an active navigation session running") and `underwaterDepthPrompt`, `underwaterDepthCriticalPrompt` (only with an active underwater depth session). Meanings, from the doc page and the HIG "Playing haptics": `directionUp` "an increase ... or when a value has gone above a certain threshold"; `directionDown` the opposite; `start`/`stop` the beginning and end of an action; `click` "the sensation of a dial clicking, helping you communicate progress at predefined increments or intervals", with the warning that overusing it "tends to diminish its utility and can even be confusing when clicks overlap each other".
- **Rate (documented).** The page says not to call it "multiple times in quick succession". If the haptic engine is already engaged, "the system stops the current feedback and imposes a minimum delay of 100 milliseconds before engaging the engine to generate the new feedback". It gives no call quota. It warns that heavy use "may create a noticeable drain on the Apple Watch battery". It does not say how long each type lasts (unconfirmed), so the real minimum useful interval between two different types is unknown.
- **App state (documented).** Only while the scene is active (or in a workout session); see section 1.
- **SwiftUI `sensoryFeedback(_:trigger:)` (documented).** watchOS 10.0. It plays a `SensoryFeedback` when a value changes: `success`, `warning`, `error`, `selection`, `increase`, `decrease`, `start`, `stop`, `alignment`, `levelChange`, `pathComplete`, `impact`, `impact(weight:intensity:)`, `impact(flexibility:intensity:)`, plus `press`, `release` and `selection` variants (Xcode 26.2 SwiftUI interface). `impact` "Only plays feedback on iOS and watchOS", and "Not all platforms will play different feedback for different weights and intensities". Which `SensoryFeedback` plays which `WKHapticType`, and whether `intensity` changes anything on a watch, is not documented (unconfirmed). It is also tied to a view update, and an inactive app's UI "doesn't update by default" (section 1), so it is a poor fit for ticks while the wrist is down (my reading).
- **System settings (Support).** Users can set Haptics to Default, Prominent ("adds an additional haptic tap that pre-announces some of your other haptic alerts") or Off, and Crown Haptics and System Haptics separately. Silent Mode silences alerts, notifications and sound effects but haptics "still" come through. Whether Haptics Off or Prominent changes what `play(_:)` does for an app is not stated (unconfirmed). Support pages: "Change the volume, audio, and haptic settings on your Apple Watch", "Adjust volume and haptics on Apple Watch".
- **HIG (documented).** Use system haptics for their documented meanings; where none fits "use a generic pattern or create your own, where supported" (not supported by WatchKit); prefer short haptics for discrete events; make haptics optional; match the haptic to the animation it accompanies.

### Can a rise and a fall be approximated?

- **Not as one continuous event (documented).** There is no continuous haptic and no intensity control in WatchKit or in `sensoryFeedback`.
- **As a series of discrete taps (my reading, untested).** The Haptic plan's inhale is intensity 0.35 to 1.0 following the Breath level curve, exhale 1.0 to 0.65. If amplitude cannot change, rate can: tap more often when the intensity is high. Nothing in the sources says that a changing tap rate is felt as a rise or a fall; this is my proposal and must be felt on a watch.

### Proposed mapping (my reading unless marked)

| Kit Haptic plan item | watchOS call | Basis |
|---|---|---|
| Hold or rest: a transient at the Phase start and every second after (intensity 1.0, sharpness 1.0) | `.click` at the Phase start and at every whole second | One-to-one with the plan; one tap a second is far from the 100 ms floor. `click` is "progress at predefined increments" (HIG). |
| Inhale start | `.directionUp` once, then ticks | Weakly fits "a value rose" (HIG); the only general type with a direction. Duration of the type unknown, so the first tick must wait (see below). |
| Exhale start | `.directionDown` once, then ticks | Same. |
| Inhale body (continuous, intensity 0.35 to 1.0, sharpness 0.7) | `.click` taps, spacing shrinking as the intensity rises | Spacing = f(intensity): the adapter samples the plan's intensity along the Phase. |
| Exhale body (continuous, 1.0 to 0.65, sharpness 0.25) | `.click` taps, spacing growing as the intensity falls | Same. |
| Sharpness | ignored | There is no sharpness on watchOS. |

- **Tick cadence, a starting value to tune on a device, not documented:** spacing about 0.30 s at intensity 1.0 and about 0.60 s at intensity 0.35 (linear in between), so an inhale goes from about 0.6 s to about 0.3 s between taps and an exhale back to about 0.45 s. These numbers are mine. Three constraints bound them: never closer than the documented 100 ms floor (a closer call stops the previous haptic), no tap in the first beat after a `directionUp` or `directionDown` marker (its length is unknown, a later call stops it; start with about 0.4 s and tune), and battery (the page gives no figures; 20 minutes at the fastest spacing, about 3 taps a second, is 3,600 calls, and what that costs I have not measured).
- **A cheaper variant, if the dense ticks feel wrong or drain too much:** one marker at each inhale and exhale start and per-second `.click` taps in hold and rest only. That is exactly the plan's hold/rest rule plus two markers, and every call is one a second or less. It does not follow the shape, so it fails the spirit of #47; use it as the fallback.
- **Single source of truth.** The tick times should come from a pure function in the Kit (Phase kind, Phase length, Breath level curve in, tick offsets out), so `swift test` covers them and the adapter only calls `play(_:)` (my reading; ADR 0001 keeps feel numbers in the Kit and the adapter in the app). `Pattern.breathLevel(at:)` already exists; the Haptic plan (#26) carries start and end intensity only, as the ticket describes it, so the intensity along the Phase has to be derived from the level curve or added to the plan. That is a #26 or #47 decision.
- **Pause and Resume.** Cancel scheduled ticks on pause, do not replay the current Phase's ticks on resume (matches #32), and cancel on Stop, Done and invalidation of the extended runtime session. One `Task` that sleeps to absolute instants is enough (same clock rules as the iOS note, section 5).

### What cannot be tested in the Simulator

- Feel: nothing can be felt in a Simulator, so every choice above (marker type, spacing, whether a rise is perceived) is a device test. (The iOS note records older Apple sources for the iPhone Simulator; I found no Apple statement for the watch Simulator.)
- Own check: `WKInterfaceDevice.current().play(.click)` returned without error or crash in the watchOS 27.0 Simulator (Series 11, 46 mm). That says nothing about what it does on a watch; the Simulator shows nothing.
- The 100 ms rule, the interplay between `directionUp` and the following tap, the effect of System Haptics settings, and whether it plays with the wrist down are all device-only.

### Recommended approach

- Build the adapter on `WKInterfaceDevice.current().play(_:)`, called from the Session model's task (not from a view), mapped as above. Keep the Kit free of WatchKit.
- Start with the dense-tick mapping, put the cadence constants in the Kit as data, and judge it on a watch; fall back to the cheaper variant if the first feels wrong.
- Gate it by the Haptics switch and by the extended runtime session test in section 1.

**Apple sources**: `WKInterfaceDevice.play(_:)`, `WKHapticType`, `WKInterfaceDevice`, `sensoryFeedback(_:trigger:)`, `SensoryFeedback`, `SensoryFeedback.impact(weight:intensity:)`, Core Haptics framework and engine pages, HIG "Playing haptics", headers `WKInterfaceDevice.h` and `CHHapticEngine.h`, Support "Adjust volume and haptics".

## 3. Digital Crown

### Constraint

- **The modifier (documented).** `digitalCrownRotation(_:from:through:by:sensitivity:isContinuous:isHapticFeedbackEnabled:)`, watchOS 6.0, takes a `Binding<V>` where `V: BinaryFloatingPoint`. `by` means "the value settles on multiples of stride". `sensitivity` is "how much the user needs to rotate the Digital Crown to move between two integer numbers" (`.low`, `.medium`, `.high`, default `.high`; Apple says "You may need to experiment"). `isContinuous: false` (default) stops at the ends; `true` wraps. `isHapticFeedbackEnabled` defaults to `true`. Doc pages; Xcode 26.2 SwiftUI interface.
- **The `detent:` overload (documented).** `digitalCrownRotation(detent:from:through:by:sensitivity:isContinuous:isHapticFeedbackEnabled:onChange:onIdle:)`, watchOS 9.0, has both a floating-point and a `BinaryInteger` form (so an `Int` binding), takes a non-optional `by`, and "will always be updated to a value that is a multiple of the stride". `onChange` gets a `DigitalCrownEvent` (`offset`, `velocity`) while turning and `onIdle` when it settles. WWDC22 10133 defines the detent as "the resting notch position of the crown on your view" and binds it to an integer index. Doc page; Xcode 26.2 SwiftUI interface.
- **Focus (documented).** Every Apple example puts `.focusable()` on the same view before `digitalCrownRotation`; WWDC19 219 says "focusable will feel very familiar ... a lot like the UI Focus Engine", i.e. the crown goes to the focused view. `focusable(_:)` is in the watchOS 26.2 SwiftUI interface. I found no page that states the requirement in words, so "crown input needs focus" rests on the examples and the WWDC19 comparison.
- **Detent haptics (documented).** The HIG says by default "the system provides linear haptic detents" as the crown turns, most models give haptic feedback for the crown, and an app may turn the detents off if they do not match its animation. WWDC19 219 says `by` is the stride along which the crown gives haptic feedback and settling. Users can switch Crown Haptics off (Support).
- **The crown indicator (unconfirmed).** `digitalCrownAccessory(_:)` (watchOS 9) is about an accessory view; its page says "You may want to keep an accessory visible even when the Digital Crown Indicator is not visible", which confirms the system indicator is sometimes hidden. I found no documented API to force the indicator on, and no page that states when it appears. The design says to use the system one; its visibility rules need to be seen on a device or in the Simulator.
- **HIG (documented).** Update the interface at a speed a person can follow and "avoid updating content at a rate that makes it difficult for people to select values"; pickers show the current value as the crown turns.

### Gotchas

- **Non-uniform values.** The Duration options are a short, uneven list per Exercise (in `BreathnestKit/Sources/BreathnestKit/Exercise.swift`: Box breathing 1, 3, 5, 10 min; 4-7-8 1:15, 2:00, 2:30; Coherent breathing 1, 5, 10, 20 min; Physiological sigh 1, 5, 10 min). A stride of 1 over the minutes would skip or invent values (my reading). Bind to an `Int` index into the Kit's Duration options and derive the displayed length from it.
- **Binding type.** The older overload accepts only floating-point values; the `detent:` overload accepts `Int`, which is the better type for an index (documented).
- **Focus.** The view with the modifier must be the focused one. The screen has nothing else focusable ("nothing else is on the screen", design 4), which helps; tapping to go on (decisions, #39) must not take the focus away (my reading; test).
- **`isContinuous`.** Keep `false` so the crown stops at the first and last options. `true` wraps (documented).
- **Simulator (documented, own check).** The device types carry the feature `com.apple.hid.digital-crown` (own check, Simulator device profile for Apple Watch Series 11 (46mm)). The archived Simulator guide says dragging up or down in the watch's content window turns the crown, quickly for a fast turn (an older page, "deprecated in Xcode 9", to be checked with Simulator Help). In tests, `XCUIDevice.rotateDigitalCrown(delta:)` ("1.0 represents one full rotation", `watchOS` header, Xcode 13 and later per WWDC21 10208). Whether the Simulator plays crown detent haptics is unconfirmed; they cannot be felt there.
- **Sensitivity is not specified in numbers.** Apple gives no rotation per step; choose by feel on a device.

### Recommended approach

- `Text` (the value) with `.focusable()` and `.digitalCrownRotation(detent: $index, from: 0, through: options.count - 1, by: 1, sensitivity: .medium, isContinuous: false)`, an `Int` index, default haptics on, and the system indicator left to the system. Start the index at the Kit's default option.
- Try `.medium` first (the sample in WWDC22 10133 uses it for an integer index) and tune on a device.
- Give VoiceOver users a way to change the value without the crown (the design has no button; this is a design question for #43 and #50, since a crown-only control cannot be the only way for someone who does not use the crown; whether VoiceOver can turn the crown on its own is unconfirmed).

**Apple sources**: `digitalCrownRotation(_:from:through:by:sensitivity:isContinuous:isHapticFeedbackEnabled:)`, `digitalCrownRotation(detent:...)`, `digitalCrownAccessory(_:)`, `DigitalCrownRotationalSensitivity`, `focusable(_:interactions:)`, HIG "Digital Crown", WWDC19 219, WWDC21 10208, WWDC22 10133, `XCUIDevice.h` (watchOS), archived Simulator guide.

## 4. Audio

### Constraint

- **Categories on watchOS (documented, header).** `AVAudioSession` exists on watchOS (2.0). Ambient, solo ambient, playback, record, play-and-record and multi-route are available there; `.ambient` "Screen locking and the Silent switch (on iPhone, the Ring/Silent switch) silence your audio", `.playback` continues with the Silent switch set to silent or when the screen locks and, by default, "activating your session will interrupt any other audio sessions which are also nonmixable" (`mixWithOthers` allows mixing). Doc pages: `Category.ambient`, `Category.playback`; header `AVAudioSessionTypes.h`. Those pages talk about iPhone's Ring/Silent switch; the watch has no such switch (it has Silent Mode in Control Center), and what these categories do with Silent Mode on a watch is unconfirmed.
- **Long-form audio on watchOS (documented).** "watchOS requires a Bluetooth audio route for long-form audio." Set category `.playback` and route policy `.longFormAudio`, then activate with `activate(options:completionHandler:)` (watchOS 5.0), not `setActive`. The system presents a route picker when no Bluetooth route is selected, and passes an error if no route results. The newer `activate` page adds: "On supported Apple Watch models running watchOS 11.0 or later, the built-in speaker also satisfies this routing requirement"; if no Bluetooth route is available and the watch supports speaker playback the system routes to the speaker, otherwise it shows the picker; and "On watchOS, long-form audio can't play through the built-in speaker while the watch is charging". Which models are "supported" is not stated (unconfirmed). Doc pages: "Playing Background Audio", `activate(options:completionHandler:)`, `RouteSharingPolicy.longFormAudio`; header `AVAudioSession.h`. Unconfirmed (mirror transcript of WWDC18 504 only): it says long-form content is restricted to Bluetooth routes; that was before watchOS 11.
- **Short sounds (unconfirmed).** No page I read states which route a short, foreground sound uses with the default policy, or whether the built-in speaker is allowed for it on watchOS 26. Unconfirmed (mirror transcript of WWDC18 504 only): it names `AVAudioPlayer` and `AVAudioEngine` for playback and says `WKAudioFileQueuePlayer` is for long-form content; `WKAudioFilePlayer` is deprecated in favour of AVFoundation's `AVPlayer` (doc page). I can only say what is documented for long-form playback.
- **Background audio (documented).** Enable the Audio background mode capability; the page says this sets `UIBackgroundModes` in the extension's Info.plist, without giving the value (the key page lists `audio` with no description; `WKBackgroundModes` does not list audio). Apps with the long-form policy "are able to play audio in the background, as long as the audio session can activate an eligible audio route". The mindfulness description says an app that plays audio during the whole meditation does not need an extended runtime session, because "the background audio mode provides additional runtime as long as the audio plays". A short chime is not "as long as audio plays".
- **Sounds during an extended runtime session (documented, partly).** The doc says extended runtime sessions let the app "play sounds or haptics, even after the watch's screen turns off"; it does not say which audio route or category.
- **Silent Mode (Support, partial).** Silent Mode "silence[s] all alerts" and mutes notifications and sound effects; haptics still play. The pages I read do not say whether it silences third-party app audio (unconfirmed). The Support page on volume says media volume is adjusted with the crown "while audio media is playing".
- **Interruptions and route changes (documented, header).** `AVAudioSessionInterruptionNotification` (watchOS 2.0), `AVAudioSessionRouteChangeNotification` (watchOS 2.0), `AVAudioSessionInterruptionReasonKey` (watchOS 7.3), `AVAudioSessionInterruptionOptionShouldResume`, and `setPrefersNoInterruptionsFromSystemAlerts` (watchOS 7.3). Unconfirmed (mirror transcript of WWDC18 504 only, no developer.apple.com page read): a phone call on the paired iPhone will not take the route onto the watch. Handling follows the iOS note's section 3: pause on an interruption that begins, do not resume on its own.
- **App Review (documented text).** 2.5.4 says background services may be used only for their intended purposes, "audio playback" among them, which covers the audio background mode; 2.5.9 rejects apps that alter or disable the Ring/Silent switch. That a watch app should therefore respect Silent Mode is my reading.

### What the app needs while a Session runs (my reading)

- Sounds are optional (the design's Sound switch) and haptics are the primary cue. For short sounds on the speaker or headphones inside the extended runtime session: category `.playback` with `mixWithOthers` (so a person's own audio is not stopped), activated when the Session starts and deactivated when it ends; `AVAudioPlayer` with the preloaded file. Whether `activate(options:completionHandler:)` or `setActive(true)` is right for the default policy is not documented (the docs require `activate` for the long-form policy and for the route picker). Because the documented speaker rule is for long-form audio only, the safest documented path is the long-form policy with `activate`, which has the route picker as a safety net, but it would route a chime like a podcast and uses the long-form route, which may interrupt Music.
- Own check, Simulator only (watchOS 27.0, Series 11 46 mm): `setCategory(.playback, mode: .default, options: [.mixWithOthers])` and `setActive(true)` both succeeded and `currentRoute.outputs` was `Speaker`. That is a Simulator route, not evidence about the hardware speaker, Silent Mode, charging or Bluetooth, and I did not play a sound. Nothing here is tested on a watch.

### Recommended approach

- Do not decide the audio path in #48; the ticket does not play sounds. In the playback ticket after #49, build the minimum: one `AVAudioSession` adapter behind a Kit seam, `.playback` + `mixWithOthers`, activation at Session start, and an interruption handler that pauses. Test on a watch on the speaker, on AirPods, in Silent Mode and while charging, and write the results into the note or the ticket.
- Do not add the `audio` background mode unless the device test shows a chime cannot play from the extended runtime session without it (App Review 2.5.4 risk, my reading).

**Apple sources**: pages named above; `AVAudioSession.h`, `AVAudioSessionTypes.h`; WWDC18 504, WWDC19 251 and 716 (mirror); Support pages "Adjust volume and haptics on Apple Watch" and "Change the volume, audio, and haptic settings on your Apple Watch".

## 5. Standalone app

### Constraint

- **Kinds (documented).** An **independent** watchOS app does not need the iPhone app ("people can choose to install the watchOS app, the iOS app, or both"); it can have a companion or be **watch-only**. A watch-only app has no iOS app. A dependent app (the default when Xcode makes a watch app with an iOS app) needs both. Doc page: "Creating independent watchOS apps".
- **What an independent app must do on its own (documented).** Sign in and create accounts, ask for permissions on the watch, download its own data, not rely on Watch Connectivity as its main source, send push notifications directly. Nothing in the app so far needs the iPhone (the iPhone saves nothing, ticket #41).
- **Targets (documented).** A single watchOS app target since Xcode 14 (the Xcode 14 release notes: "combines the WatchKit App and WatchKit App Extension targets into a single Watch App target", deployable to watchOS 7 and later). Doc page: "Setting up a watchOS project" (create via the watchOS App template: "Watch-only App", "Watch App with New Companion iOS App", or add a watch target "for Existing iOS App").
- **Info.plist keys (documented, own check).**

| Key | Meaning | Source |
|---|---|---|
| `WKApplication` | watchOS 7.0; the doc page has no text. | Own check: Xcode adds `WKApplication = true` by itself for a watchOS `application` target (a build with no setting for it produced it). Not a build setting, so do not set it by hand. |
| `WKWatchOnly` | "the app is only available on Apple Watch, with no related iOS app". Build setting `INFOPLIST_KEY_WKWatchOnly`. | Doc page; Xcode 26.2 `CoreBuildSystem.xcspec`. Not deprecated. |
| `WKCompanionAppBundleIdentifier` | The bundle ID of the iOS companion; "should be the same as the iOS app's `CFBundleIdentifier`". | Doc page. Not deprecated. |
| `WKRunsIndependentlyOfCompanionApp` | "the app doesn't need its iOS companion app to operate properly. Users can choose to install the iOS app, the watchOS app, or both." | Doc page. Not deprecated. |
| `WKWatchKitApp`, `WKAppBundleIdentifier`, `WKExtensionDelegateClassName` | Older extension-era keys the "Setting up" page still lists; not needed in a single-target SwiftUI app (my reading). | Doc page. |

  So nothing *replaced* `WKCompanionAppBundleIdentifier` or `WKRunsIndependentlyOfCompanionApp`; which keys apply depends on the shape in the next bullets.
- **Bundle identifiers.**
  - Xcode 26.2 templates (own check, `Platforms/WatchOS.platform/Developer/Library/Xcode/Templates/Project Templates/watchOS/Application`): the "Watch-only App" template sets `INFOPLIST_KEY_WKWatchOnly = YES`, gives the watch app the id `<prefix>.<name>.watchkitapp` and also creates an iOS **stub** target of product type `com.apple.product-type.application.watchapp2-container` (`<prefix>.<name>`, resources only). "Watch App for Existing iOS App" sets `INFOPLIST_KEY_WKCompanionAppBundleIdentifier` to the iOS app's id and the watch app's id to `<iOS id>.watchkitapp`. The doc page says the root bundle identifier is used "for Universal Purchase and cross-device communication, such as Device Discovery" and the stub "acts as an iOS wrapper"; nothing is installed on the paired iPhone.
- **Deployment target (documented, own check).** A deployment target of watchOS 26.0 is written as `MinimumOSVersion = 26.0` in the built Info.plist (own check).
- **Distribution (documented).** App Store Connect Help: the app record is created in the **iOS** platform ("In the New App dialog, select iOS"), Apple Watch screenshots are needed ("Required for Apple Watch apps", one size used for all localizations, ASC "Screenshot specifications"), and "Watch-only apps can't be part of a universal purchase". To offer an app on iPhone and Apple Watch, "create an iOS app in Xcode that includes a watchOS counterpart. Upload both apps ... from the same Xcode project." The two pages (independent apps page: root bundle id for Universal Purchase; ASC: watch-only apps cannot be part of one) read as inconsistent for watch-only apps; I could not reconcile them. Adding an iOS app to an existing watch-only record is not covered by any page I read (unconfirmed).
- **Can the Kit be linked into a watchOS target? (own check: yes.)** In a scratch XcodeGen project: `type: application`, `platform: watchOS`, `deploymentTarget: watchOS "26.0"`, `dependencies: - package: BreathnestKit` on a copy of `BreathnestKit` (its `Package.swift` already declares `.watchOS(.v26)`), a SwiftUI `App` that `import BreathnestKit`: `xcodebuild -destination 'generic/platform=watchOS Simulator'` printed `BUILD SUCCEEDED`. XcodeGen 2.44.1, Xcode 27.0 beta, watchOS 27.0 SDK.
- **Embedding in an iPhone app (own check).** A second scratch project with an iOS `application` target that lists the watch target under `dependencies:` produced `Phone.app/Watch/Watch.app`; the watch Info.plist had `WKApplication`, `WKCompanionAppBundleIdentifier` and `WKRunsIndependentlyOfCompanionApp` (set through `INFOPLIST_KEY_...`) and `UIDeviceFamily = 4` even though the project's base settings carried `TARGETED_DEVICE_FAMILY: "1"`. The repo's `project.yml` has the same base setting, so it did not leak into the watch target in this probe. That was a debug simulator build, not an archive: no signing, no App Store Connect validation (unconfirmed).
- **What `project.yml` needs (my reading).** Add `deploymentTarget: watchOS: "26.0"`; a target `type: application`, `platform: watchOS`, `dependencies: [package: BreathnestKit]`, `GENERATE_INFOPLIST_FILE: YES`; for background modes an `info:` block (own check: `info: path:, properties: WKBackgroundModes: [mindfulness]` was merged into the generated plist); a scheme and a UI test target for the watch. `SWIFT_TREAT_WARNINGS_AS_ERRORS: YES` in the base settings applies to it too: scratch UI test code warned about main-actor isolation, so test code needs `@MainActor` (own check on the compiler output).

### What changes if an iPhone companion is added later

- If the watch app is **embedded in the existing iPhone app** (independent app with a companion): nothing structural; the companion already exists. If the project ships a **watch-only app** with its own record, ASC says watch-only apps cannot be part of a universal purchase, and no page I read describes converting to an iPhone plus watch app later (gap), so I would expect a new record (my reading). "Creating independent watchOS apps" says an independent app "can use Watch Connectivity to transfer information from its companion iOS app when the iOS device is available" but cannot rely on it.

### Recommended approach

- This repo already has an iPhone app target in the same project (`com.siroroman.breathnest`) and #22 ships both. The simplest shape with the least rework is an **independent watch app embedded in the iPhone app** (`<iOS id>.watchkitapp`, `WKCompanionAppBundleIdentifier` = the iOS id, `WKRunsIndependentlyOfCompanionApp` = YES): one record, the watch app still works without the iPhone app installed, and a later companion needs no restructure. A **watch-only** app is also possible but needs a separate root id, a stub target and probably a separate record (my reading). #40 says "standalone watchOS 26 app" and the design says "standalone"; the owner should confirm which Apple shape is meant before #40 (this is a question, not settled).
- Either way, do not rely on Watch Connectivity or on the iPhone for data. Link `BreathnestKit` the same way as the iPhone does (own check shows it builds).

**Apple sources**: "Creating independent watchOS apps", "Setting up a watchOS project", `WKWatchOnly`, `WKCompanionAppBundleIdentifier`, `WKRunsIndependentlyOfCompanionApp`, `WKApplication`, Xcode 14 Release Notes, ASC Help "Add watchOS app information" and "Add platforms", WWDC19 208 (mirror); Xcode 26.2 templates and `CoreBuildSystem.xcspec`.

## 6. Sizes and testing

### Case sizes of watchOS 26 hardware

- **Which models run watchOS 26 (documented, partly my reading).** Support's compatibility table gives the first watchOS for each model: Series 6 (watchOS 7), Series 7 (8), SE 2 and Series 8 and Ultra (9), Series 9 and Ultra 2 (10), Series 10 (11), Series 11, SE 3 and Ultra 3 (26), with no upper limit given for those; Series 5, SE 1 and older have one ("through watchOS 10.6.1"). So watchOS 26 runs on Series 6, 7, 8, 9, 10, 11, SE 2, SE 3, Ultra, Ultra 2 and Ultra 3 (my reading of a table that gives only lower bounds). The same page lists Series 12 and Ultra 4 as watchOS 27; the current "Apple Watch models" guide lists watchOS 27 for Series 9 and later only, so Series 6, 7, 8, SE 2 and the first Ultra stay on 26 as their last version (my reading). Support: "Apple Watch and iPhone compatibility".
- **Sizes.** App Store Connect's screenshot page gives these screen sizes in **pixels** (it lists one size per series): 422 x 514 (Ultra 4, Ultra 3), 410 x 502 (Ultra 2, Ultra), 416 x 496 (Series 12, 11, 10), 396 x 484 (Series 9, 8, 7), 368 x 448 (Series 6, 5, 4, SE 3, SE 2, SE), 312 x 390 (Series 3, 2, 1). It does not list the 40, 41 or 42 mm sizes.
- **Own check: the Simulator device profiles** (`/Library/Developer/CoreSimulator/Profiles/DeviceTypes/<name>.simdevicetype/Contents/Resources/capabilities.plist`, `displays`, `width`, `height`, `scale`) give every case size with a scale of 2:

| Case | Models (name in the device type list) | px | pt (px / 2) | aspect (w/h) | scale vs 45 mm (width / height) |
|---|---|---|---|---|---|
| 40 mm | Series 6, SE 2, SE 3 | 324 x 394 | 162 x 197 | 0.822 | 0.818 / 0.814 |
| 41 mm | Series 7, 8, 9 | 352 x 430 | 176 x 215 | 0.819 | 0.889 / 0.888 |
| 42 mm | Series 10, 11 | 374 x 446 | 187 x 223 | 0.839 | 0.944 / 0.921 |
| 44 mm | Series 6, SE 2, SE 3 | 368 x 448 | 184 x 224 | 0.821 | 0.929 / 0.926 |
| **45 mm** | Series 7, 8, 9 | **396 x 484** | **198 x 242** | 0.818 | 1 / 1 |
| 46 mm | Series 10, 11 | 416 x 496 | 208 x 248 | 0.839 | 1.050 / 1.025 |
| 49 mm | Ultra, Ultra 2 | 410 x 502 | 205 x 251 | 0.817 | 1.035 / 1.037 |
| 49 mm | Ultra 3 | 422 x 514 | 211 x 257 | 0.821 | 1.066 / 1.062 |

  The pixel sizes for 44, 45, 46 and 49 mm agree with the App Store Connect page; 40, 41 and 42 mm appear only in the Simulator profiles, not in a published Apple table I could read (unconfirmed against the HIG; the HIG layout page I fetched did not return its watchOS table, so I could not read Apple's point sizes in prose). The point sizes are the pixel sizes divided by the scale of 2 in the same profile. Own check on the running Simulator: `WKInterfaceDevice.current().screenBounds` reported 187 x 223 pt (Series 11, 42 mm) and 208 x 248 pt (Series 11, 46 mm), both with `screenScale` 2.0, so the division holds for those two; the other sizes are derived, not read from a running device.
- **Is 396 x 484 correct for the 45 mm case? Yes, as pixels.** The design doc says "396 x 484 pt frame (45 mm case)" and "A length in a `.dc.html` file in px is the same number in pt on that frame". A watch of that case is 198 x 242 pt at 2x (the device profile has scale 2). A 256 wide ring box (design 2) and a 216 wide torus cannot fit a 198 pt wide screen, so the design numbers are px (my reading). Own check: `xcrun simctl io <device> screenshot` gave 416 x 496 px for Series 11 (46mm), 374 x 446 for Series 11 (42mm), 422 x 514 for Ultra 3 (49mm), 368 x 448 for SE 3 (44mm) and 324 x 394 for SE 3 (40mm), the pixel sizes in the table; a designer working from Simulator screenshots would naturally get 396 x 484 for 45 mm. The effect for the tickets is that every design length is twice the length in points (32 px title = 16 pt) unless the design owner says otherwise (section "Implications").

### Simulators on this Mac (own check)

- **Runtimes:** `xcrun simctl list runtimes` shows **only `watchOS 27.0 (27.0 - 24R5305f)`**. There is no watchOS 26 runtime (Xcode 26.2 reports "watchOS 26.2 is not installed" for a watchOS build destination). Everything below ran on the 27 runtime with the deployment target 26.0.
- **Devices available with that runtime (`xcrun simctl list devices available`):** `Apple Watch Series 11 (46mm)`, `Apple Watch Series 11 (42mm)`, `Apple Watch Ultra 3 (49mm)`, `Apple Watch SE 3 (44mm)`, `Apple Watch SE 3 (40mm)`. The device type list (`xcrun simctl list devicetypes`) also has Series 9 and 8 and 7 (45mm and 41mm), Ultra 2 and Ultra (49mm), SE 2 (44mm and 40mm), Series 10 (46mm and 42mm) and older, but no devices exist for them with this runtime; I did not try to create any.
- **A destination string** that worked for a build: `-destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)'` was accepted by `xcodebuild test` (it then hung, see below); `-destination 'generic/platform=watchOS Simulator'` built.
- **Simulator capabilities (own check, device profile):** the Series 11 profile has `com.apple.hid.digital-crown`, `com.apple.display.aot` (an always-on display) and `com.apple.hid.watch.gestures` (runtime-conditional).

### Which sizes to test (my reading)

- **Smallest: SE 3 (40mm)**, 324 x 394 px: the tightest height for Controls (two 92-high buttons) and the Progress ring box. Also the 26-only models (Series 6, SE 2) share this size.
- **A 42 mm and a 46 mm** (aspect 0.839, wider than the others at 0.817 to 0.822): the width/height ratio differs from the 45 mm design, so a layout that scales by height alone may crop or leave side gaps.
- **Largest: Ultra 3 (49mm)**, 422 x 514 px.
- **The design size (45 mm) is not installed.** The 45 mm device type exists but there is no 26 runtime; install a watchOS 26 runtime in Xcode > Settings > Components to get Series 9 (45mm) and (41mm), or compare against the 46 mm and 44 mm. I would add 41 mm and 45 mm as soon as a runtime has them, because Series 7 to 9 are the most common watchOS 26 devices (my reading, no figure).
- **On a real watch:** at least one 40/41 mm and one 45/46 mm model, with Always On on and off.

### How the design frame scales (my reading)

- The design is drawn at 45 mm only (design doc "Still open" 2). The ratios in the table show the available room as a fraction of 45 mm. A simple, safe rule is to scale every design length by the width ratio, clamped to the height ratio so nothing overflows (on 40 mm the height ratio 0.814 is smaller than the width ratio 0.818); the ring box (256) and torus (216) become 208 and 176 on 40 mm (256 × 0.814 and 216 × 0.814, rounded). Fixed spacing, not scaled values, is what the design tickets would otherwise write. This is a design decision (rule 3 of the design doc), not mine: ask on #40 with `needs-info` and decide on one rule for all tickets.

### `performAccessibilityAudit()` and XCUITest on watchOS

- **XCUITest on watchOS (documented, header).** `XCUIApplication` is in the watchOS platform's `XCUIAutomation.framework` with no watchOS restriction; WWDC21 10208 says "Xcode 12.5 introduced UI Testing support for watchOS apps". `XCUIDevice.rotateDigitalCrown(delta:)` and `rotateDigitalCrown(delta:velocity:)` are `TARGET_OS_WATCH || TARGET_OS_VISION`; `perform(handGesture:)` is watchOS 10; `XCUIDevice.Button` has `.home` and, for watchOS and iOS, `.action`; the volume buttons are marked unavailable in the Simulator. Headers: `XCUIDevice.h`, `XCUIDeviceButton.h`, `XCUIApplication.h` (Xcode 26.2, `Platforms/WatchOS.platform/Developer/Library/Frameworks/XCUIAutomation.framework`).
- **`performAccessibilityAudit(for:_:)` (documented, header).** Declared `watchOS 10.0` on `XCUIApplication` (header and Swift interface; the doc page lists watchOS 10.0 and Xcode 16.3). The audit types on watchOS are contrast, element detection, hit region, sufficient element description, dynamic type, text clipped and trait; `action` and `parentChild` are macOS only (header `XCUIAccessibilityAuditTypes.h`). The doc page has no discussion text, so what the audit can and cannot detect on a watch is not described (unconfirmed).
- **What I could not verify (own check, negative).** I wrote a minimal watch-only app with a UI test target (`bundle.ui-testing`, `platform: watchOS`) that read a label, called `rotateDigitalCrown`, `performAccessibilityAudit()` and pressed Home, and ran it with `xcodebuild test` on `Apple Watch Series 11 (46mm)`. The build and the install of the test runner succeeded, but the test never started: after about 10 minutes the app under test still was not installed on the device, and I killed it (the Simulator went back to shutdown). The cause was not found (a watch-only app, the beta Xcode, or a missing paired phone are guesses, none checked). So I cannot say that the audit or the crown helper runs on a Simulator here.
- **What they cannot do on the watch (my reading, from the header and the docs).** No `action`/`parentChild` audit types; the Dynamic Type audit is moot for this app, which keeps fixed sizes (decision 7 in the design); no way to test haptics, sound, the wrist-down state, the Always On look or the extended runtime session in XCUITest (nothing in `XCUIDevice` addresses them); some device buttons are not available in the Simulator.

### Recommended approach

- Test on `Apple Watch SE 3 (40mm)`, `Apple Watch Series 11 (42mm)` and `(46mm)`, and `Apple Watch Ultra 3 (49mm)`, and add 41 and 45 mm once a watchOS 26 runtime is installed. Pass the size by `name=` in `-destination`.
- Treat the screenshot size as pixels when comparing with the design (416 x 496 for 46 mm).
- Do not promise `performAccessibilityAudit()` on the watch screens until one run has worked on this Mac or on CI; keep the device checklist (#50) as the fallback for what it cannot reach.

**Apple sources**: Support "Apple Watch and iPhone compatibility", ASC "Screenshot specifications", `XCUIApplication.performAccessibilityAudit(for:_:)`, `XCUIAccessibilityAuditType`, WWDC21 10208; headers named above; Simulator device profiles in `/Library/Developer/CoreSimulator/Profiles/DeviceTypes`.

## Implications for the watch tickets (input only, nothing decided)

**Input only.** (C) lines restate a documented platform constraint. (R) lines are this note's reading of the sources, not Apple statements. "Gap" lines need a real watch. Each ticket is free to overrule an (R) line.

**#40 app target, Kit on watchOS and design tokens**

- (C) `type: application`, `platform: watchOS`, deployment target 26.0, `GENERATE_INFOPLIST_FILE`; `WKApplication` is added by Xcode (own check); the Kit already declares `.watchOS(.v26)` and links and builds (own check).
- (C) The design frame 396 x 484 is the 45 mm size in pixels, 198 x 242 pt. The design doc's rule 2 and the title style in #40 ("32 / semibold / ... 32 from the top and 30 from the left") are in px on that frame, so in points they are half (R). **#40 must stop and raise this with `needs-info` before the tokens and the title style are built**, and the design doc's rule 2 and "Still open" 2 need the decision. All other UI tickets inherit the answer.
- (R) The owner should decide the shape (independent watch app embedded in the iPhone app, or watch-only with a stub and its own record) before #40 writes `project.yml`; the ticket's "standalone" wording does not say which of Apple's two shapes it means (section 5).
- (R) `make` commands for the watch target need a watch Simulator name (`Apple Watch Series 11 (46mm)` is installed; no watchOS 26 runtime is). The watch UI test could not be run here (own check), so `make test-watch` should start with unit and build checks.

**#41 saved settings and last Session**

- No finding changes it. `UserDefaults` on the watch was not researched (none found, not checked). The watch has no iPhone dependency to sync with (C, documented for independent apps).

**#42 Exercises with Quick Start**

- (R) Layout values follow the px-to-pt decision above; the list must work on the 40 mm size (324 x 394 px). Nothing else from this research.

**#43 Set duration and Start screens**

- (C) Use `digitalCrownRotation(detent:from:through:by:...)` with an `Int` index into the Duration options (not the minute value, the options are not evenly spaced), `.focusable()` on the value view, `isContinuous: false`, default haptics.
- (C) The system crown indicator cannot be forced on; its visibility is not documented. Check on a watch, and if the design's "bar on the right edge" must be visible at rest, ask in a comment.
- (R) A crown-only control is hard for a VoiceOver user; the design has no button on this screen. Needs a design answer (also #50).
- (R) Tests: `XCUIDevice.rotateDigitalCrown(delta:)` (own check could not run a watch UI test, so unit-test the index mapping in the ViewModel instead).

**#44 Lead-in, Progress and Complete**

- (C) The inactive app's UI "doesn't update by default"; with Always On the system dims the view and updates at a lower rate, and Apple says to pause animation and remove subsecond updates (doc page, Always On). The design has no Always On look for Progress. Per design rule 3 this needs a design question: what the ring and torus show with the wrist down while the Session runs (this is "Still open" 4).
- (R) Use `TimelineView` and `isLuminanceReduced`: a `.seconds` cadence means the hold segment lights one per second and the torus can be shown at the second's Breath level without animation.
- (R) Whether the Complete screen's end cue is a haptic (`.success` or `.stop`) is not in the design; with the wrist down it would be the only signal. Ask.

**#45 Session model and Controls page**

- (C) The ticket says "the Session pauses whenever the scene is not active and never advances while away". On the watch the scene goes inactive on every wrist drop, so this rule would pause every Session at the first wrist drop and defeat eyes-closed use. **It must change** (R): run a mindfulness `WKExtendedRuntimeSession` from Start (started while active, `WKBackgroundModes` = [`mindfulness`]), keep the Session running while it runs and the scene is inactive, pause when it invalidates (crown press, leaving the app, expiry, `SuppressedBySystem`, error) or never started, and pause on `.background` regardless. Invalidate it on Stop, Done and natural end.
- (C) "The screen stays awake during a Session as far as watchOS allows": there is no developer API; the frontmost timeout is a user setting (2 minutes by default) and `isFrontmostTimeoutExtended` is "No longer supported". The honest reading is that the extended runtime session is the "as far as watchOS allows".
- (R) ADR 0002 lists the seams "screen awake" and "scene phase". On the watch "screen awake" has no implementation (a no-op), and the Session needs a new seam for the extended runtime session (start, invalidate, invalidation events). Handle `BARDisabled`, `SessionInProgress`, `SuppressedBySystem` and `ExceededResourceLimits` without crashing (C: header).
- (C, own check) In the watchOS 27.0 Simulator an extended runtime session failed to start at once (`WKExtendedRuntimeSessionErrorCode` 1, even with `mindfulness` in the plist). So the Session must run, and the app must not crash, when the session fails to start, and tests use a fake seam (R). On a real watch a failed start means "pause when the scene is not active".
- (Gap) The `scenePhase` sequence on a wrist drop, with and without the extended runtime session.

**#46 navigation end to end and smoke test**

- (C) `XCUIApplication` is available on watchOS (header, WWDC21 10208); `rotateDigitalCrown` exists. (Own check) a minimal watch UI test did not start on this Mac. The ticket's "one watch UI test runs a whole Session ... in the watch Simulator" is not proven feasible; do a spike first (R).
- (R) The smoke test must not depend on haptics or the extended runtime session (the latter fails in the Simulator, own check); swap them for fakes in the `DEBUG` launch argument, as ADR 0002 says.

**#47 haptics follow the shape**

- (C) No Core Haptics on watchOS. The only tool is `WKInterfaceDevice.current().play(_:)` (discrete types, no intensity, 100 ms floor, plays only when active or in a workout session per its page) or `sensoryFeedback` (watchOS 10, view-driven).
- (R) The acceptance criterion "each Phase's haptic is requested exactly once, at the Phase start" has to be read as "a Phase's haptic is one schedule of taps started once at the Phase start"; the taps after the first are the adapter's, cancelled on Pause, Stop, Done and extended runtime session invalidation, not replayed on Resume. The ticket's "closest mapping the research note proposes" is in section 2.
- (R) A tick-schedule function in the Kit (pure, tested by `swift test`), and a decision whether the Haptic plan (#26) carries intensity along the Phase or the adapter derives it from `breathLevel`.
- (Gap, blocking) Whether `play(_:)` works with the wrist down under the extended runtime session. Everything about how it feels is a device test (section 2).

**#48 Settings and Sounds screens**

- No change from this research. (C) HIG says haptics must be optional, which the Haptics switch does. (R) The Sound switch has no effect until the playback ticket; the Silent Mode and speaker questions in section 4 are for that ticket.

**#49 choose the sounds**

- (C) Long-form audio on the watch needs an eligible route (Bluetooth, and on supported models with watchOS 11 or later the speaker). No primary source says a short chime uses the speaker; whether the owner wants sounds at each Phase start while the wrist is down depends on the device tests in section 4 (R). The rule for "when a sound plays" should say whether it plays with the wrist down.

**#50 accessibility and audits**

- (C) `performAccessibilityAudit(for:_:)` is declared for watchOS 10 with the audit types listed in section 6; (own check) I could not run it on a watch Simulator here, so the ticket's "where it works" branch applies to everything until one run succeeds (R): put the audits on the device checklist with that reason.
- (C) `AccessibilityNotification.Announcement` exists on watchOS (10.0, Xcode 26.2 `Accessibility.framework` interface), which is what "Box breathing, starting" and each Phase name would use; whether VoiceOver speaks while the screen is dark with the wrist down is unconfirmed (Gap) and is part of the device checklist.
- (R) VoiceOver and the crown-only Set duration (see #43).

**#51 localization of the watch strings**

- No finding changes it.

## Gaps and open items

- **Needs a real watch (not testable here):** `play(_:)` with the wrist down inside a mindfulness extended runtime session (docs conflict); whether the session survives 20 minutes with the wrist down, with Always On on and off, and with Return to Clock at its default; what `scenePhase` reports on wrist drop and raise (the Simulator started no extended runtime session at all, own check); whether the Progress UI keeps updating in Always On; the feel of the tick mapping and the 100 ms behaviour; System Haptics and Prominent settings; the crown indicator's visibility; short-sound routing (speaker, AirPods), Silent Mode, charging; Background App Refresh off (`BARDisabled`).
- **Not documented in what I read:** what an extended runtime session does to the Return to Clock timer; whether App Review accepts a breathing app under `mindfulness`; which `WKHapticType` each `SensoryFeedback` maps to; the length of each `WKHapticType`; which Apple Watch models "support speaker playback" for long-form audio; the default-policy audio route for a short sound; Silent Mode's effect on third-party audio; the exact wording of "Background Modes > Audio" for a single-target watch app's Info.plist; how to force the crown indicator; conversion of a watch-only record to an iPhone plus watch app; whether ASC accepts a watch-only archive without the iOS stub.
- **Pages that disagree:** `WKInterfaceDevice.play(_:)` (no haptics when inactive, except workout) against the extended runtime pages (haptics after the screen turns off); the independent apps page (root bundle id for Universal Purchase) against ASC (watch-only apps cannot be part of a universal purchase); "Handling common state transitions" (a wrist drop enters the background) against "Working with the watchOS app life cycle" (inactive for 2 minutes first).
- **Own checks that are negative or limited:** the watch UI test hung and was killed, so XCUITest and `performAccessibilityAudit()` on a watch are unproven here; no watchOS 26 runtime is installed, so all Simulator checks ran on watchOS 27.0 with a 26.0 deployment target; the five installed devices do not include 41 or 45 mm; the archive, signing and App Store Connect validation were not tried.
- **Sizes:** the 40, 41 and 42 mm sizes come from Simulator profiles only; Apple's HIG point table was not readable through my fetcher.
- **Not researched:** `UserDefaults` on watchOS, SwiftData or other persistence, complications, Smart Stack, notifications on the watch, watchOS 26 release-note items beyond a keyword scan, Low Power Mode behaviour (Support says Always On is not available in it), water lock, and App Review for the Watch screenshots.
- **Transcripts:** WWDC19 251, 208, 716 and WWDC18 504 were read through a mirror with a transcription-error warning; the time limits in them agree with the doc page, which is the source I cite for them.
- **Out of scope:** HealthKit data (a workout session is described only as the fallback), Live Activities, complications, sound design.

## Own checks (what I ran, for the record)

All outside the repo, in a scratch directory; no repo file changed; every Simulator shut down afterwards.

1. `xcrun simctl list devicetypes`, `list runtimes`, `list devices available`: the names above. One runtime, `watchOS 27.0`.
2. `ls` of the `Frameworks` folders of `WatchOS26.2.sdk` (Xcode 26.2) and `WatchOS27.0.sdk` (Xcode 27.0 beta): no `CoreHaptics.framework`.
3. `grep` of headers and `.swiftinterface` files in the watchOS 26.2 SDK for `WKHapticType`, `WKExtendedRuntimeSession`, `digitalCrownRotation`, `digitalCrownAccessory`, `sensoryFeedback`, `AVAudioSession`, `XCUIAutomation`.
4. XcodeGen 2.44.1 projects in scratch: a watchOS `application` target linking a copy of `BreathnestKit` (`BUILD SUCCEEDED`, plist read with `plutil`), the same with an iOS target embedding a watch target (`Phone.app/Watch/Watch.app` present), and one with `info:` properties merged.
5. `xcodebuild test` of a minimal watch UI test: hung, killed.
6. A minimal app launched on the five installed devices (screenshot sizes, and `screenBounds` and `screenScale` on two of them), and on Series 11 (46mm) with `play(.click)`, `AVAudioSession` activation and `WKExtendedRuntimeSession` (with and without `WKBackgroundModes`): results are in sections 1, 2, 4 and 6. Each app was uninstalled and each device shut down afterwards.

## Sources

All Apple unless marked. Developer documentation pages (https://developer.apple.com/documentation/...):

- WatchKit: `watchkit/wkextendedruntimesession`; `watchkit/using-extended-runtime-sessions`; `watchkit/background-execution`; `watchkit/life-cycles`; `watchkit/working-with-the-watchos-app-life-cycle`; `watchkit/handling-common-state-transitions`; `watchkit/taking-advantage-of-frontmost-app-state`; `watchkit/playing-background-audio`; `watchkit/wkinterfacedevice` and `/play(_:)` and `/screenbounds`; `watchkit/wkhaptictype`; `watchkit/wkaudiofileplayer`
- Info.plist keys (`bundleresources/information-property-list/...`): `wkbackgroundmodes`; `wksupportsalwaysondisplay`; `wkapplication`; `wkwatchonly`; `wkcompanionappbundleidentifier`; `wkrunsindependentlyofcompanionapp`; `uibackgroundmodes`
- watchOS apps: `watchos-apps/creating-independent-watchos-apps`; `watchos-apps/setting-up-a-watchos-project`; `watchos-apps/designing-your-app-for-the-always-on-state`; `watchos-release-notes/watchos-26-release-notes`; `xcode-release-notes/xcode-14-release-notes`
- SwiftUI: `swiftui/scenephase`; `swiftui/environmentvalues/isluminancereduced`; `swiftui/view/digitalcrownrotation(_:from:through:by:sensitivity:iscontinuous:ishapticfeedbackenabled:)`; `swiftui/view/digitalcrownrotation(detent:from:through:by:sensitivity:iscontinuous:ishapticfeedbackenabled:onchange:onidle:)`; `swiftui/view/digitalcrownaccessory(_:)`; `swiftui/digitalcrownrotationalsensitivity`; `swiftui/view/focusable(_:interactions:)`; `swiftui/view/sensoryfeedback(_:trigger:)`; `swiftui/sensoryfeedback` and `/impact(weight:intensity:)`
- HealthKit: `healthkit/hkworkoutsession`; `healthkit/running-workout-sessions`; `healthkit/setting-up-healthkit`
- Core Haptics: `corehaptics`; `corehaptics/chhapticengine`
- AVFAudio: `avfaudio/avaudiosession/activate(options:completionhandler:)`; `avfaudio/avaudiosession/routesharingpolicy-swift.enum/longformaudio`; `avfaudio/avaudiosession/category-swift.struct/playback` and `/ambient`
- XCUIAutomation: `xcuiautomation/xcuiapplication/performaccessibilityaudit(for:_:)`; `xcuiautomation/xcuiaccessibilityaudittype`

Human Interface Guidelines (https://developer.apple.com/design/human-interface-guidelines/...): `digital-crown`; `playing-haptics`; `always-on`; `designing-for-watchos`; `layout` (the watchOS size table was not returned by my fetcher)

Other Apple pages

- App Review Guidelines (2.5.1, 2.5.4, 2.5.9, 5.1.3): https://developer.apple.com/app-store/review/guidelines/
- App Store Connect Help: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-watchos-app-information/ ; https://developer.apple.com/help/app-store-connect/create-an-app-record/add-platforms/ ; https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- Apple Watch User Guide and Support: https://support.apple.com/guide/watch/adjust-the-display-settings-apd127ec93ac/watchos ; https://support.apple.com/guide/watch/apd62807a9f3/watchos ; https://support.apple.com/en-us/108368 ; https://support.apple.com/en-us/118490 ; https://support.apple.com/guide/watch/apd2054d0d5b/watchos
- Simulator guide (archived): https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/iOS_Simulator_Guide/InteractingwithiOSandwatchOS/InteractingwithiOSandwatchOS.html

WWDC sessions

- WWDC21 10208, Explore Digital Crown, Trackpad, and iPad pointer automation: https://developer.apple.com/videos/play/wwdc2021/10208/
- WWDC22 10133, Build a productivity app for Apple Watch: https://developer.apple.com/videos/play/wwdc2022/10133/
- WWDC19 219, SwiftUI on watchOS: https://developer.apple.com/videos/play/wwdc2019/219/
- Read through the nonstrict.eu mirror of Apple's transcripts (secondary hosting): WWDC19 251 Extended Runtime for watchOS Apps https://nonstrict.eu/wwdcindex/wwdc2019/251/ ; WWDC19 208 Creating Independent Watch Apps https://nonstrict.eu/wwdcindex/wwdc2019/208 ; WWDC19 716 Streaming Audio on watchOS 6 https://nonstrict.eu/wwdcindex/wwdc2019/716 ; WWDC18 504 Creating Audio Apps for watchOS https://nonstrict.eu/wwdcindex/wwdc2018/504/

SDK headers and files on this Mac

- Xcode 26.2, watchOS 26.2 SDK (`/Applications/Xcode.app/Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS26.2.sdk/System/Library/Frameworks/`): `WatchKit.framework/Headers/WKExtendedRuntimeSession.h`, `WKApplication.h`, `WKExtension.h`, `WKInterfaceDevice.h`; `AVFAudio.framework/Headers/AVAudioSession.h` and `AVAudioSessionTypes.h`; `SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64e-apple-watchos.swiftinterface`; `SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-watchos.swiftinterface`; `Accessibility.framework/Modules/Accessibility.swiftmodule/arm64e-apple-watchos.swiftinterface`
- Xcode 26.2, watchOS platform (`/Applications/Xcode.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/`): `XCUIDevice.h`, `XCUIApplication.h`, `XCUIAccessibilityAuditTypes.h`, `XCUIDeviceButton.h`
- Xcode 26.2, iPhoneOS 26.2 SDK: `CoreHaptics.framework/Headers/CHHapticEngine.h`
- Xcode 26.2 project templates: `/Applications/Xcode.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/Xcode/Templates/Project Templates/watchOS/Application/` (`watchOS App Base.xctemplate`, `iOS App Stub for watchOS App.xctemplate`)
- Xcode 26.2 build settings: `/Applications/Xcode.app/Contents/SharedFrameworks/XCBuild.framework/Versions/A/PlugIns/XCBBuildService.bundle/Contents/PlugIns/XCBSpecifications.ideplugin/Contents/Resources/CoreBuildSystem.xcspec`
- Xcode 27.0 beta (`/Users/romansiro/Downloads/Xcode-beta.app`, build 27A5209h), watchOS 27.0 SDK: framework list of `WatchOS27.0.sdk`
- Simulator device profiles: `/Library/Developer/CoreSimulator/Profiles/DeviceTypes/<device>.simdevicetype/Contents/Resources/capabilities.plist` and `profile.plist`

Repo files read: `docs/product/watch-design.md`, `GLOSSARY.md`, `docs/adr/0001-domain-logic-in-a-ui-free-swift-package.md`, `docs/adr/0002-app-architecture.md`, `docs/product/research/ios-26-session-constraints.md`, `BreathnestKit/Package.swift`, `BreathnestKit/Sources/BreathnestKit/BreathLevel.swift`, `project.yml`, issues #26, #32, #38, #40 to #51.
