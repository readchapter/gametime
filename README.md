# THE FALL

A first-person, narrative-driven WWII game. Travis Boyd, a USAAF tail
gunner, is shot down over occupied France. This repository holds the
**complete campaign — Chapters 1–6** — playable as one continuous flow
from the dawn hardstand to the Pyrenees: the raid from the tail turret,
the bail-out and descent, the farmhouse, the barn vetting, the escape
line west, the Paris apartment where the danger wears a smile, the
campaign's fork (the courtyard trap or the rooftops), the boxcar east or
the barge south, and the crossing — where the man who has been reading
you since a beet field in Picardy is waiting at the border cairn. The
story ends; the ending depends on everything you did.

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

**Chapter 4 — The Helpful Ones.** Paris. A blackout walk to door 17, and
an apartment where the danger wears a smile and carries real bread.
Lucien's three questions all sound like favours — every true answer you
give him prices your future. At dusk Freeman brings the fast route, and
the game's biggest choice: go with the charming man, or stay with the
slow soup. **Neither answer is a fail state.** One leads over a plank and
the rooftops to a canal barge; the other leads to a courtyard, a hood,
and a quiet conversation with Kriminalkommissar Voss — who knows exactly
as much as you told Lucien, and proves it.

**Chapter 5 — The Long Way Home.** Two openings, one per Chapter 4 ending.
Captured: a boxcar east, slat-light, and the quietest corner in the car —
the reunion the game has been holding since the hardstand — then the grade
before the border and the second jump of Travis Boyd's war. Escaped: a
barge south through the locks, the survivor's ledger of everyone you left
behind, and landfall on the crow roads toward the mountains.

**Chapter 6 — The White Teeth of the Sky.** The finale. Both roads home
converge on a shepherd's hut at the snow line — the last roof in France —
where the bad stone in the bread is delivered plainly: a man in a city
coat went up the valley yesterday, asking for a parcel by name. He is
ahead of you, not behind. The crossing climbs past where the sheep turn
back to the cairn where France runs out of stones, and the game's last
conversation: Voss, at the end of his jurisdiction, holding the folder
that is his whole war. How it resolves — and what the ending cards read
back — depends on who you are by then: who stands beside you, what you
know about the paper, and everything you ever told the helpful ones.

Landing quality and dialogue choices set story flags that persist into the
save file — Chapter 2 reads them, Chapter 3 reads the barn, Chapter 4
turns trust into the campaign's fork, Chapter 5 pays it forward, and
Chapter 6 reads the whole ledger back over the final fade: who crossed
with you, what became of Voss, where the paper went, and who paid.

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
