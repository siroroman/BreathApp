#!/usr/bin/env bash
# Tests .claude/hooks/block-dangerous-git.sh (rules: docs/agents/git.md).
# Usage: test-block-dangerous-git.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
hook="$root/.claude/hooks/block-dangerous-git.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git init -q -b main "$tmp/on-main"
git init -q -b feat/x "$tmp/on-feature"
failed=0

# run <expected exit> <project dir> <command>
run() {
  local got
  jq -n --arg c "$3" '{tool_input: {command: $c}}' | CLAUDE_PROJECT_DIR="$2" "$hook" >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$1" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$1" "$got" "$3"
    failed=1
  fi
}
allow() { run 0 "$tmp/on-feature" "$1"; }
deny() { run 2 "$tmp/on-feature" "$1"; }

# Pushing a feature branch must keep working, so pull requests can be opened.
allow "git push -u origin chore/git-guardrails"
allow "git push origin feat/12-box-breathing-timer"
allow "git push origin HEAD:feat/x"
allow "git push origin feat-f"
allow "git push origin feat/main"
allow "git push origin main-fix"
allow "git push"
allow "git -C /tmp push origin chore/x"
allow "git push origin chore/x && echo main"
allow "git push origin chore/x && echo -f"

# Harmless git commands.
allow "git status"
allow "git fetch origin"
allow "git checkout .githooks"
allow "git checkout -b feat/x"
allow "git restore README.md"
allow "git reset --soft HEAD~1"
allow "git clean -n"
allow "git branch -d merged-branch"
allow "git branch --force moved HEAD~1"
allow "ls -la"

# Force push, including combined flags and options before the subcommand.
deny "git push --force origin x"
deny "git push --force-with-lease origin x"
deny "git push -f"
deny "git push -fu origin x"
deny "git push -uf origin x"
deny "git push origin x --force"
deny "git -C . push -f"
deny "git -c a=b push -f"
deny "git --git-dir=.git push -f"
deny "git -C \"my dir\" push -f"
deny "git push origin +x"

# Delete remote branches or push everything.
deny "git push origin --delete x"
deny "git push origin --del x"
deny "git push -d origin x"
deny "git push origin :x"
deny "git push --mirror"
deny "git push --all"
deny "git push --prune origin"

# Push to main.
deny "git push origin main"
deny "git push origin master"
deny "git push -u origin main"
deny "git push origin HEAD:main"
deny "git push origin x:refs/heads/main"
deny "git push origin refs/heads/main"
deny "git push origin 'main'"
deny "git -C . push origin main"
run 2 "$tmp/on-main" "git push"
run 2 "$tmp/on-main" "git push -u origin"
run 2 "$tmp/on-main" "git push origin HEAD"
run 0 "$tmp/on-main" "git push origin feat/x"

# Hard reset, forced clean, forced branch delete, discard all changes.
deny "git reset --hard"
deny "git reset --hard HEAD~1"
deny "git reset  --hard"
deny "git reset -q --hard"
deny "git reset HEAD --hard"
deny "git -C . reset --hard"
deny "git clean -fd"
deny "git clean -d -f"
deny "git clean -d -x -f"
deny "git clean --force"
deny "git -C . clean -fd"
deny "git branch -D x"
deny "git branch -vD x"
deny "git branch -df x"
deny "git branch -fd x"
deny "git branch -d -f x"
deny "git branch --delete --force x"
deny "git branch --force --delete x"
deny "git -C . branch -D x"
deny "git checkout ."
deny "git checkout -- ."
deny "git restore ."
deny "git restore -- ."

# The command is only found in a chain.
deny "cd /tmp && git push -f"
deny "echo hi; git reset --hard"

# Input the hook cannot inspect is refused.
printf 'not json' | CLAUDE_PROJECT_DIR="$tmp/on-feature" "$hook" >/dev/null 2>&1
if [[ $? -ne 2 ]]; then
  echo "FAIL (want 2): input that is not JSON"
  failed=1
fi

if [[ "$failed" -eq 0 ]]; then
  echo "all cases passed"
fi
exit "$failed"
