# Pull requests

What a pull request body contains. Read this before opening one. The reader is the user, who reviews many PRs and wants to see in one minute what was tested, what it looks like, what could break and where an agent was unsure.

The body starts from the `pr` skill (Summary, Evidence, Merge Danger) and adds the sections below. The order is fixed:

```markdown
## Summary
## Tests
## Snapshots
## Evidence
## Merge Danger
## Reviewer notes

Closes #<issue>
```

`.github/pull_request_template.md` opens a new PR with this skeleton, and CI (`pr-body.yml`) fails a body with a missing, misordered or empty section or without `Closes #<issue>` as the last line of your text. Attribution lines the tooling appends after it are fine.

Every section is present. A section with nothing to say says so in one line ("No UI change."), it is not deleted: a missing section reads as forgotten.

## Get the facts first

Commit, then run:

```bash
scripts/pr-facts.sh
```

It prints the Tests, Critical paths and Snapshots parts for the diff against `origin/main`, as Markdown. Paste it and edit. The script reads names and files, it does not judge: you add the sentence that says what the numbers mean. It is tested by `scripts/test-pr-facts.sh`.

## Tests

The user wants the list of tests that concern the change, and what is new.

- **Tests for the changed code:** each changed Swift source file with its mirrored test file ([testing](testing.md)) and the number of tests in it. A source file with `no mirrored test file` needs a reason on the same line (view code covered by a screenshot, a one-line change, glue covered elsewhere) or a test.
- **New tests:** the test names that were added, per file, as `scripts/pr-facts.sh` prints them. Under each, one line in glossary terms of the behaviour it pins down. Do not describe tests the diff did not add.
- **Removed or renamed tests:** never silent. Name each one and say why it is gone. A removed test with no replacement is a finding for the reviewer.
- **Result:** the last output line of `make test` (`Test run with N tests ... passed`, `Test Succeeded`), copied, with the commit it was run on.

## Snapshots

For a change under `App/Breathnest/` (UI): the screens it touches, as screenshots at the default text size and at AX5, next to the design value they were compared with ([definition of done](definition-of-done.md), `ui-verifier` in [workflow](workflow.md)). A screen the design does not draw is listed as such, not left out.

- The files come from `make run screenshot` and the `ui-verifier` agent and sit in the git-ignored `build/`. Do not commit them. The caller drags them into the PR description in the GitHub web editor, where GitHub stores them; `scripts/pr-facts.sh` lists the files and the commit they belong to.
- An agent that cannot run the simulator or the `ui-verifier` writes "snapshots not attached" with the screen names, so the user knows what to add. It never writes a description of a screen it did not see.
- No UI change: write "No UI change."

## Evidence

As in the `pr` skill: before and after, as a screenshot or a failing then passing test, shown by the exact test.

## Merge Danger

As in the `pr` skill (**Door**, **Blast Radius**), plus one required line:

**Critical paths touched:** the areas from [critical paths](critical-paths.md) that the diff reaches, each with the one thing that could break and the evidence that it does not (a test name, a screenshot, a command output), or "not covered" when there is none. Take the first draft from `scripts/pr-facts.sh`, then add by hand an area it could not match. Write "none" when no area is touched.

A change of behaviour in a critical path with no test and no screenshot is called out in the first line of the body, above the Summary, as `> **Warning:** ...`, so it is not missed.

## Reviewer notes

Where a reader should slow down. Each item is `file:line`, what is there, and which of these it is:

- **Unclear:** the ticket, the design or an ADR was silent or ambiguous. Say what you chose, why, and what changes if the choice is wrong. Do not guess quietly; an AFK agent that cannot decide stops and asks ([workflow](workflow.md)), this list is for the smaller choices it could make and wants confirmed (which public interface a test goes through, a name not in the glossary, a default value).
- **Worth a look:** code that is clever, a workaround, a deliberate departure from the neighbouring style, a place where a test could not reach, a `TODO`.
- **Not verified:** something the agent could not run or check (simulator, device, haptics, the `ui-verifier`).

Facts, not apologies: no "I think this is fine". If there is nothing to note, write "Nothing unclear." and mean it. Do not pad the list to look careful.

## End of the body

The last line of your own text is `Closes #<issue>` ([git](git.md)). Keep any attribution line the tooling appends after it.
