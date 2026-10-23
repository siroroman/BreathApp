# Breathing techniques: parameters and safety notes

Research for issue #9 (part of the map in issue #8). Researched 2026-10-23.

## Question

What are the established phase timings for box breathing, 4-7-8, coherent breathing and the physiological sigh, and which safety notes or contraindications must the app show? Express each as a Pattern (ordered Phases of kind and seconds, fractional allowed) and recommend default Session durations.

## Short answer

- Only two of the four have timings that a primary source gives: **4-7-8** (4 / 7 / 8 as a ratio, from its inventor) and **coherent breathing** (about 5.5 to 6 breaths per minute with equal inhale and exhale, from physiological studies). **Box breathing** has equal phases in a primary study, but the 4 s length is an example, not a finding. The **physiological sigh** has no published seconds at all; its structure (double inhale, long exhale) is supported, its timings are an app design choice.
- Effect evidence is thin and short-term. The strongest result is a 28-day randomized trial (Balban 2023) where 5 minutes a day of cyclic sighing improved mood the most. Slow breathing near 6 per minute reliably raises heart rate variability in small lab studies. 4-7-8 and box breathing have little direct support.
- No primary or clinical-guidance source I found lists formal contraindications for slow breathing. What exists is trial exclusion lists, a general NIH caution, and review-level theoretical risks. The safety text the app shows is therefore partly a conservative design decision, labelled as such below.

## Terms

`GLOSSARY.md` does not exist in the repository yet (checked every local and remote branch). This file uses the definitions given in issue #8 and `docs/product/brief.md`:

- **Pattern**: an ordered list of Phases.
- **Phase**: a kind (`inhale`, `hold`, `exhale`; the brief also lists `rest`) plus a duration in seconds, fractional allowed.
- **Cycle**: one pass through the Pattern. **Session**: a run of Cycles. **Exercise**: a named Pattern with its notes.

Assumptions this file makes, to be reconciled when the glossary is written:

- Both holds in box breathing use kind `hold`. The first is a hold with full lungs, the second with empty lungs. If the glossary wants these distinguished, `rest` is the candidate kind for the empty-lung hold.
- Two consecutive Phases of the same kind are allowed (the double inhale of the sigh).

## Source quality key

- **Primary study**: the paper that ran the experiment.
- **Review**: a published synthesis of primary studies. Used for background, flagged as such.
- **Originator**: the person who defined the technique. Authoritative for what the technique *is*, not for whether it *works*.
- **Convention**: widely repeated, no primary source found in this research. Marked clearly.

## Patterns

### Box breathing

| Phase | Kind | Seconds |
|---|---|---|
| 1 | inhale | 4 |
| 2 | hold | 4 |
| 3 | exhale | 4 |
| 4 | hold | 4 |

Cycle length 16 s (3.75 breaths per minute).

What the sources support:

- Equal inhale, hold, exhale and hold phases are the definition used in the only randomized trial of box breathing found: Balban et al. 2023 (Cell Reports Medicine). Phase length there was scaled to the participant, from 3 to 4 s for people who emptied their lungs quickly after a maximal inhale, up to 8 to 10 s for people who took long. Their worked example is 4 / 4 / 4 / 4. Participants were told to shorten phases if they strained.
- Effect: in that trial (21 people in the box group, 5 min a day for 28 days) positive mood and state anxiety improved, but box breathing did not differ from the mindfulness control, and no group-level advantage was shown for box over the other breathwork groups.
- A head-to-head HRV study (Marchant et al. 2025, Applied Psychophysiology and Biofeedback, 84 students) found square breathing raised heart rate variability less than breathing at 6 per minute, and its authors state that square and 4-7-8 breathing "have little empirical support".

Convention only: the fixed 4 s length as "the" box pattern, and any military origin story. I found no primary source for either.

Suggested range for the app: allow 3 to 6 s per phase, default 4 s.

### 4-7-8

| Phase | Kind | Seconds |
|---|---|---|
| 1 | inhale | 4 |
| 2 | hold | 7 |
| 3 | exhale | 8 |

Cycle length 19 s (about 3.2 breaths per minute).

What the sources support:

- The 4:7:8 definition comes from its originator, Andrew Weil (drweil.com instructions): inhale through the nose for 4, hold for 7, exhale through the mouth for 8, repeated for four cycles. He states that the ratio matters, not the absolute seconds, and that anyone who struggles with the hold should speed up while keeping the ratio. He advises no more than four cycles at a time for the first month, extendable to eight, and says mild lightheadedness early on will pass. (The Weil pages returned HTTP 403 to direct fetching; the wording above was read from search result excerpts of those pages, so re-verify before quoting.)
- Effect: no randomized trial of 4-7-8 on its own was found. A small study in 43 healthy 19 to 25 year olds (Physiological Reports 2022, doi 10.14814/phy2.15389) measured immediate effects of three sets of six cycles: heart rate and systolic blood pressure fell and high-frequency HRV rose in the non-sleep-deprived group. It had no control condition for breathing, so it shows an immediate change, not that 4-7-8 is better than other slow breathing. Marchant 2025 (above) found 4-7-8 raised HRV less than 6 breaths per minute.

