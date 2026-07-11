# Model credits

Curated low-poly models in `assets/models/kit/` are from **Kenney**
(https://kenney.nl) — Nature Kit, Furniture Kit, Food Kit, Survival Kit —
released under **CC0 1.0** (public domain, no attribution required; credited
here as courtesy). They are tone-matched at load via `Kit.tint_node` (see
src/systems/procgen/kit.gd) to fit the game's dark palette.

The full unpacked packs live on the `assets-src` branch (fetched by
.github/workflows/fetch-assets.yml); only the files actually used are
committed here to keep the repo lean.

| area | files |
|---|---|
| landscape | tree_*, crops_*, grass, cliff_rock |
| farmhouse | table, tableCloth, chair, chairRounded, bedSingle, lampRoundTable, bench |
| props | barrel, box, bucket, bedroll, bread, loaf, pot |

The B-17 and fighters are hand-built procedural meshes (src/systems/procgen/
aircraft.gd) — no external plane asset.
