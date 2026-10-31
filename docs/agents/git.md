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
- Open as a draft until `/code-review` has run in a fresh session and the checks are green.
- Merge with **squash**. Linear history on `main`.

## Rules for agents

- Push only your own feature branch: `git push -u origin <branch>`. Never force-push and never push `main`.
- Never bypass the hook with `--no-verify`. If a message is rejected, fix the message.
- Never rewrite history that is already pushed.
- Do not merge a PR unless the user asked for it.

## Enforcement

| Rule | Where it is checked |
|---|---|
| Commit message format | `commit-msg` hook, `.githooks/commit-msg` calling `scripts/check-commit-msg.sh` |
| PR title format | CI, `.github/workflows/pr-title.yml` calling `scripts/check-commit-msg.sh -` on `$PR_TITLE` |
| PR body: the six sections in order, none empty, `Closes #<issue>` last | CI, `.github/workflows/pr-body.yml` calling `scripts/check-pr-body.sh`, tested by `scripts/test-check-pr-body.sh`. `.github/pull_request_template.md` starts a PR with the sections. Dependabot PRs are skipped. Whether the content is true is checked by the `code-reviewer` agent ([pull requests](pull-requests.md)) |
| Critical path source changed with no test change | CI, `.github/workflows/pr-body.yml` calling `scripts/check-critical-paths.sh`, tested by `scripts/test-check-critical-paths.sh`. A PR body that starts with `> **Warning:**` passes ([critical paths](critical-paths.md)) |
| Kit tests before a push | `pre-push` hook, `.githooks/pre-push` running `make test-kit`. Skipped when the push only deletes a branch |
| Squash merge, PR title as commit title | repository setting: only squash merge is allowed, the PR title is the commit title, branches are deleted after the merge |
| No direct commits to `main`, no force push, no deleting it, required checks green | repository ruleset `Main branch ruleset`; only the Admin role can bypass it. Required checks: `Script tests`, `Kit tests`, `Build, app tests, lint`, `check-title`, `check-body`, `critical-paths`. A new job in a workflow is not required until it is added to the ruleset |
| Destructive commands: force push (also `-fu`, `--force-with-lease`), deleting or mirroring remote refs, push to `main`, hard reset, forced clean, forced branch delete, `checkout .` / `restore .` | Claude Code `PreToolUse` hook, `.claude/hooks/block-dangerous-git.sh`, registered in `.claude/settings.json`, tested by `scripts/test-block-dangerous-git.sh`. Needs `jq` and refuses everything without it. Pushing a feature branch is allowed. Options before the subcommand (`git -C dir ...`) are ignored when matching. The hook matches the command text, so a commit message or PR body that quotes a blocked command is blocked too, reword it |

Enable the `commit-msg` and `pre-push` hooks once per clone (linked worktrees share it). The Claude Code hook needs no setup, it is registered in the checked-in `.claude/settings.json`:

```bash
git config core.hooksPath .githooks
```
