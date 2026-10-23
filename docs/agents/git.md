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
- Body follows the `pr` skill (summary, before/after evidence, merge danger) and ends with `Closes #<issue>`.
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
| Squash merge, PR title as commit title | repository setting: only squash merge is allowed, the PR title is the commit title, branches are deleted after the merge |
| No direct commits to `main` | not enforced yet |
| Destructive commands (force push, push to `main`, hard reset, forced clean, forced branch delete, discarding all changes) | Claude Code `PreToolUse` hook, `.claude/hooks/block-dangerous-git.sh`, registered in `.claude/settings.json`. Pushing a feature branch is allowed. The hook matches the whole command text, so a commit message or PR body that quotes a blocked command is blocked too |

Enable the hook once per clone (linked worktrees share it):

```bash
git config core.hooksPath .githooks
```
