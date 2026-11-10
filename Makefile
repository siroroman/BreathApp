# One command per check. Output of xcodebuild goes through xcbeautify. Details: docs/agents/commands.md
# `-o pipefail` sits in SHELL because macOS ships GNU Make 3.81, which ignores .SHELLFLAGS. Without it
# `xcodebuild ... | xcbeautify` returns the exit code of xcbeautify and a failed build or test passes.
SHELL := /bin/bash -o pipefail
.SHELLFLAGS := -ec
# The swiftformat and swiftlint pinned in tools.env (scripts/install-tools.sh) win over any other install.
export PATH := $(CURDIR)/.tools/bin:$(PATH)

SCHEME := Breathnest
UI_SCHEME := BreathnestUI
BUNDLE_ID := com.siroroman.breathnest
BUILD_DIR := build
# $(call XCODEBUILD,<scheme>): the scheme `Breathnest` runs the app tests, `BreathnestUI` the UI tests.
XCODEBUILD = xcodebuild -project Breathnest.xcodeproj -scheme $(1) -derivedDataPath $(BUILD_DIR) \
	-destination "platform=iOS Simulator,id=$$(scripts/simulator.sh)"
APP := $(BUILD_DIR)/Build/Products/Debug-iphonesimulator/Breathnest.app
SWIFT_DIRS := App BreathnestKit/Sources BreathnestKit/Tests

.PHONY: setup gen build test test-kit test-app test-ui test-catalogs coverage lint format run screenshot sim

setup: ## Once per clone: turn on the git hooks, check the tools
	@scripts/setup.sh

# The signing team comes from the environment or from local.env (git-ignored, one line `DEVELOPMENT_TEAM=XXXXXXXXXX`).
# project.yml reads it, so it is always exported, empty when unset (CI has no team). The variable wins over the file.
LOCAL_TEAM := $(shell sed -nE 's/^DEVELOPMENT_TEAM=(.*)$$/\1/p' local.env 2>/dev/null)
export DEVELOPMENT_TEAM ?= $(LOCAL_TEAM)

gen: ## Generate Breathnest.xcodeproj from project.yml, with the signing team of local.env
	xcodegen generate --quiet

build: gen ## Build the app for the simulator
	$(call XCODEBUILD,$(SCHEME)) build | xcbeautify --quiet

test: test-kit test-app test-catalogs ## Run all tests

test-kit: ## Kit tests with `swift test`, no simulator
	cd BreathnestKit && swift test --quiet

test-app: gen ## App tests on the simulator
	$(call XCODEBUILD,$(SCHEME)) test | xcbeautify --quiet

test-ui: gen ## UI tests (smoke test and accessibility audit) on the simulator, not part of `make test`
	$(call XCODEBUILD,$(UI_SCHEME)) test | xcbeautify --quiet

test-catalogs: ## Check the String Catalog (comments, review state, translations, plural categories), no simulator
	scripts/check-catalogs.sh

coverage: ## Kit tests with line coverage per source file and in total, no simulator
	scripts/coverage.sh

lint: ## Check the tool versions, formatting and the repo rules, changes nothing
	scripts/check-tools.sh
	swiftformat $(SWIFT_DIRS) --lint
	swiftlint lint --strict --quiet || { echo "A Swift convention is broken, see docs/agents/ios.md (Conventions) and docs/agents/testing.md (Time)" >&2; exit 1; }
	scripts/check-workflows.sh
	scripts/check-docs.sh
	scripts/check-context-size.sh
	scripts/check-architecture.sh
	scripts/check-catalogs.sh

format: ## Format the Swift sources in place
	swiftformat $(SWIFT_DIRS)

run: build ## Install and launch the app on the simulator
	scripts/simulator.sh boot >/dev/null
	xcrun simctl install "$$(scripts/simulator.sh)" $(APP)
	xcrun simctl launch "$$(scripts/simulator.sh)" $(BUNDLE_ID)

screenshot: ## Save the simulator screen to build/screenshot.png
	mkdir -p $(BUILD_DIR)
	xcrun simctl io "$$(scripts/simulator.sh)" screenshot $(BUILD_DIR)/screenshot.png

sim: ## Print this checkout's simulator UDID, creating it if needed
	@scripts/simulator.sh
