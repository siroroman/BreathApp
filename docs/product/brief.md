# Breathnest: product brief

Working name: **Breathnest**. A simple iPhone app for guided breathing exercises such as box breathing.

Input for `/wayfinder` and `/to-spec`. Visual references are in [references/](references/README.md).

## Why this project exists

Two goals, and when they conflict the first one wins:

1. **Build a reusable system for agentic development.** Success means the next app can be built with minimal human work: strong guardrails that carry over to other projects, and a skill for every repeated activity.
2. **Ship a high-quality app** that meets both the product requirements and the technical ones (tests, lint, architecture, accessibility).

## Screens

### Exercises

- **Quick Start** at the top repeats the last session in one tap: the same exercise, duration and settings.
- Below it, the **list of exercises**. Each row has:
  - an icon and the name,
  - the phase pattern (inhale, hold, exhale, rest), for example `4 · 7 · 8`,
  - a play button and an edit button.

### History

- At the top, a **weekly view** of the days with practice, similar to the Activity app on iPhone.
- Below it, the full **chronological list of sessions**.

## Tracer bullet

The first end-to-end slice: **exercise list → exercise detail → breathing session with an animated circle**.

## Decisions

| Topic | Decision |
|---|---|
| Platforms | iPhone in v1, plus an Apple Watch app designed in [watch-design.md](watch-design.md) and specified in [#22](https://github.com/siroroman/BreathApp/issues/22). The domain logic stays in a UI-free Swift package so both apps share it. |
| Minimum OS | iOS 26 |
| Business model | Free, no paywall, no StoreKit in v1 |
| Reusable system | Built in this repo first, extracted into a template or plugin after the tracer bullet |
| Visual design | Made with Claude Design after the spec is written |

## Assumptions to confirm during wayfinding

- Works fully offline, no account, all data stays on the device.
- UI in English, strings in a String Catalog so more languages can be added later.
- Built-in exercises: box, 4-7-8, coherent, physiological sigh (parameters and safety notes come from a research ticket).

## Out of scope for v1

- iPhone and Apple Watch sync, complications
- Paywall and StoreKit
- HealthKit (Mindful Minutes)
- Live Activities, widgets, reminders

## How the system is measured

Hypotheses for the observer, written down before the work starts:

- Share of tickets that land without the human editing code.
- Human interventions per pull request.
- Where the agent gets stuck. Expected: animation, haptics and the feel of the UI. Logic should go smoothly.
- Bugs found in manual QA that passed green tests.
- Reusable skills, hooks and guardrails created along the way, and how many of them carry over to the next app unchanged.
