#!/usr/bin/env bash
# PostToolUse hook: when the session context reaches 15% of the window, tells the agent to save progress and stop.
# The size of an assistant message is its input + cache creation + cache read tokens. What counts is the growth:
# the last message's size minus the first one's (the fixed startup cost: system prompt, tools, CLAUDE.md).
# BREATHNEST_CONTEXT_WINDOW is the window in tokens (default 200000, set 1000000 for a 1M model).
# It never fails a tool call: it exits 0 and only adds context. Rules: docs/agents/workflow.md (Context limit).
# Tested by scripts/test-context-check.sh.
set -uo pipefail

command -v jq >/dev/null || exit 0
path=$(jq -r '.transcript_path // empty' 2>/dev/null) || exit 0
[ -n "$path" ] && [ -f "$path" ] || exit 0

window=${BREATHNEST_CONTEXT_WINDOW:-200000}
case $window in '' | *[!0-9]*) window=200000 ;; esac
limit=$((window * 15 / 100))

size='select(.type == "assistant" and .message.usage != null)
  | .message.usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)'
latest=$(tail -n 200 "$path" | jq -r "$size" 2>/dev/null | tail -n 1)
baseline=$(jq -rn "first(inputs | $size)" "$path" 2>/dev/null)
case $latest in '' | *[!0-9]*) exit 0 ;; esac
case $baseline in '' | *[!0-9]*) baseline=0 ;; esac
used=$((latest - baseline))
[ "$used" -ge "$limit" ] || exit 0

msg="Context limit: this session grew by $used tokens since its start (baseline $baseline), over 15% of the window ($limit of $window). Stop new work now. 1. Post the handoff as a comment on the ticket (branch, done, next, open questions, commands to resume). 2. Commit what builds. 3. End your turn and tell the user to run /clear and restart from the ticket; an AFK subagent ends its run with the handoff as its report. Do not compact."
jq -n --arg m "$msg" '{systemMessage: $m, hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $m}}'
