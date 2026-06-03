#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="${1:-macos}"

"$ROOT_DIR/scripts/build_engine.sh" "$DEVICE"

cd "$ROOT_DIR/frontend"
flutter run -d "$DEVICE"
