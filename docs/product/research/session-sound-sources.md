# Where the Session sounds come from: source, licence, format, playback

Research for issue #208. Researched 2026-11-26.

## Question

The app has a Sounds list (five placeholder names: Soft bell, Singing bowl, Chime, Wood block, Pulse; `SoundID` in `BreathnestKit/Sources/BreathnestKit/AppSettings.swift`), a Sound switch and a Haptics switch on the iPhone and the Apple Watch, but no audio behind them. Ticket #49 (ready-for-human) must decide the real list, the files and when a sound plays; playback tickets follow it. Six questions, from the ticket: (1) which sources the audio files can come from (royalty-free libraries, paid packs, generated sounds, system sounds) with licence terms, App Store redistribution, attribution duty, cost and fit for calm cues; (2) the per-file licensing checklist and the licences to avoid; (3) formats and size (CAF, M4A/AAC, WAV, sample rate, length, loudness, app size); (4) iPhone playback (audio session category and options, silent switch, mixing, background, Bluetooth, which API); (5) Apple Watch playback, reusing `watchos-session-constraints.md` and adding only what is new; (6) a short list of candidate sources for the five sounds with trade-offs. Primary sources only: Apple documentation, licence texts, library terms, SDK headers. No code and no audio file is added to the repo.

## Short answer

- **Only CC0 and CC BY files are safe to take from a library (my reading, from documented terms).** CC0 is a waiver with a fallback licence and no duty (documented: CC0 1.0 legal code). CC BY 4.0 needs a credit, a licence link and a note of changes (documented: CC BY 4.0 legal code section 3(a)). CC licences with NonCommercial are about commercial use by their own description (documented: CC FAQ), so avoid them. I did not read the legal text of NC, ND or SA, so "avoid those" is my reading (section 2).
- **Every library says the file's rights are the uploader's problem, not the library's (documented).** Freesound: the uploader warrants the rights and the site accepts no liability; Pixabay: "We do not warrant that any consents or licenses have been obtained ... Before using any Content (including CC0 Content), you must consider whether you require the consent of a third party". App Review 5.2.1 puts the same duty on the app owner (documented). So each file needs a provenance record in the repo (section 2).
- **Generated-in-code or self-rendered sounds have no third-party licence (my reading, not a documented statement).** `AVAudioSourceNode` is available on watchOS 6.0 and iOS 13.0 (documented, header). I did not evaluate any AI audio tool's terms, nor the copyright status of AI output (gap).
- **Apple's built-in system sounds are not a source (documented absence).** `AudioServices` plays files you supply; no Apple page I read grants use of Apple's own sound files. On the watch, `AudioServices` is not in the SDK at all (own check, section 5).
- **Format: mono, 44.1 kHz, 16-bit linear PCM in CAF for short cues is the safe default (documented preference plus own check on size).** Apple's archived guide prefers it for uncompressed audio. Own check: a 3 s mono test tone is 268,696 bytes as PCM CAF and 15,068 bytes as AAC in M4A, so five PCM cues are about 1.3 MB, under 2 % of the watchOS 75 MB limit (documented limit, own check of sizes). Apple gives no sample-rate or loudness target for cues (gap).
- **iPhone: `AVAudioPlayer` with an `AVAudioSession` is the fitting API; `AudioServices` is not (documented, plus my reading).** `AudioServices` has fixed system volume, one sound at a time and "does not use audio routing" (documented). The category is a product choice: `.ambient` follows the Silent switch and mixes; `.playback` with `.mixWithOthers` plays with the switch on silent (documented). Which one the Session cue should use is open (section 4). No `audio` background mode is needed while the Session pauses when the scene is not active (my reading from the iOS note).
- **Watch: nothing new settles the open questions of #38 (documented, gap).** New facts: `AVAudioPlayer`, `AVAudioEngine` and `AVAudioSourceNode` exist on watchOS; Silent Mode mutes "sound effects", and whether it mutes app audio is still not stated; the 75 MB limit applies. The device test list in `watchos-session-constraints.md` section 4 still stands (section 5).
- **What #49 must pick:** a licence-clean source for each of the five sounds, whether sounds play at each Phase start or only at the start and end, and the category choice above (section 6, section 7).

## Terms

`GLOSSARY.md` terms used as defined: **Session**, **Phase**, **Cycle**, **Haptic plan**, **Lead-in**, **Exercise**.

Names and clashes:

- "Sounds", "Sound" (the switch) and `SoundID` are the app's UI and Kit names, not glossary terms. "Chime" is both the third placeholder sound and an ordinary word for a bell cue; in this note "Chime" with a capital is the placeholder.
- Apple's "session" in `AVAudioSession` is written "audio session"; "Session" always means the glossary term. `WKExtendedRuntimeSession` is "extended runtime session".
- Apple's "system sound" is the `AudioServices` API (it plays a file the app supplies). People also say "system sounds" for the sounds Apple ships (alerts, keyboard clicks). This note keeps them apart: "System Sound Services" and "Apple's built-in sounds".
- "Silent switch" (iPhone Ring/Silent switch) is not the watch's "Silent Mode" (Control Center). Apple's category pages speak of the first only.
- Phase start is the Kit's term; "cue" here means a sound played at a Phase start or at the start or end of a Session, as in the ticket.
- Creative Commons "attribution" is a licence duty, not the same as crediting someone politely; Pixabay calls crediting "appreciated" but not required.

