# Breathnest

A guided breathing app for iPhone, and an experiment in building software with AI agents.

You pick an Exercise (box breathing, 4-7-8, coherent breathing, physiological sigh or your own), choose how long to practise and follow an animated circle through a Session, with optional haptics and sound cues for each Phase.

The repository folder is called BreathApp; the app and the Xcode project are called Breathnest.

## Why this project exists

Two goals. When they conflict, the first wins.

1. **Build a reusable system for agentic development.** The next app should need minimal human work: guardrails that carry over to other projects and a skill for every repeated activity.
2. **Ship a high-quality app** that meets the product requirements and the technical ones (tests, lint, architecture, accessibility).

The app is deliberately small, so the process is what is being tested. The full brief is in [docs/product/brief.md](docs/product/brief.md).

## The app

- **Exercises**: a list of built-in Exercises plus your own Custom exercises (name, icon, description and a four-step pattern in whole seconds).
- **Quick Start**: repeats the last Session in one tap.
- **Session**: a short Lead-in countdown, then an animated torus and progress ring that follow the Breath level through each Phase. The Session length is a whole number of Cycles, the count closest to the chosen duration.
- **Haptics and sound**: Core Haptics follow the breath, and a chosen sound marks the start and end of a Session.
- **Offline and private**: no account, no network, all data stays on the device.

Planned, tracked as issues: the Stats tab (weekly view and Log), Reminders, and an Apple Watch app. Designs are in [docs/product/phone-design.md](docs/product/phone-design.md) and [docs/product/watch-design.md](docs/product/watch-design.md). The words used in code and docs (Exercise, Pattern, Phase, Cycle, Session) are defined in [GLOSSARY.md](GLOSSARY.md).

## Architecture

MVVM over a UI-free Swift package. Dependencies point one way and the domain package depends on nothing.

```text
Breathnest (iPhone app)   composition root, adapters, SwiftUI views, ViewModels
        │
        ▼
BreathnestKit             domain logic, no UI, imports only Foundation,
                          Synchronization and Swift
BreathnestKitTesting      fakes of the seams, used by tests and previews only
```

- **Model** is `BreathnestKit`: the Session engine, Exercises, Breath level, Haptic plan, Sound plan and the saved-data types. `swift test` covers it in seconds with no simulator.
- **ViewModel** is an `@MainActor` `@Observable` class per screen. It holds values, not app text; views build text from the String Catalog.
- **Seams**: protocols for the ticker, haptics, sound, screen awake, scene phase and storage live in the Kit. The app owns the adapters (Core Haptics, `AVFoundation`, `UserDefaults`). Dependencies come in through initialisers from one composition root, so tests and previews use fakes.
- **Persistence**: small settings in `UserDefaults`; the Log, custom Exercises and Reminders in versioned JSON files. Data that cannot be read is set aside, never deleted.

Decisions are written down as ADRs: [0001 domain logic in a UI-free package](docs/adr/0001-domain-logic-in-a-ui-free-swift-package.md), [0002 app architecture](docs/adr/0002-app-architecture.md), [0003 persistence](docs/adr/0003-persistence.md).

## Tech stack

| Area | Choice |
|---|---|
| Language | Swift 6, strict concurrency, compiler warnings are errors |
| UI | SwiftUI, Observation (`@Observable`), String Catalog for text |
| Platform | iOS 26.0 and later, Xcode 26 or later |
| System frameworks | Core Haptics, AVFoundation, UserNotifications |
| Project | `project.yml` with XcodeGen; the `.xcodeproj` is generated, not committed |
| Tests | Swift Testing and `swift test` for the Kit, `xcodebuild test` for the app, UI tests with accessibility audits |
| Quality | SwiftFormat and SwiftLint (versions pinned in `tools.env`), an 80% coverage floor for the Kit, a String Catalog check, an architecture check |
| CI | GitHub Actions: Kit tests on Linux, build, app tests and lint on macOS, PR title, body and review checks |
| Tooling | `make` targets, Homebrew `Brewfile`, git hooks, gitleaks |

## Agentic development experiment

The whole app is built by Claude Code agents working to written rules, with a human setting direction, deciding open questions, reviewing and merging. The repo is the experiment: the process lives in files, not in anyone's head.

**How a change moves**

1. Work starts from a GitHub issue with acceptance criteria. The `start-task` skill finds or creates the issue, names the branch and offers a plan.
2. One ticket is one session, one worktree, one branch and one pull request.
3. The agent works in red-green slices (`tdd` skill), commits each slice and opens a draft PR whose body has fixed sections: tests, snapshots, merge danger, critical paths and reviewer notes.
4. A separate `code-reviewer` agent reviews the PR in a fresh context. It reports findings and never fixes them. Only the human marks a PR ready and merges.

**Roles**

| Agent | Job |
|---|---|
| `implementer` | Implements one `ready-for-agent` ticket alone in a worktree and stops at a draft PR |
| `code-reviewer` | Reviews a branch against the repo standards and the ticket's acceptance criteria |
| `ui-verifier` | Runs the app in the simulator and compares screenshots with the design values |
| `researcher` | Answers a research ticket from primary sources and writes a note in `docs/product/research/` |

Skills in [`.claude/skills/`](.claude/skills/) cover the repeated activities: starting a task, TDD, writing PRs, code review, domain modelling, SwiftUI and Swift concurrency.

**Guardrails**

Rules are only trusted when a machine checks them. [docs/agents/rules-enforcement.md](docs/agents/rules-enforcement.md) lists every rule and what enforces it, and marks the rest as process rules that the reviewer and the human look for.

- Git hooks: Conventional Commits, no commits on `main`, secret scan, lint and Kit tests before a push.
- Claude Code hooks: format Swift after every edit, run `make lint test` when the agent stops, and block dangerous git and `gh` commands.
- CI: required checks for scripts, Kit tests, build and lint, PR title, PR body and critical paths.
- Size budgets for `CLAUDE.md` and for skill and agent descriptions, so context stays small.

**Self-improvement loop**

Outside the repo, an independent observer agent records how the sessions went into a notes vault and proposes process improvements. A daily improver agent turns accepted proposals into a draft PR that touches only the process files (`CLAUDE.md`, `docs/agents/`, hooks, CI, scripts). A human still reviews and merges every one.

**Status**

Started on 2026-10-22; about 95 merged pull requests so far. The reusable system is meant to be extracted into a template or plugin once the tracer bullet is done.

## Get started

You need macOS with Xcode 26 or later and [Homebrew](https://brew.sh).

```bash
brew bundle   # xcodegen, xcbeautify, jq, gh, gitleaks
make setup    # once per clone: git hooks, pinned swiftformat and swiftlint
make gen build test lint
make run      # build, boot the simulator, install and launch the app
```

To sign the app, put `DEVELOPMENT_TEAM=XXXXXXXXXX` in a git-ignored `local.env`. Every command is described in [docs/agents/commands.md](docs/agents/commands.md).

## Repository layout

| Path | What is in it |
|---|---|
| `App/` | The SwiftUI app, its unit tests and UI tests |
| `BreathnestKit/` | The UI-free domain package and its test fakes |
| `docs/` | ADRs (`adr/`), product and design notes (`product/`), working rules for agents (`agents/`) |
| `scripts/` | Checks run by `make lint` and CI |
| `.claude/` | Agents, skills and hooks for Claude Code |
| `.github/` | Workflows and the pull request template |
| `prototypes/` | Throwaway prototypes |

[CLAUDE.md](CLAUDE.md) is the entry point for agents working in the repo.
