# Asset Import Workflow — Isolated Port-to-Port V03

## 1. Stage

Put new GLB / GLTF files in `asset_staging/third_party/incoming/`. Do not put unreviewed files into an active scene.

## 2. Inspect

Open the model in `AssetGallery.tscn` and check:

- scale against the boat and meter references;
- pivot and ground contact;
- forward direction (`-Z`) and up direction (`+Y`);
- material slots, texture paths, transparency, and roughness;
- shadow casting and receiving;
- accidental animation tracks or hidden cameras/lights;
- obvious abnormal faces, flipped normals, or excessive mesh density.

## 3. Approve

After visual review, copy the accepted asset to `asset_staging/third_party/approved/`. Keep source files and license notes alongside the asset in `incoming/` or `approved/` as appropriate.

## 4. Mount

Instance approved visual assets only under the matching Port B visual mount:

`LighthouseMount`, `HousesMount`, `PierMount`, `BreakwaterMount`, `RocksMount`, `VegetationMount`, or `LandmarkPropsMount`.

The current `PortBCollisionRoot` is intentionally script-owned by the lightweight world-space guard. Replacing a visual GLB must not require rewriting voyage navigation or collision code.

## 5. Validate

Run the AssetGallery capture, then run the V03 collision check and A→B→A regression. If the visual is disabled or replaced, the route must still work. Do not add complex mesh colliders by default; create a small explicit collision change only when the visual shoreline actually changes.
