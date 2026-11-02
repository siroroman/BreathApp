#!/usr/bin/env bash
# Tests scripts/check-branch-name.sh (rules: docs/agents/git.md, Branches).
# Usage: test-check-branch-name.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
failed=0

# case_ <expected exit> <branch name>
case_() {
  local want=$1 branch=$2 got
  "$root/scripts/check-branch-name.sh" "$branch" >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$branch"
    failed=1
  fi
}

case_ 0 "feat/12-box-breathing-timer"
case_ 0 "fix/31-timer-drift-in-background"
case_ 0 "docs/git-conventions"
case_ 0 "ci/119-enforce-written-rules"
case_ 0 "chore/7-x"
case_ 0 "revert/88-bad-haptics"
case_ 0 "dependabot/github_actions/actions/checkout-7"
case_ 1 "main"
case_ 1 "feature/12-box-breathing-timer"
case_ 1 "research/breathing-techniques"
case_ 1 "feat/"
case_ 1 "feat/12-"
case_ 1 "feat/Box-Breathing"
case_ 1 "feat/12_box_breathing"
case_ 1 "feat/box--breathing"
case_ 1 "feat/-box"
case_ 1 "feat/a/b"
case_ 1 "feat/12 box"
case_ 1 "worktree-agent-a10381de9f2f6332e"
case_ 1 ""

if "$root/scripts/check-branch-name.sh" >/dev/null 2>&1; then
  echo "FAIL: no argument should exit 1"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all check-branch-name cases passed"; fi
exit $failed
