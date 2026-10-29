# Definition of done

A change counts as done when all of this is true and you can say so from output you saw, not from memory.

1. `make build` passes.
2. `make test` passes. New behaviour has a test written first (see [testing](testing.md)).
3. `make lint` passes. If it fails, run `make format` and check again.
4. A UI change was run and looked at: `make run screenshot`, then read `build/screenshot.png` and describe what is on screen. Compare it with the design in `docs/product/design-brief.md` when the ticket has one. Say so in the PR when the change has no UI.
5. The acceptance criteria of the ticket are met one by one. Name each in the PR.
6. Domain terms follow `GLOSSARY.md`, and no ADR is contradicted (or the PR says which one and why).
7. Commits and PR title follow [git conventions](git.md). The PR body follows the `pr` skill and ends with `Closes #<issue>`.
8. Nothing unrelated in the diff. Follow-ups are written down as issues, not slipped in.

The Stop hook runs `make lint test` as a safety net when Swift or project files changed. It does not replace steps 1, 4 and 5. A PR stays a draft until `/code-review` ran in a fresh session and CI is green.
