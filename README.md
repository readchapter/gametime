# THE FALL

A first-person, narrative-driven WWII game. Travis Boyd, a USAAF tail
gunner, is shot down over occupied France. This repository holds
**Chapters 1 and 2**, playable as one continuous flow: the dawn hardstand,
the raid from the tail turret, the bail-out, the parachute descent, the
first night in a French farmhouse — and then the morning after: a German
patrol at the door, a night walk behind a resistance guide, and the
vetting in a barn where wrong answers end the game.

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

**Chapter 1 — The Fall.** Title → Hardstand (talk to Pat, board) → The raid
(tail turret; the bail-out order comes when it comes — this sequence cannot
be lost) → The jump → The descent (steer: where you land matters — the
hedgerow hides you, the road does not) → The farmhouse (sit to the table;
sleep).

**Chapter 2 — The Vetting.** The farmhouse morning (when Henri says hide,
hide) → dusk handoff to Marcel → the night walk (stay close; when he drops,
you drop) → the barn. The questions are about *your* life — Travis knows
the answers, so answer as him, and think before you spend your word on a
stranger. **Wrong answers can end the game here.** A failed vetting restarts
the barn — and it will not replay word-for-word.

Landing quality and dialogue choices set story flags that persist into the
save file — Chapter 2 reads them (a bad landing changes the morning), and
Chapter 3 will read the trust you earned or burned in the barn.

## Audio

Every audio slot ships with a **synthesized placeholder** (engine drone,
wind, fire crackle, gunfire, a dark title theme — generated license-free by
`tools/synth_audio.py`). To upgrade any sound, drop a sourced recording
with the same name into `assets/audio/` (see `MANIFEST.md`); it plays with
no code changes. Attribution goes in `assets/audio/CREDITS.md`.

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
