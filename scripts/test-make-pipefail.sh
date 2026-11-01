#!/usr/bin/env bash
# Tests that a failing command in a pipe fails a make recipe, as in `xcodebuild ... | xcbeautify` (docs/agents/commands.md).
# macOS ships GNU Make 3.81, which ignores `.SHELLFLAGS`, so CI runs this on a macOS runner.
# Usage: test-make-pipefail.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
printf 'probe-fail:\n\tfalse | cat\nprobe-pass:\n\ttrue | cat\n' > "$tmp/probe.mk"
failed=0

# want <0: make must succeed | 1: make must fail> <target>
want() {
  make -s -C "$root" -f Makefile -f "$tmp/probe.mk" "$2" >/dev/null 2>&1
  local got=$?
  if { [[ "$1" -eq 0 ]] && [[ "$got" -ne 0 ]]; } || { [[ "$1" -ne 0 ]] && [[ "$got" -eq 0 ]]; }; then
    printf 'FAIL (want %s, make exited %s): %s\n' "$1" "$got" "$2"
    failed=1
  fi
}

want 0 probe-pass
want 1 probe-fail

[[ "$failed" -eq 0 ]] && echo "all make pipefail cases passed"
exit "$failed"
