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

Timed shots drift on llvmpipe for long scripted sequences; for event-exact
frames call `CaptureHarness.snap("tag")` from gameplay code (saves
`mark_<tag>.png`, no-op outside capture runs). capture.sh passes
`--autoplay`, which scripted sequences may use to self-advance past
interactive gates (see bomber_raid.gd's bailout step).
For motion (tracers, descent), use Godot's movie writer:
`engine/godot --path . --write-movie artifacts/seq/f.png <scene>`.

## Audio

`python3 tools/synth_audio.py` regenerates the synthesized placeholder set
(prints duration/peak/RMS per file). In-engine check: run any scene and
grep the log for `AudioManager: no asset` — silence means every slot
resolved. Actual listening happens on the user's machine.

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
