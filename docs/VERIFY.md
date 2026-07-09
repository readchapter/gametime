# Verification

## Visual (required for any shader/lighting/scene change)

```sh
tools/setup_engine.sh                                  # once per container
tools/capture/capture.sh res://src/dev/graybox.tscn    # default: 1 shot at t=1.0
tools/capture/capture.sh res://src/chapters/ch1/field.tscn 0.5,2.0,5.0
```

Runs the game under Xvfb with llvmpipe (software GL, matches the pinned
gl_compatibility renderer) and writes `shot_NN.png` + `log.txt` to
`artifacts/`. Inspect the PNGs — do not trust a clean log alone.
For motion (tracers, descent), use Godot's movie writer:
`engine/godot --path . --write-movie artifacts/seq/f.png <scene>`.

## Logic

Headless script tests (dialogue parsing, GameState save/load, landing
grading) run as plain assert scripts:

```sh
engine/godot --headless --path . -s tests/run_tests.gd
```

## End-to-end

`godot --headless` autoplay pass advancing all SceneDirector beats without
errors, then a human playthrough in the local editor (the real acceptance
test — llvmpipe is stills-only slow).
