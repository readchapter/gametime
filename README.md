# THE FALL — Chapter 1

A first-person, narrative-driven WWII game. Travis Boyd, a USAAF tail gunner,
is shot down over occupied France. This repository builds **Chapter 1**: the
bomber raid through the first night in a French farmhouse.

Textureless, procedural art direction (vertex colors, shader-driven lighting,
fog, and atmosphere — *The Falconeer* is the visual reference). Dark, grounded
tone. Text-based, data-driven dialogue.

## Running the game locally

1. Install **Godot 4.7-stable** (the pinned version; also recorded in
   `ENGINE_VERSION` on the `engine-bin` branch). Download from
   https://godotengine.org/download
2. Clone this repo and open `project.godot` in the Godot editor.
3. Press **Play** (F5).

The project pins the **Compatibility** (OpenGL) renderer — don't switch it to
Forward+; development screenshots are verified against the compatibility
renderer and the art direction targets it.

## Development (remote container)

- `tools/setup_engine.sh` — fetches the Godot binary from the `engine-bin`
  branch (populated by `.github/workflows/fetch-engine.yml`) and unpacks it to
  `engine/godot`.
- `tools/capture/capture.sh` — renders a scene under Xvfb + llvmpipe and saves
  screenshots to `artifacts/` for visual verification.

## Layout

- `src/` — GDScript: autoloads, player controllers, systems (dialogue,
  cutscene, interaction), UI, shaders, chapter scenes.
- `data/` — external dialogue and cutscene data (JSON). Dialogue is
  data-driven by design; see `docs/ARCHITECTURE.md`.
- `assets/audio/` — sourced, licensed audio; attribution in
  `assets/audio/CREDITS.md`.
- `docs/` — architecture, art direction, and verification notes.
