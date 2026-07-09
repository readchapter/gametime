#!/usr/bin/env bash
# Fetch the Godot binary from the engine-bin branch and unpack it to engine/.
# Idempotent: exits fast if the engine is already unpacked and runnable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_DIR="$ROOT/engine"
GODOT="$ENGINE_DIR/godot"

if [ -x "$GODOT" ]; then
    echo "Engine already present: $("$GODOT" --version)"
    exit 0
fi

echo "Fetching engine-bin branch..."
git -C "$ROOT" fetch origin engine-bin

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git -C "$ROOT" archive FETCH_HEAD | tar -x -C "$TMP"

mkdir -p "$ENGINE_DIR"
unzip -q -o "$TMP/godot_linux.zip" -d "$ENGINE_DIR"
cp "$TMP/ENGINE_VERSION" "$ENGINE_DIR/ENGINE_VERSION"

BIN="$(find "$ENGINE_DIR" -maxdepth 1 -name 'Godot_v*_linux.x86_64' | head -1)"
[ -n "$BIN" ] || { echo "No Godot binary found in zip" >&2; exit 1; }
mv "$BIN" "$GODOT"
chmod +x "$GODOT"

echo "Godot $(cat "$ENGINE_DIR/ENGINE_VERSION") installed at engine/godot"
"$GODOT" --version
