#!/usr/bin/env bash
# Tests .claude/hooks/stop-check.sh (rules: docs/agents/commands.md, Hooks).
# Each case builds a throwaway repo whose Makefile only leaves a marker file, so no real build runs.
# Usage: test-stop-check.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
hook="$root/.claude/hooks/stop-check.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0
n=0

git_in() { git -C "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false "${@:2}"; }

# new_repo <name> [lint exit code]: a repo with one commit on main. `make lint test` touches ran in the repo.
new_repo() {
  local d="$tmp/$1"
  mkdir -p "$d/App" "$d/docs"
  git init -q -b main "$d"
  printf 'lint test:\n\t@touch ran\n\t@exit %s\n' "${2:-0}" >"$d/Makefile"
  echo 'let a = 1' >"$d/App/A.swift"
  echo '# docs' >"$d/docs/a.md"
  # ran is a build product, not a change.
  echo ran >"$d/.gitignore"
  git_in "$d" add -A
  git_in "$d" commit -q -m init
  printf '%s' "$d"
}

# with_origin <repo>: makes origin/main point at the current main, like a fresh clone.
with_origin() {
  git_in "$1" update-ref refs/remotes/origin/main refs/heads/main
}

# commit_on_branch <repo> <file> <content>
commit_on_branch() {
  git_in "$1" switch -q -c feat/x
  mkdir -p "$(dirname "$1/$2")"
  printf '%s\n' "$3" >"$1/$2"
  git_in "$1" add -A
  git_in "$1" commit -q -m change
}

# run_hook <repo> [stdin json]: prints the exit code, leaves stderr in $tmp/err
run_hook() {
  printf '%s' "${2:-{\}}" | CLAUDE_PROJECT_DIR="$1" "$hook" >/dev/null 2>"$tmp/err"
  echo $?
}

# check <name> <repo> <expect ran: yes|no> <expect exit> [stdin json]
check() {
  local name=$1 repo=$2 want_ran=$3 want_exit=$4 got ran=no
  rm -f "$repo/ran"
  got=$(run_hook "$repo" "${5:-{\}}")
  [ -f "$repo/ran" ] && ran=yes
  n=$((n + 1))
  if [[ "$ran" != "$want_ran" || "$got" -ne "$want_exit" ]]; then
    printf 'FAIL %s (want ran=%s exit=%s, got ran=%s exit=%s)\n' "$name" "$want_ran" "$want_exit" "$ran" "$got"
    failed=1
  fi
}

# Clean tree, nothing differs from main.
r=$(new_repo clean-main); with_origin "$r"
check "clean tree on main does not run" "$r" no 0

# A committed Swift change since main still runs the checks (the bug this hook had).
r=$(new_repo committed-swift); with_origin "$r"
commit_on_branch "$r" App/B.swift 'let b = 2'
check "committed Swift change runs" "$r" yes 0

# Each watched path counts when committed.
for p in BreathnestKit/Sources/K.swift project.yml .swiftformat; do
  r=$(new_repo "committed-$(basename "$p")"); with_origin "$r"
  commit_on_branch "$r" "$p" 'x'
  check "committed change in $p runs" "$r" yes 0
done
r=$(new_repo committed-makefile); with_origin "$r"
git_in "$r" switch -q -c feat/x
printf '# edited\n' >>"$r/Makefile"
git_in "$r" commit -q -am change
check "committed Makefile change runs" "$r" yes 0

# A branch that only changes docs does not run them.
r=$(new_repo committed-docs); with_origin "$r"
commit_on_branch "$r" docs/b.md 'more docs'
check "committed docs-only change does not run" "$r" no 0

# Uncommitted and untracked changes in the watched paths run them, outside them they do not.
r=$(new_repo dirty-tracked); with_origin "$r"
echo 'let a = 2' >"$r/App/A.swift"
check "uncommitted edit runs" "$r" yes 0

r=$(new_repo dirty-untracked); with_origin "$r"
echo 'let c = 3' >"$r/App/C.swift"
check "untracked Swift file runs" "$r" yes 0

r=$(new_repo dirty-docs); with_origin "$r"
echo 'x' >"$r/docs/new.md"
check "untracked docs file does not run" "$r" no 0

r=$(new_repo committed-then-dirty); with_origin "$r"
commit_on_branch "$r" docs/b.md 'more docs'
echo 'let a = 2' >"$r/App/A.swift"
check "docs commit plus uncommitted Swift edit runs" "$r" yes 0

# A change that was committed on the branch and reverted again does not run.
r=$(new_repo reverted); with_origin "$r"
commit_on_branch "$r" App/B.swift 'let b = 2'
git_in "$r" rm -q App/B.swift
git_in "$r" commit -q -m revert
check "change added and removed again does not run" "$r" no 0

# Without origin/main the hook falls back to a local main.
r=$(new_repo no-origin)
commit_on_branch "$r" App/B.swift 'let b = 2'
check "no origin/main, local main: committed change runs" "$r" yes 0

r=$(new_repo no-origin-docs)
commit_on_branch "$r" docs/b.md 'more docs'
check "no origin/main, local main: docs-only does not run" "$r" no 0

# origin/main wins over a stale local main.
r=$(new_repo stale-main); with_origin "$r"
git_in "$r" switch -q -c feat/x
echo 'let b = 2' >"$r/App/B.swift"
git_in "$r" add -A
git_in "$r" commit -q -m change
git_in "$r" update-ref refs/remotes/origin/main refs/heads/feat/x
check "branch equal to origin/main does not run" "$r" no 0

# Neither origin/main nor main (a worktree on a detached HEAD, a repo whose default branch has another name): working tree only.
r=$(new_repo no-main)
git_in "$r" branch -q -m trunk
check "no main, clean tree does not run" "$r" no 0
echo 'let a = 2' >"$r/App/A.swift"
check "no main, uncommitted edit runs" "$r" yes 0

# An origin/main with unrelated history has no merge-base: the hook falls back to local main, then to the working tree.
other=$(new_repo other-history)
r=$(new_repo no-merge-base)
git_in "$r" fetch -q "$other" main:refs/remotes/origin/main
commit_on_branch "$r" App/B.swift 'let b = 2'
check "no merge-base with origin/main, local main: committed change runs" "$r" yes 0

r=$(new_repo no-merge-base-no-main)
git_in "$r" fetch -q "$other" main:refs/remotes/origin/main
git_in "$r" branch -q -m trunk
check "no merge-base, no main: clean tree does not run" "$r" no 0
echo 'let a = 2' >"$r/App/A.swift"
check "no merge-base, no main: uncommitted edit runs" "$r" yes 0

# A repo without any commit does not crash the hook.
r="$tmp/empty"; git init -q -b main "$r"
printf 'lint test:\n\t@touch ran\n' >"$r/Makefile"
mkdir "$r/App"; echo 'let a = 1' >"$r/App/A.swift"
check "repo without commits, untracked Swift runs" "$r" yes 0

# A failure exits 2 with the tail of the output.
r=$(new_repo failing 1); with_origin "$r"
commit_on_branch "$r" App/B.swift 'let b = 2'
check "failing checks exit 2" "$r" yes 2
if ! grep -q 'make lint test failed' "$tmp/err"; then
  echo "FAIL failing checks: no failure report on stderr"
  failed=1
fi

# stop_hook_active prevents a loop: the checks do not run again.
check "stop_hook_active skips the checks" "$r" no 0 '{"stop_hook_active": true}'

# Not a git repo, no Makefile: nothing to do.
r="$tmp/plain"; mkdir -p "$r/App"
check "no Makefile does not run" "$r" no 0

if [[ "$failed" -eq 0 ]]; then
  echo "all $n cases passed"
fi
exit "$failed"
