#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-macos}"

build_macos() {
	mkdir -p "$ROOT_DIR/frontend/macos/Runner"

	cd "$ROOT_DIR/backend"
	go build -buildmode=c-shared -o "$ROOT_DIR/frontend/macos/Runner/libambrosia_engine.dylib" .
}

find_android_ndk() {
	if [[ "${ANDROID_NDK_HOME:-}" != "" ]]; then
		printf '%s\n' "$ANDROID_NDK_HOME"
		return
	fi
	if [[ "${ANDROID_HOME:-}" != "" && -d "$ANDROID_HOME/ndk" ]]; then
		find "$ANDROID_HOME/ndk" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1
		return
	fi

	return 1
}

build_android_arm64() {
	local ndk_dir
	ndk_dir="$(find_android_ndk)"

	local clang_path="$ndk_dir/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android24-clang"
	if [[ ! -x "$clang_path" ]]; then
		printf 'build_android_arm64: missing Android clang at %s\n' "$clang_path" >&2
		return 1
	fi

	mkdir -p "$ROOT_DIR/frontend/android/app/src/main/jniLibs/arm64-v8a"

	cd "$ROOT_DIR/backend"
	CGO_ENABLED=1 GOOS=android GOARCH=arm64 CC="$clang_path" go build -buildmode=c-shared -o "$ROOT_DIR/frontend/android/app/src/main/jniLibs/arm64-v8a/libambrosia_engine.so" .
}

case "$TARGET" in
	macos)
		build_macos
		;;
	android | android-arm64)
		build_android_arm64
		;;
	*)
		printf 'build_engine: unsupported target %s\n' "$TARGET" >&2
		exit 1
		;;
esac
