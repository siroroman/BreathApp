# PROTOTYPE: circle motion and haptic feel (issue #13)

Throwaway SwiftUI app. Lives on the `prototype/13-circle-motion-haptics` branch, never merged into `main`.
Plain shapes only: colours, layout and style are out of scope.

## Run

```bash
cd prototypes/circle-feel
xcodegen
xcodebuild -project CircleFeel.xcodeproj -scheme CircleFeel -destination 'id=<iPhone UDID>' \
  -allowProvisioningUpdates DEVELOPMENT_TEAM=<team id> build
```

Haptics do not play in the Simulator, so judge feel on a real iPhone.

## What it does

- Pattern menu: box (hold/hold and hold/rest), 4-7-8, coherent, sigh (double inhale), calm with rest.
- **Motion** switcher (A Organic, B Linear, C Wave): curve per inhale/exhale, scale range, how hold and rest are shown (still, pulse, ring, orbit, guide rings).
- **Haptics** switcher (A Follow, B Ticks, C Pulse): a haptic style per Phase kind (off, tap, seconds, ramp, pulses, hum).
- Tweak sheet edits every knob live; "Copy settings" puts the current choice on the clipboard.
- One clock: a `CADisplayLink` evaluates the position in the Pattern from elapsed time. Haptics are started from the same tick when the Phase changes.
