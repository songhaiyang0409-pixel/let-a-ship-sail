# V2FUN Asset Integration 01

## Outcome

The two V2FUN Pro-Multiview GLBs are preserved byte-for-byte and recorded in
the reusable intake pipeline. Their original files are never edited. Because
the current machine has no Blender, Assimp, gltfpack, or other trusted
decimation tool, the working files are conservative pass-through derivatives,
not falsely labeled mobile-final assets.

## Verified source data

| Asset | Actual source statistics | Raw bounds (m) | Classification |
|---|---|---|---|
| A Faroe Turf-Roof Cottage | 1 mesh; 294,918 vertices; 498,550 triangles; 1 material; 2 embedded 8192x8192 textures; 0 animations; 0 skeletons; no missing external textures | 0.712 x 0.713 x 0.677 | B |
| B Harbor Fishing Shed | 1 mesh; 292,659 vertices; 494,994 triangles; 1 material; 2 embedded 8192x8192 textures; 0 animations; 0 skeletons; no missing external textures | 0.749 x 0.708 x 0.691 | B |

The classifications are technical: usable after optimization, not approved
final art. The approximate 500k-triangle and 8K-texture costs are the main
mobile risks.

## Preservation and derivatives

Incoming copies:

- `V2FUN_INBOX/incoming/Faroe_Turf_Roof_Cottage__V2FUN.glb`
- `V2FUN_INBOX/incoming/Harbor_Fishing_Shed__V2FUN.glb`

Preserved originals:

- `V2FUN_INBOX/originals/Faroe_Turf_Roof_Cottage__V2FUN__7e3dd2ee.glb`
- `V2FUN_INBOX/originals/Harbor_Fishing_Shed__V2FUN__68c336dd.glb`

Godot-facing working copies:

- `V2FUN_INBOX/working/Faroe_Turf_Roof_Cottage__V2FUN__7e3dd2ee.glb`
- `V2FUN_INBOX/working/Harbor_Fishing_Shed__V2FUN__68c336dd.glb`

The source and preserved-original SHA256 values match. No geometry or texture
optimization was performed. A non-destructive scale of 5.0 is applied only to
scene instances, giving an approximate 3.5--3.8 m staging footprint.

## Isolated preview

Use the runtime review scene because the current headless project cache did not
finish importing these unusually large GLBs as normal PackedScenes. The review
loads the GLB bytes through Godot's built-in `GLTFDocument`, without changing
the files or project settings:

- Scene: `scenes/tools/V2FUNAssetReview02_Runtime.tscn`
- Launcher: `启动V2FUN资产复核02.bat`
- Captures: `V2FUN_INBOX/previews/asset_review_02_runtime/01_front.png`,
  `02_side.png`, `03_back.png`, `04_game_distance.png`

The earlier `V2FUNAssetReview01.tscn` remains as an initial importer probe; it
is not the recommended launcher after the runtime-loader finding.

## Isolated overnight staging

- Scene: `scenes/staging/OvernightWorldStagingPrep01_V2FUN_Runtime.tscn`
- Launcher: `启动V2FUN资产Staging02.bat`
- Script: `scenes/staging/overnight_world_staging_prep_01_v2fun_runtime.gd`

This wrapper instantiates the existing overnight staging scene unchanged and
mounts the two working derivatives into its existing cottage and shed sockets.
It carries no sailing, timer, controller, camera, collision, wake, or formal
game logic.

## Formal-project safety

No Sea Trial, Journey Test, formal Port-to-Port scene, boat, water, camera,
collision, wake, control file, or `project.godot` was modified. No third-party
tool was installed. The assets are ready for visual staging tonight, but a
proper Blender/gltfpack-style conservative optimization pass is still required
before mobile production approval.
