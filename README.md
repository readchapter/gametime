# THE FALL — Chapter 1

A first-person, narrative-driven WWII game. Travis Boyd, a USAAF tail
gunner, is shot down over occupied France. This repository is **Chapter 1**,
a complete playable slice: the dawn hardstand, the raid from the tail
turret, the bail-out, the parachute descent, and the first night in a
French farmhouse.

Textureless, procedural art direction (vertex colors, shader-driven
lighting, fog, atmosphere — *The Falconeer* is the visual reference).
Dark, grounded tone. Text-based, data-driven dialogue.

## Running the game locally

1. Install **Godot 4.7-stable** (the pinned version; also recorded in
   `ENGINE_VERSION` on the `engine-bin` branch). Download from
   https://godotengine.org/download
2. Clone this repo and open `project.godot` in the Godot editor.
3. Press **Play** (F5).

The project pins the **Compatibility** (OpenGL) renderer — don't switch it
to Forward+; development screenshots are verified against the compatibility
renderer and the art direction targets it.

## Controls

- **WASD** — move / steer the parachute
- **Mouse** — look / aim the turret
- **Left mouse** — fire / advance dialogue
- **E** — interact / advance dialogue
- **Space** — advance dialogue / begin
- **Esc** — skip a cutscene you've already seen

## Chapter flow

Title → Hardstand (talk to Pat, board) → The raid (tail turret; the
bail-out order comes when it comes — this sequence cannot be lost) →
The jump → The descent (steer: where you land matters — the hedgerow
hides you, the road does not) → The farmhouse (sit to the table; sleep).

Landing quality and dialogue choices set story flags that persist into the
save file — Chapter 2 will read them.

## Audio

The game currently runs silent-by-design: `assets/audio/MANIFEST.md` lists
every wanted file; drop license-safe audio in and it plays with no code
changes. Attribution goes in `assets/audio/CREDITS.md`.

## Development (remote container)

- `tools/setup_engine.sh` — fetches the Godot binary from the `engine-bin`
  branch (populated by `.github/workflows/fetch-engine.yml`) into `engine/`.
- `tools/capture/capture.sh <scene> [times] [outdir]` — renders under
  Xvfb + llvmpipe and saves screenshots; see `docs/VERIFY.md`.
- `engine/godot --headless --path . res://tests/test_runner.tscn` — logic
  tests (dialogue data validation, branching, save/load, landing grades).

## Layout

- `src/` — GDScript: autoloads, player controllers, systems (dialogue,
  cutscene, interaction, procgen), UI, shaders, chapter scenes.
- `data/` — external dialogue, cutscene, and raid-timeline data (JSON).
  Dialogue is data-driven by design; schema in
  `src/autoload/dialogue_manager.gd`. `docs/ARCHITECTURE.md` has the map.
- `assets/audio/` — sourced, licensed audio (see MANIFEST/CREDITS).
- `docs/` — architecture, art direction, verification notes.
