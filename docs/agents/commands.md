# Commands

One `make` target per check, run from the repository root (also from a worktree). `xcodebuild` output goes through `xcbeautify --quiet`, so only warnings, errors and a few banner lines are printed, not the full build log. Read the last lines: `Build Succeeded` / `Test Succeeded` for the app, `Test run with N tests ... passed` for `swift test --quiet`, `0/N files require formatting.` for `make lint`.

| Command | What it does | Needs simulator |
|---|---|---|
| `make gen` | Generates `Breathnest.xcodeproj` from `project.yml` (the project is not committed). Every target below runs it first where needed. | no |
| `make build` | Builds the app into `build/` (DerivedData of this checkout). | yes, as a destination |
| `make test` | `make test-kit` then `make test-app`. | yes |
| `make test-kit` | `swift test` in `BreathnestKit/`. Seconds, no simulator. Use this in the red-green loop. | no |
| `make test-app` | `xcodebuild test` of the `Breathnest` scheme (app unit tests). | yes |
| `make lint` | `swiftformat --lint`, changes nothing, fails when a file needs formatting. | no |
| `make format` | `swiftformat` in place. Fix a failing `make lint` with this. | no |
| `make run` | Builds, boots this checkout's simulator, installs and launches the app. | yes |
| `make screenshot` | Saves the simulator screen to `build/screenshot.png`. Open it with the Read tool to look at it. | yes |
| `make sim` | Prints the UDID of this checkout's simulator, creating it when missing. | no |

Typical order: `make test-kit` while working, `make format lint` before a commit, `make build test lint` before the pull request, `make run screenshot` for any UI change.

## Hooks

- **PostToolUse** `.claude/hooks/format-swift.sh` formats every `.swift` file after an Edit or Write.
- **Stop** `.claude/hooks/stop-check.sh` runs `make lint test` when `App/`, `BreathnestKit/`, `project.yml`, `Makefile` or `.swiftformat` have uncommitted changes. When it fails, the output comes back to you: fix it, do not stop. It reports once and does not loop.

The safe commands above are allowlisted in `.claude/settings.json`, so they run without a prompt.

## Tools

`xcodegen`, `xcbeautify`, `swiftformat`, `jq` and Xcode 26 or later. Install with `brew install xcodegen xcbeautify swiftformat jq`. `swiftformat` settings live in `.swiftformat`.
