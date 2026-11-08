---
status: accepted
---

# Settings live in UserDefaults, the Log, custom Exercises and Reminders in versioned JSON files

The two small saved choices (`AppSettings`, `LastSession`) go into `UserDefaults`. The three lists (the Log, custom Exercises, Reminders) go into one JSON file each, in Application Support, written atomically. The stored types, their encoding, their versions and their migrations are plain Swift in `BreathnestKit`, so `swift test` covers them. The apps only read and write bytes behind one small protocol. Data that cannot be read is set aside, never deleted or overwritten, and the app carries on with defaults. A Log entry keeps the Exercise's ID and a copy of what its row needs, so editing or deleting a custom Exercise cannot break the Log.

This is the first of the saved data, decided before the first ticket that writes any of it (#54, #57, #58, #59, and the Watch's #41). It fills in what [ADR 0002](0002-app-architecture.md) left open: that ADR fixes where the store protocols live, this one fixes what sits behind them.

Decided in [#69](https://github.com/siroroman/BreathApp/issues/69), on top of the saved-data decisions of the spec [#22](https://github.com/siroroman/BreathApp/issues/22).

## What is stored where

| Data | Medium | Name | Content |
|---|---|---|---|
| `AppSettings` | `UserDefaults` | key `breathnest.settings` | Sound on or off, the chosen sound ID, Haptics on or off. Defaults: on, the first sound, on. |
| `LastSession` | `UserDefaults` | key `breathnest.lastSession` | The Exercise ID and the length. Written when a Session starts. |
| Custom Exercises | JSON file | `custom-exercises.json` | One record per Exercise: ID, name, icon, description and the Pattern as the four whole seconds. |
| Log | JSON file | `log.json` | One entry per Session that counts for the Log (which ones is decided in #53 and #58). |
| Reminders | JSON file | `reminders.json` | One record per Reminder: ID, time, days, Exercise ID, on or off. |

The files sit in `Application Support/Breathnest/`, which the app creates on the first write. Each document is stored separately, so one unreadable file never costs the user the others.

The iPhone and the Watch each have their own store and no sync in v1 (the spec). They share the Kit types: the Watch's `WatchSettings` of #41 is the same type as the iPhone's `AppSettings`. Neither target uses an App Group.

## Layers

| Where | What |
|---|---|
| `BreathnestKit` | The stored types (`AppSettings`, `LastSession`, `LogEntry`, `CustomExerciseRecord`, `Reminder`), their `Codable` encoding, the `version` of each document, the migrations, and the load logic: bytes in, value or default out, with an outcome that says what happened. The protocol `DocumentStore`. |
| `BreathnestKitTesting` | `InMemoryDocumentStore`, which can also fail on demand (a failing load, a failing write). Already planned by ADR 0002. |
| App targets | The adapters of `DocumentStore`: one over a `UserDefaults` key and one over a file. The ViewModels that call them. |

```swift
protocol DocumentStore: Sendable {
    func load() throws -> Data?        // nil: nothing is saved yet
    func save(_ data: Data) throws     // replaces the whole document
    func setAside() throws             // keeps the current bytes under another name
}
```

The protocol is synchronous. The documents are a few kilobytes, a ViewModel on the main actor reads each once, and the file adapter writes atomically (`Data.write(to:options: .atomic)`). Every document has one writer, the ViewModel that owns it, so two writes never race. If a measurement ever shows a read or write that the user can feel, the work moves to an actor behind this protocol in a new decision.

The file adapter is in the app, so app unit tests cover it with a temporary directory. The decoding, the migration and the fallback are in the Kit and covered by `swift test`.

The stored types follow [ADR 0001](0001-domain-logic-in-a-ui-free-swift-package.md) and [ADR 0002](0002-app-architecture.md). They hold no text the app writes. The name and description of a custom Exercise are text the user typed, so they are data: they are plain `String` fields of `CustomExerciseRecord` and pass through a ViewModel to the view as they are. The Duration options of a custom Exercise are derived by the Kit from the Pattern and are not stored, so a change of the options needs no migration.

## Shapes

- **Document.** A file, and a key of `UserDefaults`, holds one JSON object. A list is `{"version": 1, "items": [...]}`. `AppSettings` and `LastSession` are `{"version": 1, ...fields}`. The encoder is fixed: sorted keys, dates as ISO 8601 in UTC, durations as seconds, so the fixtures in the tests are stable byte for byte.
- **Log entry.** `id` (a UUID string), `exerciseID`, `finishedAt` (an instant), `length` (the exact length of the Session, in seconds), `pattern` (a copy of the Phases: kind and seconds) and `customName` (a copy of the name, only for a custom Exercise; a built-in Exercise is named from the String Catalog by its ID). The week summary reads `finishedAt` with the calendar and time zone of the device when it is shown; no zone is stored.
- **Reminder.** `id`, `hour`, `minute` (a wall-clock time with no zone, so it fires at that time wherever the user is), `weekdays` (calendar weekday numbers, 1 is Sunday, so the week start never changes what is stored), `exerciseID` and `isEnabled`. The identifier of each notification request is `<reminder id>.<weekday>`, so the requests of a Reminder can be cancelled after a relaunch without reading them back.
- **Exercise IDs** are permanent. A built-in ID is never changed or reused ([critical paths](../agents/critical-paths.md)). A custom Exercise gets a UUID string once, when it is saved.

## Rules

The rules are statements a test can check. A test is named after its rule in the ticket that builds the code.

### Failure

- **F1.** A load never throws to the caller and never waits on anything but the file. It returns a value, or the default, together with an outcome: `loaded`, `empty` (nothing saved) or `recovered` (the saved bytes were unreadable).
- **F2.** Nothing saved gives the default, the outcome `empty`, and no write until the first change.
- **F3.** Bytes that are not valid JSON, have the wrong shape, carry a version newer than the app knows or fail a migration are unreadable. They are kept with `setAside()` (a file is renamed to `<name>.unreadable-<date>.json`, a `UserDefaults` value is copied to `<key>.unreadable`), the default is returned and the outcome is `recovered`. The original is not replaced until `setAside()` has succeeded. If `setAside()` itself fails, the app runs on the default and does not save that document again until the next launch, so it never writes over bytes it could not keep.
- **F4.** For `AppSettings` and `LastSession` a missing, mistyped or unknown field falls back to the default of that field, not of the whole value. An unknown sound ID resolves to the first sound.
- **F5.** A reference that points at nothing never crashes. `LastSession` with an unknown Exercise ID makes Quick Start show Box breathing at 5 min. A Log entry with an unknown ID shows from its own copy. A Reminder with an unknown Exercise ID is not scheduled and is not deleted; what the user sees for it is decided by the ticket that deletes custom Exercises.
- **F6.** A write that fails never stops, pauses or ends a Session. The ViewModel keeps its in-memory state, which is what the screens show, and writes again on the next change.
- **F7.** A write replaces the whole document atomically, so a crash in the middle leaves the old file or the new one, never half of one.

### Versions and migrations

- **M1.** Every document has an integer `version`, starting at 1.
- **M2.** A migration is a pure function from one version to the next, in the Kit.
- **M3.** A document with an older version runs through every step to the current one in order. Loading does not write: the migrated value is saved by the next change.
- **M4.** A document with a newer version (the user went back to an older app) is unreadable under F3. Its bytes are kept, not changed.
- **M5.** A change that renames or removes a field or changes its meaning raises the version and adds a migration. Adding an optional field with a default does not.
- **M6.** The JSON of every version that reached a user (a TestFlight build counts) is a fixture in `BreathnestKit/Tests/BreathnestKitTests/Fixtures/`. A test migrates each fixture to the current type and compares it with the expected value. A test also encodes a value and decodes it back, and gets the same value.

### Privacy

- **P1.** Nothing leaves the device from our code: no network call, no analytics, no sync, no shared container.
- **P2.** The system's device backup includes both stores, and we do not exclude them. That is the user's own backup, not a service of ours.

## Privacy manifest

Checked against Apple's page "Describing use of required reason API" and the entry for `NSPrivacyAccessedAPIType` on 2026-11-08.

- **`UserDefaults` is a required reason API.** Each target that reads or writes it declares the category `NSPrivacyAccessedAPICategoryUserDefaults` with the reason `CA92.1` (information only the app itself can access). The first ticket that uses it, #54, creates `PrivacyInfo.xcprivacy` for the iPhone app, and #41 creates one for the Watch app. `1C8F.1` is not used because no App Group is shared.
- **JSON files add no category by themselves.** Reading and writing bytes with `Data` does not use a required reason API. The file timestamp category (`creationDate`, `modificationDate`, `contentModificationDateKey`, `stat` and the like) and the disk space category (`volumeAvailableCapacityKey` and the like) are declared only if the code uses those APIs. The rule for the code is therefore: **no stored-data code reads the timestamp, size or free space of a file.** The Log is ordered by `finishedAt` from its own content, and the name of a set-aside file takes its date from the clock, never from the file.
- **No tracking, no collected data.** `NSPrivacyTracking` is false, the tracking domains are empty and `NSPrivacyCollectedDataTypes` is empty.
- **A new API means a new declaration.** A later change that touches file metadata, adds an App Group or reads another required reason API adds its declaration in the same pull request.

## Considered options

- **SwiftData (or Core Data) for the three lists.** It brings queries and migrations of its own, but it lives only in the app target (`scripts/check-architecture.sh` lets the Kit import Foundation, Synchronization and Swift only), so `swift test` could not cover the schema or the migrations. The data is three small lists, which do not need it. The Watch would add its own container.
- **Everything in `UserDefaults`.** The least code. The Log grows without a limit and `UserDefaults` is meant for small values, and one unreadable value could take the settings with it.
- **One JSON file for all the lists.** One write, one place to look. One unreadable byte would cost the user the Log, the Exercises and the Reminders together.
- **A Log entry with the Exercise ID only.** Smaller, but deleting a custom Exercise would leave a row with nothing to show, and editing its Pattern would change what an old Session meant. It would force a ban on deleting or a row called "Deleted exercise".
- **Overwrite an unreadable file with an empty one.** Simplest, but the app is offline and keeps the only copy, so a bug in a migration would destroy the user's data.
- **No `version`, only tolerant decoding.** Works until a field is renamed or changes its meaning, which then breaks old data silently. Critical paths already call a change of a stored shape without a migration a one-way door.
- **Sync through iCloud or an App Group between the iPhone and the Watch.** Out of scope for v1 (the spec says nothing is synced). It would also change the reason code of the manifest and the failure rules.
- **An asynchronous `DocumentStore`.** Needed only if a read or write is ever felt. A ViewModel initialiser cannot await, so it would complicate every screen for a cost nobody has measured.

## Consequences

- **Size of the Log.** An entry with the Pattern copy is about 300 bytes (an estimate, not measured). A user with three Sessions a day writes a few megabytes after ten years, and the whole file is rewritten on each completed Session. That takes milliseconds. If it ever matters, a new version of the document splits the Log by year.
- **Tickets.** #54: the `UserDefaults` store is as written there, plus: the types are in the Kit, the store is behind `DocumentStore`, and the ticket creates the privacy manifest. #41: it says the iPhone saves nothing and that the store sits in the Watch target; the iPhone saves too (#54), and the types are `AppSettings` and `LastSession` in the Kit, with a Watch adapter and a Watch manifest. #57: it says the name, icon and description are kept by the app and that storage is decided with the Log ticket's ADR; this is that ADR, and the record is a Kit type with the user's text as `String` fields. #58: it says the storage is chosen there and recorded in an ADR; it is decided here, no new ADR. #59: Reminders are in `reminders.json` and the notification identifiers follow the rule above. All are commented.
- **Critical paths.** The Log, Reminders and stored data area gets the Kit globs `*Store*`, `*AppSettings*` and `*LastSession*`, because those files hold stored shapes and the area covered only `*Log*`, `*Reminder*`, `*Persist*` and `*Migration*` in the Kit. `CustomExerciseRecord` is already matched by `*Exercise*`.
- **Checks.** None of these rules has a script yet. The first two rows of `docs/agents/rules-enforcement.md` that belong here are process rules for the `code-reviewer`: a change of a stored shape raises the version with a migration and a fixture (M5, M6), and the apps reach `UserDefaults` and the files only through `DocumentStore`. The rule that stored-data code uses no file timestamp, size or disk space API could become a check in `scripts/check-architecture.sh` with a test, as its own ticket.
- **Follow-up tickets, not part of this decision:** the Kit side of the store (`DocumentStore`, the load logic, the fixtures setup) with `InMemoryDocumentStore` in `BreathnestKitTesting` before the first ticket that saves; the privacy manifest for each app target.
- **Not decided here.** Editing and deleting custom Exercises and Reminders, and what the Log shows for an Exercise that no longer exists beyond its own copy, stay open in `docs/product/phone-design.md` ("Not in the design", points 7 and 11). Whatever is decided, the storage already supports adding, changing and removing an item.
