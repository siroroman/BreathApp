#!/usr/bin/env bash
# Tests scripts/check-architecture.sh against throwaway trees (rules: docs/agents/ios.md, Conventions).
# Usage: test-check-architecture.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

# fixture: a clean tree. Each case then changes one file.
fixture() {
  rm -rf "$tmp/repo" && mkdir -p "$tmp/repo/BreathnestKit/Sources/BreathnestKit" && cd "$tmp/repo" || exit 1
  printf 'import Foundation\nimport Synchronization\n\npublic struct A {}\n' >BreathnestKit/Sources/BreathnestKit/A.swift
  cat >BreathnestKit/Package.swift <<'EOF'
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BreathnestKit",
    products: [.library(name: "BreathnestKit", targets: ["BreathnestKit"])],
    targets: [.target(name: "BreathnestKit")]
)
EOF
  cat >project.yml <<'EOF'
name: Breathnest
packages:
  BreathnestKit:
    path: BreathnestKit
targets:
  Breathnest:
    type: application
EOF
}

# case_ <expected exit> <description>: runs the check on the fixture as the case left it.
case_() {
  local want=$1 desc=$2 got
  "$root/scripts/check-architecture.sh" "$tmp/repo" >"$tmp/out" 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

fixture
case_ 0 "clean tree"

for framework in UIKit SwiftUI CoreHaptics AVFoundation Combine WatchKit; do
  fixture
  printf 'import %s\n' "$framework" >>BreathnestKit/Sources/BreathnestKit/A.swift
  case_ 1 "Kit imports $framework"
done

fixture
printf 'public import Foundation\ninternal import UIKit\n' >>BreathnestKit/Sources/BreathnestKit/A.swift
case_ 1 "Kit imports UIKit with an access modifier"

fixture
printf 'import struct Foundation.URL\n' >>BreathnestKit/Sources/BreathnestKit/A.swift
case_ 0 "Kit imports one declaration of Foundation"

fixture
printf 'import SwiftUI\n' >BreathnestKit/Sources/BreathnestKit/A.swift
mkdir -p BreathnestKit/Sources/BreathnestKit/Deep && printf 'import Foundation\n' >BreathnestKit/Sources/BreathnestKit/Deep/B.swift
case_ 1 "forbidden import next to a clean file in a subfolder"

fixture
mkdir -p BreathnestKit/Tests/BreathnestKitTests && printf 'import Testing\nimport SwiftUI\n' >BreathnestKit/Tests/BreathnestKitTests/ATests.swift
case_ 0 "Kit tests may import what they need"

fixture
printf '// import UIKit\n' >>BreathnestKit/Sources/BreathnestKit/A.swift
case_ 0 "import in a comment"

fixture
sed -i.bak 's|    targets: \[|    dependencies: [.package(url: "https://github.com/x/y", from: "1.0.0")],\n    targets: [|' BreathnestKit/Package.swift && rm BreathnestKit/Package.swift.bak
case_ 1 "Package.swift declares a dependency"

fixture
sed -i.bak 's|^targets:|  Alamofire:\n    url: https://github.com/Alamofire/Alamofire\n    from: 5.0.0\ntargets:|' project.yml && rm project.yml.bak
case_ 1 "project.yml adds a third-party package"

fixture
sed -i.bak 's|^targets:|  Local:\n    path: ../Local\ntargets:|' project.yml && rm project.yml.bak
case_ 1 "project.yml adds a second local package"

fixture
rm project.yml
case_ 1 "project.yml is missing"

fixture
rm BreathnestKit/Package.swift
case_ 1 "Package.swift is missing"

fixture
rm -rf BreathnestKit/Sources
case_ 1 "no Kit sources"

fixture
printf 'import UIKit\n' >>BreathnestKit/Sources/BreathnestKit/A.swift
case_ 1 "failure message"
if ! grep -q 'docs/agents/ios.md' "$tmp/out" || ! grep -q 'ADR' "$tmp/out"; then
  echo "FAIL: the message should name docs/agents/ios.md and the ADR"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all check-architecture cases passed"; fi
exit $failed
