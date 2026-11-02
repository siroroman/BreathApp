#!/usr/bin/env bash
# Tests scripts/ci-scope.sh against a throwaway repository (rules: docs/agents/commands.md, CI).
# Usage: test-ci-scope.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

git init -q -b main "$tmp/repo"
cd "$tmp/repo" || exit 1
git config user.email t@example.com
git config user.name t
printf 'base\n' >README.md
git add -A && git commit -qm base
git update-ref refs/remotes/origin/main HEAD

# case <expected output> <description> <files to change...>: each case starts from main.
case_() {
  local want=$1 desc=$2 f got
  shift 2
  git checkout -q -B work origin/main
  for f in "$@"; do mkdir -p "$(dirname "$f")"; printf 'change %s\n' "$RANDOM" >"$f"; done
  git add -A && git commit -qm change
  got=$("$root/scripts/ci-scope.sh" origin/main 2>&1)
  if [[ "$got" != "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

case_ swift=false "docs only" docs/agents/git.md README.md GLOSSARY.md
case_ swift=false "other workflow, claude config and git hooks" .github/workflows/pr-title.yml .claude/settings.json .githooks/pre-push
case_ swift=true "app source" App/Breathnest/ContentView.swift
case_ swift=true "kit source" BreathnestKit/Sources/BreathnestKit/Pacer.swift
case_ swift=true "kit tests" BreathnestKit/Tests/BreathnestKitTests/PacerTests.swift
case_ swift=true "project.yml" project.yml
case_ swift=true "Makefile" Makefile
case_ swift=true "swiftformat config" .swiftformat
case_ swift=true "swiftlint config" .swiftlint.yml
case_ swift=true "tool pins" tools.env
case_ swift=true "Brewfile" Brewfile
case_ swift=true "a script that make lint runs" scripts/check-docs.sh
case_ swift=true "the CI workflow itself" .github/workflows/ci.yml
case_ swift=true "docs next to an app change" docs/agents/ios.md App/Breathnest/ContentView.swift

git checkout -q -B work origin/main
git commit -q --allow-empty -m empty
got=$("$root/scripts/ci-scope.sh" origin/main 2>&1)
[[ "$got" == "swift=false" ]] || { printf 'FAIL (want swift=false, got %s): empty diff\n' "$got"; failed=1; }

# No base (push to main, workflow_dispatch): everything runs.
got=$("$root/scripts/ci-scope.sh" 2>&1)
[[ "$got" == "swift=true" ]] || { printf 'FAIL (want swift=true, got %s): no base\n' "$got"; failed=1; }

if "$root/scripts/ci-scope.sh" no-such-ref >/dev/null 2>&1; then
  echo "FAIL: unknown base should exit 1"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all ci-scope cases passed"; fi
exit "$failed"
