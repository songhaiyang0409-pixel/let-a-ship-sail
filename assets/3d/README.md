# 3D Asset Pipeline

This directory is the replacement boundary for future imported 3D assets.

- `boats/` — main boat and future boat variants.
- `islands/` — island visual assets.
- `buildings/` — houses and other architecture.
- `docks/` — docks, piers, and harbor structures.
- `vegetation/` — trees and simple vegetation silhouettes.
- `rocks/` — rocks and shoreline masses.
- `props/` — small world props.
- `landmarks/` — lighthouse and other readable distant landmarks.
- `materials/` — authored Godot materials when an imported material is not enough.
- `textures/` — supporting textures for imported models.

Current generated geometry remains in code and is explicitly marked `PLACEHOLDER`.
Do not treat it as final art. Imported GLB/GLTF/FBX assets should be reviewed against
`docs/asset_scale_guide.md` and the import checklist in `docs/asset_pipeline_guide.md`.
