# Commands

One `make` target per check, run from the repository root (also from a worktree). `xcodebuild` output goes through `xcbeautify --quiet`, so only warnings, errors and a few banner lines are printed, not the full build log. Read the last lines: `Build Succeeded` / `Test Succeeded` for the app, `Test run with N tests ... passed` for `swift test --quiet`, `0/N files require formatting.` for `make lint`.

| Command | What it does | Needs simulator |
|---|---|---|
| `make setup` | Once per clone: sets `core.hooksPath` to `.githooks` (idempotent, also from a linked worktree) installs the pinned `swiftformat` and `swiftlint` with `scripts/install-tools.sh`, and checks the tools below are installed, printing `brew bundle` when one is missing. | no |
| `make gen` | Generates `Breathnest.xcodeproj` from `project.yml` (the project is not committed). Every target below runs it first where needed. | no |
| `make build` | Builds the app into `build/` (DerivedData of this checkout). | yes, as a destination |
| `make test` | `make test-kit` then `make test-app`. | yes |
| `make test-kit` | `swift test` in `BreathnestKit/`. Seconds, no simulator. Use this in the red-green loop. | no |
| `make test-app` | `xcodebuild test` of the `Breathnest` scheme (app unit tests). | yes |
| `make coverage` | `scripts/coverage.sh`: the Kit tests with code coverage, then one line per file of `BreathnestKit/Sources` and the total (lines, missed lines, percent). A report: it fails on a failing test, never on a low number. How to read it: [testing](testing.md) (Coverage). | no |
| `make lint` | `scripts/check-tools.sh` (the installed `swiftformat` and `swiftlint` are the versions pinned in `tools.env`, else it prints the fix), `swiftformat --lint`, then `swiftlint lint --strict` (the Swift conventions of [iOS](ios.md), config in `.swiftlint.yml`), `scripts/check-workflows.sh` (every workflow sets `permissions: contents: read` and a `timeout-minutes` on each job) `scripts/check-docs.sh` (the docs only name files, `make` targets and skills that exist) and `scripts/check-architecture.sh` (the Kit imports only Foundation, Synchronization and Swift, no package is declared). Changes nothing, fails when a file needs formatting or a rule is broken. | no |
| `make format` | `swiftformat` in place. Fix a failing `make lint` with this. | no |
| `make run` | Builds, boots this checkout's simulator, installs and launches the app. | yes |
| `make screenshot` | Saves the simulator screen to `build/screenshot.png`. Open it with the Read tool to look at it. | yes |
| `make sim` | Prints the UDID of this checkout's simulator, creating it when missing. | no |

Compiler warnings are errors: `SWIFT_TREAT_WARNINGS_AS_ERRORS` in `project.yml` for the app and `.treatAllWarnings(as: .error)` in `BreathnestKit/Package.swift` for the Kit. Fix the warning, do not silence it.

Typical order: `make test-kit` while working, `make format lint` before a commit, `make build test lint` before the pull request, `make run screenshot` for any UI change.

## Hooks

- **PostToolUse** `.claude/hooks/format-swift.sh` formats every `.swift` file after an Edit or Write.
- **Stop** `.claude/hooks/stop-check.sh` runs `make lint test` when `App/`, `BreathnestKit/`, `project.yml`, `Makefile` or `.swiftformat` differ from `main`: commits since the merge-base with `origin/main` (`main` when there is no `origin/main`), plus uncommitted and untracked files. Committing after every slice does not skip it. When neither ref exists or has a merge-base with `HEAD` (a remote not named `origin`, a default branch with another name, a single-branch clone of another branch, unrelated or shallow history) only uncommitted and untracked files count. A normal clone and a linked worktree have `origin/main`, so they are covered. It runs on every stop while the branch differs from `main`, also on turns that changed nothing. When it fails, the output comes back to you: fix it, do not stop. It reports once and does not loop. Tested by `scripts/test-stop-check.sh`.

The safe commands above are allowlisted in `.claude/settings.json`, so they run without a prompt.

`.claude/settings.json` also has a `deny` list that no prompt can approve: reading `.env` files, private keys and certificates (`*.pem`, `*.p12`, `*.key`, `*.mobileprovision`), `~/.ssh`, `~/.aws` and `~/.config/gh`, and the shell commands `curl`, `wget`, `sudo`, anything piped into `sh`, `bash` or `zsh`, and the `gh` commands `gh pr merge`, `gh api`, `gh repo delete`, `gh issue delete` and `gh release delete`. Merging a pull request is the user's. `.claude/hooks/block-dangerous-git.sh` blocks the same `gh` commands too, also with options before the subcommand (`gh -R owner/repo pr merge`), which a `deny` rule does not match. `gh pr create`, `gh pr view` and the other read commands stay allowed. Use `gh` for GitHub (not `gh api`, which can write around the git hook) and `make` for everything else. The `Read` rules cover the Read tool, not `cat` in a shell command, so the allowlist stays narrow and a Bash command outside it still needs approval.

