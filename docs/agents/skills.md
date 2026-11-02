# Agent skills

Which skills the workflow needs, where each one comes from, and how to install and update them. Skills live in `.claude/skills/` (this repo) or `~/.claude/skills` (one machine).

## Skills the workflow needs

A fresh clone, a worktree on another machine and a cloud agent have only what is committed, so every skill an agent needs to implement and review a ticket is **vendored**: a copy in `.claude/skills/<name>/`, identical to upstream at the commit below (`git archive`, nothing edited) plus the upstream `LICENSE` (all MIT). `/tdd`, `/pr` and `/code-review` work in a fresh clone because of these.

| Skill | Used by | Source | Commit |
|---|---|---|---|
| `tdd` | [testing](testing.md), [git](git.md), `implementer` | [mattpocock/skills](https://github.com/mattpocock/skills) `skills/engineering/tdd` | `3f59913` (2026-10-07) |
| `pr` | [pull requests](pull-requests.md), [workflow](workflow.md), `implementer` | mattpocock/skills `skills/engineering/pr` | `e484a80` (2026-09-24) |
| `code-review` | [workflow](workflow.md), [definition of done](definition-of-done.md), `code-reviewer` | mattpocock/skills `skills/engineering/code-review` | `3da8c01` (2026-10-07) |
| `domain-modeling` | [domain](domain.md), `implementer` | mattpocock/skills `skills/engineering/domain-modeling` | `d80fa0f` (2026-09-17) |
| `swiftui-expert-skill` | [ios](ios.md), `implementer` | [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) `swiftui-expert-skill` | `572c7e1` (2026-07-24) |
| `swift-concurrency-pro` | [ios](ios.md), `implementer` | [twostraws/Swift-Concurrency-Agent-Skill](https://github.com/twostraws/Swift-Concurrency-Agent-Skill) `swift-concurrency-pro` | `bee3f69` (2026-05-17) |

The commit is the last upstream commit that touched the skill's folder. For `swift-concurrency-pro` only the skill folder is vendored, not the upstream plugin files (`.claude-plugin/`, `agents/`, `assets/`, a nested `skills/`), because a second `SKILL.md` would register the skill twice.

## Skills written for this repo

Not vendored, there is no upstream: they are edited here, in `.claude/skills/<name>/`.

| Skill | What it does |
|---|---|
| `start-task` | First step of a session that asks for a change: finds or creates the GitHub issue, shows type, branch, title and description, offers plan mode, implements after approval and offers the pull request. `CLAUDE.md` tells the agent to invoke it, a skill cannot start itself. |

## Skills that stay personal

Named in the docs, but used by the user in their own interactive sessions (HITL, planning, triage), not to implement a ticket, so they are not copied. A session that wants one installs it from the source.

| Skill | Where the docs name it | Source |
|---|---|---|
| `grilling`, `prototype`, `research` | [issue tracker](issue-tracker.md) (ticket types of `/wayfinder`). The `researcher` agent covers research tickets without the `research` skill. | mattpocock/skills `skills/productivity/grilling`, `skills/engineering/prototype`, `skills/engineering/research` |
| `codebase-design`, `diagnosing-bugs` | the user's own sessions, no repo doc names them | mattpocock/skills `skills/engineering/` |
| `grill-with-docs`, `improve-codebase-architecture` | [domain](domain.md) | mattpocock/skills `skills/engineering/` |
| `triage`, `wayfinder` | [triage labels](triage-labels.md), [issue tracker](issue-tracker.md) | mattpocock/skills `skills/engineering/` |
| `setup-matt-pocock-skills` | [next steps](../next-steps.md), already run for this repo | mattpocock/skills `skills/engineering/` |

Observer, retro, handoff and similar skills belong to the user's other tooling and are not part of this repo.

## Which copy wins

Claude Code resolves a skill name enterprise, then personal (`~/.claude/skills`), then project (`.claude/skills`). With the same name in both, `/tdd` runs the personal copy and the vendored one is ignored. On the Mac that is fine as long as the personal copy is not older than the vendored one; if a skill behaves differently here than on a fresh clone, compare the two folders (`diff -r ~/.claude/skills/tdd .claude/skills/tdd`). The vendored copy is the version the workflow was written against, and the only one a fresh clone, a worktree on another machine or a cloud agent has.

## Update a vendored skill

1. Clone the source repo and pick the commit. Read the diff of the skill folder first, a skill is instructions the agent obeys (and `swiftui-expert-skill` also ships Python scripts).
2. Replace the folder and the `LICENSE`, and change the commit in the table above in the same pull request. `.claude/skills/*` is a [guardrail path](guardrail-paths.md), so the body needs a **Guardrails touched:** line:

```bash
git -C <clone> archive <commit> <path-in-repo> | tar -x -C .claude/skills/<name> --strip-components=<depth of path-in-repo>
```

When a skill is added to the workflow docs, add it to the first table (vendored) or the second (personal) in the same pull request.

## Install a personal skill

Only for the skills of the second table, or others the user wants on their machine. Not for the vendored ones.

### Check Node before `npx skills`

`npx skills find` / `npx skills add` requires Node ≥ 22.20. On an older Node it fails. Run `node -v` first; below 22.20, skip the CLI and go straight to a fallback: the `skills.sh` web UI, `gh search code` in the skill's source repo, or a plain web search.

### Verify leaderboard counts against the repo

Install counts on the `skills.sh` leaderboard are not ground truth — a skill can be listed with a large count while no longer existing in its source repo. Before relying on a leaderboard entry, confirm the skill is actually there, e.g.:

```bash
gh search code --repo <owner>/<repo> --filename SKILL.md <skill-name>
```
