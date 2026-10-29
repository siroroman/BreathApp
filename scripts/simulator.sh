#!/usr/bin/env bash
# Prints the UDID of this checkout's simulator, creating it on first use and booting it when asked.
#   scripts/simulator.sh          print the UDID
#   scripts/simulator.sh boot     print the UDID after booting the simulator
#
# A base simulator named "Breathnest" (iPhone 17 Pro, iOS 26.2) is the template. Every other worktree
# gets a clone named "Breathnest-<worktree folder>", so parallel sessions never share a running device.
# The main checkout uses the base simulator itself. Details: docs/agents/ios.md
set -euo pipefail

DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-2"
BASE_NAME="Breathnest"

ROOT=$(git rev-parse --show-toplevel)
if [ "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)" ]; then
  NAME=$BASE_NAME
else
  NAME="$BASE_NAME-$(basename "$ROOT")"
fi

# Prints the UDID of the simulator called $1 on $RUNTIME, or nothing.
find_udid() {
  xcrun simctl list devices --json | jq -r --arg rt "$RUNTIME" --arg name "$1" \
    '.devices[$rt] // [] | map(select(.name == $name and .isAvailable)) | first | .udid // empty'
}

UDID=$(find_udid "$NAME")
if [ -z "$UDID" ]; then
  BASE=$(find_udid "$BASE_NAME")
  if [ -z "$BASE" ]; then
    BASE=$(xcrun simctl create "$BASE_NAME" "$DEVICE_TYPE" "$RUNTIME")
  fi
  if [ "$NAME" = "$BASE_NAME" ]; then
    UDID=$BASE
  else
    # simctl clone needs the template shut down.
    xcrun simctl shutdown "$BASE" 2>/dev/null || true
    UDID=$(xcrun simctl clone "$BASE" "$NAME")
  fi
fi

if [ "${1:-}" = boot ]; then
  xcrun simctl boot "$UDID" 2>/dev/null || true # already booted is fine
  xcrun simctl bootstatus "$UDID" -b >&2
fi

echo "$UDID"