Convention only: use before sleep, and the claims that it calms the nervous system. Those come from the originator's publications, not from trials.

Because of the long hold and the 19 s cycle, 4-7-8 is the pattern most likely to make a new user feel breathless. The ratio-preserving speed-up Weil describes should be exposed as a pace control (for example scale factor 0.5 to 1.0).

### Coherent breathing

| Phase | Kind | Seconds |
|---|---|---|
| 1 | inhale | 5.5 |
| 2 | exhale | 5.5 |

Cycle length 11 s (5.45 breaths per minute). Exactly 5.5 breaths per minute would be 5.4545 s per phase; 5.5 s is the usual rounding.

What the sources support:

- Heart rate variability and respiratory sinus arrhythmia peak at about 6 breaths per minute (0.1 Hz): Russo et al. 2017 (Breathe, review) and Bernardi et al. (BMJ 2001, 23 healthy adults), who found that reciting at six breaths per minute increased cardiovascular rhythms and baroreflex sensitivity from 9.5 to 11.5 ms/mmHg. Lehrer and Gevirtz (Frontiers in Psychology 2014, a hypothesis paper) explain the proposed baroreflex mechanism.
- The exact optimum varies between people (Russo et al.; Lehrer and Gevirtz describe resonance-frequency biofeedback, in which the rate is tuned to the individual).
- Equal inhale and exhale: Lin et al. 2014 (International Journal of Psychophysiology, 47 students) compared 6 and 5.5 breaths per minute at ratios 5:5 and 4:6. 5.5 per minute with 5:5 gave the highest HRV, and all four patterns raised subjective relaxation over baseline. This is the primary support for the 5.5 s value. Russo et al. also note a tendency toward higher HRV at a 1:1 ratio.
- Slow breathing in general: Zaccaro et al. 2018 (Frontiers in Human Neuroscience, systematic review of 15 studies) found slow breathing (10 per minute or fewer) associated with higher HRV and with relaxation, but the studies were small, within-subject or pre-post, and none was a randomized longitudinal trial.
- Caveat for the app: Marchant 2025 measured end-tidal CO2 and found that 6 per minute with a 4:6 or 5:5 ratio produced mild over-breathing (CO2 fell). This is the only direct evidence of a physiological downside I found, and it is the reason for the "stop if dizzy" note below.

Alternatives with equal support: 5 / 5 (6 per minute) is the better-studied rate (Bernardi, Marchant). A longer exhale such as 4 / 6 is also studied (Lin) but gave lower HRV than 5:5; Gerritsen and Band 2018 (a theory paper) argue a longer exhale favours vagal effects, based on one HRV study, so this is not settled.

### Physiological sigh (cyclic sighing)

| Phase | Kind | Seconds | Basis |
|---|---|---|---|
| 1 | inhale | 2 | design choice |
| 2 | inhale | 1 | design choice |
| 3 | exhale | 6 | design choice |

Cycle length 9 s (6.7 breaths per minute). The structure is: a normal inhale, a second shorter inhale on top to fill the lungs, then a long slow exhale.

What the sources support:

- Balban et al. 2023 tested exactly this structure as "cyclic sighing" and describe it as a slow inhale, a second shorter inhale, then a slow full exhale, with the exhale emphasized and the double inhale increasing inhalation depth. The paper gives **no seconds** for any phase. In the 28-day trial (30 people in the cyclic sighing group), it was the only breathwork that improved positive mood significantly more than the mindfulness control, and the only one that lowered resting respiratory rate significantly more than the control. Its effect on anxiety was not different from the other groups.
- Spontaneous sighs reset breathing: Vlemincx and colleagues (Physiology and Behavior 2012, Psychophysiology 2009 and 2011) found that a sigh restores respiratory variability lost under mental load, and that sigh rate is higher in moments of relief than of stress. Li et al. (Nature 2016) identified the brain circuit that produces sighs, in mice. These are background for why a sigh exists, not evidence that a deliberate double-inhale pattern helps.
- The name "physiological sigh" and the seconds popularly quoted for it are not from these papers. I did not fetch any popular source, so I cannot say what timings are typical. The 2 / 1 / 6 values above are a proposal that satisfies the one rule the trial states (exhale clearly longer than the inhale), and should be validated by feel on a device.

Offer a lower bound: exhale at least as long as both inhales combined.

## Safety notes and contraindications

### What the evidence actually says

