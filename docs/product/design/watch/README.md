# Apple Watch design sources

Copies of the screen files of the Claude Design canvas "Breathnest Design", taken from the live canvas. They are the exact markup and styles of the watch design. The written description is [`../../watch-design.md`](../../watch-design.md); read it first.

These are design sources, not code to ship. They use the canvas runtime (`<x-dc>`, `<sc-for>`, `dc-import`), so they do not open on their own in a browser. Read the inline `style` values and the `renderVals()` numbers.

| File | Screen |
|---|---|
| `WatchControls.dc.html` | Controls (`mode`: running or paused) |
| `WatchControlsPaused.dc.html` | Controls while paused |
| `WatchSession.dc.html` | Progress, Lead-in and Complete (`mode`: leadin, inhale, hold, exhale, paused, complete) |
| `WatchSessionLeadIn.dc.html`, `WatchSessionHold.dc.html`, `WatchSessionExhale.dc.html`, `WatchSessionPaused.dc.html`, `WatchSessionComplete.dc.html` | One state each of `WatchSession` |
| `WatchList.dc.html` | Exercises |
| `WatchDurationPicker.dc.html` | Set duration |
| `WatchDuration.dc.html` | Start |
| `WatchSettings.dc.html` | Settings |
| `WatchSounds.dc.html` | Sounds |
| `Torus.dc.html` | The torus, drawn with 620 SVG dots here. The app draws about 1,700 in a `Canvas` ([#30](https://github.com/siroroman/BreathApp/issues/30)). Only the colours, scale and tube ratio are binding. |

`WatchSession` also holds `leadin2` and `leadin1`, the digits 2 and 1 of the Lead-in. They are not separate screens on the canvas.

When the design changes, copy the changed files here in the same pull request as the change to `watch-design.md`.
