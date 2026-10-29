# Breathnest on Apple Watch: design

The visual design of the Apple Watch app. It is the single source of truth for every watch screen. Behaviour is in the spec ([#22](https://github.com/siroroman/BreathApp/issues/22), section "Apple Watch"); this document says what each screen looks like and what is still open. Terms follow `GLOSSARY.md`.

Source: the Claude Design canvas "Breathnest Design" (rows "Apple Watch"). The canvas is private, so its screen files are copied to [`design/watch/`](design/watch/README.md). Each `.dc.html` there holds the exact markup and styles of one screen.

## Rules for agents

1. **Build exactly this design.** Every size, colour, spacing, string and state below is a requirement, not a suggestion. Do not restyle, "improve", add elements or remove elements.
2. **Units.** The design is drawn on a 396 × 484 pt frame (45 mm case). A length in a `.dc.html` file in px is the same number in pt on that frame.
3. **When the design is silent, stop.** Do not invent. Comment on the ticket with the question and your proposal, add the label `needs-info` and wait. The list "Still open" below is what is already known to be open.
4. **When the design cannot be built as drawn** (a watchOS limit), stop in the same way. Do not build a lookalike.
5. **Show the evidence.** Every watch UI pull request attaches a Simulator screenshot of each screen it touches, next to the design values it matched, and says which screens were not checked. The `ui-verifier` agent can take them.
6. **Dark only.** There is no light variant. watchOS draws on black; the tokens below are the only colours.
7. **A text change needs a design change first.** Strings in this document are the English source for the String Catalog.

## Tokens

All colours are dark-mode values. Contrast is WCAG 2.x. Text needs 4.5:1, shapes and rings 3:1.

| Token | Value | Use | Contrast |
|---|---|---|---|
| bg | `#000000` | Screen ground | n/a |
| surface | `#14202E` | List rows, Quick Start card, Settings rows | n/a |
| fg | `#E9F0F6` | Titles, primary text, primary button fill | 18.26 on bg, 14.31 on surface |
| fg2 | `#A7B6C4` | Secondary text, Stop outline | 10.13 on bg, 7.94 on surface |
| ring | `#5CC7D6` | Lit ring arcs, accent text, play and selected fills | 10.60 on bg, 8.30 on surface |
| on-ring | `#04141A` | Text and icons on a ring fill, switch knob | 9.46 on ring |
| track | `#2B3E53` | Unlit ring arcs, crown indicator track | 1.92 on bg; lit ring on it 5.53 |
| outline | `#5E7389` | Hold arcs in the row glyph | 4.29 on bg, 3.36 on surface |

Primary button text is `bg` on `fg` (18.26). The torus dots use the dark phone colours: `#6FA8E8` at Breath level 0 to `#52D6B6` at level 1, mixed linearly in sRGB.

## Type and layout shared by all screens

- Font: the system font (SF), no custom fonts. Numbers use tabular figures.
- **Screen title** (Exercises, Duration, Settings, Sounds, and "Box" on the Controls and Progress pages): 32 / weight 600 / line height 1.15 / `fg`. Placed 32 from the top and 30 from the left (20 padding + 10 margin), with 14 below it. Titles are the same on every screen.
- Row and card corner radius 28. Buttons are full pills (radius 999).
- Gap between stacked rows 8. Screen padding on list screens: 32 top, 20 left and right, 0 bottom; the list clips at the bottom edge and scrolls.
- Icons are drawn as vectors in the file; they are hidden from VoiceOver and the control carries the text.

## Screens

The order of this list is the order on the canvas.

### 1. Controls (`WatchControls`, `WatchControlsPaused`)

The page to the side of Progress during a Session. Padding 32 / 20 / 28.

- Header row, margin 0 10 14: title "Box" on the left, the total time left on the right (32 / 600, tabular, `m:ss`, "4:42" in the design).
- Two buttons centred vertically in the remaining space, gap 14, side inset 10, bottom inset 34. Each is 92 high, a pill, text 34 / 600, an icon and the text side by side with a gap of 16.
  - **Pause**: fill `fg`, text and icon `bg`. Icon: two bars, 26 × 30. While paused the same button reads **Resume** with a play triangle, 24 × 28. Its fill and text colours are the same as Pause.
  - **Stop**: transparent, 2 border `fg2`, text and icon `fg`. Icon: a rounded square, 26 × 26.
- Paused and running look identical apart from the first button's icon and label.

### 2. Progress (`WatchSession`, states Inhale, Hold, Exhale, `WatchSessionPaused`)

Padding 32 / 30 / 28.

- Header row: title "Box" and the total time left (32 / 600), top-left and top-right, same positions as Controls.
- **The Phase name is not shown.** The ring, the torus size and the haptics carry the Phase.
- A 256 × 256 box centred on the screen (not in the space under the header). Inside it:
  - The ring: radius 119.5, stroke 8.5, round caps. It shows one Cycle clockwise from the top, with the same logic as the iPhone ring ([#31](https://github.com/siroroman/BreathApp/issues/31)). Phases are separated by 4° off each end of an arc. Inhale and exhale fill smoothly; a hold lights one segment per second, each segment 1.6° shorter on both ends. Lit = `ring`, unlit = `track`.
  - The torus, 216 across, centred, following the Breath level.
- Inhale at 55%, Hold with 2 of 4 segments lit and Exhale at 40% are the three states drawn.
- **Paused** is the same screen frozen. Nothing on it changes except that it stops moving.
- Lead-in: see 9.

### 3. Exercises (`WatchList`)

The root screen. Title "Exercises". Below it, 8 apart:

- **Quick Start card**: surface, radius 28, padding 16 / 20. Left: "Quick Start" (24 / 500, `fg2`), the Exercise name (32 / 600), the length "5 min" (26, `fg2`), 2 apart. Right: a 72 round button filled `ring` with a play triangle (24 × 28, `on-ring`, nudged 4 to the right), label "Start Box breathing".
- **Four Exercise rows**, in order Box breathing, 4-7-8, Coherent breathing, Physiological sigh. Row: surface, radius 28, padding 14 / 20, gap 14. Left: a 56 × 56 glyph of the Pattern, a ring of arcs with 16° gaps, ring radius 17 of 44, stroke 4, round caps; moving Phases (inhale, exhale) `ring`, holds `outline`. Right: the name (32 / 600) and under it the Pattern as numbers (26, `fg2`, `4 · 4 · 4 · 4`, `4 · 7 · 8`, `5.5 · 5.5`, `2 · 1 · 6`).
- No selected state anywhere. The Quick Start card looks like a row.

### 4. Set duration (`WatchDurationPicker`)

Reached from a row. Title "Duration". In the centre of the remaining space: the number 150 / 600 in `ring` (letter spacing -0.03em) and "min" 44 / 600 in `fg`, 12 apart, centred on each other vertically. "5 min" in the design. The Digital Crown changes the value; nothing else is on the screen (no button). The thin bar on the right edge (8 × 300, 8 from the edge) stands for the system Digital Crown indicator: use the system one.

### 5. Settings (`WatchSettings`)

Title "Settings". Three rows, min height 72, padding 12 / 20 / 12 / 24, text 32 / 600:

- **Sounds**: on the right the chosen sound in 26 `fg2` ("Soft bell") and a chevron (12 × 20, stroke 3). Opens screen 6.
- **Sound**: a switch, on in the design. Switch: 76 × 44 pill filled `ring`, a 36 knob in `on-ring`, 4 from the edge.
- **Haptics**: a switch, same look.

### 6. Sounds (`WatchSounds`)

Title "Sounds". A single-choice list, rows as on Settings (min height 72, radius 28, text 32 / 600):

- **Selected row**: fill `ring`, text `on-ring`, and a check mark on the right (32 × 32, stroke 3.5). The check is there so the state is not carried by colour alone.
- Other rows: surface, text `fg`, no mark.
- The names in the design (Soft bell, Singing bowl, Chime, Wood block, Pulse) are placeholders. See "Still open".

### 7. Start (`WatchDuration`)

The last screen before a Session. Padding 30 / 36 / 28, everything centred as one group:

1. The torus at rest (Breath level 0), 100 across.
2. The Exercise name, 32 / 600, 10 below.
3. The Pattern as numbers, 32 `fg2`, 6 below.
4. The result line "5 min · 19 Cycles", 32 / 600 `ring`, 18 below. It uses the same Cycle count as the iPhone ([#23](https://github.com/siroroman/BreathApp/issues/23)).
5. The **Start** button, 28 below: full width, min height 76, fill `fg`, text `bg` 32 / 600.

### 8. Complete (`WatchSessionComplete`)

Padding 32 / 30 / 28, centred as one group with a 6 side margin:

1. The torus at rest, 100 across.
2. "Session complete", 32 / 600, 10 below.
3. "Box breathing", 32 `fg2`, 6 below.
4. "19 Cycles · 5:04", 32 / 600 `ring`, 18 below.
5. The **Done** button, 28 below, same as Start.

No auto-dismiss and no "Again".

### 9. Lead-in (`WatchSessionLeadIn`)

Same as Progress (header, ring box) with these differences: the ring is fully unlit, the torus is **not drawn**, and a single digit 160 / 600 `fg`, tabular, is centred in the ring box. The digit counts **3, 2, 1**, one per second. The header time is the full Session length ("5:04").

## Names and strings

English source strings (the String Catalog gets them with translator comments):

`Exercises`, `Quick Start`, `Start`, `Duration`, `min`, `Settings`, `Sounds`, `Sound`, `Haptics`, `Pause`, `Resume`, `Stop`, `Done`, `Session complete`, `Cycles`, `Start Box breathing` (the play button label).

Exercise names on the list and the Start and Complete screens are the full names ("Box breathing"). On the Controls and Progress pages the title is a short name. They are `Box`, `4-7-8`, `Coherent` and `Sigh` (see "Decisions").

## Decisions

Decided by the user in [#39](https://github.com/siroroman/BreathApp/issues/39). They are part of the design.

1. **Navigation.** Exercises is the root. A row opens Set duration; the Digital Crown sets the length and a tap goes on to Start; Start opens the Lead-in and then Progress. Controls sits to the left of Progress and a horizontal swipe moves between them (as in the Workout app). Complete returns to Exercises on Done. Stop returns to Exercises at once.
2. **Settings** is a page beside Exercises, reached by a horizontal swipe from Exercises. Sounds opens from the Sounds row and goes back to Settings.
3. **Quick Start** starts the Exercise and length of the last Session that was started (stopped ones count). It is saved when a Session starts. Before any Session it is Box breathing at 5 min.
4. **Short names** on the Controls and Progress titles: `Box`, `4-7-8`, `Coherent`, `Sigh`.
5. **Switch off state.** A `track` pill with the knob on the left in `fg2`; same size as the on state (76 × 44, knob 36). The knob position, not only the colour, shows the state.
6. **Length on Set duration** that is not whole minutes is written as `1:15` with "min" beside it, like "5 min". The number scales down to stay on one line next to "min" when it is wider than a whole-minute value (at 150 `1:15` and "min" do not fit in 356); it never wraps. The result must be checked with a screenshot.
7. **Dynamic Type.** Text on the watch keeps the fixed sizes of the design.
8. **VoiceOver** still speaks each Phase name at its start, although it is not shown.
9. **Safety note.** The watch has none. This is a deliberate exception to the iPhone, where it is shown before Start on every Exercise.

## Still open

These are open. An agent that needs one of them stops and asks (rule 3).

1. **Sounds**: the real names, the audio files, and when a sound plays. Placeholders only ([#49](https://github.com/siroroman/BreathApp/issues/49)).
2. **Other case sizes.** Only 396 × 484 is drawn. How to scale for 40, 42, 44, 46 and 49 mm is not decided; the research ticket lists the sizes ([#38](https://github.com/siroroman/BreathApp/issues/38)).
3. **Haptics on the watch.** The iPhone uses continuous Core Haptics events. watchOS may only offer discrete haptics. The research ticket decides what the watch plays.
4. **Running with the wrist down.** What a Session does when the wrist drops or the screen dims is a watchOS question for the research ticket.

## Differences from the iPhone design

The watch is a different product surface, not a small iPhone. These differences are deliberate:

| Topic | iPhone | Watch |
|---|---|---|
| Colour modes | light and dark | dark only |
| Phase name on the Session | large text above the shape | not shown |
| Length | chips on the detail sheet | Digital Crown on Set duration |
| Haptics switch | on the detail sheet, reset each time | in Settings, saved |
| Sound | out of scope | Settings has a Sound switch and a Sounds list |
| Quick Start | out of scope | on the Exercises screen |
| Safety note | on the detail sheet | none (decided in #39) |
| Pause and Stop | on the Session screen | on a separate Controls page |
| Lead-in | countdown time shown | a large 3, 2, 1 and no torus |
