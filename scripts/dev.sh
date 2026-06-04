#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="${1:-}"

"$ROOT_DIR/scripts/build_engine.sh" macos
"$ROOT_DIR/scripts/build_engine.sh" ios-simulator

cd "$ROOT_DIR/frontend"
if [[ "$DEVICE" != "" ]]; then
	flutter run -d "$DEVICE"
else
	flutter run
fi
