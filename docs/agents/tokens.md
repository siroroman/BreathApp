# Token use

A session pays again for everything in its context on every turn, so the cost is what stays in the context, not what one command prints. These rules keep it small. The context limit and when to reset are in [workflow](workflow.md).

## What every session loads

- `CLAUDE.md` stays under 3000 bytes: pointers only, detail goes into `docs/agents/*.md` that a task reads when it needs it. **Checked:** `scripts/check-context-size.sh`.
- The `description:` of every skill and agent stays under 700 characters, it is in the catalog of every session. The body is read only when the skill or agent runs. **Checked:** the same script.
- One skill per framework, a vendored skill nobody uses is removed ([skills](skills.md)). Process rule.
- Read the docs the task needs ([workflow](workflow.md) lists them), not all of `docs/agents/`.

## Reading

- Search first (`grep`, glob), then read the lines you need (`offset` and `limit`). Read a whole file only when you edit most of it. Do not read a file again after you edited it or when it did not change.
- Command output stays short: `xcodebuild` goes through `xcbeautify --quiet`. For `gh`, `git log` and `swift test` ask for what you need (`--json field`, `-n 5`, `--filter`), not the full listing.

## Running

- Run the narrowest test first (`swift test --filter`), the full `make build test lint` once at the end.
- Wait for a long command inside one command (a `until` loop with a limit, or `run_in_background`), not with repeated check turns.
- Two failed attempts at the same fix: stop, say what you tried and what you saw, change the approach or ask. A third blind retry reads the same files again.

## Models and subagents

- Read-only work that follows fixed steps runs on a smaller model: `ui-verifier` is `haiku`, `researcher` and `implementer` are `sonnet`. The review judges a change it did not write, so `code-reviewer` stays `opus`. Moving an agent to a smaller model is a pull request that says what got worse or not.
- A self-contained search or investigation that would fill the context with files you will not need goes to a subagent that returns a summary. A subagent starts cold and re-reads, so do not use one for a two-line lookup.

## Replies

Lead with the result. Do not narrate each tool call or repeat a diff the user can see.