## Source quality key

- **Doc page**: an Apple Developer Documentation page read through the documentation JSON feed (`developer.apple.com/tutorials/data/...`) with WebFetch on 2026-11-26. WebFetch summarises. Text in quotation marks was returned as a quote; everything else is paraphrased.
- **HIG / ASC Help / App Review Guidelines**: Apple pages read the same way.
- **Archived Apple guide**: "Multimedia Programming Guide" under `developer.apple.com/library/archive/...`. Apple marks it retired (updated 2015) and says it "may not represent best practices for current development". Used for format preferences only, and labelled.
- **Licence text / library terms**: the legal code or terms page of the licence or site, read through WebFetch the same day (quotes returned, rest paraphrased). The licence of a given file on a given date is the file's own page, which I did not open (I did not pick files).
- **Header**: a file in the Xcode SDK on this Mac, cited as "Xcode beta bundle, iPhoneOS 27.0 SDK" or "Xcode beta bundle, watchOS 27.0 SDK" (`/Users/romansiro/Downloads/Xcode-beta.app`), or "Xcode 26.2, watchOS 26.2 SDK" (`/Applications/Xcode.app`).
- **Own check**: something I ran myself in the scratchpad outside the repo (a Python-generated test tone converted with `afconvert` and read with `afinfo`; `ls` and `grep` of SDK folders). No repo file was changed, no Simulator state was changed, and no sound was played.
- **Unconfirmed**: a statement I could not confirm from a primary source. Mark of a gap.
- **My reading**: my conclusion from the sources, not a statement of any source.
- Two pages I tried returned errors or no usable text (Mixkit licence, US Copyright Office Part 2 report); they are listed as gaps, not cited.

## 1. Where the files can come from

### Libraries with a per-file licence

