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

# run <transcript path> [window] [agent id]: leaves stdout in $tmp/out, prints the exit code.
# With an agent id the input is a subagent's tool call: transcript_path is still the parent's.
run() {
  local agent=""
  [ -n "${3:-}" ] && agent=",\"agent_id\":\"$3\""
  printf '{"transcript_path":"%s","hook_event_name":"PostToolUse"%s}' "$1" "$agent" \
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

# grown <name> <baseline> <latest> [filler lines]: the first assistant entry has <baseline> tokens, the last <latest>.
grown() {
  {
    echo '{"type":"user","message":{"role":"user","content":"hi"}}'
    printf '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":%s,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}\n' "$2"
    for _ in $(seq 1 "${4:-0}"); do echo '{"type":"user","message":{"role":"user","content":"tool result"}}'; done
    printf '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":%s,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}\n' "$3"
  } >"$tmp/$1.jsonl"
}

# The startup cost (system prompt, tools, CLAUDE.md) is the baseline; only the growth above it counts.
grown fresh 75000 80000
run "$tmp/fresh.jsonl" 200000 >/dev/null
check "a fresh session with a 75000 baseline and 5000 of work is silent" silent

grown worked 75000 105000
run "$tmp/worked.jsonl" 200000 >/dev/null
check "30000 of growth above the baseline injects" injects
check "the message reports growth, baseline and limit" sh -c "jq -r '.hookSpecificOutput.additionalContext' '$tmp/out' | grep -q '30000 tokens since its start (baseline 75000)'"

grown long 75000 105000 500
run "$tmp/long.jsonl" 200000 >/dev/null
check "the baseline is found beyond the lines read for the latest usage" injects

# A line that is not JSON before the first usage entry must not hide the baseline.
{
  echo 'not json'
  echo '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":75000}}}'
  echo '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":105000}}}'
} >"$tmp/malformed.jsonl"
run "$tmp/malformed.jsonl" 200000 >/dev/null
check "a malformed line before the first usage entry keeps the baseline (30000 of growth injects)" injects

grown quiet 75000 80000 500
run "$tmp/quiet.jsonl" 200000 >/dev/null
check "75000 to 80000 with 500 filler lines is silent" silent

grown compacted 105000 40000
run "$tmp/compacted.jsonl" 200000 >/dev/null
check "negative growth after compaction is silent" silent

# A subagent's own transcript lives in <session>/subagents/agent-<id>.jsonl next to the parent's <session>.jsonl.
grown parent 78000 120000
mkdir -p "$tmp/parent/subagents"
grown sub_small 16000 18000
mv "$tmp/sub_small.jsonl" "$tmp/parent/subagents/agent-small.jsonl"
run "$tmp/parent.jsonl" 200000 small >/dev/null
check "a subagent that grew 2000 is silent although its parent grew 42000" silent

run "$tmp/parent.jsonl" 200000 >/dev/null
check "the parent itself, without agent_id, still injects" injects

grown sub_big 16000 46000
mv "$tmp/sub_big.jsonl" "$tmp/parent/subagents/agent-big.jsonl"
run "$tmp/parent.jsonl" 200000 big >/dev/null
check "a subagent that itself grew 30000 injects" injects
check "the message reports the subagent's growth and baseline" sh -c "jq -r '.hookSpecificOutput.additionalContext' '$tmp/out' | grep -q '30000 tokens since its start (baseline 16000)'"

code=$(run "$tmp/parent.jsonl" 200000 nosuch)
check "a subagent without a transcript file exits 0" test "$code" = 0
check "a subagent without a transcript file is silent, the parent is not measured for it" silent

# Autonomous mode (an AFK subagent, or BREATHNEST_AFK=1): nobody can run /clear, so the message must not ask for it.
autonomous() { ! message | grep -q '/clear' && ! message | grep -qi 'tell the user' && message | grep -q 'handoff' && message | grep -qi 'end your run'; }
grown afk 75000 105000
printf '{"transcript_path":"%s"}' "$tmp/afk.jsonl" | BREATHNEST_AFK=1 "$hook" >"$tmp/out" 2>/dev/null
check "BREATHNEST_AFK=1 still injects at the limit" injects
check "BREATHNEST_AFK=1 message has no /clear and ends the run with the handoff" autonomous

run "$tmp/parent.jsonl" 200000 big >/dev/null
check "a subagent message (agent_id) is the autonomous one" autonomous

run "$tmp/parent.jsonl" 200000 >/dev/null
check "the interactive message still asks for /clear" names_save_and_stop
check "the interactive message offers scripts/afk-run.sh for an unattended restart" sh -c "jq -r '.hookSpecificOutput.additionalContext' '$tmp/out' | grep -q 'scripts/afk-run.sh'"

printf '{"transcript_path":"%s"}' "$tmp/fresh.jsonl" | BREATHNEST_AFK=1 "$hook" >"$tmp/out" 2>/dev/null
check "BREATHNEST_AFK=1 under the limit is silent" silent

echo '{"type":"user"}' >"$tmp/nousage.jsonl"
run "$tmp/nousage.jsonl" 200000 >/dev/null
check "a transcript without usage is silent" silent

exit "$failed"
