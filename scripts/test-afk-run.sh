#!/usr/bin/env bash
# Tests scripts/afk-run.sh (rules: docs/agents/workflow.md, Context limit).
# gh and claude are stubs (GH_BIN, CLAUDE_BIN): the stub claude counts its runs and may "open a PR" on a given round.
# Usage: test-afk-run.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
script="$root/scripts/afk-run.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0
n=0

# The stub gh answers from files in $tmp: prs.json (open pull requests), labels (one per line).
cat >"$tmp/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "pr list") cat "$STUB_DIR/prs.json" ;;
  "issue view") jq -Rn '{labels: [inputs | {name: .}]}' <"$STUB_DIR/labels" ;;
esac
STUB
# The stub claude records its prompt and environment; PR_ON_ROUND makes it open a PR on that round.
cat >"$tmp/claude" <<'STUB'
#!/usr/bin/env bash
c=$(($(cat "$STUB_DIR/rounds" 2>/dev/null || echo 0) + 1))
echo "$c" >"$STUB_DIR/rounds"
echo "afk=${BREATHNEST_AFK:-} args=$*" >>"$STUB_DIR/calls"
if [ "$c" = "${PR_ON_ROUND:-0}" ]; then echo '[{"number":9,"body":"Body\n\nCloses #42"}]' >"$STUB_DIR/prs.json"; fi
exit "${CLAUDE_EXIT:-0}"
STUB
chmod +x "$tmp/gh" "$tmp/claude"

# run <args...>: fresh stub state, prints the exit code. Set PR_ON_ROUND / CLAUDE_EXIT / LABELS / PRS before.
run() {
  rm -f "$tmp/rounds" "$tmp/calls"
  : "${CLAUDE_FLAGS=--permission-mode acceptEdits}"
  echo "${PRS:-[]}" >"$tmp/prs.json"
  printf '%s' "${LABELS:-}" >"$tmp/labels"
  STUB_DIR="$tmp" CLAUDE_FLAGS="${CLAUDE_FLAGS-}" GH_BIN="$tmp/gh" CLAUDE_BIN="$tmp/claude" "$script" "$@" >"$tmp/out" 2>&1
  echo $?
}
rounds() { cat "$tmp/rounds" 2>/dev/null || echo 0; }

check() {
  local name=$1
  shift
  n=$((n + 1))
  if "$@"; then echo "ok $n $name"; else echo "not ok $n $name"; failed=1; fi
}

code=$(run)
check "no issue number is a usage error (2)" test "$code" = 2
code=$(run abc)
check "a non-numeric issue is a usage error (2)" test "$code" = 2
code=$(run 42 --max-rounds 0)
check "--max-rounds 0 is a usage error (2)" test "$code" = 2
code=$(run 42 --bogus)
check "an unknown option is a usage error (2)" test "$code" = 2

code=$(PR_ON_ROUND=2 run 42)
check "stops with 0 once a draft PR closing the issue exists" test "$code" = 0
check "it took two rounds" test "$(rounds)" = 2
check "every round runs the implementer with BREATHNEST_AFK=1" sh -c "[ \$(grep -c 'afk=1 args=.*--agent implementer' '$tmp/calls') = 2 ]"
check "the prompt names the issue and the handoff comment" sh -c "grep -q '#42' '$tmp/calls' && grep -qi 'handoff' '$tmp/calls'"

code=$(run 42)
check "no PR after the default 3 rounds exits 1" test "$code" = 1
check "the default is 3 rounds" test "$(rounds)" = 3
check "the failure names the ticket" grep -q '#42' "$tmp/out"

code=$(run 42 --max-rounds 5)
check "--max-rounds 5 runs 5 rounds" test "$(rounds)" = 5
code=$(AFK_MAX_ROUNDS=2 run 42)
check "AFK_MAX_ROUNDS sets the default" test "$(rounds)" = 2

code=$(PRS='[{"number":3,"body":"Closes #42"}]' run 42)
check "an open PR before the first round exits 0 without a run" sh -c "[ '$code' = 0 ] && [ \$(cat '$tmp/rounds' 2>/dev/null || echo 0) = 0 ]"

code=$(PRS='[{"number":3,"body":"Closes #420"}]' run 42 --max-rounds 1)
check "a PR closing #420 is not a PR for #42" test "$code" = 1

code=$(LABELS=$'ready-for-agent\nneeds-info' run 42)
check "needs-info on the ticket exits 3 without a run" sh -c "[ '$code' = 3 ] && [ \$(cat '$tmp/rounds' 2>/dev/null || echo 0) = 0 ]"

code=$(CLAUDE_EXIT=1 run 42 --max-rounds 2)
check "a failing claude run does not stop the loop" test "$(rounds)" = 2

CLAUDE_FLAGS="--model sonnet" run 42 --max-rounds 1 >/dev/null
check "CLAUDE_FLAGS are passed to claude" grep -q -- '--model sonnet' "$tmp/calls"

code=$(CLAUDE_FLAGS="" run 42)
check "without CLAUDE_FLAGS it refuses to start (2) and runs nothing" sh -c "[ '$code' = 2 ] && [ \$(cat '$tmp/rounds' 2>/dev/null || echo 0) = 0 ]"
check "the refusal names CLAUDE_FLAGS" grep -q CLAUDE_FLAGS "$tmp/out"

exit "$failed"