| Source | What it says | Strength |
|---|---|---|
| NCCIH, "Relaxation Techniques: What You Need to Know" (updated June 2021) | Relaxation techniques are generally safe for healthy people; occasionally cause increased anxiety, intrusive thoughts or fear of losing control; rare reports of worsening in people with epilepsy, certain psychiatric conditions, or a history of abuse or trauma. Names no cardiac or pregnancy caution. | Government health agency, general to all relaxation techniques |
| Balban et al. 2023, eligibility | Excluded people with moderate to severe psychiatric or medical conditions that participation could worsen, with examples heart disease, glaucoma, seizure history, pregnancy, psychosis, suicidality, bipolar disorder, substance use disorder. In the debrief, 10% reported negative experiences with the exercises (not itemized). No adverse event analysis. | Trial exclusion list: shows who was *not studied*, not that they are harmed. |
| Zaccaro et al. 2018 | Excluded people under 18 or over 65 and anyone with chronic or acute pathology. Lists adverse effects of slow breathing as an open research question. | Review: shows an evidence gap. |
| Russo et al. 2017 | States that no documented adverse effects of breathing at 6 to 10 per minute were found in the literature; makes no statement on pregnancy, dizziness or breath holds. | Review, healthy people, short sessions |
| Marchant et al. 2025 | Breathing at 6 per minute caused mild over-breathing (lower end-tidal CO2) in healthy students. | Primary study, single session |
| Gerritsen and Band 2018 | Notes that over-stimulation could be harmful, mentioning vasovagal syncope and bronchoconstriction (possibly relevant to asthma), and that fast deep breathing behaves differently from slow breathing. | Theory paper, speculative |
| Weil (4-7-8 originator) | Mild lightheadedness when starting is normal; limit to four cycles at first. Search excerpts also suggested he advises people with respiratory or cardiac conditions or dizziness to ask a clinician before breath-holding exercises; I could not confirm this on the page itself. | Originator guidance, not clinical |
| NHS, "Breathing exercises for stress" (reviewed 12 June 2026) | Gives a simple 5-count breath for at least 5 minutes and contains no safety warnings. | Shows the mainstream guidance for gentle breathing is minimal. |

There is **no source** in this set that addresses pregnancy, driving, or breath holds and fainting directly. I searched NHS, NIH and PubMed-indexed guidance and found none. Anything the app says on those points is a design decision.

### What the app should show (recommendation)

Marked S (supported by a source above) or D (design decision, conservative, no direct source).

1. **First-launch notice, once, with acknowledgement.** The app is for relaxation and is not medical advice or treatment. (D)
2. **Stop and breathe normally if you feel dizzy, lightheaded, tingly, faint, short of breath, or anxious.** Never force a breath or a hold. Dizziness is expected mild and short at first, but stop if it persists. (S: Weil, Marchant, NCCIH, Balban 10%.)
3. **Talk to a doctor first if you are pregnant, or have a heart, lung (including asthma), blood pressure or seizure condition, glaucoma, a history of fainting, or a serious mental health condition, especially panic disorder, psychosis, bipolar disorder or trauma.** This list is the union of trial exclusions and NCCIH cautions. Present it as "ask first because this has not been studied for you", not as "this is dangerous". (S for the groups listed in trial exclusions and NCCIH; D for the phrasing.)
4. **Extra line on Exercises with holds (box, 4-7-8):** you can shorten the holds or the whole pace; the hold should never feel like strain. Hold-free Patterns (coherent, sigh) are the gentler starting point. (S: Balban shorten-if-strained, Weil ratio-preserving speed-up; D: ordering.)
5. **Not while driving, operating machinery, cycling, or in or near water (bath, pool).** Eyes may be closed, attention is inward, and lightheadedness is possible. (D, no source; convention.)
6. **Sit or lie down comfortably.** (S: NHS, Weil.)
7. **Seek emergency care for chest pain, severe breathlessness or fainting.** This is not an exercise. (D.)

Do not build the third technique from Balban et al. (cyclic hyperventilation with retention: 30 deep inhales then a 15 s empty-lung hold, three rounds). It is the only protocol in the sources that combines rapid deep breathing with breath retention, it is out of the requested set, and the trial excluded the vulnerable groups above.

## Recommended default Session durations

