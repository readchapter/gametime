# Roadmap & session handoff notes

## State

**Chapters 1 and 2 are complete and play as one flow:** title → hardstand →
raid → player-walked bail-out → descent → wake → two-room farmhouse →
Ch1 end cards → **Ch2**: farmhouse morning (German patrol at the door, hide
beat) → dusk handoff to Marcel → night walk (truck headlight beat) → barn
vetting (Willis's execution, the questions, the BIGOT document search,
pass/fail verdict) → end of Chapter 2 → title. All verified headless via
`--autoplay` plus screenshot captures; `--autoplay-fail` drives the vetting
fail path (game_over card → beat reloads with attempt-varied lines — the
replay-variation pools are live). Fidelity: hand-built B-17/Fw 190, CC0
low-poly trees/crops/furniture/props (tinted via `Kit`), synthesized
placeholder audio in every slot, pause menu + mouse sensitivity.

Ch2 systems added: `SceneDirector.CH2_BEATS`/`beat_scene()`/`game_over()`,
dialogue numeric conditions (`suspicion>=2`), `+flag` increment effects,
attempt-indexed line pools, autoplay-preferred choices. Trust flags written
in Ch2 (consult in Ch3+): `trust_henri`, `trust_etienne`, `doubted_willis`,
`vouched_willis`, `said_nothing_willis`, `told_truth_document`,
`lied_document`, `mentioned_pat`, `ch2_failed_once`, plus `landing_bad`.

## Next priorities (in rough order of value)

1. **Feel tuning from playtests** — turret aim, parachute steering,
   dialogue speed, night-walk pacing. Cheap, high-impact, needs feedback.
2. **Characters** — the deferred hard problem. Box-figures stand in for
   everyone. Wanted: grounded low-poly rigged humans (idle/sit/walk),
   1940s rural tone. The Kenney blocky pack was rejected (cartoonish).
   Likely path: user-sourced pack (poly.pizza/Sketchfab CC0) dropped into
   `assets/models/` slots (`villager_seated`, `villager_standing`,
   `airman_standing`) — ModelLib wiring already exists. The three standing-
   figure builders (farm_morning/night_walk/barn_vetting) should collapse
   into one Figures helper when characters get real.
3. **Sourced audio upgrades** — replace synth placeholders file-by-file
   (same names, no code changes). Engine drone and gunfire benefit most.
4. **Scene polish** — raid tracer feel, farmhouse exterior approach shot,
   night-walk hedgerow density near the route, barn straw/texture read.
5. **Chapter 3 (safehouse chain toward the hub city)** — per brief §7:
   movement through safehouses, a city checkpoint sequence, Voss felt
   closer. The Ch2 trust flags above are the branch inputs.

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
