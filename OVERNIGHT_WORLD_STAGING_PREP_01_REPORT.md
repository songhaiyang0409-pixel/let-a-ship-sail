# OVERNIGHT WORLD STAGING PREP 01

## Scope

This is an isolated spatial staging layer. It does not replace the formal
Sea Trial, Journey Test, Port-to-Port slices, or `project.godot`.

## Staging scene

- Scene: `scenes/staging/OvernightWorldStagingPrep01.tscn`
- Script: `scenes/staging/overnight_world_staging_prep_01.gd`
- Launcher: `启动OvernightWorldStagingPrep01.bat`
- Base: `scenes/reference/SailingReferenceScene.tscn`
- Runtime foundation retained: B+ V3-derived Regional Ocean, shared boat/wave
  coupling, canonical camera, and canonical controls.

The wrapper adds only world-space staging anchors, empty future-asset sockets,
one neutral exposed-coast proxy, and deterministic capture helpers. It does not
duplicate the water shader, Gerstner formula, boat controller, or camera.

## Provisional A → B route

- Destination A: exposed northern coast, route origin at `(0, 0, 70)`.
- Destination B: sheltered inhabited coast, route end at `(0, 0, -78)`.
- Provisional route distance: `148 m`.
- Existing canonical coastal proxy provides B's headlands, harbor corridor,
  shore strips, pier proxies, and single high beacon.
- A receives one low-cost, no-collision headland proxy only for scale context.

Approximate travel times using the canonical route speed:

| Mode | Speed | 148 m route |
| --- | ---: | ---: |
| Normal interactive reference speed | 2.2 m/s | 67.3 s |
| Test observation speed | 5.0 m/s | 29.6 s |

The first existing B shoreline proxy begins around route distance 94 m; the
harbor transition begins around 126 m. These are staging measurements, not
final game pacing.

## Scale findings

- The current project convention remains `1 Godot unit ≈ 1 meter`.
- The intended player boat hull reference remains approximately 6 m, while the
  preserved raw prototype mesh is not rescaled.
- A 148 m route is enough to show a meaningful open-water interval while still
  allowing rapid test observation.
- The boat should remain a small readable foreground subject; large landforms
  need broad silhouette and vertical mass before detail is added.
- The B proxy's harbor width and nearshore corridor remain spatial references,
  not final navigation or art dimensions.

## V2FUN readiness

Empty sockets are present under `V2FUN_Asset_Sockets_READY`:

- `TurfRoofCottage_SOCKET`
- `HarborWarehouseFishingShed_SOCKET`
- `DestinationBLandmark_SOCKET`
- `PierVisual_SOCKET`

They contain no fabricated assets. Future approved V2FUN derivatives can be
instanced at these locations without changing the canonical sailing system.
`V2FUN_INBOX/incoming` is currently empty apart from its marker file, so no
real V2FUN model was imported or classified in this prep.

## Curated local asset shortlist

No downloaded pack was imported or unpacked in this prep. The shortlist is a
technical starting point for the later AssetGallery pass:

### Candidate / inspect first

- In-project KayKit Forest CC0 rocks:
  `assets/3d/environment/kaykit_forest_cc0/Rock_1_A_Color1.gltf`,
  `Rock_1_B_Color1.gltf`, `Rock_1_C_Color1.gltf`, `Rock_2_B_Color1.gltf`.
  Use as sparse rock references only; inspect color and scale before approval.
- `C:\Users\Administrator\Downloads\LowPolyRockPack.blend` and its
  duplicate `(1)` copy: possible neutral rock source, pending gallery review.
- `C:\Users\Administrator\Downloads\Low Poly Brick Houses.blend`: possible
  house blockout source, pending scale/material/pivot review.

### Secondary / fallback only

- `LowPolyTreePack.blend` and `LowpolyForestPack.zip`: vegetation candidates;
  rounded or bright forms may conflict with the North Atlantic direction.
- `KayKit_Forest_Nature_Pack_1.0_FREE.zip`: useful only after selecting muted,
  non-toy shapes.
- `MBJ_PLANTPACK_01_FREE.zip`: vegetation candidate, not yet screened.

### Not shortlisted yet

`Models.zip`, `Models (1).zip`, `Models (2).zip`, `Models (3).zip`, `Files.zip`,
`Demo.zip`, `Demo (1).zip`, `Textures.zip`, and `Textures (1).zip` have
ambiguous/repeated names and were not imported without a later inventory pass.

Bright rounded toy trees, tropical-looking assets, western-fantasy assets, and
high-detail props remain rejected until proven compatible through the gallery.

## Evidence screenshots

- [01_departure.png](scenes/staging/overnight_world_staging_captures/01_departure.png)
- [02_open_sea.png](scenes/staging/overnight_world_staging_captures/02_open_sea.png)
- [03_first_destination_read.png](scenes/staging/overnight_world_staging_captures/03_first_destination_read.png)
- [04_near_approach.png](scenes/staging/overnight_world_staging_captures/04_near_approach.png)

All four are actual game viewport captures at `1152×648` using the canonical
camera. They are spatial evidence, not a claim that final island art is done.

## Verification

- `gda 0.12.0` script validation: staging script valid.
- `gda` scene validation: staging scene valid.
- `gda` scene preflight: status `ready`, no staging diagnostics.
- Actual capture run: completed and wrote all four PNGs.
- Actual coastal observation run: logged the route through North Atlantic,
  Open Ocean / Coastal Approach, Shallow Coastal Water, and Sheltered Harbor,
  including the harbor turnaround.
- Formal project files modified by this prep: `0`.

The project-wide gda scene inventory still reports pre-existing missing
Boujie benchmark dependencies under `addons/boujie_water_shader`; those are
historical benchmark warnings and are not used by this staging scene.

## Limitations

- The staging route currently reuses the canonical RegionalOceanSystem's
  existing interactive route rather than introducing a second route controller.
- Destination B remains the existing placeholder proxy. No final island,
  settlement, harbor, or collision art was attempted.
- The local image viewer helper was unavailable during this run, so pixel-level
  visual judgment of the generated PNGs still requires human inspection.
