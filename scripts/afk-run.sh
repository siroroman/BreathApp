#!/usr/bin/env bash
# Implements a ticket without a human: runs the implementer agent headless, and when a run ends (for example at the
# context limit, with a handoff comment on the ticket) starts a fresh one from the ticket, up to N rounds.
# Usage: afk-run.sh <issue> [--max-rounds N]
# Env: AFK_MAX_ROUNDS (default 3), CLAUDE_BIN (default claude), GH_BIN (default gh), CLAUDE_FLAGS (extra claude flags).
# Exit: 0 a draft PR that closes the issue exists, 1 no PR after N rounds, 2 usage error, 3 the ticket needs info.
# Rules: docs/agents/workflow.md (Context limit). Tested by scripts/test-afk-run.sh.
set -uo pipefail

claude_bin=${CLAUDE_BIN:-claude}
gh_bin=${GH_BIN:-gh}
max=${AFK_MAX_ROUNDS:-3}
issue=""

usage() { echo "usage: afk-run.sh <issue> [--max-rounds N]" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case $1 in
    --max-rounds) [ $# -ge 2 ] || usage; max=$2; shift 2 ;;
    -*) usage ;;
    *) [ -z "$issue" ] || usage; issue=$1; shift ;;
  esac
done
case $issue in '' | *[!0-9]*) usage ;; esac
case $max in '' | *[!0-9]* | 0) usage ;; esac

# pr_open: succeeds when an open PR body has "Closes #<issue>" (not #<issue>0).
pr_open() {
  "$gh_bin" pr list --state open --json number,body 2>/dev/null \
    | jq -e --arg re "Closes #$issue([^0-9]|\$)" 'any(.[]; .body // "" | test($re))' >/dev/null 2>&1
}
needs_info() {
  "$gh_bin" issue view "$issue" --json labels 2>/dev/null \
    | jq -e 'any(.labels[]?; .name == "needs-info")' >/dev/null 2>&1
}

prompt="Implement #$issue end to end. Read the ticket and its latest handoff comment first and continue from it. Stop at a draft pull request that closes #$issue. If you reach the context limit, post the handoff on the ticket and end your run."

round=1
while [ "$round" -le "$max" ]; do
  if pr_open; then echo "afk-run: a draft PR for #$issue exists" >&2; exit 0; fi
  if needs_info; then echo "afk-run: #$issue is labelled needs-info, a human has to answer" >&2; exit 3; fi
  echo "afk-run: round $round of $max for #$issue" >&2
  # shellcheck disable=SC2086
  BREATHNEST_AFK=1 "$claude_bin" -p --agent implementer ${CLAUDE_FLAGS:-} "$prompt" || echo "afk-run: round $round exited non-zero" >&2
  round=$((round + 1))
done
if pr_open; then echo "afk-run: a draft PR for #$issue exists" >&2; exit 0; fi
echo "afk-run: no pull request for #$issue after $max rounds, a human has to look at the ticket" >&2
exit 1
