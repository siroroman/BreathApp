# Breathnest on iPhone: design

The visual design of the iPhone app. It is the single source of truth for every iPhone screen. Behaviour is in the spec ([#22](https://github.com/siroroman/BreathApp/issues/22)); this document says what each screen looks like and what is still open. Terms follow `GLOSSARY.md`.

Source: the Claude Design canvas "Breathnest Design" (row "Mobile"). The canvas is private, so its screen files are copied to [`design/phone/`](design/phone/README.md). Each `.dc.html` there holds the exact markup and styles of one screen. This design replaces the brief in [design-brief.md](design-brief.md); where the two differ, this document wins (see "Differences from the brief and the first spec").

## Rules for agents

1. **Build exactly this design.** Every size, colour, spacing, string and state below is a requirement, not a suggestion. Do not restyle, "improve", add elements or remove elements.
2. **Units.** The design is drawn on a 390 × 844 pt frame (iPhone 15/16 class). A length in a `.dc.html` file in px is the same number in pt on that frame. Sheets sit under a 44 pt top gap.
3. **When the design is silent, stop.** Do not invent. Comment on the ticket with the question and your proposal, add the label `needs-info` and wait. "Not in the design" below lists what is already known to be open.
4. **When the design cannot be built as drawn** (an iOS limit), stop in the same way. Do not build a lookalike. Where the design uses a custom control that iOS has natively (switch, slider, time wheel, menu, segmented control), use the native one, styled with the tokens, and keep the drawn sizes where UIKit allows.
5. **Show the evidence.** Every iPhone UI pull request attaches a Simulator screenshot of each screen it touches (default text size and AX5), next to the design values it matched, and says which screens were not checked. The `ui-verifier` agent can take them.
6. **A screen the design does not draw is not built.** Features whose screens are drawn but whose behaviour is open have their own tickets (see the spec).
7. **A text change needs a design change first.** Strings in this document are the English source for the String Catalog.
8. **Dynamic Type.** The `ax` branch in each source file holds the AX5 layout (bigger sizes, stacked buttons, hidden glyphs). It is part of the design. Text scales to AX5 with no upper limit.

## Tokens

[`Tokens.dc.html`](design/phone/Tokens.dc.html) is the colour table, light and dark. The screens use the dark column only. Contrast is WCAG 2.x. Text needs 4.5:1, shapes and rings 3:1.

| Token | Light | Dark | Contrast L / D | Use |
|---|---|---|---|---|
| bg | `#F3F6F8` | `#000000` | n/a | Screen ground |
| surface | `#FFFFFF` | `#121F2E` | n/a | List groups, cards, sheet rows, unselected chips |
| fg | `#12202C` | `#E9F0F6` | 15.25 / 18.26 | Text, primary button fill (button text is `bg`) |
| fg2 | `#475766` | `#A7B6C4` | 6.85 / 10.13 | Secondary text, Stop outline. On surface 7.44 / 8.03 |
| ring | `#1F7A8C` | `#5CC7D6` | 4.58 / 10.60 | Lit ring arcs, Cancel, Done in Settings, switch on, selected tab, moving Phases in the row glyph |
| track | `#CBD6DE` | `#2B3E53` | 1.36 / 1.92 | Unlit ring arcs, selected time-wheel band. Lit ring on it 3.37 / 5.53 |
| outline | `#7D8E9C` | `#5E7389` | 3.11 / 4.29 | Chip outline, switch off, slider track, grabber, holds in the row glyph. On surface 3.38 / 3.40 |
| dot-empty | `#2F6DB3` | `#6FA8E8` | 4.89 / 8.44 | Dots at Breath level 0 |
| dot-full | `#157A66` | `#52D6B6` | 4.83 / 11.65 | Dots at Breath level 1; in between, mixed linearly in sRGB |

Colours that appear only in the dark screens and have no light value yet (see "Not in the design", point 2): `line` `#22344A` (dividers, tab bar top border), `pop` `#1B2C42` (menu fill), `scrim` `#04080D` (ground under a sheet). The switch knob is `#FFFFFF`. Increase Contrast is not drawn: ship asset-catalog variants of fg2, outline and ring one step darker (light) or lighter (dark).

## Type and layout shared by all screens

- Font: the system font (SF), no custom fonts. Numbers use tabular figures.
- **Screen title** (Exercises, and the sheet titles): Exercises 34 / 700, sheet titles 30 / 700, line height 1.1 to 1.15, letter spacing -0.02em. AX5: 56 and 52.
- Screen padding: 64 top, 16 sides, 34 bottom. Sheets: 44 gap above, radius 38 on the top corners, padding 10 / 20 / 36, 14 between blocks (12 on New exercise, 16 on Settings), a 36 × 5 grabber in `outline`, then Cancel (or Done) as a text button, `ring`, 17 / 500 (Done 17 / 600), min height 44.
- Groups: `surface`, radius 20 on screens, 16 on sheets, rows divided by a 1 pt `line`. Rows are at least 44 high on sheets (Settings 52).
- Buttons: full pills (radius 999). Primary: `fg` fill, `bg` text, 19 / 600, min height 54 (Quick Start's is 17 / 600, 44). Secondary (Stop): transparent, 2 pt `fg2` border, `fg` text.
- Chips: pills, min height 44, padding 0 20, 17 / 600. Selected: `fg` fill, `bg` text. Unselected: `surface` fill, 1.5 `outline` border, `fg` text.
- Switch: 52 × 32 pill, a 28 white knob 2 from the edge. On = `ring`, off = `outline`; the knob position carries the state too.
- Icons are drawn as vectors in the files; they are hidden from VoiceOver and the control carries the text.

## Screens

The order of this list is the order on the canvas (Session first, then the rest).

### 1. Session: Lead-in (`SessionLeadInDark`)

Full screen, no close button. Padding 64 / 16 / 34, content centred.

- **Gear** button, top right (top 56, right 16), 44 × 44, icon 26, `fg2`, label "Settings", opens the menu in 4.
- **Time block**: the total length of the Session, `m:ss` (32 / 600, tabular), and under it "remaining" (13, `fg2`). In the Lead-in it is the full length ("5:04").
- **Phase block**, 24 below: the title "Get ready" (44 / 600, letter spacing -0.01em) and an empty second line (17, `fg2`, min height 24) that holds "Paused" while paused.
- **Ring box** 330 × 330, centred on the screen. The ring is fully unlit. **The torus is not drawn.** A single digit 180 / 600, tabular, `fg`, is centred in the box and counts **3, 2, 1**, one per second (announced politely).
- **Buttons** at the bottom, side by side, gap 12: Pause (primary) and Stop (secondary), each equal width. While paused, Pause reads **Resume**.
- Ring geometry (all Session states): radius 154 (140 on a 300 viewBox scaled 1.1), stroke 8.8, round caps, one Cycle clockwise from the top. Phases are separated by 4° off each end of an arc. Inhale and exhale fill smoothly; a hold lights one segment per second, each segment trimmed 1.6° on both ends. Lit = `ring`, unlit = `track`. The same logic as the watch ring and [#31](https://github.com/siroroman/BreathApp/issues/31).
- AX5: gear 64, time 52, phase 60, ring box 230, torus 194, digit 130, buttons stacked vertically at min height 76 and 32.

### 2. Session: breathing (`SessionInhaleDark`)

As the Lead-in, with these differences:

- The Phase title is the Phase name: **Inhale**, **Hold**, **Exhale**, **Rest** (44 / 600). Phase names never depend on colour.
- The time block shows the total time left (4:42 in the design).
- The torus is drawn, 278 across, centred in the ring box, following the Breath level (see 13).
- Drawn states: Inhale at 55%, with the ring part-filled. Hold (2 of 4 segments lit), Exhale (40%) and Paused (Inhale at 45%, second line "Paused", button "Resume") are in the component's data but not on the canvas.
- Seconds left in a Phase are not shown. They remain the VoiceOver value.

### 3. Session: Complete (`SessionCompleteDark`)

Centred as one group, content spread between the top and the button:

1. The torus at rest (Breath level 0), 240 across (AX5 190).
2. 24 below: "Session complete" (32 / 600) and under it, 8 below, "Box breathing · 19 Cycles · 5:04" (17, `fg2`).
3. The **Done** button at the bottom: full width, primary.

No gear, no time block, no auto-dismiss and no "Again".

### 4. Session: Settings menu (`SessionMenuDark`)

The Session in breathing state with the gear open (gear in `ring`). A popover below the gear, right aligned (top 110, right 16), 280 wide (AX5: full width minus 32), `pop` fill, 1 pt `line` border, radius 22, a soft shadow and a caret. Three rows, 48 high (AX5 92), 17 / 500, padding 0 16:

- **Sounds**: on the right the chosen sound in `fg2` ("Soft bell") and a chevron. Opens the single-choice list of 5.
- **Sound**: a switch.
- **Haptics**: a switch.

The Session keeps running behind the menu unless the spec says otherwise (see "Not in the design", point 8).

### 5. Exercises (`ListDark`)

The first tab. Title "Exercises" 34 / 700 with 4 side margin and 20 below. Then, 16 apart:

- **Quick Start card**: `surface`, radius 20, padding 16. Left: "Quick Start" (13, `fg2`), the Exercise name (17 / 600), and "5 min · Haptics on" (15, `fg2`). Right: a **Start** pill, `fg` fill, `bg` text 17 / 600, min height 44, padding 0 22, a play triangle (12 × 14) and "Start" with a gap of 8. At AX5 the button drops below, full width, 84 high, 40.
- **List group**: `surface`, radius 20, clipped. First row **Custom exercise**: a 44 glyph (dashed ring, r 17, plus sign) and the text, all in `ring`, 17 / 600. Then **four Exercise rows**, in order Box breathing, 4-7-8, Coherent breathing, Physiological sigh. Row: padding 14 / 16, gap 12, the whole row one button. Left: a 44 × 44 glyph of the Pattern, a ring of arcs with 16° gaps, radius 17, stroke 4, round caps; moving Phases (inhale, exhale) `ring`, holds `outline`. Right: the name (17 / 600) and under it, 2 apart, the Pattern as numbers (15, `fg2`, tabular): `4 · 4 · 4 · 4`, `4 · 7 · 8`, `5.5 · 5.5`, `2 · 1 · 6`. At AX5 the glyph is hidden, the name is 44 and the Pattern 38.
- No play or edit button on a row. No selected state.
- **Tab bar**: pinned to the bottom, height 88 (AX5 150), padding 8 / 16 / 34, 1 pt `line` top border, `bg`. Two equal tabs, **Exercises** (ring icon) and **Stats** (three bars icon), icon 26, label 11. Current tab: `ring`, weight 700, icon stroke 2.4. The other: `fg2`, 500, stroke 1.8.

### 6. Exercise detail (`DetailDark`)

A bottom sheet over the list (see Type and layout). Top to bottom:

1. Cancel, left.
2. Title: the Exercise name (30 / 700). Below, 6: the Pattern with Phase names (16, `fg2`), `Inhale 4 · Hold 4 · Exhale 4 · Hold 4`. Below, 10: a description (15, `fg2`, line height 1.4). Box: "Four equal counts for every breath in, hold, breath out and hold. A steady, even rhythm." Physiological sigh is drawn only in German ("Zwei kurze Atemzüge durch die Nase, dann ein langes Ausatmen."); the English source is its translation, "Two short breaths in through the nose, then one long breath out.", and is not in the design. The descriptions of 4-7-8 and Coherent are not drawn either; the designer supplies them (point 14).
3. **Duration** section. A row: "Duration" (15 / 600, `fg2`) and the chosen length on the right ("5 min", 15 / 600). Then the **chips** ("Quick options" group, 10 apart): box 1, 3, 5, 10 min with 5 selected; physiological sigh 1, 5, 10 min. Then a **slider**, 1 to 60 min in steps of 1, labelled "Custom duration in minutes", track 6 thick in `outline`, thumb 28 in `ring`; its ends are labelled "1 min" and "60 min" (13, `fg2`). Then, 14 below, the result line (22 / 600, tabular, announced politely): "19 Cycles · 5:04".
4. A group (`surface`, radius 16) of three rows, 17 / 500, padding 10 / 16:
   - **Sounds**: the chosen sound ("Soft bell", `fg2`) and an up-down chevron. Opens the menu in 7.
   - **Sound**: a switch, on.
   - **Haptics**: a switch, on.
5. The **Start** button, pinned to the bottom: primary, 54 high.

AX5: the sheet is 2,100 high and scrolls; chips 76 high, rows 88, switches scaled 1.5, slider thumb 44, Start 96.

The German variant (physiological sigh) is drawn to check long strings: "Abbrechen", "Physiologischer Seufzer", "Einatmen 2 · Einatmen 1 · Ausatmen 6", "Dauer", "5 Min.", "33 Zyklen · 4:57", "Haptik", "Starten", "Klänge", "Sanfte Glocke", "Ton".

**The Safety note is not in this design.** See "Not in the design", point 1.

### 7. Sounds menu (`SoundsDark`)

The detail with the Sounds row open (row text and chevron in `ring`). A popover under the row, right aligned, 260 wide (AX5 full width minus 24), `pop` fill, `line` border, radius 22. A single-choice list of five rows, 48 high (AX5 92): Soft bell, Singing bowl, Chime, Wood block, Pulse. The chosen row is `ring` with a check mark (20) on the right; the others are `fg` with no mark. The names are placeholders (see "Not in the design", point 9). The Session menu (4) uses the same list.

### 8. New exercise (`NewExerciseDark`)

A sheet reached from the Custom exercise row. Cancel left. Title "New exercise" (30 / 700). Then, 12 apart:

- **Name**: label (15 / 600, `fg2`) and a text field (min height 48, radius 14, `surface`, 1.5 `outline` border, 17). Placeholder "Name your exercise". "Evening calm" is drawn.
- **Icon**: six tiles of 48 × 48, radius 14, 10 apart, in this order: Ring, Moon, Sun, Leaf, Wave, Wind (stroke icons, 26). Selected: 2.5 `ring` border and `ring` icon. Others: 1.5 `outline` border, `fg2` icon. Ring is selected in the design.
- **Description**: label and a two-line text view (min height 68, padding 12 / 16, placeholder "What is it for?"). "A slow wind-down before sleep." is drawn.
- **Pattern, in seconds**: label on the left and the summary on the right ("12 s per cycle", live). A group of four rows, 48 high, in this order: Inhale, Hold, Exhale, Hold. Each row has a minus button, the value ("4 s", min width 52, centred, 600) and a plus button (44 × 44 targets, `ring`). Drawn values 4, 2, 6, 0. Inhale and Exhale cannot go below 1 s; the two Holds can reach 0 s (the minus button is dimmed to 40% and `aria-disabled` at the minimum). The second Hold is "after exhale", the first "after inhale"; VoiceOver labels read "Increase hold after inhale".
- **Add exercise** button at the bottom, primary.

AX5: the sheet is 2,300 high and scrolls; icon tiles 88, rows 88.

### 9. Settings (`SettingsDark`)

A sheet with **Done** at the top right (17 / 600, `ring`) and the title "Settings" (30 / 700). Four separate groups (`surface`, radius 16), one row each, min height 52, 17 / 500:

- **Appearance**: value "Aurora" in `fg2`, a chevron.
- **Health access**: value "Allowed", a chevron.
- **Share the app**: a share icon in `ring` on the right.
- **Version**: "1.0 (1)" in `fg2`, no chevron, not a control.

How the sheet is opened, what Appearance offers and what Health access does are not in the design (points 3 and 4).

### 10. Stats (`StatsDark`)

The second tab. A **segmented control** at the top, "Stats" and "Reminder" (a `surface` pill, 4 padding, each segment min height 40, 15; selected: `fg` fill, `bg` text, 600). Then:

- **This week**: heading (22 / 700) and the week's total on the right ("23 min", 17 / 600, `fg2`).
- **Week card**: `surface`, radius 20, padding 16 / 8, seven equal columns Monday to Sunday. Each: the day letter (13, `fg2`; today `fg`, 700), a 38 circle, and the minutes below (13, `fg2`, blank for a future day). Circle: a day with practice is a filled `ring` disc (r 15); a past day without practice is an empty `outline` ring (stroke 2.5); a future day is a dashed `outline` ring; today also has a thin outer `fg` ring. VoiceOver reads each as "Monday, 5 min" (no minutes for the future).
- **Log**: heading (22 / 700) and a group (`surface`, radius 20) of rows, newest first. Row: padding 14 / 16; the Exercise name (17 / 600) and the time under it (15, `fg2`: "Today, 7:30 AM", "Tue 27 Oct, 9:40 PM"); the length on the right (17 / 600, tabular: "10 min").
- The tab bar from 5, with Stats current.

### 11. Reminders (`RemindersDark`)

The segmented control on the Stats tab with "Reminder" selected (the canvas title is "Stats · Reminder"). Then:

- A line of text (15, `fg2`): "A quiet nudge to take a few breaths at the times you choose."
- A group (`surface`, radius 20) of reminders, padding 12 / 16. Each: the time (26 / 600, tabular; `fg2` when off), the Exercise name under it (14, `fg2`), a switch on the right, and below them seven day circles M T W T F S S (30, 8 apart; chosen days `fg` fill with `bg` letter, others a 1.5 `outline` ring with `fg2` letter). The circles are one VoiceOver element: "Weekdays: Monday, Tuesday, …". An off reminder is dimmed to 75%. Drawn: 7:30 AM Coherent breathing every day, on; 1:00 PM Box breathing weekdays, on; 10:00 PM 4-7-8 weekends, off.
- A group with one row, **Add reminder**: a plus icon (22) and the text in `ring`, 17 / 600, min height 52.
- A footnote (13, `fg2`): "Reminders arrive as notifications. You can turn them off for Breathnest in the iOS Settings app."
- The tab bar from 5, with Stats current.

### 12. New reminder (`NewReminderDark`)

A sheet reached from Add reminder. Cancel left. Title "New reminder". Then, 14 apart:

- **Time**: label and the chosen time on the right ("7:30 AM", live). A wheel picker (190 high, `surface`, radius 16, a `track` band behind the chosen row) with hour, minute and AM/PM columns. The wheel is drawn static; use the system time wheel.
- A group with one row, **Exercise**: the chosen Exercise ("Coherent breathing", `fg2`) and a chevron. Opens a menu of the Exercises.
- **Repeat**: label and a summary on the right ("Weekdays"). Seven toggle circles M to S (44; on: `fg` fill, `bg` letter, 700; off: dashed 2 `outline` ring, `fg2` letter, 500), spread across the width. Drawn: Monday to Friday on.
- A footnote (13, `fg2`): "You will get a notification at this time. Tap it to start the exercise."
- **Add reminder** button at the bottom, primary.

AX5: the wheel is 380 high with 76 rows, the day circles 88.

### 13. Shape at three Breath levels (`ShapesDark`) and the torus

A reference board: the torus at Breath level 0, 0.5 and 1, with motion (top row) and with Reduce Motion (bottom row). The rules, from the file:

- **With motion.** Scale `0.64 + 0.16 · level`. Tube ratio (tube radius over ring radius) `0.42 + 0.22 · level`. Base dot radius `1.15 + 0.75 · level`. Colour: `dot-empty` to `dot-full`, mixed linearly in sRGB by the level.
- **Depth.** Dots are sorted back to front. A dot's depth `t` runs 0 (back of the tube) to 1 (front). Its radius is base × `(0.75 + 0.5 · t)` and its opacity `0.45 + 0.55 · t`. Front dots are fully opaque, back dots fainter.
- **Reduce Motion.** Scale fixed at 0.72, tube ratio 0.53, base dot radius 1.7. The level shows as colour and brightness: opacity is multiplied by `0.75 + 0.25 · level`, so it stays between 75% and 100% of the depth opacity.
- The board draws 620 SVG dots; the app draws about 1,700 in a `Canvas` ([#30](https://github.com/siroroman/BreathApp/issues/30)). Only the colours, scales, ratios and depth rules are binding. Flat dots, no blur or shadow per dot.

## Names and strings

English source strings (the String Catalog gets them with translator comments):

`Exercises`, `Quick Start`, `Start`, `Custom exercise`, `Stats`, `Reminder`, `This week`, `Log`, `min`, `Cancel`, `Done`, `Duration`, `Quick options`, `Custom duration in minutes` (slider label), `Sounds`, `Sound`, `Haptics`, `Haptics on`, `Settings`, `Appearance`, `Health access`, `Share the app`, `Version`, `Get ready`, `remaining`, `Paused`, `Pause`, `Resume`, `Stop`, `Session complete`, `Cycles`, `Inhale`, `Hold`, `Exhale`, `Rest`, `New exercise`, `Name`, `Name your exercise`, `Icon`, `Description`, `What is it for?`, `Pattern, in seconds`, `Add exercise`, `New reminder`, `Time`, `Exercise`, `Repeat`, `Add reminder`, `Reminders arrive as notifications. You can turn them off for Breathnest in the iOS Settings app.`, `A quiet nudge to take a few breaths at the times you choose.`, `You will get a notification at this time. Tap it to start the exercise.`, the four Exercise descriptions, the Safety note (`Safety.xcstrings`), the five sound names and the icon names (Ring, Moon, Sun, Leaf, Wave, Wind).

The design writes "12 s per cycle" in lower case; the catalog says "Cycle" as the glossary does, and the plural variation follows the Cycle count.

Exercise names are the full names on every iPhone screen ("Box breathing", "4-7-8", "Coherent breathing", "Physiological sigh"). The short watch names are not used.

## Not in the design

These are open. An agent that needs one of them stops and asks (rule 3). Each has a proposal; the ticket [#53](https://github.com/siroroman/BreathApp/issues/53) collects the decisions. The features that need them have their own tickets: [#54](https://github.com/siroroman/BreathApp/issues/54) saved settings and Quick Start, [#55](https://github.com/siroroman/BreathApp/issues/55) Duration slider, [#56](https://github.com/siroroman/BreathApp/issues/56) Session menu, [#57](https://github.com/siroroman/BreathApp/issues/57) custom exercises, [#58](https://github.com/siroroman/BreathApp/issues/58) Stats and Log, [#59](https://github.com/siroroman/BreathApp/issues/59) Reminders, [#60](https://github.com/siroroman/BreathApp/issues/60) Settings. The list, detail and Session are [#28](https://github.com/siroroman/BreathApp/issues/28) to [#33](https://github.com/siroroman/BreathApp/issues/33).

1. **Safety note.** The detail sheet has no Safety note, although the spec requires it on every Exercise, visible before Start in the reading order, non-blocking and with no acknowledgement. This is a gap in the design, not a decision to drop it. Proposal: a block in `surface`, radius 16, with `fg2` text 15, between the result line and the Sounds group, so it comes before Start for VoiceOver. The designer adds it to the canvas and to `design/phone/` before the detail ticket's Safety criterion is built.
2. **Light mode.** Tokens has light values, but every screen is drawn dark. Proposal: build the asset catalog with both columns of Tokens, give `line`, `pop` and `scrim` light values from the designer, and check light with screenshots. If the designer wants dark only, say so and the spec drops light.
3. **Opening Settings.** No screen shows how the Settings sheet opens. Proposal: a gear button at the top right of the Exercises screen, as in the Session.
4. **What Settings does.** "Aurora" in Appearance looks like a colour theme; no theme list is drawn. "Health access: Allowed" implies writing Mindful Minutes to Apple Health, which the first brief put out of scope; the permission flow is not drawn. "Share the app" has no link. Proposal: decided before the Settings ticket (a human decision).
5. **Sounds on the iPhone.** Sound, the chosen sound and the Haptics switch appear in the detail, the Session menu and the Quick Start card, so they are one saved setting, like the watch. The spec said sound was out of scope; now only the real names, files and the rule for when a sound plays are open ([#49](https://github.com/siroroman/BreathApp/issues/49), widened to both apps).
6. **Duration slider and 4-7-8.** The slider runs 1 to 60 min for every Exercise, while the spec offers 4-7-8 only 1:15, 2:00 and 2:30 for safety. Proposal: the slider's range is per Exercise; 4-7-8 has no slider (or one limited to 1:15 to 2:30 in Cycle steps). The value is shown as `m:ss` when it is not whole minutes. Whether the chips and the slider stay in step is open (proposal: the chosen chip follows the slider when it matches, otherwise none is selected).
7. **Custom exercises.** Not drawn: where a custom Exercise sits in the list and which of its icon or Pattern glyph the row shows, its Duration options (proposal: 1, 3, 5, 10 min and the slider), editing and deleting, the step and the maximum of a Phase (proposal: 1 s steps, 1 to 30 s), and what a 0 s Hold means (proposal: the Phase is omitted). Duplicated names are allowed.
8. **Settings menu in the Session.** Opening it does not pause the Session in the design (proposal: it keeps running and the Session keeps its auto-pause rules); the menu is dismissed by a tap outside it.
9. **Sounds names.** The five names are placeholders, as on the watch.
10. **Log rules.** Which Sessions are logged (proposal: completed ones only, which keeps "Stop means stop" of the spec), which length is shown (the Session's exact length), the week start (the design starts on Monday; proposal: follow the system's first weekday), an empty state for a new install, and long lists (the Log scrolls).
11. **Reminders.** When the notification permission is asked (proposal: on the first Add reminder), what a tap on the notification opens (proposal: the detail sheet of that Exercise, so the Safety note is seen and Start stays a deliberate tap), editing and deleting a reminder, and the denied-permission state. Reminders are local notifications; there is no server.
12. **Quick Start rules.** It shows the Exercise, length and Haptics state of the last Session that was started, and Box breathing at 5 min before any. Proposal: the same rule as the watch (stopped Sessions count, written when a Session starts). Start skips the detail and begins the Lead-in. Whether the Sound setting is shown on the card is open.
13. **The paused look and the AX5 layouts.** The component data holds Paused and the AX5 sizes, but the canvas draws only the default size and the states listed in 1 to 4. Screenshots of both are checked against the source values.
14. **Missing descriptions.** The English texts for the 4-7-8, Coherent and Physiological sigh descriptions are not in the design. Proposal: Claude drafts them in the style of the Box text and the designer approves them.
15. **Other device sizes.** Only 390 × 844 is drawn. Smaller and larger iPhones follow the same layout with the content scrolling; no other frame is specified.

## Differences from the brief and the first spec

The design added screens and features the first brief put out of scope, and changed some decisions. The spec ([#22](https://github.com/siroroman/BreathApp/issues/22)) is amended to match.

| Topic | Brief and first spec | This design |
|---|---|---|
| Navigation | One stack, no tabs | Two tabs, Exercises and Stats; Stats holds a Stats and Reminder switch |
| Saved data | Nothing is saved | Settings (Sound, chosen sound, Haptics), the last Session, the Log, custom Exercises and Reminders are saved |
| Quick Start, History | Out of scope | Quick Start card on Exercises; Stats with a week view and the Log |
| Custom Patterns, edit button | Out of scope | A Custom exercise row and a New exercise sheet; no edit button on rows |
| Reminders | Out of scope | A Reminder section and a New reminder sheet |
| Sound | Out of scope | Sounds, Sound and Haptics on the detail and in the Session menu |
| Settings screen | None | A Settings sheet (Appearance, Health access, Share, Version) |
| Duration | Chips per Exercise only | Chips plus a 1 to 60 min slider |
| Haptics switch | On the detail, reset on every open | Saved setting, also in the Session menu |
| Session controls | Exactly two: Pause and Stop | Pause, Stop and a gear that opens the Settings menu |
| Lead-in | Shape at its smallest, remaining Lead-in time shown | "Get ready", a large 3, 2, 1, no torus; the Session's full length is shown |
| Time block | `m:ss` | `m:ss` with the caption "remaining" |
| Reduce Motion dots | Brightness and opacity | Colour, brightness and opacity |
| Colour modes | Light and dark | Dark drawn; light only as tokens (point 2) |
| Safety note | On the detail | Not drawn (point 1) |
| Row | Name and Pattern | A Pattern glyph, name and Pattern |
| Exercise description | None | A description on the detail |

## Differences from the watch

| Topic | iPhone | Watch |
|---|---|---|
| Colour modes | dark drawn, light tokens | dark only |
| Phase name on the Session | large text above the shape | not shown |
| Time block | `m:ss` and "remaining" | `m:ss` only |
| Length | chips and a slider | Digital Crown |
| Settings | in the detail, in a Session menu and in a Settings sheet | in a Settings page beside Exercises |
| Pause and Stop | on the Session screen | on a separate Controls page |
| Lead-in | "Get ready" and a large digit | a large digit |
| Safety note | required, not drawn yet | none (decided in #39) |
| History and Reminders | Stats tab | none |
| Custom exercises | yes | none |
