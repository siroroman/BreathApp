# Workflow

How a ticket moves through a session to a pull request.

## One ticket, one session

- One ticket = one session = one worktree = one branch = one PR (see [git](git.md)). A session is about 100K tokens of work. When it grows past that, reset instead of compacting: the handoff is the ticket, an ADR or a note, not the chat.
- Start from the ticket (`gh issue view <n>`), `GLOSSARY.md` and the ADRs of the area ([domain](domain.md)). Do not start without acceptance criteria: ask or label the ticket `needs-info`.
- Unrelated problems you notice become new issues (`needs-triage`), not part of the diff.

## Levels of supervision

| Level | Meaning | Used for |
|---|---|---|
| **HITL** (human in the loop) | The user is in the session, decides open points and reviews as you go. Checkpoints after the failing test and after the first working slice. | The first tickets, anything with open design or domain questions, tickets labelled `ready-for-human`. |
| **AFK** (away from keyboard) | The agent works alone in a worktree (`implementer` agent) and stops at a draft PR. | Tickets labelled `ready-for-agent` with clear acceptance criteria and a logic-only scope that `make test-kit` can prove. |

An AFK session that hits a decision it cannot make stops and writes the question on the ticket, it does not guess. UI work always ends with a screenshot (see [definition of done](definition-of-done.md)).

## Steps

1. Read the ticket, glossary and ADRs. Restate the acceptance criteria.
2. `git fetch`, then create `<type>/<issue>-<slug>` from the latest `main` in a worktree ([git](git.md)). `git config core.hooksPath .githooks` once per clone.
3. Red-green slices with `make test-kit` ([testing](testing.md)). Commit each slice.
4. `make build test lint`, and `make run screenshot` for UI ([commands](commands.md)).
5. Push the feature branch, open a **draft** PR with the `pr` skill. Check CI.
6. Review in a **fresh** session with `/code-review`, never in the session that wrote the code. Fix findings, then mark the PR ready.
7. The user merges (squash). Do not merge yourself unless asked. Afterwards remove the worktree and its simulator (`xcrun simctl delete "Breathnest-<folder>"`).

## Agents

Four subagents live in `.claude/agents/`. Each one's file is its definition; this table only says when to use it.

| Agent | Use it for | Writes |
|---|---|---|
| `implementer` | One `ready-for-agent` ticket, AFK in a worktree, up to a draft PR. | Code, commits, the draft PR. |
| `code-reviewer` | Step 6: review of a branch or PR in a fresh context. | Only the review comment. |
| `ui-verifier` | Step 4 for UI: screenshots at default size and AX5, compared with the design. The `implementer` cannot run it, so the caller runs it on the finished branch and attaches the screenshots to the PR by hand. | Screenshots in `build/` (git-ignored). |
| `researcher` | A research ticket, answered from primary sources. | One note in `docs/product/research/`. |

## Handoffs

Leave state where the next session will look: the ticket (progress, open questions), the PR description, an ADR for a decision that outlives the ticket. Notes for the user's other sessions go in the shared notes folder the session was given, not in the repo.
