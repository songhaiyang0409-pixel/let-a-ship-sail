# V2FUN ASSET INBOX PIPELINE 01

## Intake

Drop manually downloaded V2FUN assets into:

V2FUN_INBOX/incoming/

The scanner also accepts supported files placed directly in V2FUN_INBOX/.
Generated areas are kept separate:

- V2FUN_INBOX/incoming/ — untouched incoming downloads
- V2FUN_INBOX/originals/ — preserved byte-for-byte copies
- V2FUN_INBOX/working/ — independent working/pass-through derivatives
- V2FUN_INBOX/reports/ — per-asset technical reports
- V2FUN_INBOX/previews/ — preview output area
- V2FUN_INBOX/ledger.json — reusable asset ledger

Original files are never overwritten. SHA-256 idempotency prevents the same
download from being processed twice.

For GLTF and OBJ packages, referenced BIN, MTL, and texture sidecars are copied
into the same preserved/working package directory when they are present, so the
relative references remain usable in the isolated preview.

## One-click commands

- 处理V2FUN资产.bat — scan, preserve, inspect, ledger
- 启动V2FUN资产预览.bat — isolated neutral Asset Inbox Gallery

Supported formats: GLB, glTF, FBX, OBJ.

## Current inspection capability

Using Python 3.14 standard library only:

- GLB/glTF: meshes, primitives, vertices, triangles, materials, textures,
  embedded/external images, basic image resolution, animations, skins, and
  missing external buffers/images.
- OBJ: vertices, triangulated face count, MTL material use, texture references,
  basic image resolution, and missing texture files.
- FBX: safely preserved and recorded, but detailed structure is unavailable
  until Blender or Assimp is installed.
- Every asset receives a SHA-256 hash and a technical A/B/C classification.

Risk flags include high triangle count, textures over 2048px, missing external
dependencies, parser failures, and unavailable FBX inspection.

## Derivatives and optimization

The first version prioritizes reliable inspection. The working derivative is a
separate byte-for-byte pass-through copy; no decimation, retopology,
rescaling, material rewrite, or destructive optimization is performed.

The project convention remains 1 Godot unit approximately 1 meter. Orientation
and scale normalization are intentionally deferred to a non-destructive
wrapper or derivative after a real asset is inspected.

No Blender, Assimp, trimesh, Pillow, gltf-transform, or other large dependency
was installed.

## AssetGallery integration

V2FUNAssetInboxGallery.tscn is an isolated neutral preview scene. It provides:

- neutral environment, light, ground, and camera;
- 1 m, 1.8 m, 3 m, and 10 m scale references;
- automatic loading of Node3D PackedScene assets from working/;
- filename labels and a clear empty-state message.

It has no sailing, boat-control, collision, wake, Sea Trial, Journey Test,
Port-to-Port, or project.godot dependency.

## Validation status

No real V2FUN asset is currently present. The intake script was run twice on the
empty inbox and safely reported new_assets=0. The Gallery script and scene
passed gda validation and preflight, and the empty Gallery was launched with
Godot 4.7.2. Real-model statistics and visual approval are waiting for the
first manual V2FUN download.

## Exact files added

- tools/v2fun_asset_pipeline.py
- 处理V2FUN资产.bat
- 启动V2FUN资产预览.bat
- V2FUN_INBOX/README.md
- V2FUN_INBOX/ledger.json
- V2FUN_INBOX/incoming/.gitkeep
- V2FUN_INBOX/originals/.gitkeep
- V2FUN_INBOX/working/.gitkeep
- V2FUN_INBOX/reports/.gitkeep
- V2FUN_INBOX/previews/.gitkeep
- scenes/tools/V2FUNAssetInboxGallery.tscn
- scenes/tools/v2fun_asset_inbox_gallery.gd
- V2FUN_ASSET_INBOX_PIPELINE_01_REPORT.md

Formal Sea Trial, Journey Test, Port-to-Port, water, controls, camera,
boat model, collision, and project.godot files modified: 0.
