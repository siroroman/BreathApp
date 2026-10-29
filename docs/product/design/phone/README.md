# iPhone design sources

Copies of the screen files of the Claude Design canvas "Breathnest Design" (row "Mobile"), taken from the live canvas. They are the exact markup and styles of the iPhone design. The written description is [`../../phone-design.md`](../../phone-design.md); read it first.

These are design sources, not code to ship. They use the canvas runtime (`<x-dc>`, `<sc-for>`, `dc-import`), so they do not open on their own in a browser. Read the inline `style` values and the `renderVals()` numbers. Each file's `ax` branch holds the AX5 sizes.

| File | Screen |
|---|---|
| `SessionLeadInDark.dc.html` | Session, Lead-in (`mode`: leadin) |
| `SessionInhaleDark.dc.html` | Session, breathing (`mode`: inhale; the component also holds hold, exhale and paused) |
| `SessionCompleteDark.dc.html` | Session, Complete |
| `SessionMenuDark.dc.html` | Session with the Settings menu open |
| `ListDark.dc.html` | Exercises (Quick Start, Custom exercise, four rows, tab bar) |
| `DetailDark.dc.html` | Exercise detail sheet (box in English; `variant` also holds the German sigh) |
| `SoundsDark.dc.html` | Exercise detail with the Sounds menu open |
| `NewExerciseDark.dc.html` | New exercise sheet |
| `SettingsDark.dc.html` | Settings sheet |
| `StatsDark.dc.html` | Stats tab: This week and Log |
| `RemindersDark.dc.html` | Stats tab, Reminder section |
| `NewReminderDark.dc.html` | New reminder sheet |
| `ShapesDark.dc.html` | The torus at Breath level 0, 0.5 and 1, with motion and with Reduce Motion |
| `Tokens.dc.html` | Colour tokens, light and dark, with contrast ratios |

The `Session*` files share one component: `SessionLeadInDark` and `SessionInhaleDark` differ only in `mode`. Every screen is drawn dark; there is no light variant (see "Not in the design" in `phone-design.md`).

When the design changes, copy the changed files here in the same pull request as the change to `phone-design.md`.
