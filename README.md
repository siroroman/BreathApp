# Breathnest

A guided breathing app for iPhone. Pick an Exercise, choose how long to practise and follow an animated circle through a Session.

The repository folder is called BreathApp; the app and the Xcode project are called Breathnest.

## Requirements

- macOS with Xcode 26 or later (the app targets iOS 26.0, Swift 6)
- [Homebrew](https://brew.sh), for the tools in the `Brewfile`: `xcodegen`, `xcbeautify`, `jq`, `gh` and `gitleaks`

## Get started

```bash
brew bundle   # install the tools
make setup    # once per clone: git hooks, pinned swiftformat and swiftlint
make gen build test lint
make run      # build, boot the simulator, install and launch the app
```

`Breathnest.xcodeproj` is generated from `project.yml` and is not committed. To sign the app, put `DEVELOPMENT_TEAM=XXXXXXXXXX` in a git-ignored `local.env`.

Every command, with what it needs and what it prints, is in [docs/agents/commands.md](docs/agents/commands.md).

## Repository layout

| Path | What is in it |
|---|---|
| `App/` | The SwiftUI app, its unit tests and its UI tests |
| `BreathnestKit/` | A UI-free Swift package with the domain logic (Session engine, Exercises, feel logic), tested with `swift test` in seconds ([ADR 0001](docs/adr/0001-domain-logic-in-a-ui-free-swift-package.md)) |
| `docs/` | Decisions (`adr/`), product and design notes (`product/`), working rules (`agents/`) |
| `scripts/` | Checks run by `make lint` and CI, and helper scripts |
| `prototypes/` | Throwaway prototypes |

## Read more

- [GLOSSARY.md](GLOSSARY.md): the words used in the code and the docs (Exercise, Pattern, Phase, Cycle, Session)
- [docs/product/brief.md](docs/product/brief.md): what the app is for
- [docs/adr/](docs/adr/): architecture decisions
- [CLAUDE.md](CLAUDE.md): the entry point for coding agents working in this repo

## Contributing

Work follows GitHub flow with Conventional Commits, checked by the `commit-msg` hook. Run `make setup` once per clone to turn the hooks on. Branch, commit and pull request rules: [docs/agents/git.md](docs/agents/git.md).
