# Model manifest — Chapter 1

Drop `.glb` files here (`assets/models/<name>.glb`) and they replace the
procedural primitives automatically via `ModelLib.get_model()` — no code
changes. Keep the art direction: **flat-shaded / low-poly, no textures or
baked lighting** (vertex colors or solid materials only). CC0 preferred;
record attribution in `CREDITS.md`.

Good sources: quaternius.com (CC0 low-poly packs incl. planes and people),
kenney.nl (CC0), opengameart.org (filter CC0).

Scale: 1 unit = 1 meter, +Z forward for aircraft. If a model imports at the
wrong scale/orientation, wrap it in Godot's import settings rather than code.

## Wanted (highest value first)

| file | replaces | notes |
|---|---|---|
| `villager_seated` | box-figures at the farmhouse table | static seated pose, dark 1940s rural clothes |
| `villager_standing` | wake-beat figures in the field | static standing/leaning pose |
| `airman_standing` | Pat on the hardstand | flight jacket silhouette; ~1.75m |
| `b17` | primitive B-17 (hardstand, formation, descent) | ~31m wingspan; sits on gear origin at ground |
| `fw190` | attacking fighters | ~10m wingspan, +Z nose |
| `farm_table`, `farm_chair`, `farm_bed` | farmhouse furniture | rustic, chunky |
