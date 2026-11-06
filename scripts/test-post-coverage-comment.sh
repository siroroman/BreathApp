#!/usr/bin/env bash
# Tests scripts/post-coverage-comment.sh with a fake `gh` that records its calls (rules: docs/agents/testing.md, Coverage).
# Usage: test-post-coverage-comment.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

# The fake gh: `gh api --paginate ...` prints the comments of $FAKE_COMMENTS, any other call is logged with the body file it got.
mkdir "$tmp/bin"
cat > "$tmp/bin/gh" <<'FAKE'
#!/usr/bin/env bash
if [[ " $* " == *" --paginate "* ]]; then cat "$FAKE_COMMENTS"; exit 0; fi
echo "gh $*" >> "$FAKE_LOG"
for arg in "$@"; do
  if [[ "$arg" == body=@* ]]; then sed 's/^/  body: /' "${arg#body=@}" >> "$FAKE_LOG"; fi
done
FAKE
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" FAKE_LOG="$tmp/log" FAKE_COMMENTS="$tmp/comments.json"

printf '### Kit line coverage\nTOTAL 100.00%%\n' > "$tmp/table.md"

# run_ <comments json> <args...>: runs the script, leaves the exit code in $got and the recorded calls in $tmp/log.
run_() {
  printf '%s\n' "$1" > "$FAKE_COMMENTS"
  shift
  : > "$FAKE_LOG"
  "$root/scripts/post-coverage-comment.sh" "$@" > "$tmp/out" 2>&1
  got=$?
}
# expect_ <description> <fixed string that must be in the log>, reject_ <description> <string that must not be>
expect_() { if ! grep -qF -- "$2" "$FAKE_LOG"; then printf 'FAIL: %s\n  missing: %s\n' "$1" "$2"; failed=1; fi; }
reject_() { if grep -qF -- "$2" "$FAKE_LOG"; then printf 'FAIL: %s\n  unexpected: %s\n' "$1" "$2"; failed=1; fi; }
code_() { if [[ "$got" -ne "$1" ]]; then printf 'FAIL (want exit %s, got %s): %s\n' "$1" "$got" "$2"; failed=1; fi; }

run_ '[{"id":1,"user":{"login":"someone"},"body":"looks good"}]' o/r 7 "$tmp/table.md"
code_ 0 "no coverage comment yet"
expect_ "posts a new comment on the pull request" "gh api --method POST repos/o/r/issues/7/comments"
expect_ "the body starts with the marker" "  body: <!-- kit-coverage -->"
expect_ "the body carries the table" "  body: TOTAL 100.00%"
reject_ "does not patch anything" "PATCH"

run_ '[{"id":1,"user":{"login":"someone"},"body":"looks good"},{"id":42,"user":{"login":"github-actions[bot]"},"body":"<!-- kit-coverage -->\nold"}]' o/r 7 "$tmp/table.md"
code_ 0 "an earlier coverage comment exists"
expect_ "updates that comment" "gh api --method PATCH repos/o/r/issues/comments/42"
reject_ "does not post a second comment" "POST"

run_ '[{"id":5,"user":{"login":"someone"},"body":"<!-- kit-coverage --> pasted by a person"}]' o/r 7 "$tmp/table.md"
code_ 0 "a person quotes the marker"
expect_ "ignores a comment of another author and posts its own" "gh api --method POST repos/o/r/issues/7/comments"
reject_ "never edits a comment of a person" "PATCH"

run_ '[]' o/r 7 "$tmp/missing.md"
code_ 1 "markdown file does not exist"
run_ '[]' o/r seven "$tmp/table.md"
code_ 2 "pull request number is not a number"
run_ '[]' o/r
code_ 2 "arguments are missing"

if [[ $failed -eq 0 ]]; then echo "all post-coverage-comment cases passed"; fi
exit $failed
