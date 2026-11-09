# Rules and how they are enforced

Every working rule in `CLAUDE.md` and `docs/agents/*.md`, and what stops a break of it. Read this before you add a rule: if a machine can verify it, add the check in the same pull request and a row here. A rule with no check is a **process rule**, it holds because the `code-reviewer` agent and the user look for it.

Checks run in one of five places: a git hook (`.githooks/`, switched on by `make setup`), the Claude Code hooks and `deny` list (`.claude/`), `make lint` (also the `Build, app tests, lint` CI job), the `Script tests` CI job, or the pull request workflows (`pr-title.yml`, `pr-body.yml`, `pr-review.yml`). The ruleset requires `Script tests`, `Kit tests`, `Build, app tests, lint`, `check-title`, `check-body` and `critical-paths` before a merge ([git](git.md)).

The Swift conventions are checked by SwiftLint (`.swiftlint.yml`, run by `make lint` with `--strict`) and `scripts/check-architecture.sh`. The one rule a linter cannot see, a user-visible string literal in logic, stays a process rule.

## CLAUDE.md

| Rule | Enforced by |
|---|---|
| Start a change with the `start-task` skill | Process rule. A skill cannot start itself, so `CLAUDE.md` tells the agent. |
| `make setup` once per clone | The hooks in `.githooks/` do not run without it, so a commit on `main` is not refused on that clone. `make setup` is idempotent and checks the tools. Nothing forces a person to run it. |
| `make gen build test lint` must pass | CI job `Build, app tests, lint`. The Stop hook runs `make lint test` when Swift or project files differ from `main`. |
| The workflow skills are vendored in `.claude/skills/` | `scripts/check-docs.sh` (in `make lint`): every skill directory is named in [skills](skills.md) and every vendored skill in its table has a directory. Whether the copy equals upstream is a manual pull request. |
| Docs and ADRs the agent should read first | Process rule. |
| `CLAUDE.md` stays under 3000 bytes, every skill and agent `description:` under 700 characters | `scripts/check-context-size.sh` (in `make lint` and the `Script tests` job), tested by `scripts/test-check-context-size.sh`. |

## Token use ([tokens](tokens.md))

| Rule | Enforced by |
|---|---|
| `CLAUDE.md` and the skill and agent descriptions stay within their size budget | `scripts/check-context-size.sh`, see the `CLAUDE.md` table. |
| Read-only agents run on a smaller model, the reviewer on `opus` | Process rule. The `model:` line of the agent is the record, the `code-reviewer` reads a change to it. |
| Search before reading, narrow tests first, wait inside one command, stop after two failed attempts, subagents for self-contained searches, results first in replies | Process rule. Nothing can see how a session read a file. |

## Testing ([testing](testing.md))

| Rule | Enforced by |
|---|---|
| Every string in the String Catalog has a translator comment, nothing is `needs_review`, every required language is translated, every plural category is present | `scripts/check-catalogs.sh` (in `make lint` and `make test`, job `Script tests`), tested by `scripts/test-check-catalogs.sh`. The required languages are `CATALOG_REQUIRED_LANGUAGES`, default `en` until #34. |
| A user-facing string is in the catalog and not built in code | Process rule. The script reads the catalog, nothing sees a string that never got in. |
| Every screen has a UI smoke test and a passing accessibility audit, identifiers are `<screen>.<element>` | Process rule, the `code-reviewer` checks it. `make test-ui` runs the tests by hand, CI and the Stop hook do not run it until #35. |

## Workflow and definition of done ([workflow](workflow.md), [definition of done](definition-of-done.md))

