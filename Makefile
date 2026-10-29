# One command per check. Output of xcodebuild goes through xcbeautify. Details: docs/agents/commands.md
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -ec

SCHEME := Breathnest
BUNDLE_ID := com.siroroman.breathnest
BUILD_DIR := build
XCODEBUILD := xcodebuild -project Breathnest.xcodeproj -scheme $(SCHEME) -derivedDataPath $(BUILD_DIR) \
	-destination "platform=iOS Simulator,id=$$(scripts/simulator.sh)"
APP := $(BUILD_DIR)/Build/Products/Debug-iphonesimulator/Breathnest.app
SWIFT_DIRS := App BreathnestKit/Sources BreathnestKit/Tests

.PHONY: gen build test test-kit test-app lint format run screenshot sim

gen: ## Generate Breathnest.xcodeproj from project.yml
	xcodegen generate --quiet

build: gen ## Build the app for the simulator
	$(XCODEBUILD) build | xcbeautify --quiet

test: test-kit test-app ## Run all tests

test-kit: ## Kit tests with `swift test`, no simulator
	cd BreathnestKit && swift test --quiet

test-app: gen ## App tests on the simulator
	$(XCODEBUILD) test | xcbeautify --quiet

lint: ## Check formatting, changes nothing
	swiftformat $(SWIFT_DIRS) --lint

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
