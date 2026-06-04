DEVICE ?=
ANDROID_DEVICE ?= android

.PHONY: build-engine build-engine-android build-engine-ios-simulator devices dev dev-android dev-ios-simulator dev-macos

build-engine:
	./scripts/build_engine.sh macos

build-engine-android:
	./scripts/build_engine.sh android-arm64

build-engine-ios-simulator:
	./scripts/build_engine.sh ios-simulator

devices:
	cd frontend && flutter devices

dev:
	./scripts/dev.sh "$(DEVICE)"

dev-macos:
	./scripts/dev.sh macos

dev-ios-simulator:
	./scripts/dev.sh "$(DEVICE)"

dev-android:
	./scripts/build_engine.sh android-arm64
	cd frontend && flutter run -d "$(ANDROID_DEVICE)"