## CI

`.github/workflows/ci.yml` runs on every pull request, on a push to `main` and by hand. The checks are the same commands as above, so a green local `make gen build test lint` is what CI repeats. The ruleset requires the three jobs named in [git](git.md) (Enforcement).

| Job | Runner | Runs | When |
|---|---|---|---|
| `Changes` | ubuntu | `scripts/ci-scope.sh`: does the diff against the base touch `App/`, `BreathnestKit/` or `project.yml`? The base is the target branch of a pull request, or the previous tip of `main` on a push | always |
| `Script tests` | ubuntu | the tests of every script, `check-workflows.sh`, `check-docs.sh`, `check-architecture.sh` | always |
| `Kit tests` | ubuntu, in the `swift:6.2-noble` image pinned by digest | `scripts/coverage.sh`: `swift test` in `BreathnestKit/` with coverage, the table goes to the job summary | always |
| `Build, app tests, lint` | `macos-26` | `scripts/test-make-pipefail.sh`, then `make gen build test lint` and `make run screenshot` (the screenshot is uploaded as an artifact) | unless `Changes` says no Swift file changed |

- **A pull request or push that changes neither the Kit nor the app** (docs, scripts, workflows, `Makefile`, `tools.env`, `Brewfile`, lint configs) runs only the ubuntu jobs. Accepted risk: a change to only `Makefile`, a tool pin or a lint config is not built on macOS until the next Kit or app change; start the workflow by hand (`workflow_dispatch` runs everything) when it matters. The macOS job is skipped with a job-level `if`, not a workflow-level `paths:` filter: GitHub counts a skipped job as passed for a required check, but leaves the check of a filtered workflow pending. When `Changes` itself fails, the macOS job runs anyway.
- **Xcode** is `CI_XCODE_VERSION` in `tools.env` (26.6), selected from `/Applications/Xcode_26.6.app` on the `macos-26` image. The step fails and lists the installed Xcodes when the image no longer has it. The `Toolchain` step prints `xcodebuild -version`, `swift --version` and the Simulator runtimes.
- **Simulator runtime** is iOS 26.2, `RUNTIME` in `scripts/simulator.sh`. The image has 26.2, 26.4 and 26.5 installed, so the pin works there without a download.
- **Linux or macOS for the Kit:** the Kit imports only Foundation, Synchronization and Swift, so `swift test` passes on Linux. The `Build, app tests, lint` job runs the Kit tests again through `make test`, on macOS. The Swift version of the image is the `swift-tools-version` of `BreathnestKit/Package.swift`: bump the tag and the digest together.
- **Cost:** the repository is public, so hosted runners, macOS included, are free. On a private repository a macOS minute counts 10 times: one run of the macOS job took about 8 minutes (`make gen build test lint` 4, `make run screenshot` 3), see issue #65 for the monthly estimate.
- **Permissions and time:** every workflow sets `permissions: contents: read` and a `timeout-minutes` on each job, checked by `scripts/check-workflows.sh` (`make lint`).

## Tools

- **`Brewfile`**: `brew bundle` installs `xcodegen`, `xcbeautify`, `jq`, `gh` and `gitleaks` (the `pre-commit` hook scans the staged changes for secrets).
- **`swiftformat` and `swiftlint` are pinned** in `tools.env`, the one place their versions are written (CI reads the same file). Homebrew installs only the newest version, and another version formats and lints differently, so these two are not in the `Brewfile`. `scripts/install-tools.sh` (run by `make setup`, safe to run again) downloads the pinned release, checks its SHA256 from `tools.env` and links it into `.tools/bin` (git-ignored; the Makefile puts it first on `PATH`). The binaries are cached in `~/.cache/breathnest/tools`, shared by all worktrees. `make lint` starts with `scripts/check-tools.sh` and fails with this fix when the installed version differs.
- **Bump a pin** in its own pull request: change the version and the SHA256 of the release zip in `tools.env`, run `scripts/install-tools.sh` and `make format lint`. A new version may change the formatting of files nobody touched.
- `xcodegen` and `gitleaks` are only recorded in `tools.env`: the `Brewfile` installs the current versions and a difference is a warning, not an error.
- **Xcode** 26 or later, last run with Xcode 27.0. The Simulator runtime is pinned to iOS 26.2 whatever Xcode is installed, see [iOS](ios.md) (Supported Xcode and runtime).

`swiftformat` settings live in `.swiftformat`, `swiftlint` rules in `.swiftlint.yml`.
