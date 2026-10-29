# Breathnest

A guided breathing app for iPhone. Users pick an Exercise, choose how long to practise and follow an animated circle through a Session.

## Language

### Structure

**Exercise**:
A named breathing technique with a Pattern, such as box breathing or 4-7-8.
_Avoid_: Technique, routine, workout

**Pattern**:
The ordered list of Phases that make up one Cycle of an Exercise.
_Avoid_: Rhythm, sequence, ratio

**Phase**:
One step of a Pattern: a kind (inhale, hold, exhale or rest) and a duration in seconds, which may be fractional.
_Avoid_: Stage, step, segment

**Cycle**:
One pass through every Phase of a Pattern.
_Avoid_: Round, rep, breath

**Custom exercise**:
An Exercise the user makes: a name, an icon, a description and a Pattern of inhale, hold, exhale and hold in whole seconds.
_Avoid_: Custom pattern, own technique

### Session

**Session**:
One pass through an Exercise for a whole number of Cycles, the count that lands closest to the chosen duration.
_Avoid_: Workout, practice, run

**Duration option**:
A Session length offered for one Exercise, one of which is its default.
_Avoid_: Preset, timer length

**Lead-in**:
The short countdown between Start and the first Phase of a Session, shown as a large 3, 2, 1 with the shape not drawn (Breath level 0). It does not count toward the Session's length.
_Avoid_: Warm-up, intro, get-ready

**Quick Start**:
A shortcut on the Exercises screen that starts the last Session that was started, with the same Exercise, length and settings.
_Avoid_: Repeat, resume, favourite

**Log**:
The newest-first list of the Sessions the user has done, shown on the Stats tab with the week view.
_Avoid_: History, journal

**Reminder**:
A notification at a chosen time on chosen days that invites the user to practise one Exercise.
_Avoid_: Alarm, schedule

**Safety note**:
The short, non-blocking text shown with every Exercise about when not to practise and what to do if dizzy.
_Avoid_: Disclaimer, warning, medical notice

### Feel

**Breath level**:
How full the lungs are at a moment of a Session, from 0 (empty) to 1 (full).
_Avoid_: Circle size, progress, amplitude

**Haptic plan**:
The haptic events (when, how strong, how sharp) that the start of a Phase asks the phone to play.
_Avoid_: Vibration pattern, buzz
