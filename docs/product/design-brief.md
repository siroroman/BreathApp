# Breathnest: design brief for Claude Design

Input for the visual design of the tracer bullet. The behaviour is fixed by the spec ([#22](https://github.com/siroroman/BreathApp/issues/22)); this brief says what is open for design and what is not. Terms follow `GLOSSARY.md`.

## What to design

iPhone only, iOS 26, portrait only, light and dark. Three screens, in this order:

1. **Exercises list.** Four rows: Box breathing `4 · 4 · 4 · 4`, 4-7-8 `4 · 7 · 8`, Coherent breathing `5.5 · 5.5`, Physiological sigh `2 · 1 · 6`. The whole row is one tap target.
2. **Exercise detail sheet.** A bottom sheet with Cancel. It holds the name, the Pattern with Phase names (`Inhale 4 · Hold 7 · Exhale 8`), Duration option chips, a result line such as `19 Cycles · 5:04`, a Haptics switch (on by default), the Safety note and a Start button.
3. **Session**, full screen, no close button and no swipe-down. It has these states:
   - Lead-in: 3 seconds, shape at its smallest, remaining Lead-in time shown. The look is open.
   - Breathing: Phase name in large text above the shape, a torus of dots, a progress ring for one Cycle, total time remaining as `m:ss`, and exactly two controls, Pause (becomes Resume) and Stop.
   - Paused: the same screen, frozen, with Resume.
   - Complete: shape at rest, "Session complete", a summary such as `Box breathing · 19 Cycles · 5:04`, and one Done button. No auto-dismiss, no "Again".

## Decided, not open

- **Shape.** A still torus of about 1,700 dots, seen straight on. Scale 0.64 at Breath level 0 to 0.80 at level 1. Dots shrink and grow with it. The only motion is the breath. Do not add rotation, glow pulses or particles.
- **Ring.** One Cycle, clockwise from the top. Each Phase takes the share of the ring that its seconds take of the Cycle. Inhale and exhale fill their arc smoothly. Hold and rest light one segment per second.
- **Reduce Motion.** The shape stays at a fixed size (about 0.72) and the Breath level shows as dot brightness and opacity. Ring and Phase name are unchanged. The exact look of the dots is for design.
- **No countdown per Phase.** Seconds left in the Phase are not shown; the ring replaces them.
- **Phase is never colour alone.** The Phase name and the ring position carry it. Colour is extra.
- **Safety note** is shown on every Exercise, non-blocking, with no acknowledgement. It must be visible before Start in the reading order.
- **Nothing is saved.** No history, no streak, no Quick Start, no play or edit button on rows, no settings screen.

## Constraints to design within

- Text contrast at least 4.5:1. Shape and ring contrast at least 3:1. Dark Mode and Increase Contrast respected.
- Dynamic Type up to AX5 with no upper limit. On the list, the Pattern moves to its own line. On the detail, the sheet opens at full height, chips wrap and content scrolls. On the Session, text has priority, the shape takes the remaining space, and Pause and Stop stack vertically.
- Six languages: en, cs, sk, de, fr, es. Strings can be about twice as long (the test uses a double-length pseudolanguage). Numbers use the local format (`5,5`).
- VoiceOver gets no decoration: shape and ring are hidden from it. Design nothing that only works visually.
- Cancel, Start, Pause, Stop and Done have visible text (Voice Control).
- The shape is drawn in a `Canvas`; keep it to flat dots (no blur or shadow per dot) so it stays smooth.

## Open for design

- Colour: palette, light and dark variants. The prototype goes from blue when empty to teal-green when full. It is a starting point, not a decision.
- Type, spacing, and the look of rows, chips, switch and buttons within native iOS 26 conventions.
- The Lead-in, paused and complete looks.
- Whether a row has an icon or a small shape preview (see the references). The spec says only name and Pattern.
- How the Safety note is set so that it is read, not skipped, and still calm.

## References

Everything is in `docs/product/references/`; they are references, not designs to copy. The "Take" column in its README is a draft and not yet checked, so use the files themselves. Some of them show things this version does not have: Quick Start, History, sound and haptic intensity, skip, cycle counter, a per-Phase seconds countdown, settings inside the Session. Take the mood and layout, not those features.

- List: `exercise-list-recent-sessions.webp`, `exercise-grid-particles.jpg` (a shape per technique, calm dark blue).
- Detail: `exercise-detail-sheet.webp` (chips and one clear Start).
- Session: `circle-phase-ring-hold.webp`, `session-breathe-in.webp`, `circle-phase-ring-mood.webp`.

## Output wanted

- The three screens in light and dark, plus the Session states above.
- Each screen at the default text size and at AX5.
- One screen with a long German string.
- Colour tokens with their contrast ratios, so they can go into the asset catalog.
- A Reduce Motion version of the shape at Breath level 0, 0.5 and 1.
