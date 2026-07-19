# Art pivot: mid-fidelity textured realism

Decision (playtest owner, July 2026): move away from the textureless
vertex-color look. No block characters. Scenery and set pieces go textured
and grounded. Reference calibration: **Easy Red 2 / PowerWash Simulator
fidelity** — real PBR textures, real rigged humans, heavy atmosphere,
economical geometry. NOT AAA (no MetaHumans, no photoreal faces).

The narrative/systems layer (dialogue JSON, beats, flags, scenes' pacing
and staging) is untouched by this pivot. Only the render layer changes.
The trust ledger is the game; the renderer is clothing.

## The stack (all free or near-free)

| need | tool | notes |
|---|---|---|
| Characters | **Mixamo** (free, Adobe) | Pick mid-fidelity humans (Ch1 airmen, FR civilians, DE uniforms need clothing edits in Blender or sourced packs), auto-rig, export FBX → Blender → .glb. Includes idle/walk/sit animations. This alone kills the block people. |
| Character variety | Sketchfab (CC0/CC-BY filters), itch.io WW2 packs ($10–30) | Search "ww2 soldier low poly rigged", "1940s civilian". Check licenses; record in CREDITS.md. |
| Terrain | **Terrain3D** plugin (free, GDExtension) | Real heightmap terrain for the field, road, foothills, col. |
| PBR textures | **Poly Haven**, **ambientCG** (both CC0) | Ground, plaster, cobbles, wood, snow, corrugated metal. Direct-download URLs → fetchable via the proven CI asset workflow. |
| Skies | Poly Haven HDRIs (CC0) | Or keep the procedural sky shader — it already reads well. |
| Foliage | Kenney nature is now too toylike; use Poly Haven models / Sketchfab CC0 trees | Sparse — fog does most of the work in the references. |
| Aircraft/vehicles | Sketchfab CC0/CC-BY B-17, Fw 190, Citroën, trucks | Plenty exist at this fidelity. |
| Animation polish | Mixamo library + Godot AnimationTree | Blend idle/walk/turn. |

## Engine/renderer

- Stay in **Godot 4.7**. Textured PBR + fog works in the pinned
  gl_compatibility renderer, so the cloud screenshot-verification loop
  keeps working (slower with textures; keep capture resolutions modest).
- Optional later: a Forward+ project preset for local builds (volumetrics,
  SDFGI) once look-dev settles. Do not break compat verification.

## Code changes required (small, well-scoped)

1. **ModelLib v2**: play an "Idle"/named animation if the .glb has an
   AnimationPlayer; per-character model names (`villager_standing_henri`)
   falling back to generic then procedural; optional tint on imported
   meshes. (~40 lines.)
2. **Figures v3**: becomes a thin router into ModelLib character slots;
   procedural box people remain the last-resort fallback only.
3. **Material pass helper**: StandardMaterial3D factory applying the
   grading (desaturation, roughness, fog-friendly albedo) to imported
   textured assets so packs from different sources read as one game.
4. **Terrain3D adoption** per outdoor scene, replacing flat ground boxes;
   colliders stay as-is.
5. Scene dressing swaps (`Kit`/`_place` sites) from tinted CC0 blocks to
   textured props.

## Migration order (session-sized tasks, each verified via captures)

1. **Look-dev slice: the descent + field** — Terrain3D + Poly Haven
   ground/hedgerow textures + fog tuning. One scene proves the pipeline
   (CI texture fetch → import → material pass → capture).
2. **Characters everywhere**: Mixamo pipeline documented + first three
   humans (Travis hands/POV needs nothing; Pat, Henri, Voss). ModelLib v2.
3. **Farmhouse + hut interiors** (plaster/wood/fabric textures, lightmap
   or improved lights).
4. **The raid** (textured B-17 interior + formation models).
5. **Paris blackout + checkpoint** (facade textures — big win, canyon
   geometry already good).
6. **Train/barge/crossing** (snow + rock materials for the col).
7. **Cohesion pass** + performance check on real hardware.

## Asset workflow

- Direct-URL CC0 zips (Poly Haven/ambientCG) → extend
  `.github/workflows/fetch-assets.yml` (the proven page-scrape/commit
  route) → `assets-src` branch → import + material pass.
- Licensed/purchased packs and Mixamo exports: owner downloads locally,
  commits to `assets/models/` / `assets/textures/`; attribution in
  `CREDITS.md`. Mixamo's license permits game embedding; note it anyway.
- Steam requires an AI-generated-content disclosure — using sourced human
  assets (Mixamo/Poly Haven/Sketchfab) keeps the disclosure clean.

## Superseded

`docs/ART_DIRECTION.md` (textureless Falconeer look) is superseded by
this document for all new work. The procedural builders stay in the tree
as fallbacks — the game must always run even with zero assets present.
