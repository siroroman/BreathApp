#!/usr/bin/env bash
# Tests scripts/check-guardrail-paths.sh against a throwaway repository (rules: docs/agents/guardrail-paths.md).
# Usage: test-check-guardrail-paths.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

git init -q -b main "$tmp/repo"
cd "$tmp/repo" || exit 1
git config user.email t@example.com
git config user.name t
mkdir -p docs/agents
cp "$root/docs/agents/guardrail-paths.md" docs/agents/
printf 'base\n' >README.md
git add -A && git commit -qm base
git update-ref refs/remotes/origin/main HEAD

said='**Guardrails touched:** `pre-push` also runs the app tests, stricter.'

# case <expected exit> <description> <PR body> <files to change...>: each case starts from main.
case_() {
  local want=$1 desc=$2 pr_body=$3 f got
  shift 3
  git checkout -q -B work origin/main
  for f in "$@"; do mkdir -p "$(dirname "$f")"; printf 'change %s\n' "$RANDOM" >"$f"; done
  git add -A && git commit -qm change
  PR_BODY="$pr_body" "$root/scripts/check-guardrail-paths.sh" origin/main >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

case_ 0 "no guardrail path" "## Summary" README.md App/Breathnest/ContentView.swift
case_ 1 "hook changed, body silent" "## Summary" .githooks/pre-push
case_ 0 "hook changed, body says what" $'## Merge Danger\n\n'"$said" .githooks/pre-push
case_ 1 "workflow changed, line says none" $'**Guardrails touched:** none.' .github/workflows/ci.yml
case_ 1 "line with no text" $'**Guardrails touched:**   \n' .claude/settings.json
case_ 1 "line only inside an HTML comment" $'<!-- **Guardrails touched:** x -->' .claude/hooks/stop-check.sh
case_ 0 "line with CRLF" $'## Merge Danger\r\n'"$said"$'\r\n' .claude/agents/improver.md
case_ 1 "check script changed" "## Summary" scripts/check-pr-body.sh
case_ 1 "test script changed" "## Summary" scripts/test-check-pr-body.sh
case_ 0 "other script is no guardrail" "## Summary" scripts/simulator.sh
case_ 1 "Makefile changed" "## Summary" Makefile
case_ 1 "lint config changed" "## Summary" .swiftformat
case_ 1 "critical paths registry changed" "## Summary" docs/agents/critical-paths.md
case_ 1 "registry emptied, globs on main still count" "## Summary" docs/agents/guardrail-paths.md .githooks/pre-push
case_ 0 "other agent doc is no guardrail" "## Summary" docs/agents/git.md

git checkout -q -B work origin/main
if "$root/scripts/check-guardrail-paths.sh" no-such-ref >/dev/null 2>&1; then
  echo "FAIL: unknown base should exit 1"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all check-guardrail-paths cases passed"; fi
exit $failed
