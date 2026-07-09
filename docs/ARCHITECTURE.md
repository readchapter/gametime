# Architecture

Godot 4.x, GDScript, **gl_compatibility renderer pinned** (see README). No
third-party addons — all systems are hand-rolled so the dialogue/trust and
replay-variation mechanics stay custom-fit.

## Autoloads (src/autoload/)

| Autoload | Role |
|---|---|
| `Boot` | Registers the input map in code (keeps project.godot hand-maintainable). |
| `GameState` | Story flags, inventory, seen-cutscenes, chapter/beat; JSON save to `user://save.json`. The later trust mechanic is flags consulted by dialogue conditions — never a visible meter. |
| `SceneDirector` | Scene transitions with fade; owns chapter beat flow. Ch1 is linear; later chapters branch on GameState flags. |
| `DialogueManager` | Data-driven dialogue runtime (schema documented in the script header). `lines` is an array per node — the replay-variation pool; Ch1 uses index 0. |
| `AudioManager` | Music/SFX playback so scenes never own players. |
| `CaptureHarness` | Dev-only screenshot loop; inert without `++ --capture` user args. |

## Players (src/player/)

- `fps_controller.gd` — ground movement + mouse-look + interact raycast.
  Single entry point that Ch2 stealth (crouch, noise) will extend.
- `turret_controller.gd` (M3) — tail-gunner position: constrained aim cone,
  fire, scripted fighter waves.
- `parachute_controller.gd` (M4) — descent drift steering, landing-zone
  grading (`landing_grade` flag: good/neutral/bad — has dialogue and Ch2
  consequences, never a fail state).

## Data (data/)

Dialogue and cutscenes are external JSON, never hardcoded in scripts, so
replay variation, localization, and future voice work extend without
rewrites. Interaction is a duck-typed `interact(player)` method on any
collider (see `fps_controller.gd::_try_interact`).

## Chapter flow (Ch1)

hardstand → bomber_tail (raid → bail-out, silent document grab) → descent
(steering + zone grading) → field (landing, blackout) → farmhouse (wake
cutscene, table dialogue, bed → end card). No fail state anywhere in Ch1.
