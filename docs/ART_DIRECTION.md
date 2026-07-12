# Art direction

**Reference: *The Falconeer* (2020), evolved to "in-between":** stylized
low-poly with real model silhouettes, never photoreal. The look is built
from:

- Low-poly geometry with **vertex colors** (Godot primitives, CSG,
  SurfaceTool-generated meshes) for terrain, buildings, and the hand-built
  aircraft (`src/systems/procgen/aircraft.gd` — the B-17 and Fw 190 are
  sculpted in code, not imported).
- **Curated CC0 low-poly models** (Kenney kits in `assets/models/kit/`) for
  trees, crops, furniture, and props — always loaded through
  `Kit.model(name, tint, scale)` with a **cohesion tint** that multiplies
  their color atlas down into the scene palette. Never drop a model in
  untinted; brightness pop is what breaks the style.
- A custom **sky shader**: gradient + sun disc + shader-noise cloud layer.
- **Distance and height fog** doing most of the compositional work.
- Per-scene **WorldEnvironment color grading**. The chapter's palette arc:
  cold blue-grey dawn (hardstand) → harsh daylight and smoke (raid) → amber
  dusk (field) → lamplit interior warmth against darkness (farmhouse) →
  near-black night with a cold moon (end).

Tone is dark and grounded (*Masters of the Air*): restrained saturation, no
heroic golden-hour glamour. Lighting, fog, and grading are where the visual
budget goes — geometry stays simple.

Every shader/lighting change must be **looked at**, not just compiled: render
via `tools/capture/capture.sh` and inspect the PNGs (see VERIFY.md).
