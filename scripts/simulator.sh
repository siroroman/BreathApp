#!/usr/bin/env bash
# Prints the UDID of this checkout's simulator, creating it on first use and booting it when asked.
#   scripts/simulator.sh          print the UDID
#   scripts/simulator.sh boot     print the UDID after booting the simulator
#
# The main checkout uses a simulator named "Breathnest" (iPhone 17 Pro, iOS 26.2). Every other worktree
# gets its own, named "Breathnest-<worktree folder>", so parallel sessions never share a running device.
# A device is created, never cloned: `simctl clone` needs its source shut down, which would kill the
# simulator another session is using. Details: docs/agents/ios.md
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
  UDID=$(xcrun simctl create "$NAME" "$DEVICE_TYPE" "$RUNTIME")
fi

if [ "${1:-}" = boot ]; then
  xcrun simctl boot "$UDID" 2>/dev/null || true # already booted is fine
  xcrun simctl bootstatus "$UDID" -b >&2
fi

echo "$UDID"
