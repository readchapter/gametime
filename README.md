# THE FALL

A first-person, narrative-driven WWII game. Travis Boyd, a USAAF tail
gunner, is shot down over occupied France. This repository holds
**Chapters 1–3**, playable as one continuous flow: the dawn hardstand, the
raid from the tail turret, the bail-out, the descent, the first night in a
French farmhouse; the morning patrol, the night walk, and the barn vetting
where wrong answers end the game; then the escape line itself — the road
west past a Feldgendarmerie post, a safehouse over a shop, and a station
checkpoint at dusk where you must pass as a deaf-mute Frenchman while the
man hunting you specifically stands close enough to see.

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

**Chapter 3 — The Line.** The road west with Marcel (when he says down,
slowly) → the calvary handoff to Sylvie → her safehouse (the radio, and
the street you should not watch — but will) → the station checkpoint. You
are Jean Caillet, deaf and mute: at the barrier, the winning move is
almost always to do **nothing**. React to a German voice like a hearing
man and the chapter ends in an arrest — and replays with the questions
rephrased.

Landing quality and dialogue choices set story flags that persist into the
save file — Chapter 2 reads them (a bad landing changes the morning),
Chapter 3 reads the trust you earned or burned in the barn (a lie about
the paper follows you all the way to the barrier), and Chapter 4 will
know that Voss has seen your face.

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
