# Roadmap & session handoff notes

## State

**Chapters 1–4 are complete and play as one flow, and the campaign now
forks.** Chapter 4 (The Helpful Ones): ch4_arrival (CityGen blackout
canyon, patrol sweep, door 17) → ch4_apartment (Lucien's three probes
feed +exposure and told_lucien_* flags; Paine book to the flour tin;
the fast-route/stay branch) → ch4_break (one scene, two canon endings:
courtyard trap → cell → the Voss interview, whose certain knowledge is
exactly the told_lucien_* set; or the rooftop escape: plank, chimneys,
coal chute, canal barge). Flags out: ch4_captured / ch4_escaped,
freeman_lost, beranger_taken, met_voss, voss_named_pat, paine_kept,
exposure 0–4, warned_freeman, defied/silent_voss, defended_beranger.
--autoplay drives the escape branch; --autoplay-fail drives capture.
CHAPTER 5 MUST OPEN FROM BOTH: the transfer east (POW thread) and the
canal barge. Ch3 summary below still applies.

**Chapters 1–3:** Chapter 3 (The Line):
ch3_road (dawn detour past a Feldgendarmerie post, Marcel→Sylvie handoff
reading Ch2 flags) → ch3_safehouse (plan dialogue, BBC radio beat, the
street sweep watched from the curtain gap) → ch3_checkpoint (behavioural
deaf-mute vetting; a Ch2 document lie adds the missing-stamp trap;
suspicion ≥ 2 = arrest with attempt-varied retry; Voss appears silently
and is named off-screen; chapter=4 saved). New Ch3 flags:
`trust_sylvie`, `kept_cover`, `saw_voss`, `heard_radio`, `ch3_complete`,
`ch3_failed_once`, `marcel_thanked`, `asked_sylvie_why`.

Chapter 2 summary below still applies:

**Chapters 1 and 2 play as one flow:** title → hardstand →
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
5. **Chapter 5 (twin openings)** — per brief §7 the endgame routes begin:
   5A from ch4_captured (the transfer east: escape from the train or the
   POW thread; Voss's Pat claim resolves here — the mid-campaign reunion
   the brief architects for), 5B from ch4_escaped (the canal barge south
   toward the Pyrenees/coastal split). Branch scene selection needs a
   conditional beat: goto_beat consulting ch4_captured at chapter start.

## Gotchas (hard-won — read before editing)

- **Never `await tween.finished` after other awaits**: a tween that
  finished meanwhile is freed and the await hangs forever. Time long
  moves with pause-aware timers instead.
- **Every walkable scene needs a floor collider** — a tween-driven player
  is still a CharacterBody3D with gravity (checkpoint forecourt bug).
- **Euler readback**: after a tween lands on yaw=PI, `rotation` re-reads
  as (-PI, 0, -PI); tweening `rotation:y` from there flips the camera.
  Pan cameras with tween_method setting the full rotation Vector3.
- **Never spawn a walker intersecting a collider** (bed blocker bug) —
  physics depenetration pins autoplay walkers that set position directly.

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