| Rule | Enforced by |
|---|---|
| One ticket = one session = one worktree = one branch = one PR | Branch format: `scripts/check-branch-name.sh` in `check-title`. The rest is a process rule. |
| Do not start without acceptance criteria | Process rule. |
| Unrelated problems become new issues, nothing unrelated in the diff | Process rule, the `code-reviewer` checks it. |
| AFK agent stops at a question it cannot decide | Process rule. |
| Red-green slices, one commit per slice | Process rule. A test change next to a critical path change is required by `scripts/check-critical-paths.sh`. |
| `make lint` is clean before a pull request is opened | `pre-push` hook runs `make lint` before the push that precedes `gh pr create`, tested by `scripts/test-githooks.sh`. Reading the last line `0/N files require formatting.` stays a process rule ([pull requests](pull-requests.md)). |
| `make build`, `make test`, `make lint` pass | CI job `Build, app tests, lint` and the Stop hook. |
| Kit line coverage stays at or above 80%, per file and in total | CI job `Kit tests` (`scripts/coverage.sh` hands the table to `scripts/check-coverage.sh`, [testing](testing.md) Coverage), also `make coverage`. Tested by `scripts/test-check-coverage.sh` in `Script tests`. 100% still does not prove the behaviour is checked: a process rule for the `code-reviewer`. The App target is not measured. |
| The simulator is used only when [Simulator use](workflow.md#simulator-use) allows it (no boot in the red-green loop, one screenshot per changed screen, `ui-verifier` once per PR) | Process rule, the `code-reviewer` checks the PR for a second shot of one screen. Nothing can see a boot. CI keeps `make run screenshot` on every Swift change, by decision. |
| A UI change was run and looked at (screenshot) | Process rule. `scripts/pr-facts.sh` lists the files, `check-pr-body.sh` requires the Snapshots section to be non-empty. |
| Acceptance criteria are met one by one, named in the PR | Process rule. The PR body sections are checked by `scripts/check-pr-body.sh`, their content by the `code-reviewer`. |
| Domain terms follow `GLOSSARY.md`, no ADR contradicted | Process rule. |
| A session stays under 15% of the context window: save the handoff on the ticket, `/clear`, restart from the ticket ([workflow](workflow.md), Context limit) | Partly checked: the PostToolUse hook `.claude/hooks/context-check.sh` (tested by `scripts/test-context-check.sh`) tells the agent at 15%. Saving stays a process rule and a hook cannot run `/clear`. In a subagent or with `BREATHNEST_AFK=1` the message ends the run instead; `scripts/afk-run.sh` (tested by `scripts/test-afk-run.sh`) restarts an `implementer` from the ticket, 3 rounds at most. Not checked: whether `claude -p --agent implementer` loads the project hooks unattended, and whether a caller really starts the next agent. The hook measures the growth of the session transcript since its first assistant message, with a window from `BREATHNEST_CONTEXT_WINDOW`. For a subagent it measures the subagent's own transcript (found by `agent_id` in the hook input), tested with a large parent; with no such file it stays silent. |
| Review in a fresh session, the PR stays a draft until then | Partly checked: `scripts/check-review.sh` (job `review-posted` of `pr-review.yml`, tested by `scripts/test-check-review.sh`) fails a PR that is not a draft without a `code-reviewer` review of a commit of the PR (one round, a push after it needs no second review). That the session was fresh, and that the commits after the review were reviewed, stay process rules, GitHub cannot tell a fresh session from the one that wrote the code. |
| The user merges, the agent does not | `deny` list and `.claude/hooks/block-dangerous-git.sh` for `gh pr merge`. |
| Remove the worktree and its simulator after the merge | Process rule. |

## Git ([git](git.md))

Has its own Enforcement table, which is the source for these.

| Rule | Enforced by |
|---|---|
| Commit message is a Conventional Commit | `commit-msg` hook, `scripts/check-commit-msg.sh` |
| PR title is a Conventional Commit (it is the merge commit title on `main`) | CI `check-title` |
| Branch is `<type>/<issue>-<slug>` | `scripts/check-branch-name.sh`, CI `check-title`. Tested by `scripts/test-check-branch-name.sh`. |
| No commit or push on `main`, no force push, no `--no-verify`, no history rewrite, no secret in a commit | `pre-commit`, `pre-push`, the Claude `PreToolUse` hook, the repository ruleset, GitHub push protection |
| A scope in a commit header or PR title is in the list of [git](git.md) | Process rule until #145 adds the check to `scripts/check-commit-msg.sh` with a test for a wrong scope. |
| Merge commit only, PR title as merge commit title | Repository setting |
| Merge `main` into the branch before the PR | Process rule. |
| A PR branch that fell behind `main` is not merged as it is | Repository ruleset: **Require branches to be up to date before merging**. The user presses **Update branch**, the checks run again. A setting, not a file; see [git](git.md) (Keeping a PR branch up to date). |
| `Closes #<issue>` ends the PR body, the six sections | `scripts/check-pr-body.sh` |
| Open as a draft until reviewed and green | Green checks are required by the ruleset. The review part is checked by `review-posted`, see the review row above: it fails a PR that is not a draft without a `code-reviewer` review of a commit of the PR. Opening as a draft stays a process rule. |

## Pull requests, critical paths, guardrail paths ([pull requests](pull-requests.md), [critical paths](critical-paths.md), [guardrail paths](guardrail-paths.md))

| Rule | Enforced by |
|---|---|
| The six sections, in order, none empty | `scripts/check-pr-body.sh` |
| Critical path source changed without a test or a warning | `scripts/check-critical-paths.sh` |
| Guardrail file changed without a **Guardrails touched:** line | `scripts/check-guardrail-paths.sh` |
| A new module adds its critical path glob, a new guardrail adds its glob | Process rule. A glob that is missing hides a change, nothing sees what is not listed. |
| What the Tests, Snapshots and Reviewer notes say is true | The `code-reviewer` agent. |
| Changing a check so it passes is never the fix | Guardrail paths: the change needs the **Guardrails touched:** line and a reviewer reads it. |
| Every workflow sets `permissions: contents: read` and a `timeout-minutes` on each job | `scripts/check-workflows.sh` (in `make lint` and the `Script tests` job), tested by `scripts/test-check-workflows.sh` |

## Testing and iOS ([testing](testing.md), [ios](ios.md))

| Rule | Enforced by |
|---|---|
| Time from an injected `Clock`: no `Date()`, `ContinuousClock()`, `Task.sleep` in logic | SwiftLint custom rule `time_from_injected_clock` in the Kit, in `make lint`, tested by `scripts/test-swiftlint-rules.sh` |
| No `DispatchQueue`, Combine, `ObservableObject`, completion handlers | SwiftLint custom rules `no_dispatch_queue`, `no_combine`, `no_observable_object`, `no_completion_handler` |
| No force unwrap or `try!` outside tests | SwiftLint `force_unwrapping` and `force_try`, tests are not linted |
| No user-visible string literals in logic | Process rule. A regex cannot tell a user string from an identifier or a catalog key, so a rule would cry wolf. |
| The Kit imports only the standard library and Foundation, no third-party dependency without an ADR | `scripts/check-architecture.sh` (in `make lint` and the `Script tests` job), tested by `scripts/test-check-architecture.sh` |
| Swift Testing, not XCTest; tests mirror the source files | Process rule, `scripts/pr-facts.sh` prints the source files without a mirrored test.  |
| Compiler warnings are errors | `project.yml` and `BreathnestKit/Package.swift`, so `make build` and `make test-kit` fail |
| `swiftformat` and `swiftlint` are the versions pinned in `tools.env` | `scripts/check-tools.sh` (first step of `make lint`), tested by `scripts/test-check-tools.sh`. CI installs the same versions with `scripts/install-tools.sh`. |
| Code formatting | `make lint` (`swiftformat --lint`), the `format-swift.sh` hook formats after each edit |
| `Breathnest.xcodeproj` is generated, never committed | `.gitignore` |
| Use the glossary terms in type and test names | Process rule. |
| A screen with derived values, a side effect or shared state has a `@MainActor` `@Observable` `<Screen>ViewModel`; a view holds no I/O or logic ([ADR 0002](../adr/0002-app-architecture.md)) | Process rule, the `code-reviewer` agent. |
| A ViewModel imports no view type and holds no text the app writes (text the user typed passes through as data) | Process rule, the `code-reviewer` agent. A regex cannot tell app text from user data. |
| The protocols of the seams are in the Kit, the adapters in the app, dependencies come through `init` from one composition root | Process rule, the `code-reviewer` agent. |
| No `static let shared` or `static var shared` in `App/` and `BreathnestUI/` | Process rule. A check in `scripts/check-architecture.sh`, with a test, is a consequence of ADR 0002 and lands with the `BreathnestUI` setup. |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` is MainActor for the app target and `BreathnestUI` | Process rule. The check follows with the `BreathnestUI` setup: `project.yml` for the app, `Package.swift` for the package. |
| `BreathnestUI` imports only SwiftUI, Observation, Foundation, Synchronization, Swift and the Kit | Process rule until `scripts/check-architecture.sh` knows the package. |
| A change of a stored shape (rename, removal, new meaning of a field) raises the document `version` and adds a migration and a fixture of the old JSON ([ADR 0003](../adr/0003-persistence.md)) | Process rule, the `code-reviewer` agent. A test change next to a stored type is required by `scripts/check-critical-paths.sh`, but only a reader can tell whether the shape changed. |
| The apps reach `UserDefaults` and the data files only through `DocumentStore`, and stored-data code reads no file timestamp, size or free space (a privacy manifest category) | Process rule, the `code-reviewer` agent. A check in `scripts/check-architecture.sh`, with a test, is a possible follow-up ticket. |
| The Session ticker `Task` is cancelled on Pause, Stop, completion and `deinit`; one root navigation model on the iPhone | Process rule, the `code-reviewer` agent, the Session ViewModel tests once they exist. |

## Skills, issues and domain docs ([skills](skills.md), [issue tracker](issue-tracker.md), [triage labels](triage-labels.md), [domain](domain.md))

| Rule | Enforced by |
|---|---|
| A skill named in the docs is in the skills table, a vendored skill has its directory | `scripts/check-docs.sh` |
| A vendored skill equals upstream at the commit in the table | Process rule, a manual pull request. Nothing warns when upstream moves on. |
| Every file, script, hook and `make` target the docs name exists | `scripts/check-docs.sh` |
| Use `gh`, not `gh api`, for GitHub | `deny` list in `.claude/settings.json` |
| Issues use the triage labels of [triage labels](triage-labels.md) | Process rule. |
| Read the glossary and ADRs of the area first, flag an ADR conflict | Process rule. |