| Source | Licence terms (documented) | App Store redistribution | Attribution duty | Cost | Fit for calm cues |
|---|---|---|---|---|---|
| **Freesound**, files marked CC0 | CC0 1.0: a waiver; if the waiver fails, a fallback licence that is "royalty-free, non transferable, non sublicensable, non exclusive, irrevocable and unconditional" and worldwide. No trademark or patent rights are touched; the work is offered "as-is" (CC0 legal code, sections 3 and 4). Freesound: "for the 'zero' license you can do pretty much what you want with the sound" (Freesound FAQ). | Not restricted by the text read (my reading: a waiver has no distribution condition). | None in the licence. Freesound's FAQ adds that you still cannot claim to be the author. | Free; a registered account is needed to download (FAQ). | Not checked: I did not browse the catalogue or listen. A bowl, bell or chime recording may or may not exist as CC0 (gap). |
| **Freesound**, files marked CC BY | The uploader picks the licence per sound ("You select the CC license for your sound", Freesound terms). CC BY 4.0 section 3(a): keep the creator's credit, copyright notice, licence reference and disclaimer notice, indicate modifications, include the licence text or a link; "any reasonable manner based on the medium, means, and context"; on the licensor's request the credit may have to be removed (3(a)(3)). Whether Freesound uses 4.0 or an older version for a given file is not stated in what I read (gap). | Allowed with the credit (my reading). Whether App Store encryption counts as an "Effective Technological Measure" that CC BY 4.0 section 2(a)(5) forbids "if doing so restricts exercise of the Licensed Rights" is not answered in the pages I read: the CC FAQ headings on DRM were returned without their answers (unconfirmed). | Yes, per file, in the app or a page it links to (my reading of "reasonable manner"). Freesound's suggested form: title, uploader, URL, licence. | Free. | As above. |
| **Freesound**, files marked CC BY-NC or Sampling+ | NC: Freesound says "you can't earn any money with the piece of work you create". Sampling+ "is being removed by creative commons because it's a difficult license to interpret" (Freesound FAQ). | Avoid (section 2). | n/a | n/a | n/a |
| **Pixabay** (Content License, terms section 5) | "irrevocable, worldwide, perpetual ... non-exclusive and royalty-free right to download, use, copy, modify or adapt the Content for commercial or non-commercial purposes". Not allowed: selling or distributing the content "on a Standalone basis" (no creative effort applied), content with recognisable trademarks or logos for commercial use, misleading or illegal use, use as part of a trade mark or name. The terms say no consents or licences are warranted, "including CC0 Content". Pixabay may change the terms at any time (section 1). The "audio" content type is defined as "music, sounds, sound effects and other audio representations and content" (section 2). | Allowed (my reading: the file is embedded in an app, not distributed standalone). A sound file shipped in the app bundle could be copied out by a user; whether that counts as "standalone" distribution is not addressed (unconfirmed). | "You do not need to credit Pixabay or the contributor" (section 6). | Free. | Not checked (I did not browse or listen). |
| **Mixkit** | The "Sound Effects Free License" is named on the licence page, but I could not read its terms. | Unconfirmed. | Unconfirmed. | Unconfirmed. | Not checked. |
| **Sonniss "GDC Game Audio" bundle** | "All of the sounds are royalty free and commercially usable." "No attribution is required". Not allowed: resale "as sound effects ... the original files and any edited or re-designed versions". "licensed for media production (games, film, TV, interactive projects) only"; AI/ML training is prohibited (Sonniss page). The page says you may sell them inside a finished game, film, app or project (my paraphrase of the page's FAQ). The linked licence text (`sonniss.com/gdc-bundle-license/`) was not read. | The page says an app is fine; the licence text was not read (unconfirmed for an app whose sounds are the Sounds list the user picks from, because the bundle limits use to "media production"). | None. | Price not read (gap). | Game sound effects; fit for soft bowls and bells not checked. |
| **Kenney "UI Audio"** (and other Kenney packs) | The pack page says "Creative Commons CC0". Other Kenney packs: the licence is on each pack's page, which I did not read. | As CC0. | None. | Free (page shows a download; price not stated, so read as free: unconfirmed). | The pack's tags are button, switch, click (page); a breathing cue it is not (my reading). Not listened to. |
| **Paid packs and commissioned sounds** | No vendor or price read. | Depends on the licence; read it before paying (my reading). | Depends. | Gap. | Gap. |

Table sources: CC0 legal code; CC BY 4.0 legal code; Freesound FAQ and terms of use; Pixabay Terms of Service (Content License); Sonniss GDC Game Audio page; Kenney asset pages (see Sources).

### Generating the sounds

- **Synthesis in code (documented availability).** `AVAudioSourceNode` is `API_AVAILABLE(macos(10.15), ios(13.0), tvos(13.0), watchos(6.0))` (Xcode beta bundle, watchOS 27.0 SDK, `AVFAudio.framework/Headers/AVAudioSourceNode.h`). `AVAudioEngine` renders to the output node by default and has a manual rendering mode that disconnects from audio devices ("your app drives the rendering"; doc page `AVAudioEngine`, paraphrased in part).
- **Licence (my reading).** Sound written by the project has no third-party rights, so no licence record beyond "own work, date, author" is needed. This is my reading, not a statement of any source. I did not read any statement on who owns generated audio.
- **Own check on feasibility.** I generated a 3 s mono test tone of two decaying sine partials (440 Hz and 1180 Hz, the second decaying faster) as a WAV with a short Python script outside the repo. I did not listen to it and do not claim it sounds like a bell. It only gives the file sizes in section 3.
- **Fit (my reading).** Bell, Chime, Wood block and Pulse are built from a few decaying partials and short envelopes, so they are plausible to build. A singing bowl is a beating, slowly swelling sound; I expect it is harder to make convincing from sine partials, but I did not try.
- **AI or audio-generation tools.** I read no tool's terms. Terms differ by tool and plan and change; the US Copyright Office has a Part 2 report on copyrightability of AI output (January 2025), but my fetch returned only the cover pages and the landing page says only that Part 2 "addresses the copyrightability of outputs created using generative AI". Both the tool's licence and the copyright status of the output are open (gap).

### System sounds

- **The `AudioServices` API (documented).** `AudioServicesCreateSystemSoundID` takes the URL of a file you supply. A sound played with `AudioServicesPlaySystemSound` must be "no longer than 30 seconds", "in linear PCM or IMA4 (IMA/ADPCM) format" and "packaged in a .caf, .aif, or .wav file". It plays "at the current system audio volume, with no programmatic volume control", looping and stereo positioning are unavailable, "you can play only one sound at a time", and "The sound is played locally on the device speakers; it does not use audio routing" (doc page `AudioServicesPlaySystemSound`). The header says `AudioServicesPlaySystemSound` and `AudioServicesPlayAlertSound` "will be deprecated in a future release" in favour of the `...WithCompletion` variants (Xcode beta bundle, iPhoneOS 27.0 SDK, `AudioToolbox.framework/Headers/AudioServices.h`), and "On iOS there is no preferred user alert sound".
- **Apple's built-in sounds.** I found no Apple page that grants the use of Apple's own sound files in a third-party app, and no public list of them. App Review 5.2.1 forbids "protected third-party material such as ... copyrighted works ... without permission". Not a source (my reading).
- **What a system sound cannot do for a Session (my reading).** No volume control, no routing (the page says it ignores audio routing), one at a time, and an archived Apple guide says sounds played with System Sound Services "are not subject to configuration using your audio session". The HIG nevertheless says "iOS, iPadOS: Use the system's sound services to play short sounds and vibrations" (documented). The two Apple statements pull different ways for a Session cue; I weigh the page's limits above the HIG's general line.

## 2. Licensing checklist

### What to write in the repo per file (my reading)

None of the sources I read prescribes a record format; the fields come from what the licences require or what a later audit would need.

| Field | Why |
|---|---|
| File name in the repo and the `SoundID` it serves | Maps the file to the app. |
| Title and author or uploader as the source names them | CC BY credit (documented: creator's credit). |
| Source URL of that exact file (the permalink, not a search page) | Provenance; Freesound and Pixabay say the licence belongs to the individual item. |
| Licence name, version and a link to its legal text | CC BY: "include the licence text or a link" (documented). |
| Date downloaded and who downloaded it | Pixabay may change its terms at any time (documented); a dated record shows what was agreed. |
| A saved copy of the licence or terms page text as of that date | Same reason; my reading. |
| Modifications made (trim, fade, normalise, convert) | CC BY: "indicating any modifications" (documented). |
| The exact credit string to show, or "none required" | CC BY. |
| Checksum of the original download | Lets a later reader tell whether a file is the original or an edit (my reading). |
| For generated files: the script or tool, its version, the date | Provenance of own work (my reading). |

One place for the whole list (my reading): a single file in the repo (a credits table), so a CC BY credit can also be shown in the app's acknowledgements. Where the record lives and whether the app shows a credits screen is #49's decision (section 7). I did not check what App Store Connect needs for acknowledgements; none is mentioned in the pages I read.

### Licences and terms to avoid (my reading unless marked)

- **Anything NonCommercial** (CC BY-NC and similar): the CC FAQ describes NC as one that "prohibits commercial use of the material" (documented); whether a free, ad-free app is "commercial" is a question the FAQ answer I could not read addresses (unconfirmed), so avoid.
- **NoDerivatives and ShareAlike**: I did not fetch their legal code. NoDerivatives would forbid the trims, fades and normalising the cues need, and ShareAlike would put a share-alike condition on the result; both are my reading from what I know, not from a source read for this note. Avoid.
- **Sampling+**: Freesound says it is being removed and is "a difficult license to interpret" (documented).
- **Files with no stated licence, "free download" pages with no licence text, re-uploads of other people's work, files from a site whose terms I could not read** (for example Mixkit's in this research).
- **Content with recognisable trademarks or logos** (Pixabay's terms bar commercial use of such content, documented) and any sound from a film, game or product jingle.
- **Apple's built-in sounds and Apple Music or iTunes previews** (5.2.5 says previews "may not be used for their entertainment value", documented for previews only; for Apple's built-in sounds see section 1, my reading).
- **AI-tool output whose terms were not read or that bar commercial use** (gap in this note).
- **Sonniss material beyond the stated use** ("media production (games, film, TV, interactive projects) only") until the licence text is read.

## 3. Formats and size

### What the documents say

- **System Sound Services**: 30 s or shorter, PCM or IMA4, in `.caf`, `.aif` or `.wav` (doc page, quoted in section 1).
- **`AVAudioPlayer`**: "Play audio of any duration from a file or buffer" and supports volume, panning, rate and looping; the page does not list file formats (doc page `AVAudioPlayer`). The header marks it watchOS 3.0 (Xcode beta bundle, watchOS 27.0 SDK, `AVAudioPlayer.h`).
- **Preferred formats (archived guide, 2015)**: "For uncompressed (highest quality) audio, use 16-bit, little endian, linear PCM audio data packaged in a CAF file." "For compressed audio when playing one sound at a time ... use the AAC format packaged in a CAF or m4a file." "For less memory usage when you need to play multiple sounds simultaneously, use IMA4". It adds that hardware-assisted decoding of AAC, HE-AAC, MP3 and ALAC supports only one instance at a time. It names `/usr/bin/afconvert -f caff -d LEI16 {INPUT} {OUTPUT}` for PCM. This is a retired page (my reading: the hardware-decoder statement may be out of date; I found no current page for it).
- **CAF**: "a file format for storing and transporting digital audio data" without the "file-size limitations of other audio file formats" (archived CAF specification introduction). It names no supported codecs there.
- **Sample rate, loudness**: no Apple page I read gives a sample rate for cues or a loudness target. The HIG "Playing audio" has "no explicit loudness guidance"; it says the "system volume always governs the final output" and that an app may adjust relative levels (HIG, paraphrased in part). So the loudness of the five cues relative to each other and to a person's other audio is a choice to make by ear on devices (gap).
- **App size limits (documented, ASC Help "Maximum build file sizes")**: iOS and iPadOS apps 4 GB uncompressed; watchOS apps 75 MB uncompressed for all deployment targets.

### Own check: file sizes of one 3 s mono test tone

A 3 s, mono, 16-bit test tone (two decaying partials, peak -1.0 dBFS and RMS -15.4 dBFS as I computed in the script), converted with `afconvert` from the Xcode beta (`afinfo` for the details). The signal is a simple tone, so AAC sizes here are lower than a noisy real recording would give. Treat the ratios, not the byte counts, as the finding.

| Format | Size (bytes) | Detail |
|---|---|---|
| WAV, 44.1 kHz, PCM 16-bit | 264,644 | the source |
| WAV, 48 kHz, PCM 16-bit | 288,044 | |
| WAV, 22.05 kHz, PCM 16-bit | 132,344 | |
| CAF, 44.1 kHz, PCM 16-bit (`LEI16`) | 268,696 | 4,052 bytes more than the WAV |
| CAF, 22.05 kHz, PCM 16-bit | 136,396 | |
| CAF, 44.1 kHz, IMA4 | 74,408 | 34 bytes per 64-frame packet |
| M4A, 44.1 kHz, AAC, requested 64 kbit/s | 15,068 | measured 28.6 kbit/s |
| M4A, 44.1 kHz, AAC, requested 96 kbit/s | 16,995 | |
| M4A, 44.1 kHz, AAC, requested 128 kbit/s | 23,832 | |
| M4A, 48 kHz, AAC, requested 64 kbit/s | 15,758 | |

- Five PCM CAF cues of 3 s at 44.1 kHz mono: 5 x 268,696 = 1,343,480 bytes, about 1.3 MB, under 2 % of the 75 MB watch limit. Five AAC cues: about 75 KB. A 3 s cue is a size I chose for the arithmetic, not a requirement.
- `afinfo` on the AAC file reports "2112 priming" frames (about 48 ms at 44.1 kHz) next to "132300 valid frames". Whether `AVAudioPlayer` drops the priming frames at playback is not documented in the pages I read (gap). For a cue that must line up with a Phase start (my reading), PCM avoids the question.
- The file size on an iPhone is not a limit: 4 GB and no real pressure from cues (my reading). On the watch, one PCM cue of a long ambient sound would matter (10 s at 44.1 kHz mono PCM is about 0.9 MB, my arithmetic from the table).

### Recommendation (my reading)

- Cues up to a few seconds: mono, 44.1 kHz, 16-bit linear PCM in CAF, made with `afconvert -f caff -d LEI16`. Apple's archived guide prefers it, `AVAudioPlayer` and System Sound Services both take it, and it avoids decoder questions.
- Use AAC in M4A only for a long sound where size matters (not expected for five cues).
- Sample rate: Apple gives no figure. 44.1 kHz is what I measured; a lower rate halves the size but I did not evaluate the sound quality or a watch speaker (gap).
- Loudness: normalise the five cues to one measured loudness and leave headroom (not a documented rule; the numbers are for #49 or the playback ticket to choose and write down).
- Trim silence at the head so the cue starts at the file start, and give each sound a gentle fade-out so it does not click at the end (my reading, untested).

## 4. Playback on iPhone

### Documented behaviour

- **Default category is `soloAmbient`**: "Your audio is silenced by screen locking and by the Silent switch" and it is nonmixable: "activating your session will interrupt any other audio sessions which are also nonmixable" (doc page `soloAmbient`).
- **`ambient`**: "audio from other apps mixes with your audio"; "Screen locking and the Silent switch ... silence your audio"; "appropriate for 'play-along' apps" and for "an app in which sound playback is nonprimary — that is, your app also works with the sound turned off" (doc page `ambient`).
- **`playback`**: "your app audio continues with the Silent switch set to silent or when the screen locks"; to keep playing in the background add `audio` to `UIBackgroundModes`; "By default ... your app's audio is nonmixable", so use `mixWithOthers` to allow mixing (doc page `playback`).
- **`mixWithOthers`** can be set explicitly only for `playAndRecord`, `playback` and `multiRoute`, and is set automatically for `ambient`; "Clearing this option and then activating your session interrupts other audio sessions" (doc page `mixWithOthers`).
- **`duckOthers`**: lowers other audio while your session is active and "Set this option on a temporary basis only. Don't use it to duck the audio of other apps for more than a few seconds" (doc page `duckOthers`). A Session cue is a few seconds at most, but ducking begins at activation and ends at deactivation, so a session that stays active for a whole Session would keep ducking (my reading; the page: "Ducking begins when you activate your app's audio session and ends when you deactivate"). Do not use it for a whole Session.
- **`interruptSpokenAudioAndMixWithOthers`**: for "occasional and spoken" audio such as an exercise app; it would pause someone's podcast. A tone is not spoken audio (my reading), so it does not apply.
- **When to activate**: "it's recommended to defer this call until your app begins audio playback ... that you don't prematurely interrupt any other background audio" (doc page "Configuring your app for media playback").
- **Changing category while active** "results in an immediate change" (doc page `setCategory`).
- **Bluetooth**: "The system automatically routes to A2DP ports if you configure an app's audio session to use the ambient, soloAmbient, or playback categories" (doc page `allowBluetoothA2DP`). So `ambient` and `playback` reach Bluetooth headphones with no option.
- **HIG, silent mode**: "When a device is in silent mode, it plays only the audio that people explicitly initiate, like media playback, alarms, and audio/video messaging"; "nonessential sounds, such as keyboard clicks, sound effects, game soundtracks" should be silent. The system volume "always governs the final output". People "expect sound to reroute automatically without interruption" to headphones, and "when disconnecting headphones, they expect playback to pause immediately". Interruptions can be resumable or non-resumable (HIG "Playing audio", paraphrased in part).
- **Background**: the iOS note (#10) concludes that the Session pauses whenever the scene is not active and recommends against a background mode just to keep a timer alive (`ios-26-session-constraints.md`, section 1, and App Review 2.5.4 there). Sounds are optional, so a Session sound is not a reason to add `audio` (my reading).
- **Interruptions and route changes**: handle `AVAudioSession.interruptionNotification` (the iOS 26 mechanism) and `routeChangeNotification`; do not resume by itself (`ios-26-session-constraints.md`, section 3). Nothing new from this research.

### Which category: the decision (my reading)

| Choice | Silent switch | Other audio | Lock | Needs `audio` mode | Fit |
|---|---|---|---|---|---|
| `.ambient` | Silences the cue | Mixes (automatic) | Silences it | No | The HIG's "nonessential sounds" rule; a person who muted the phone hears haptics only |
| `.playback` + `.mixWithOthers` | Cue still plays | Mixes | Continues only with the `audio` background mode | No (the Session pauses on lock) | The person turned Sound on in the app, which is an explicit choice (my reading of "explicitly initiate"); but it breaks the silence a person set with the switch |

- The sources do not decide it. The ticket asks for a recommendation: I lean to `.playback` with `.mixWithOthers`, because the in-app Sound switch is the person's explicit choice and an eyes-closed Session with a muted phone would otherwise show "Sound on" and play nothing (my reading). The opposite reading, that a Session cue is a "nonessential sound" the Silent switch should silence, is as supported by the HIG text. It is an owner decision for #49 (section 7).
- If `.playback` is chosen, deactivate the audio session when the Session ends so other apps' audio is not held (documented in the activation guidance; `notifyOthersOnDeactivation` is documented for the spoken-audio option only).

### Which API

| API | Facts (documented) | Fit for a Session cue (my reading) |
|---|---|---|
| `AVAudioPlayer` | Plays audio of any duration from a file or buffer; volume, rate, looping; `prepareToPlay()`; works with the audio session. An archived guide says Apple recommends it "if your application does not require stereo positioning or precise synchronization". | Good: one preloaded player per sound, `prepareToPlay()` at Session start, `play()` at the cue. Simple. |
| `AVAudioEngine` with `AVAudioPlayerNode` or `AVAudioSourceNode` | Node graph; for "more advanced playback capabilities". `AVAudioSourceNode` can synthesise. | More than the cues need, unless sounds are synthesised at run time. |
| System Sound Services (`AudioServices`) | 30 s limit, PCM or IMA4 in `.caf`/`.aif`/`.wav`, system volume only, one at a time, "does not use audio routing"; not configured by the audio session (archived). | Not recommended: no volume control, no routing, and it does not follow the audio session choice above. |

- **Timing accuracy of a cue against a Phase start**: no Apple figure for `AVAudioPlayer` start latency (gap). `AVAudioPlayer.play(atTime:)` exists (header, `AVAudioPlayer.h`, iOS 4.0 and watchOS 2.0) but the clock-alignment problem noted in the iOS note for haptics applies to any second clock (`ios-26-session-constraints.md`, section 4); measure on a device.
- **Test list (my reading)**: with the Silent switch on and off; with Music playing; on speaker, wired and Bluetooth headphones; after a phone call interruption; with the screen locking mid-Session.

## 5. Playback on Apple Watch

Reused from `watchos-session-constraints.md` section 4 (not repeated): the categories exist on watchOS; long-form audio needs a Bluetooth route, and on supported models with watchOS 11 or later the built-in speaker also satisfies it; no primary source covers a short sound with the default policy; Silent Mode does not say what it does to app audio; the extended runtime session may or may not allow `play(_:)` and sounds with the wrist down (documented in conflict); the Simulator gave `Speaker` for `.playback` with `.mixWithOthers` (own check in that note, nothing about hardware); do not add the `audio` background mode unless a device test shows a cue needs it.

New in this note:

- **Classes on watchOS (documented, header, Xcode beta bundle, watchOS 27.0 SDK).** `AVAudioPlayer` watchOS 3.0; `AVAudioEngine` and `AVAudioPlayerNode` watchOS 2.0; `AVAudioSourceNode` watchOS 6.0; `AVAudioSession` ambient, soloAmbient: watchOS 2.0 (`AVAudioSessionTypes.h`).
- **`AudioServices` is not in the watch SDK (own check).** `AudioToolbox.framework` is absent from the `System/Library/Frameworks` folder of the watchOS 27.0 SDK in the Xcode beta bundle and of the watchOS 26.2 SDK in Xcode 26.2, and a text search of the whole watchOS 27.0 SDK and the 26.2 SDK for `AudioServicesPlaySystemSound` found nothing, while the iPhoneOS 27.0 SDK's `AudioServices.h` marks the functions `watchos(2.0)`. I did not compile a call. My reading: do not plan on System Sound Services for the watch; the header's availability mark is not backed by a framework in these SDKs.
- **Activation page (documented, paraphrased).** "On supported Apple Watch models running watchOS 11.0 or later, the built-in speaker also satisfies this routing requirement" for the `playback` category with the `longFormAudio` or `longFormVideo` policy. The system routes to the speaker if the watch supports it, otherwise shows the route picker; it "only presents the audio route picker for the playback category and longForm route sharing policy"; and "Use the activate(options:completionHandler:) method instead of setActive(_:options:) to authorize other categories and sharing policies". The page does not say whether a plain `.playback` or `.ambient` session without the long-form policy can use the speaker (the open question stays).
- **Silent Mode and Theater Mode (Support, from a search result summary, paraphrased).** "Use Silent Mode to mute all alerts, notifications, and sound effects. You still receive haptic notifications." Theater Mode also turns Silent Mode on, and Apple Watch has separate volume controls for system sounds, Siri and media playback. Alarms and timers sound while charging even in Silent Mode. The pages do not say whether Silent Mode silences third-party app audio (unconfirmed). Support pages: "Change the volume, audio, and haptic settings on your Apple Watch" and "Adjust volume and haptics on Apple Watch". I read them only through a search summary in this research, so treat the quotes as paraphrase.
- **Sound switch on a watch without a speaker or without a route (my reading).** The page says a watch that does not support speaker playback shows the route picker, and "long-form audio can't play through the built-in speaker while the watch is charging". A cue for the watch should therefore fail quietly if no route is available, and the Session must not depend on it (sound is optional, haptics are the cue).
- **App size**: 75 MB uncompressed for a watchOS app (ASC Help); the cues in section 3 are well under it. Whether the watch app bundle needs its own copy of each file rather than sharing the iPhone's is not documented in what I read; I would expect it does as a separate bundle (my reading, unconfirmed).
- **Secondary, not used as evidence.** A search result summary of one developer forum thread (not an Apple statement, not fetched) reports that on watchOS 11 a long-form audio session played to the speaker without the route picker. It is consistent with the documented speaker rule but is not a source.
- **What a running Session needs (my reading, repeated in one line).** The mindfulness extended runtime session from #38 owns "may run with the wrist down"; whether a cue plays under it must be tested on a device before any watch sound ticket is called done.

Test list for a watch (my reading): speaker, AirPods, Silent Mode on, Theater Mode on, charging, wrist down inside the extended runtime session, with Music playing from the watch, and a model without a speaker.

## 6. Candidate sources for the five placeholders

Only trade-offs; none of these was listened to, and no file was chosen. Fit is my reading.

| Placeholder | Candidate A | Candidate B | Notes |
|---|---|---|---|
| Soft bell | Synthesised (own work) | Freesound CC0 or CC BY recording | A bell is a few decaying partials (my reading). |
| Singing bowl | Freesound CC0 recording, provenance recorded | Commissioned or paid pack (price and licence unread) | Hardest to synthesise (my reading, untried). A recording from a library carries the uploader-warranty risk the terms describe. |
| Chime | Synthesised | Freesound CC0 | Same as bell. |
| Wood block | Synthesised (short noise burst plus tuned partial) | Kenney or Pixabay click sound | A UI-click pack may sound like an interface click, not a calm cue (my reading, not listened to). |
| Pulse | Synthesised (soft low sine, short envelope) | n/a | The simplest to make; no library needed. |

| Source | Licence | Cost | Attribution | Main risk |
|---|---|---|---|---|
| Synthesis in code or an offline script | Own work | Developer time | None | Singing bowl quality; the script must be kept in the repo or recorded for the credits table. |
| Freesound CC0 | CC0 (per file) | Free | None | Provenance: the uploader's warranty is theirs, the library accepts no liability (documented). |
| Freesound CC BY | CC BY (per file) | Free | Yes, per file | A credit screen, and the DRM question in section 1 is unanswered (unconfirmed). |
| Pixabay | Pixabay Content License | Free | None | Terms can change; "no consents warranted"; the standalone clause (unconfirmed for files shipped in a bundle). |
| Sonniss GDC bundle | Sonniss licence (text not read) | Not read | None | "Media production only" scope; fit for calm sounds unknown. |
| Kenney UI Audio | CC0 | Free (not stated) | None | Fit: UI clicks. |
| Paid pack or commissioned | Per vendor | Unknown | Per vendor | Not researched. |
| AI audio tool | Per tool | Per tool | Per tool | Not researched; copyright status of output unresolved. |

Proposal for #49 to accept or reject (my reading): build Soft bell, Chime, Wood block and Pulse by synthesis, take the Singing bowl from a CC0 recording or a commissioned one with its provenance written down, and record every file in one credits table. This keeps the CC BY credit screen and the unresolved DRM question out of scope unless a CC BY file is chosen on purpose.

## 7. What #49 and the playback tickets must take from this

For #49 (decide the sounds):

1. Choose a source for each of the five sounds (section 6) and write the licence record for each (section 2).
2. Decide the category: `.ambient` (silenced by the Silent switch) or `.playback` with `.mixWithOthers` (plays with it), and write which one down (section 4). The sources do not decide it.
3. Decide when a sound plays (each Phase start, Session start and end only, or only the end). Nothing in the audio sources constrains it, but a cue at every Phase start of a 4-4-4-4 box Pattern is a cue every 4 s, so the rule and the tempo are linked (my reading).
4. Decide whether the app shows a credits screen (needed for any CC BY file) and where the credits table lives.
5. Decide the format and loudness target (section 3, a recommendation only).

For the iPhone playback ticket:

1. `AVAudioPlayer` with preloaded players and `prepareToPlay()`; activate the audio session at the first cue, not at launch (documented advice) and deactivate at Session end.
2. No `audio` background mode.
3. Handle interruption and route-change notifications; pause, do not auto-resume (the iOS note).
4. Do not use System Sound Services or `duckOthers` for the Session.

For the watch playback ticket:

1. Do not use `AudioServices` (not in the SDK, own check).
2. Follow the device test list in `watchos-session-constraints.md` section 4 plus the items in section 5 here, and write the results into the ticket.
3. Treat "no route" as normal; the Sound switch must not block the Session.

## 8. Gaps and anything unverified

- **Mixkit's Sound Effects Free License**: the terms page returned only a link; not read.
- **Sonniss licence text**, price, and whether its use scope allows an in-app list of selectable sounds: not read.
- **Per-pack Kenney licences** other than UI Audio: not read. The UI Audio page's file formats and size were not shown.
- **Freesound's CC licence versions**, and whether a file's licence can change after download: not stated in what I read.
- **CC NC, ND and SA legal texts**: not fetched. The CC FAQ's answers on NonCommercial in a commercial app and on DRM were cut off in the fetch; so "whether the App Store's protection of an app conflicts with CC BY 4.0 section 2(a)(5)" is unconfirmed.
- **No catalogue was browsed and nothing was listened to.** Whether suitable CC0 or Pixabay bowls, bells or chimes exist is unknown.
- **AI audio tools and the copyright of AI output**: nothing read (the Copyright Office report did not extract).
- **Paid packs and commissioning**: no vendor, price or licence read.
- **Apple's built-in sounds**: no Apple statement found either way; my reading is "not a source".
- **Sample rate, loudness, start latency and AAC priming handling** for `AVAudioPlayer`: no Apple figure or statement found. Own-check sizes come from a synthetic tone, not a real recording.
- **The retired archived guide** (format preferences, hardware-decoder remark) was not confirmed against a current Apple page.
- **Silent Mode and third-party audio on the watch**, the default-policy route for a short sound, which watch models have a speaker, and `AudioServices` on the watch beyond the missing framework: still open; need a device or an Apple statement.
- **Own check limits**: no sound was played; no Simulator was booted; the test tone was not listened to.
- **Docs describe OS 27 in places**; the iOS 26 and watchOS 26 behaviour of the pages above was not separately tested.

## Sources

Apple developer documentation (read as `https://developer.apple.com/tutorials/data/documentation/<path>.json`, the feed behind the pages at `https://developer.apple.com/documentation/<path>`):

- `avfaudio/avaudiosession/category-swift.struct/ambient`: https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/ambient
- `.../soloambient`: https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/soloambient
- `.../playback`: https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playback
- `avfaudio/avaudiosession/categoryoptions-swift.struct/mixwithothers`, `/duckothers`, `/allowbluetootha2dp`, `/interruptspokenaudioandmixwithothers`: https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct
- `avfaudio/avaudiosession/setcategory(_:mode:options:)`: https://developer.apple.com/documentation/avfaudio/avaudiosession/setcategory(_:mode:options:)
- `avfaudio/avaudiosession/activate(options:completionhandler:)`: https://developer.apple.com/documentation/avfaudio/avaudiosession/activate(options:completionhandler:)
- `avfaudio/avaudioplayer`: https://developer.apple.com/documentation/avfaudio/avaudioplayer
- `avfaudio/avaudioengine`: https://developer.apple.com/documentation/avfaudio/avaudioengine
- `avfoundation/configuring-your-app-for-media-playback`: https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback
- `audiotoolbox/audioservicesplaysystemsound(_:)`: https://developer.apple.com/documentation/audiotoolbox/audioservicesplaysystemsound(_:)
- `audiotoolbox/audioservicescreatesystemsoundid(_:_:)`: https://developer.apple.com/documentation/audiotoolbox/audioservicescreatesystemsoundid(_:_:)

Other Apple pages:

- HIG "Playing audio" (feed: `https://developer.apple.com/tutorials/data/design/human-interface-guidelines/playing-audio.json`): https://developer.apple.com/design/human-interface-guidelines/playing-audio
- App Review Guidelines (5.2, 5.2.1, 5.2.5): https://developer.apple.com/app-store/review/guidelines/
- App Store Connect Help, Maximum build file sizes: https://developer.apple.com/help/app-store-connect/reference/maximum-build-file-sizes/
- Archived: Multimedia Programming Guide, Using Audio: https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/MultimediaPG/UsingAudio/UsingAudio.html
- Archived: Core Audio Format Specification, introduction: https://developer.apple.com/library/archive/documentation/MusicAudio/Reference/CAFSpec/CAF_intro/CAF_intro.html
- Apple Support (read as a search-result summary only): https://support.apple.com/en-us/108368 and https://support.apple.com/guide/watch/adjust-volume-and-haptics-apd62807a9f3/watchos

SDK headers and own checks (Xcode beta bundle `/Users/romansiro/Downloads/Xcode-beta.app`, build 27A5209h; Xcode 26.2 `/Applications/Xcode.app`):

- Xcode beta bundle, iPhoneOS 27.0 SDK: `System/Library/Frameworks/AudioToolbox.framework/Headers/AudioServices.h`
- Xcode beta bundle, watchOS 27.0 SDK: `System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioPlayer.h`, `AVAudioEngine.h`, `AVAudioPlayerNode.h`, `AVAudioSourceNode.h`, `AVAudioSessionTypes.h`
- Xcode 26.2, watchOS 26.2 SDK: `System/Library/Frameworks` (no AudioToolbox)
- Own check, scratchpad outside the repo: a Python-generated 3 s mono test tone converted with `afconvert` and inspected with `afinfo`; `ls` and `grep` of the SDK folders.

Licences and library terms:

- CC0 1.0 Universal legal code: https://creativecommons.org/publicdomain/zero/1.0/legalcode
- CC BY 4.0 legal code: https://creativecommons.org/licenses/by/4.0/legalcode
- Creative Commons FAQ: https://creativecommons.org/faq/
- Freesound FAQ: https://freesound.org/help/faq/
- Freesound Terms of use (web): https://freesound.org/help/tos_web/
- Pixabay Terms of Service (Content License) and licence summary: https://pixabay.com/service/terms/ and https://pixabay.com/service/license-summary/
- Sonniss GDC Game Audio: https://sonniss.com/gameaudiogdc (licence text at https://sonniss.com/gdc-bundle-license/, not read)
- Kenney, UI Audio: https://kenney.nl/assets/ui-audio and https://kenney.nl/assets/category:Audio
- Mixkit licence page (terms not readable): https://mixkit.co/license/
- US Copyright Office, AI: https://www.copyright.gov/ai/ (Part 2 report not read)

Repo notes read: `docs/product/research/watchos-session-constraints.md`, `docs/product/research/ios-26-session-constraints.md`, `GLOSSARY.md`, `docs/product/phone-design.md`, `docs/product/watch-design.md`, and `BreathnestKit/Sources/BreathnestKit/AppSettings.swift`; tickets #208 and #49.
