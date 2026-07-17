#!/usr/bin/env bash
# Render a scene under Xvfb + llvmpipe (software GL) and save screenshots for
# visual inspection.
#
# usage: tools/capture/capture.sh <res://path/to/scene.tscn> [times] [outdir]
#   times   comma-separated seconds since scene start (default "1.0")
#   outdir  absolute output dir (default artifacts/<scene>-<hhmmss>)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCENE="${1:?usage: capture.sh <scene.tscn> [times] [outdir]}"
TIMES="${2:-1.0}"
NAME="$(basename "${SCENE%.tscn}")"
OUT="${3:-$ROOT/artifacts/${NAME}-$(date +%H%M%S)}"

[ -x "$ROOT/engine/godot" ] || { echo "Run tools/setup_engine.sh first" >&2; exit 1; }
mkdir -p "$OUT"

export LIBGL_ALWAYS_SOFTWARE=1
set +e
timeout "${CAPTURE_TIMEOUT:-180}" xvfb-run -a -s "-screen 0 1280x720x24" \
	"$ROOT/engine/godot" --path "$ROOT" --rendering-driver opengl3 \
	--resolution 1280x720 "$SCENE" \
	++ --capture "$TIMES" --out "$OUT" --autoplay ${CAPTURE_EXTRA:-} >"$OUT/log.txt" 2>&1
STATUS=$?
set -e

tail -n 20 "$OUT/log.txt"
echo "---"
ls -la "$OUT"
exit $STATUS
