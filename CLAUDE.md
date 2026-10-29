# BreathApp

## Git

GitHub flow with Conventional Commits, checked by the `commit-msg` hook (`git config core.hooksPath .githooks`). Read `docs/agents/git.md` before creating a branch, commit or pull request.

## Build and run

`make gen build test lint` must pass, `make run` launches the app on the simulator. Read `docs/agents/commands.md` for the commands and `docs/agents/ios.md` before touching Swift code.

## Skills

Before installing a Claude Code skill, read `docs/agents/skills.md` (Node version check, verifying leaderboard counts).

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in `siroroman/BreathApp` (`gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
