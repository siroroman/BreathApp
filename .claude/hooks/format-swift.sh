#!/usr/bin/env bash
# PostToolUse hook for Edit and Write: runs swiftformat on the Swift file that was just changed.
# Config: .swiftformat. Never blocks: formatting is a convenience, `make lint` is the check.
set -uo pipefail

command -v jq >/dev/null && command -v swiftformat >/dev/null || exit 0
FILE=$(jq -r '.tool_input.file_path // empty') || exit 0
case "$FILE" in
  *.swift) [ -f "$FILE" ] && swiftformat --quiet "$FILE" >/dev/null 2>&1 ;;
esac
exit 0
