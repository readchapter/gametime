# Roadmap & session handoff notes

## State (end of the fidelity pass)

Chapter 1 is complete and plays title → hardstand → raid → player-walked
bail-out → descent → wake → two-room farmhouse → end cards → title. All
verified headless via `--autoplay` (every interactive gate self-advances)
plus screenshot captures. Current fidelity: hand-built B-17/Fw 190, CC0
low-poly trees/crops/furniture/props (tinted via `Kit`), synthesized
placeholder audio in every slot, pause menu + mouse sensitivity.

## Next priorities (in rough order of value)

1. **Feel tuning from playtests** — turret aim, parachute steering
   authority, dialogue speed. Cheap, high-impact, needs user feedback.
2. **Characters** — the deferred hard problem. Box-figures stand in for
   Pat/family. Wanted: grounded low-poly rigged humans (idle/sit/walk),
   1940s rural tone. The Kenney blocky pack was rejected (cartoonish).
   Likely path: user-sourced pack (poly.pizza/Sketchfab CC0) dropped into
   `assets/models/` slots (`villager_seated`, `villager_standing`,
   `airman_standing`) — ModelLib wiring already exists.
3. **Sourced audio upgrades** — replace synth placeholders file-by-file
   (same names, no code changes). Engine drone and gunfire benefit most.
4. **Scene polish** — descent canopy read, raid tracer feel, farmhouse
   exterior approach shot, hardstand tail-dragger stance for the B-17.
5. **Chapter 2 (The Vetting)** — dialogue system already supports it:
   conditions/effects/branch nodes, trust-as-flags convention
   (`trust_<person>`), `lines` arrays for replay variation, save/continue.

## Gotchas (hard-won — read before editing)

- **.tscn `Transform3D(...)` numbers are basis ROWS then origin.** Author
  rotations via script (`rotation_degrees`) or transpose your column math.
- **Fade contract:** every scene transition leaves the screen black; the
  incoming scene must reveal itself (`SceneDirector.fade_in`). Two black-
  screen bugs came from forgetting this.
- **Verification:** every visual change gets a `capture.sh` screenshot;
  timed captures drift on llvmpipe — use `CaptureHarness.snap("tag")` from
  code for event-exact frames, and `--autoplay` to pass interactive gates.
  Scenes reached through transitions behave differently than direct loads.
- **Model tint rule:** never add a Kit/imported model untinted (see
  ART_DIRECTION.md). `albedo_color` multiplies the color atlas.
- **WAV loops need `loop_end`** set in frames (AudioManager handles it).
- **SceneTree timers:** pass `false` for pause-awareness
  (`create_timer(x, false)`); default timers run through the pause menu.
- **Autoplay walkers** get pinned on colliders — keep interact thresholds
  ≥ collider half-extent + ~0.5m.
- **Engine/network:** container can't fetch GitHub release assets or asset
  sites; use the CI workflows (`fetch-engine.yml`, `fetch-assets.yml` →
  orphan branches) or user uploads. Engine: `tools/setup_engine.sh`.
