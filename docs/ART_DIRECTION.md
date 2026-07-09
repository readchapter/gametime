# Art direction

**Reference: *The Falconeer* (2020).** Zero image textures anywhere in the
project. The look is built from:

- Low-poly geometry with **vertex colors** (Godot primitives, CSG,
  SurfaceTool-generated meshes — no external DCC tools).
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
