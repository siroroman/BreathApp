#!/usr/bin/env bash
# make setup: once per clone. Turns on the git hooks and checks the tools of docs/agents/commands.md.
# Safe to run again, also from a linked worktree (core.hooksPath is relative, so each worktree uses its own .githooks).
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

git config core.hooksPath .githooks
echo "git hooks: core.hooksPath = $(git config core.hooksPath)"

missing=()
for tool in xcodegen xcbeautify swiftformat jq; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done

xcode_major=$(xcodebuild -version 2>/dev/null | sed -nE 's/^Xcode ([0-9]+).*/\1/p')
if [[ -z "$xcode_major" ]]; then
  echo "missing: Xcode 26 or later (install it from the App Store, then xcode-select -s /Applications/Xcode.app)" >&2
  xcode_ok=0
elif [[ "$xcode_major" -lt 26 ]]; then
  echo "outdated: Xcode $xcode_major, 26 or later is needed" >&2
  xcode_ok=0
else
  xcode_ok=1
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "missing tools: ${missing[*]}" >&2
  echo "  brew install ${missing[*]}" >&2
fi
if [[ ${#missing[@]} -gt 0 || "$xcode_ok" -eq 0 ]]; then
  exit 1
fi
echo "tools: ok"
