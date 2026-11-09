# Workflow

How a ticket moves through a session to a pull request.

## One ticket, one session

- One ticket = one session = one worktree = one branch = one PR (see [git](git.md)). A session stays under 15% of the context window, see Context limit below. When it grows past that, clear instead of compacting: the handoff is the ticket, an ADR or a note, not the chat.
- Start from the ticket (`gh issue view <n>`), `GLOSSARY.md` and the ADRs of the area ([domain](domain.md)). Do not start without acceptance criteria: ask or label the ticket `needs-info`.
- Unrelated problems you notice become new issues (`needs-triage`), not part of the diff.

## Context limit

A session never goes past **15% of the context window**: long sessions get slow, expensive and less accurate.

- **Measured** by `.claude/hooks/context-check.sh` (PostToolUse hook): the input, cache creation and cache read tokens of the last assistant message in the transcript, against 15% of `BREATHNEST_CONTEXT_WINDOW` (default 200000; export 1000000 for a 1M model). From the first tool call over the limit, every tool call carries a message to the agent. A hook cannot run `/clear`, so the agent does the next two steps.
- **Save** a handoff as a comment on the ticket (`gh issue comment`): branch, what is done, what is next, open questions, how to resume (the failing test or command). Commit what builds. Nothing is saved in the chat only.
- **Clear, do not compact.** End the turn and ask the user to run `/clear`, then restart from the ticket and the handoff comment. Compaction is a lossy summary the agent writes about itself, it keeps the old context shape and runs at a moment the agent does not choose, so it cannot save first. A fresh session reads the ticket, the glossary and the ADRs again, which is cheap at this size.
- **Subagents** (`implementer`, `code-reviewer`) follow the same limit: at the message they post the handoff and end their run with it as the report. The caller starts a new agent from the ticket. Whether the hook sees the subagent's own transcript is not verified, see [rules enforcement](rules-enforcement.md).
- The auto-compact setting `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` is not used: it compacts without saving first.

- Keep the context small: search before reading, narrowest test first, stop after two failed tries ([tokens](tokens.md)).

## Levels of supervision

| Level | Meaning | Used for |
|---|---|---|
| **HITL** (human in the loop) | The user is in the session, decides open points and reviews as you go. Checkpoints after the failing test and after the first working slice. | The first tickets, anything with open design or domain questions, tickets labelled `ready-for-human`. |
| **AFK** (away from keyboard) | The agent works alone in a worktree (`implementer` agent) and stops at a draft PR. | Tickets labelled `ready-for-agent` with clear acceptance criteria and a logic-only scope that `make test-kit` can prove. |

An AFK session that hits a decision it cannot make stops and writes the question on the ticket, it does not guess. UI work always ends with a screenshot (see [definition of done](definition-of-done.md)).

## Steps

1. Read the ticket, glossary and ADRs. Restate the acceptance criteria.
2. `git fetch`, then create `<type>/<issue>-<slug>` from the latest `main` in a worktree ([git](git.md)). `make setup` once per clone.
3. Red-green slices with `make test-kit` ([testing](testing.md)). Commit each slice.
4. `make build test lint`, and `make run screenshot` for UI ([commands](commands.md)).
5. Push the feature branch, run `scripts/pr-facts.sh`, and open a **draft** PR with the `pr` skill, extended as in [pull requests](pull-requests.md). Check CI.
6. Review in a **fresh** session with the `code-reviewer` agent, never in the session that wrote the code. The `start-task` skill starts it as a subagent right after the draft PR is open, and its empty context is what makes it fresh. It posts the review with a marker for the commit it reviewed, which `pr-review.yml` looks for (the `/code-review` skill alone posts none). One round only: the review lists at most five **Blocking** findings, each with a failing case, and some **Notes**. Fix only the blocking ones, each with its evidence, push, and show the user `git diff <reviewed sha>..HEAD` (the sha is in the marker), the part no agent reviewed. Notes become issues if the user wants them. Do not run the review again unless the user asks. The user marks the PR ready, an agent does not.
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