Session length is a design choice; the evidence is: Balban used 5 minutes a day for 28 days for all breathwork groups; most lab studies of coherent breathing run for minutes (Critchley et al. used 1 minute per rate in Zaccaro's table); Weil caps 4-7-8 at four cycles to start. Sessions should end on a whole Cycle.

| Exercise | Cycle | Default | Allowed range | Basis |
|---|---|---|---|---|
| Box breathing | 16 s | 5 min = 19 Cycles (304 s) | 1 to 10 min | 5 min per Balban; range is a design choice |
| 4-7-8 | 19 s | 4 Cycles = 76 s | 4 to 8 Cycles (76 to 152 s) | Weil's first-month limit of four, extendable to eight; hold-heavy, so keep short |
| Coherent | 11 s | 5 min = 27 Cycles (297 s) | 1 to 20 min | 5 min per Balban for breathwork in general; longer practice is plausible but I did not verify a primary recommendation |
| Physiological sigh | 9 s | 5 min = 33 Cycles (297 s) | 1 to 10 min | 5 min per Balban cyclic sighing; a 1 minute quick option is a design choice and has no direct source |

Nearest whole Cycle is chosen, so the stated minutes are approximate; the UI can show "about 5 min".

## Gaps and open items

- **Not verified**: whether the "Navy SEAL" or other attributions of box breathing are accurate (no primary source checked); what timings are typical for the physiological sigh in popular sources; Lehrer's recommended duration for resonance breathing practice.
- **No guideline found** for contraindications of breath holds or pregnancy. The safety copy should be reviewed by someone with clinical training before release. This research does not replace that.
- **Weil's pages** were not directly fetchable (403). Re-check the wording at drweil.com before quoting it in the app.
- **Mechanism claims** (vagal tone, baroreflex) are proposed, not established, according to Gerritsen and Band and Zaccaro.
- Pages read in part: Balban 2023 and Zaccaro 2018 were read in full for the sections cited (the unread tail was references); Russo 2017 and Gerritsen and Band 2018 were read for the sections cited only.

## Sources

Primary studies and reviews

- Balban MY, Neri E, Kogon MM, et al. Brief structured respiration practices enhance mood and reduce physiological arousal. Cell Reports Medicine 2023;4(1):100895. https://doi.org/10.1016/j.xcrm.2022.100895 (PMC9873947)
- Marchant et al. Comparing the effects of square, 4-7-8, and 6 breaths-per-minute breathing conditions on heart rate variability, CO2 levels, and mood. Applied Psychophysiology and Biofeedback 2025;50(2):261-276. https://doi.org/10.1007/s10484-025-09688-z
- Lin et al. Breathing at a rate of 5.5 breaths per minute with equal inhalation-to-exhalation ratio increases heart rate variability. International Journal of Psychophysiology 2014. https://doi.org/10.1016/j.ijpsycho.2013.12.006
- Bernardi L, et al. Effect of rosary prayer and yoga mantras on autonomic cardiovascular rhythms: comparative study. BMJ 2001;323:1446. https://www.bmj.com/content/323/7327/1446
- Physiological Reports 2022. Effects of sleep deprivation and 4-7-8 breathing control on heart rate variability, blood pressure, blood glucose, and endothelial function in healthy young adults. https://doi.org/10.14814/phy2.15389
- Russo MA, Santarelli DM, O'Rourke D. The physiological effects of slow breathing in the healthy human. Breathe 2017;13(4):298-309. https://doi.org/10.1183/20734735.009817 (PMC5709795)
- Zaccaro A, et al. How breath-control can change your life: a systematic review on psycho-physiological correlates of slow breathing. Frontiers in Human Neuroscience 2018;12:353. https://doi.org/10.3389/fnhum.2018.00353 (PMC6137615)
- Lehrer PM, Gevirtz R. Heart rate variability biofeedback: how and why does it work? Frontiers in Psychology 2014;5:756. https://doi.org/10.3389/fpsyg.2014.00756 (PMC4104929). Hypothesis and theory article. Cited from its abstract only.
- Gerritsen RJS, Band GPH. Breath of life: the respiratory vagal stimulation model of contemplative activity. Frontiers in Human Neuroscience 2018;12:397. https://doi.org/10.3389/fnhum.2018.00397 (PMC6189422). Theory paper.
- Vlemincx E, et al. Why do you sigh? Sigh rate during induced stress and relief. Psychophysiology 2009. https://doi.org/10.1111/j.1469-8986.2009.00842.x
- Vlemincx E, et al. Sigh rate and respiratory variability during mental load and sustained attention. Psychophysiology 2011. https://doi.org/10.1111/j.1469-8986.2010.01043.x
- Vlemincx E, et al. A sigh following sustained attention and mental stress: effects on respiratory variability. Physiology and Behavior 2012. https://doi.org/10.1016/j.physbeh.2012.05.013
- Li P, et al. The peptidergic control circuit for sighing. Nature 2016. https://doi.org/10.1038/nature16964 (mouse study)

Clinical and originator guidance

- NCCIH. Relaxation techniques: what you need to know (updated June 2021). https://www.nccih.nih.gov/health/relaxation-techniques-what-you-need-to-know
- NHS. Breathing exercises for stress (reviewed 12 June 2026). https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/
- Weil A. 4-7-8 breath instructions. https://www.drweil.com/health-wellness/body-mind-spirit/stress-anxiety/three-breathing-exercises-and-techniques/ (not directly fetchable; read from search excerpts)
