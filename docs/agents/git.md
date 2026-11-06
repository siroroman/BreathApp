# Git conventions

GitHub flow with Conventional Commits. Read this before creating a branch, a commit or a pull request.

## Flow

- `main` is always releasable and only changes through a squash-merged pull request. Never commit to `main` directly.
- One ticket = one branch = one pull request. Work in a worktree per ticket when sessions run in parallel.
- Branches are short-lived and branch from the latest `main`. Merge `main` into the branch (or rebase it) before opening the PR when `main` has moved.
- Delete the branch after the merge.

## Branches

`<type>/<issue-number>-<slug>`, using the commit types below. Omit the number when no issue exists.

- `feat/12-box-breathing-timer`
- `fix/31-timer-drift-in-background`
- `docs/git-conventions`

## Commits

```
<type>(<scope>)<!>: <description>

<body, optional>

<footer, optional>
```

- **Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- **Scope:** optional, lowercase kebab-case, names a module in the ubiquitous language of `GLOSSARY.md` (the list of scopes follows the module map once it exists).
- **Description:** imperative mood, no trailing period. The whole header is at most 72 characters.
- **Body:** explains why, not what. Separated from the header by a blank line.
- **Breaking change:** `!` after the type or scope, or a `BREAKING CHANGE:` footer.
- **Issue links:** `Refs #12` in commits, `Closes #12` in the PR body.
- **Trailers:** keep the `Co-Authored-By:` line the tooling adds.
- Commit in small steps along the red-green slices of `/tdd`. Each commit builds and passes tests.

## Pull requests

- Title is a valid Conventional Commit header. Squash merge makes it the commit message on `main`.
- Body follows [pull requests](pull-requests.md), which extends the `pr` skill with the tests, snapshots, critical paths and reviewer notes, and ends with `Closes #<issue>`.
- Open as a draft until the `code-reviewer` agent has reviewed the PR in a fresh session and the checks are green. Its review ends with a marker naming the commit it reviewed, and CI fails a PR that is not a draft without a review of a commit of the PR. One review round: fix the findings and push, a push after the review needs no second one.
- Merge with **squash**. Linear history on `main`.

## Rules for agents

- Push only your own feature branch: `git push -u origin <branch>`. Never force-push and never push `main`.
- Never bypass the hooks with `--no-verify` or `-n`, and never override `core.hooksPath` (`git -c core.hooksPath=...`). If a message is rejected, fix the message. If a commit on `main` is refused, `git switch -c <branch>` and commit there.
- Never rewrite history that is already pushed.
- Do not merge a PR unless the user asked for it. `gh pr merge`, `gh repo delete`, `gh issue delete` and `gh release delete` are blocked; `gh pr create` and `gh pr view` are not.

## Enforcement

