# Rules and how they are enforced

Every working rule in `CLAUDE.md` and `docs/agents/*.md`, and what stops a break of it. Read this before you add a rule: if a machine can verify it, add the check in the same pull request and a row here. A rule with no check is a **process rule**, it holds because the `code-reviewer` agent and the user look for it.

Checks run in one of five places: a git hook (`.githooks/`, switched on by `make setup`), the Claude Code hooks and `deny` list (`.claude/`), `make lint` (also the `Build, app tests, lint` CI job), the `Script tests` CI job, or the pull request workflows (`pr-title.yml`, `pr-body.yml`). The ruleset requires `Script tests`, `Kit tests`, `Build, app tests, lint`, `check-title`, `check-body` and `critical-paths` before a merge ([git](git.md)).

The Swift conventions are checked by SwiftLint (`.swiftlint.yml`, run by `make lint` with `--strict`) and `scripts/check-architecture.sh`. The one rule a linter cannot see, a user-visible string literal in logic, stays a process rule.

## CLAUDE.md

| Rule | Enforced by |
|---|---|
| Start a change with the `start-task` skill | Process rule. A skill cannot start itself, so `CLAUDE.md` tells the agent. |
| `make setup` once per clone | The hooks in `.githooks/` do not run without it, so a commit on `main` is not refused on that clone. `make setup` is idempotent and checks the tools. Nothing forces a person to run it. |
| `make gen build test lint` must pass | CI job `Build, app tests, lint`. The Stop hook runs `make lint test` when Swift or project files differ from `main`. |
| The workflow skills are vendored in `.claude/skills/` | `scripts/check-docs.sh` (in `make lint`): every skill directory is named in [skills](skills.md) and every vendored skill in its table has a directory. Whether the copy equals upstream is a manual pull request. |
| Docs and ADRs the agent should read first | Process rule. |

## Workflow and definition of done ([workflow](workflow.md), [definition of done](definition-of-done.md))

| Rule | Enforced by |
|---|---|
| One ticket = one session = one worktree = one branch = one PR | Branch format: `scripts/check-branch-name.sh` in `check-title`. The rest is a process rule. |
| Do not start without acceptance criteria | Process rule. |
| Unrelated problems become new issues, nothing unrelated in the diff | Process rule, the `code-reviewer` checks it. |
| AFK agent stops at a question it cannot decide | Process rule. |
| Red-green slices, one commit per slice | Process rule. A test change next to a critical path change is required by `scripts/check-critical-paths.sh`. |
| `make build`, `make test`, `make lint` pass | CI job `Build, app tests, lint` and the Stop hook. |
| A UI change was run and looked at (screenshot) | Process rule. `scripts/pr-facts.sh` lists the files, `check-pr-body.sh` requires the Snapshots section to be non-empty. |
| Acceptance criteria are met one by one, named in the PR | Process rule. The PR body sections are checked by `scripts/check-pr-body.sh`, their content by the `code-reviewer`. |
| Domain terms follow `GLOSSARY.md`, no ADR contradicted | Process rule. |
| Review in a fresh session, the PR stays a draft until then | Process rule. GitHub cannot tell a fresh session from the one that wrote the code. |
| The user merges, the agent does not | `deny` list and `.claude/hooks/block-dangerous-git.sh` for `gh pr merge`. |
| Remove the worktree and its simulator after the merge | Process rule. |

## Git ([git](git.md))

Has its own Enforcement table, which is the source for these.

| Rule | Enforced by |
|---|---|
| Commit message is a Conventional Commit | `commit-msg` hook, `scripts/check-commit-msg.sh` |
| PR title is a Conventional Commit | CI `check-title` |
| Branch is `<type>/<issue>-<slug>` | `scripts/check-branch-name.sh`, CI `check-title`. Tested by `scripts/test-check-branch-name.sh`. |
| No commit or push on `main`, no force push, no `--no-verify`, no history rewrite, no secret in a commit | `pre-commit`, `pre-push`, the Claude `PreToolUse` hook, the repository ruleset, GitHub push protection |
| Squash merge, PR title as commit title | Repository setting |
| Merge `main` into the branch before the PR | Process rule. |
| `Closes #<issue>` ends the PR body, the six sections | `scripts/check-pr-body.sh` |
| Open as a draft until reviewed and green | Process rule. Green checks are required by the ruleset. |

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
| Code formatting | `make lint` (`swiftformat --lint`), the `format-swift.sh` hook formats after each edit |
| `Breathnest.xcodeproj` is generated, never committed | `.gitignore` |
| Use the glossary terms in type and test names | Process rule. |

## Skills, issues and domain docs ([skills](skills.md), [issue tracker](issue-tracker.md), [triage labels](triage-labels.md), [domain](domain.md))

| Rule | Enforced by |
|---|---|
| A skill named in the docs is in the skills table, a vendored skill has its directory | `scripts/check-docs.sh` |
| A vendored skill equals upstream at the commit in the table | Process rule, a manual pull request. Nothing warns when upstream moves on. |
| Every file, script, hook and `make` target the docs name exists | `scripts/check-docs.sh` |
| Use `gh`, not `gh api`, for GitHub | `deny` list in `.claude/settings.json` |
| Issues use the triage labels of [triage labels](triage-labels.md) | Process rule. |
| Read the glossary and ADRs of the area first, flag an ADR conflict | Process rule. |
