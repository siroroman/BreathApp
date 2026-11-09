#!/usr/bin/env bash
# Tests scripts/check-context-size.sh against throwaway repos (rules: docs/agents/tokens.md).
# Usage: test-check-context-size.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

# case_ <expected exit> <description> <CLAUDE.md size> <skill description length> <agent description length>
case_() {
  local want=$1 desc=$2 claude=$3 skill=$4 agent=$5 got
  rm -rf "$tmp/r" && mkdir -p "$tmp/r/.claude/skills/s" "$tmp/r/.claude/agents"
  head -c "$claude" /dev/zero | tr '\0' 'x' >"$tmp/r/CLAUDE.md"
  printf -- '---\nname: s\ndescription: %s\n---\nbody\n' "$(head -c "$skill" /dev/zero | tr '\0' 'x')" >"$tmp/r/.claude/skills/s/SKILL.md"
  printf -- '---\nname: a\ndescription: %s\nmodel: sonnet\n---\nbody\n' "$(head -c "$agent" /dev/zero | tr '\0' 'x')" >"$tmp/r/.claude/agents/a.md"
  "$root/scripts/check-context-size.sh" "$tmp/r" >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

case_ 0 "everything at its budget" 3000 700 700
case_ 1 "CLAUDE.md one byte over" 3001 100 100
case_ 1 "skill description one character over" 100 701 100
case_ 1 "agent description one character over" 100 100 701

if ! "$root/scripts/check-context-size.sh" "$root" >/dev/null 2>&1; then
  echo "FAIL: this repository is over a budget"
  failed=1
fi

[[ "$failed" -eq 0 ]] && echo "check-context-size: all cases pass"
exit "$failed"
