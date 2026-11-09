#!/usr/bin/env bash
# Tests .claude/hooks/context-check.sh (rules: docs/agents/workflow.md, Context limit).
# Each case writes a small transcript whose last assistant message has a given token count.
# Usage: test-context-check.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
hook="$root/.claude/hooks/context-check.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0
n=0

# transcript <name> <input> <cache_creation> <cache_read>: a transcript whose last assistant entry has this usage.
transcript() {
  {
    echo '{"type":"user","message":{"role":"user","content":"hi"}}'
    echo '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":1,"cache_creation_input_tokens":1,"cache_read_input_tokens":1}}}'
    printf '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":9}}}\n' "$2" "$3" "$4"
    echo '{"type":"user","message":{"role":"user","content":"tool result"}}'
  } >"$tmp/$1.jsonl"
}

# run <transcript path> [window]: leaves stdout in $tmp/out, prints the exit code
run() {
  printf '{"transcript_path":"%s","hook_event_name":"PostToolUse"}' "$1" \
    | BREATHNEST_CONTEXT_WINDOW="${2:-}" "$hook" >"$tmp/out" 2>"$tmp/err"
  echo $?
}

# check <name> <command...>: passes when the command succeeds
check() {
  local name=$1
  shift
  n=$((n + 1))
  if "$@"; then echo "ok $n $name"; else echo "not ok $n $name"; failed=1; fi
}

silent() { [ ! -s "$tmp/out" ]; }
message() { jq -r '.hookSpecificOutput.additionalContext' "$tmp/out"; }
injects() { jq -e '.hookSpecificOutput.hookEventName == "PostToolUse" and (.hookSpecificOutput.additionalContext | contains("15%"))' "$tmp/out" >/dev/null; }
names_save_and_stop() { message | grep -q 'ticket' && message | grep -q '/clear'; }

# 200000 window, limit 30000 tokens.
transcript under 4 1000 20000
code=$(run "$tmp/under.jsonl" 200000)
check "under 15% stays silent, exit 0" test "$code" = 0
check "under 15% prints nothing" silent

transcript just_under 4 1000 28995
run "$tmp/just_under.jsonl" 200000 >/dev/null
check "29999 tokens is under" silent

transcript over 4 1000 29000
code=$(run "$tmp/over.jsonl" 200000)
check "at 15% the exit code is 0" test "$code" = 0
check "at 15% it injects context for the agent" injects
check "the message names the ticket comment and /clear" names_save_and_stop

run "$tmp/over.jsonl" 1000000 >/dev/null
check "the window comes from BREATHNEST_CONTEXT_WINDOW (1M: 30000 is 3%)" silent

run "$tmp/over.jsonl" >/dev/null
check "the default window is 200000" injects

code=$(run "$tmp/missing.jsonl" 200000)
check "a missing transcript exits 0" test "$code" = 0
check "a missing transcript is silent" silent

printf '{}' | "$hook" >"$tmp/out" 2>/dev/null
check "no transcript_path exits 0 and is silent" silent

echo '{"type":"user"}' >"$tmp/nousage.jsonl"
run "$tmp/nousage.jsonl" 200000 >/dev/null
check "a transcript without usage is silent" silent

exit "$failed"
