.PHONY: build-engine build-engine-android dev dev-android dev-macos

build-engine:
	./scripts/build_engine.sh macos

build-engine-android:
	./scripts/build_engine.sh android-arm64

dev:
	./scripts/dev.sh macos

dev-macos:
	./scripts/dev.sh macos

dev-android:
	./scripts/dev.sh android
