# Architecture

Godot 4.x, GDScript, **gl_compatibility renderer pinned** (see README). No
third-party addons — all systems are hand-rolled so the dialogue/trust and
replay-variation mechanics stay custom-fit.

## Autoloads (src/autoload/)

| Autoload | Role |
|---|---|
| `Boot` | Registers the input map in code (keeps project.godot hand-maintainable). |
| `Settings` | Player options (mouse sensitivity) persisted to `user://settings.json`, separate from the save game. Controllers read `Settings.mouse_scale`. |
| `PauseMenu` | Esc pause overlay (resume / sensitivity slider / restart beat / quit to title); `process_mode = ALWAYS` so it runs while the tree is paused. Yields to CutscenePlayer's Esc-skip and never triggers on the title. |
| `GameState` | Story flags, inventory, seen-cutscenes, chapter/beat; JSON save to `user://save.json`. The later trust mechanic is flags consulted by dialogue conditions — never a visible meter. |
| `SceneDirector` | Scene transitions with fade; `CH1_BEATS` map + `goto_beat()` own chapter flow and record progress for the title screen's Continue. Ch1 is linear; later chapters branch on GameState flags before calling goto_beat. |
| `DialogueManager` | Data-driven dialogue runtime (schema documented in the script header). `lines` is an array per node — the replay-variation pool; Ch1 uses index 0. |
| `AudioManager` | File-based music/ambient/sfx with graceful degradation: missing assets warn once and stay silent (see assets/audio/MANIFEST.md). Scenes never own players. |
| `Hud` | Interaction prompt only — no health bars or meters by design. |
| `CutscenePlayer` | Data-driven step timeline (data/cutscenes/**), Esc-skippable after first viewing; captions render above the fade layer. |
| `DialogueBox` | Dialogue UI (code-built): typewriter line, speaker, keyboard/mouse choices. Reactive to DialogueManager signals only. |
| `CaptureHarness` | Dev-only screenshot loop; inert without `++ --capture` user args. |

## Players (src/player/)

- `fps_controller.gd` — ground movement + mouse-look + interact raycast.
  Single entry point that Ch2 stealth (crouch, noise) will extend.
- `turret_controller.gd` — tail-gunner position: constrained aim cone,
  twin guns, trauma shake. Fighter waves are choreographed (fighter.gd
  bezier runs), driven by data/ch1/raid_script.json.
- `parachute_controller.gd` — freefall + canopy deploy + drift steering
  against wind. descent.gd grades the landing zone (`landing_grade`:
  good/neutral/bad and `landing_bad` — dialogue + Ch2 consequences, never
  a fail state) and triggers ground fire if the player drifts toward the
  road/village.

## Data (data/)

Dialogue and cutscenes are external JSON, never hardcoded in scripts, so
replay variation, localization, and future voice work extend without
rewrites. Interaction is a duck-typed `interact(player)` method on any
collider (see `fps_controller.gd::_try_interact`).

## Gotchas

- The 12 numbers in a `.tscn` `Transform3D(...)` are the **basis rows** then
  the origin — not columns. When hand-authoring rotations, serialize the
  transpose of the column matrix you derived (or set rotations from script).

## Chapter flow (Ch1)

title → hardstand (Pat dialogue, board) → bomber_tail (raid → bail-out:
player walks the burning fuselage, passes the document pickup silently,
jumps at the side hatch) → descent (steering + zone grading + ground-fire
consequence → landing blackout → field wake beat with the family) →
farmhouse (main room table dialogue → walk through the doorway to the
bedroom → bed → end cards → back to title). No fail state anywhere in Ch1.

## Asset pipeline

- `Kit` (src/systems/procgen/kit.gd): curated CC0 models with cohesion
  tint; `ModelLib` remains the per-name drop-in override; `Aircraft` holds
  the hand-built planes. See docs/ART_DIRECTION.md for the tint rule.
- Audio: every manifest slot ships a synthesized placeholder from
  `tools/synth_audio.py`; same-name files replace them without code changes.

Headless verification: every interactive gate self-advances under
`--autoplay` (capture.sh passes it), so the whole chapter runs end-to-end
unattended — see docs/VERIFY.md.
