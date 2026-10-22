# Agent skills

Guidelines for installing and using Claude Code skills (`~/.claude/skills`) in this project.

## Check Node before `npx skills`

`npx skills find` / `npx skills add` requires Node ≥ 22.20. On an older Node it fails. Run `node -v` first; below 22.20, skip the CLI and go straight to a fallback: the `skills.sh` web UI, `gh api` against the skill's source repo, or a plain web search.

## Verify leaderboard counts against the repo

Install counts on the `skills.sh` leaderboard are not ground truth — a skill can be listed with a large count while no longer existing in its source repo. Before relying on a leaderboard entry, confirm the skill is actually there, e.g.:

```bash
gh api repos/<owner>/<repo>/git/trees/main?recursive=1 | grep <skill-name>
```
