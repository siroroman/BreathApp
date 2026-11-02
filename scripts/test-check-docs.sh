#!/usr/bin/env bash
# Tests scripts/check-docs.sh against a throwaway tree (rules: docs/agents/rules-enforcement.md).
# Usage: test-check-docs.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

fixture() {
  rm -rf "$tmp/repo" && mkdir -p "$tmp/repo" && cd "$tmp/repo" || exit 1
  mkdir -p docs/agents scripts .githooks .claude/skills/tdd .claude/skills/start-task
  printf 'run:\n\techo run\nlint: ## check\n\techo lint\n' >Makefile
  : >scripts/x.sh
  : >.githooks/pre-push
  : >.claude/skills/tdd/SKILL.md
  : >.claude/skills/start-task/SKILL.md
  cat >CLAUDE.md <<'EOF'
# Project
Read [git](docs/agents/git.md) first. Run `make lint`, or `scripts/x.sh -v`.
EOF
  cat >docs/agents/git.md <<'EOF'
# Git
See [skills](skills.md#table) and [the site](https://example.com/a.md). Hook: `.githooks/pre-push`.
A glob `scripts/check-*` and a placeholder `.claude/skills/<name>/` are not paths.
```bash
make run
```
EOF
  cat >docs/agents/skills.md <<'EOF'
# Skills

## Skills the workflow needs

| Skill | Source |
|---|---|
| `tdd` | upstream |

## Skills written for this repo

| Skill | What |
|---|---|
| `start-task` | ours |

## Skills that stay personal

| Skill | Source |
|---|---|
| `grilling` | upstream, not vendored |
EOF
}

# case_ <expected exit> <description> <file> <text>: appends the text to a file of the fixture.
# edit_ <expected exit> <description> <shell snippet>: for changes to the tree itself.
run_() {
  local want=$1 desc=$2 got
  "$root/scripts/check-docs.sh" "$tmp/repo" >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}
case_() { fixture; printf '%s\n' "$4" >>"$3"; run_ "$1" "$2"; }
edit_() { fixture; eval "$3"; run_ "$1" "$2"; }

edit_ 0 "everything exists" ':'
case_ 1 "link to a missing doc" docs/agents/git.md 'See [x](nope.md).'
case_ 1 "link with a missing doc and an anchor" docs/agents/git.md 'See [x](nope.md#top).'
case_ 0 "link to an existing doc from CLAUDE.md" CLAUDE.md 'See [x](docs/agents/skills.md).'
case_ 1 "link from CLAUDE.md that only works from docs/agents" CLAUDE.md 'See [x](git.md).'
case_ 1 "missing script" docs/agents/git.md 'Run `scripts/gone.sh`.'
case_ 0 "branch name example that looks like a docs path" docs/agents/git.md 'Branch `docs/git-conventions`.'
case_ 1 "missing doc file" docs/agents/git.md 'Read `docs/product/brief.md`.'
case_ 1 "missing hook" docs/agents/git.md 'Hook `.githooks/commit-msg` runs.'
case_ 1 "missing workflow" docs/agents/git.md 'CI is `.github/workflows/ci.yml`.'
case_ 0 "a command with arguments after an existing script" docs/agents/git.md 'Run `scripts/x.sh --all`.'
case_ 1 "missing make target in a span" docs/agents/git.md 'Run `make deploy`.'
case_ 1 "missing second make target in a span" docs/agents/git.md 'Run `make lint deploy`.'
case_ 0 "make with a flag and a real target" docs/agents/git.md 'Run `make -n lint`.'
case_ 1 "missing make target in a code block" docs/agents/git.md $'```bash\nmake deploy\n```'
edit_ 1 "skill directory not in the skills doc" 'mkdir .claude/skills/extra && : >.claude/skills/extra/SKILL.md'
edit_ 1 "vendored skill in the doc without a directory" 'rm -r .claude/skills/tdd'
edit_ 1 "repo skill in the doc without a directory" 'rm -r .claude/skills/start-task'

if "$root/scripts/check-docs.sh" "$tmp/no-such-dir" >/dev/null 2>&1; then
  echo "FAIL: an unknown root should exit 1"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all check-docs cases passed"; fi
exit $failed
