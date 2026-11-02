#!/usr/bin/env bash
# Tests .githooks/pre-commit and .githooks/pre-push (rules: docs/agents/git.md).
# Usage: test-githooks.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# A repo with the hooks as `make setup` configures them, and a stub `make test-kit` so pre-push needs no Swift.
git init -q --bare "$tmp/remote.git"
git init -q -b main "$tmp/repo"
cd "$tmp/repo" || exit 1
mkdir .githooks
cp "$root/.githooks/pre-commit" "$root/.githooks/pre-push" .githooks/
printf 'test-kit:\n\t@true\n' >Makefile
git config core.hooksPath .githooks
git remote add origin "$tmp/remote.git"
git -c core.hooksPath=/dev/null add -A
git -c core.hooksPath=/dev/null commit -q -m "chore: init"
git -c core.hooksPath=/dev/null push -q origin main
git switch -q -c feat/x

# check <expected: pass or fail> <description> <command...>
check() {
  local want=$1 what=$2 got
  shift 2
  "$@" >"$tmp/out" 2>&1
  got=$?
  if [[ ("$want" == pass && "$got" -ne 0) || ("$want" == fail && "$got" -eq 0) ]]; then
    printf 'FAIL (want %s, got exit %s): %s\n' "$want" "$got" "$what"
    failed=1
  fi
}
says() { # <description> <text the last command must have printed>
  if ! grep -q -- "$2" "$tmp/out"; then
    printf 'FAIL (message lacks "%s"): %s\n' "$2" "$1"
    failed=1
  fi
}

# pre-commit
check pass "commit on a feature branch" git commit -q --allow-empty -m "chore: a"
git switch -q main
check fail "commit on main" git commit -q --allow-empty -m "chore: b"
says "commit on main" "git switch -c"
says "commit on main" "docs/agents/git.md"
git switch -q -c master
check fail "commit on master" git commit -q --allow-empty -m "chore: c"
git switch -q --detach
check pass "commit on a detached HEAD (rebase)" git commit -q --allow-empty -m "chore: d"
git switch -q feat/x

# Linked worktrees read the same hooks, from their own checkout.
git worktree add -q -b feat/wt "$tmp/wt" main
pushd "$tmp/wt" >/dev/null || exit 1
check pass "commit on a feature branch in a worktree" git commit -q --allow-empty -m "chore: e"
popd >/dev/null || exit 1
git worktree add -q "$tmp/wt-main" main
pushd "$tmp/wt-main" >/dev/null || exit 1
check fail "commit on main in a worktree" git commit -q --allow-empty -m "chore: f"
popd >/dev/null || exit 1

# pre-push (git skips the hook when main is up to date, so give it something to push)
git -C "$tmp/wt-main" -c core.hooksPath=/dev/null commit -q --allow-empty -m "chore: g"
check pass "push a feature branch" git push -q -u origin feat/x
check fail "push main" git push -q origin main
says "push main" "squash-merged pull request"
check fail "push master" git push -q origin master
check fail "push a branch to main" git push -q origin feat/x:main
check fail "push a branch to refs/heads/main" git push -q origin feat/x:refs/heads/main
check fail "delete main" git push -q origin :main
check pass "delete a feature branch" git push -q origin :feat/x

if [[ "$failed" -eq 0 ]]; then
  echo "all cases passed"
fi
exit "$failed"