| Rule | Where it is checked |
|---|---|
| Commit message format | `commit-msg` hook, `.githooks/commit-msg` calling `scripts/check-commit-msg.sh` |
| PR title format | CI, `.github/workflows/pr-title.yml` calling `scripts/check-commit-msg.sh -` on `$PR_TITLE` |
| PR body: the six sections in order, none empty, `Closes #<issue>` last | CI, `.github/workflows/pr-body.yml` calling `scripts/check-pr-body.sh`, tested by `scripts/test-check-pr-body.sh`. `.github/pull_request_template.md` starts a PR with the sections. Dependabot PRs are skipped. Whether the content is true is checked by the `code-reviewer` agent ([pull requests](pull-requests.md)) |
| A PR that is not a draft has no `code-reviewer` review of a commit of the PR | CI, the `review-posted` job of `.github/workflows/pr-review.yml` calling `scripts/check-review.sh`, tested by `scripts/test-check-review.sh`. It runs on `opened`, `reopened`, `synchronize`, `ready_for_review` and `converted_to_draft`, not when a review is posted, so the agent reviews while the PR is a draft and the run after `ready_for_review` finds the review (a run that went red before the review is run again from the Actions tab). The check looks at the last line of each review for the marker `<!-- code-reviewer: <sha> -->` that the `code-reviewer` agent ends its review with (a marker quoted in the text does not count), and passes when that commit is the head or one of its ancestors and not a commit of the base branch (one review round, fixes pushed after it need no second review). It proves a review was posted for a commit of the PR, not that the session was fresh and not that the commits after the review were reviewed: GitHub cannot tell, and author and reviewer are the same GitHub user. Only a review by the owner, a member or a collaborator counts (the repo is public, anyone can comment on a PR), and a dismissed or pending one does not. Draft PRs and PRs opened by Dependabot pass. The job is required only once `review-posted` is added to the ruleset by the user |
| Critical path source changed with no test change | CI, `.github/workflows/pr-body.yml` calling `scripts/check-critical-paths.sh`, tested by `scripts/test-check-critical-paths.sh`. A PR body that starts with `> **Warning:**` passes ([critical paths](critical-paths.md)) |
| Guardrail file changed (hooks, CI, check scripts, lint config, registries) with no `**Guardrails touched:**` line in the PR body | CI, the `check-body` job of `.github/workflows/pr-body.yml` calling `scripts/check-guardrail-paths.sh`, tested by `scripts/test-check-guardrail-paths.sh`. The globs come from the registry on the base and on the branch, so dropping a glob does not hide its own change. Dependabot PRs are skipped ([guardrail paths](guardrail-paths.md)) |
| No commit on `main` or `master`, no push to them from this machine | `pre-commit` and `pre-push` hooks, `.githooks/pre-commit` and `.githooks/pre-push`, tested by `scripts/test-githooks.sh` in the `Script tests` job. The message says to `git switch -c` a branch. A detached HEAD (rebase) passes. Linked worktrees use the hooks of their own checkout |
| A secret (key, token) in the staged changes | `pre-commit` hook, `.githooks/pre-commit` running `gitleaks git --staged` after the branch check, tested by `scripts/test-githooks.sh` with a pinned `gitleaks` installed in the `Script tests` job. The finding is printed with the value redacted. A missing `gitleaks` refuses the commit (`brew install gitleaks`, `make setup` checks it). It scans what is staged, not the history, with the default rules. A false positive goes to a `.gitleaksignore` line with the fingerprint from the output. GitHub push protection stays the second layer |
| Branch name `<type>/<issue>-<slug>` | CI, the `check-title` job of `.github/workflows/pr-title.yml` calling `scripts/check-branch-name.sh` on the head branch, tested by `scripts/test-check-branch-name.sh`. The number is optional, the type is one of the commit types, the slug is lowercase words joined by hyphens. `dependabot/*` passes. A `research/` or `prototype/` branch is refused, use `docs` or `feat` |
| A workflow without `permissions: contents: read` or a job without `timeout-minutes` | `make lint` and the `Script tests` job calling `scripts/check-workflows.sh`, tested by `scripts/test-check-workflows.sh` |
| The docs name a file, script, hook, `make` target or skill that does not exist | `make lint` and the `Script tests` job calling `scripts/check-docs.sh`, tested by `scripts/test-check-docs.sh`. Which rule is checked by what: [rules enforcement](rules-enforcement.md) |
| Kit tests before a push | `pre-push` hook, `.githooks/pre-push` running `make test-kit`. Skipped when the push only deletes a branch. A push of `main` is refused before the tests run |
| A stuck or over-privileged workflow job | every workflow in `.github/workflows/` sets `permissions: contents: read` and a `timeout-minutes` on each job (5 for the ubuntu jobs, 10 for `Kit tests`, 30 for `Build, app tests, lint`; the slowest run was about 9 minutes). `scripts/check-workflows.sh` checks that both are there, not the values (see the `check-workflows.sh` row) |
| A pull request breaks the Kit tests, the build, the app tests or `make lint` | CI, `.github/workflows/ci.yml`: `Kit tests` (`swift test` on ubuntu in a pinned Swift image, always), `Build, app tests, lint` (`make gen build test lint` on `macos-26`, Xcode `CI_XCODE_VERSION` of `tools.env`, Simulator iOS 26.2) and `Script tests`. The jobs are described in [commands](commands.md) (CI) |
| A pull request or push that changes neither the Kit nor the app waits for a macOS runner | `Changes` job calling `scripts/ci-scope.sh`, tested by `scripts/test-ci-scope.sh`: `Build, app tests, lint` is skipped, with a job-level `if`, when no file of `App/`, `BreathnestKit/` or `project.yml` changed (on a push, against the previous tip of `main`). A skipped job counts as passed for the required check. It runs anyway when `Changes` fails |
| A failed `xcodebuild` or app test fails `make` | `SHELL := /bin/bash -o pipefail` in the `Makefile` (macOS ships Make 3.81, which ignores `.SHELLFLAGS`), tested by `scripts/test-make-pipefail.sh` in the `Build, app tests, lint` job on macOS |
| Squash merge, PR title as commit title | repository setting: only squash merge is allowed, the PR title is the commit title, branches are deleted after the merge |
| No direct commits to `main`, no force push, no deleting it, required checks green | repository ruleset `Main branch ruleset`. The Admin role can bypass it only when merging a pull request (`bypass_mode: pull_request`), a direct push to `main` is refused for everyone. Required checks: `Script tests`, `Kit tests`, `Build, app tests, lint`, `check-title`, `check-body`, `critical-paths`. A new job in a workflow is not required until it is added to the ruleset |
| Destructive commands: force push (also `-fu`, `--force-with-lease`), deleting or mirroring remote refs, push to `main`, hard reset, forced clean, forced branch delete, `checkout .` / `restore .`. Skipping the hooks: `--no-verify` and `-n` on `git commit` and `git push` (`git push -n` is `--dry-run`, blocked with it), `git -c core.hooksPath=...` and `--config-env`. GitHub: `gh pr merge`, `gh repo delete`, `gh issue delete`, `gh release delete`, also with options before the subcommand (`gh -R owner/repo pr merge`) | Claude Code `PreToolUse` hook, `.claude/hooks/block-dangerous-git.sh`, registered in `.claude/settings.json`, tested by `scripts/test-block-dangerous-git.sh`. Needs `jq` and refuses everything without it. Pushing a feature branch and `gh pr create` / `gh pr view` are allowed. `.claude/settings.json` also lists the four `gh` commands in `permissions.deny`. Options before the subcommand (`git -C dir ...`) are ignored when matching. The hook matches the command text, so a commit message or PR body that quotes a blocked command is blocked too, reword it |

Enable the `commit-msg`, `pre-commit` and `pre-push` hooks once per clone with `make setup` (linked worktrees share the setting and each uses the hooks of its own checkout). It also checks the tools from [commands](commands.md), and running it again changes nothing. The Claude Code hook needs no setup, it is registered in the checked-in `.claude/settings.json`. `make setup` runs:

```bash
make setup
```

It sets `git config core.hooksPath .githooks`, a relative path, so a worktree never runs hooks from another checkout.
