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

An AFK session that hits a decision it cannot make stops and writes the question on the ticket, it does not guess. UI work ends with one screenshot per changed screen ([Simulator use](#simulator-use), [definition of done](definition-of-done.md)).

## Steps

1. Read the ticket, glossary and ADRs. Restate the acceptance criteria.
2. `git fetch`, then create `<type>/<issue>-<slug>` from the latest `main` in a worktree ([git](git.md)). `make setup` once per clone.
3. Red-green slices with `make test-kit` ([testing](testing.md)). Commit each slice.
4. `make build test lint`, and for a changed screen one `make run screenshot` at the end, when [Simulator use](#simulator-use) allows it ([commands](commands.md)).
5. Push the feature branch, run `scripts/pr-facts.sh`, and open a **draft** PR with the `pr` skill, extended as in [pull requests](pull-requests.md). Check CI.
6. Review in a **fresh** session with the `code-reviewer` agent, never in the session that wrote the code. The `start-task` skill starts it as a subagent right after the draft PR is open, and its empty context is what makes it fresh. It posts the review with a marker for the commit it reviewed, which `pr-review.yml` looks for (the `/code-review` skill alone posts none). One round only: the review lists at most five **Blocking** findings, each with a failing case, and some **Notes**. Fix only the blocking ones, each with its evidence, push, and show the user `git diff <reviewed sha>..HEAD` (the sha is in the marker), the part no agent reviewed. Notes become issues if the user wants them. Do not run the review again unless the user asks. The user marks the PR ready, an agent does not.
7. The user merges (squash). Do not merge yourself unless asked. Afterwards remove the worktree and its simulator (`xcrun simctl delete "Breathnest-<folder>"`).

## Simulator use

The simulator is slow and costs time and tokens (build, boot, install, screenshots). Use it only when nothing else answers the question. This section is the rule; the other docs link here.

**Allowed:**

- One `make run screenshot` per changed screen at the default text size, on the finished branch, after `make build test lint` pass. Not a tour of the app: screens the diff does not touch are not shot.
- A critical path that only the simulator or a device shows (app leaving the foreground, screen lock, sleep: [critical paths](critical-paths.md)).
- `make test-app` and `make build` as part of `make build test lint`, which need the simulator as a destination.
- `make test-ui` when a screen changes (by hand, not in the red-green loop).
- The `ui-verifier` agent, **once per PR** on the finished branch, not per slice. Its screenshot is the one screenshot of that screen, not an extra one.

**Not allowed:**

- Booting a simulator or running `make run` to "see if it works" while the red-green loop runs. Logic goes to `make test-kit` (seconds, no simulator).
- A run for a change that is only layout or copy of a screen the design already draws and that needs no critical path: read the diff against the design values instead. Say "no run: layout or copy only" in the PR.
- A second screenshot of the same screen. Re-shoot only when a fix after review changed that screen.
- A run on a change with no `App/Breathnest/` file (Kit, docs, scripts).

A change that does not need a run says so in the PR instead of attaching a screenshot ([pull requests](pull-requests.md)).

**CI** runs `make run screenshot` in the macOS job for every PR that changes `App/`, `BreathnestKit/` or `project.yml`. It stays: it is the only automatic check that the app launches, the runner is free (public repo) and it costs no agent tokens. This rule is about agents, not CI. Narrowing it to `App/Breathnest/` is left for when the macOS minutes cost money ([commands](commands.md), CI).

## Agents

Four subagents live in `.claude/agents/`. Each one's file is its definition; this table only says when to use it.

| Agent | Use it for | Writes |
|---|---|---|
| `implementer` | One `ready-for-agent` ticket, AFK in a worktree, up to a draft PR. | Code, commits, the draft PR. |
| `code-reviewer` | Step 6: review of a branch or PR in a fresh context. | Only the review comment. |
| `ui-verifier` | Step 4 for UI, once per PR ([Simulator use](#simulator-use)): screenshots at default size and AX5, compared with the design. The `implementer` cannot run it, so the caller runs it on the finished branch and attaches the screenshots to the PR by hand. | Screenshots in `build/` (git-ignored). |
| `researcher` | A research ticket, answered from primary sources. | One note in `docs/product/research/`. |

## Handoffs

Leave state where the next session will look: the ticket (progress, open questions), the PR description, an ADR for a decision that outlives the ticket. Notes for the user's other sessions go in the shared notes folder the session was given, not in the repo.
