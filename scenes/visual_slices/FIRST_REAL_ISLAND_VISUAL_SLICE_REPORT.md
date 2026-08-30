# FIRST REAL ISLAND VISUAL SLICE 01

## Scope

This is an isolated, drivable visual slice built around the existing
SailingReferenceScene. It does not replace the formal Sea Trial, Journey Test,
or Port-to-Port scenes. It does not modify project.godot.

The canonical reference still owns:

- B+ V3 shared Gerstner water and regional presets
- Boat/wave coupling
- Boat visual and current proportions
- Camera, mouse orbit, R reset, and keyboard sailing
- Temporary coastal navigation/collision rules

The new root only adds a replaceable island visual layer. Its scene tree is:

FirstRealIslandVisualSlice01

- SailingReferenceScene
- IslandVisualRoot
  - TerrainRoot
  - RockRoot
  - VegetationRoot
  - HarborRoot
  - LandmarkRoot
  - FutureBuildingLocations
- CollisionRoot

The old RegionalOceanSystem coastal proxy is hidden visually but remains the
temporary navigation/collision authority. This keeps the tested route aligned
with the new visual coastline without duplicating the driving system.

## Asset curation

### Used

Selected from C:\Users\Administrator\Downloads\KayKit_Forest_Nature_Pack_1.0_FREE.zip:

- four rock variants
- two leafy tree variants
- one bare tree
- two bush variants

The pack's included License.txt states CC0. The project copy is a small
subset at:

res://assets/3d/environment/kaykit_forest_cc0/

The original download remains in Downloads. The shared texture and each
required GLTF .bin file were copied beside the selected GLTF files.

### Not used / conditional

- Broken Vector Demo.zip, Demo (1).zip, Models*.zip, and Textures*.zip:
  overlapping downloads and no complete license terms in the supplied
  readmes. Models (1).zip and Models (2).zip are byte-identical; the two
  LowPolyRockPack Blender files are byte-identical.
- LowpolyForestPack.zip: useful-looking rocks/trees, but its supplied readme
  does not state a usable license.
- MBJ_PLANTPACK_01_FREE.zip: personal/commercial use is allowed, but the
  supplied readme prohibits redistribution as an asset pack; it is not needed
  for this slice.
- Blender-only files and Unity packages: not imported because the selected
  GLTF subset avoids a conversion dependency.

Full curation notes are in FIRST_REAL_ISLAND_ASSET_CURATION.md.

## Layout

The island is organized as a broad low-cost three-dimensional terrain mass:

- two green/grey outer headlands form the harbor mouth;
- two darker slope masses create a climb from water to the back rise;
- a back rise supports three restrained future house placeholders;
- a small central pier and two low breakwater placeholders define the landing;
- a simple windward beacon provides one readable high point;
- KayKit rocks and sparse trees/bushes supply natural shoreline and slope
  silhouettes.

The terrain, pier, breakwaters, beacon, and house bodies are intentionally
marked PLACEHOLDER in the scene/script. They are layout scaffolding, not
final environment art.

## Runtime evidence

The slice was run with Godot 4.7.2 at 1152x648 using the actual reference
camera. The capture run completed without script or shader errors after the
GLTF import cache was initialized. The route observation completed the
existing coastal sequence:

North Atlantic / Faroe -> Open Ocean / Coastal Approach -> Shallow Coastal Water -> Sheltered Harbor -> back to Open Ocean / Coastal Approach

The observed route completed in about 43.6 seconds and reported
returned_to_open_water=true. The existing keyboard/mouse control remains on
the child RegionalOceanSystem; the wrapper does not intercept input.

## Visual QA

Captured from the real game camera, with no HUD, debug labels, or editor
gizmos:

- res://scenes/visual_slices/first_real_island_visual_slice_01_captures/01_overview.png
- res://scenes/visual_slices/first_real_island_visual_slice_01_captures/02_approach.png
- res://scenes/visual_slices/first_real_island_visual_slice_01_captures/03_world_read.png
- res://scenes/visual_slices/first_real_island_visual_slice_01_captures/04_boat_to_island.png
- res://scenes/visual_slices/first_real_island_visual_slice_01_captures/05_island_silhouette.png

Observed concrete results:

- the channel, two headlands, pier, back rise, and high beacon are readable;
- the boat remains the existing hero asset and stays on the existing camera;
- the new layer contains actual imported natural models rather than only
  generated primitives;
- the scene remains sparse and does not add characters, UI, story, or
  exploration systems.

Known weak points:

- the terrain and architecture are still unmistakable placeholder geometry;
- the imported KayKit foliage is small at the normal camera distance and still
  reads as generic stylized pack content in close views;
- the temporary collision authority is not yet a separately authored
  IslandRoot/Collision scene; it remains the tested RegionalOceanSystem proxy
  by design;
- the current project renderer remains Compatibility because changing the
  formal project renderer is out of scope.

These are recorded as next asset-production work, not hidden behind a
completion claim.

## Modified/new files

New scene and script:

- res://scenes/visual_slices/FirstRealIslandVisualSlice01.tscn
- res://scenes/visual_slices/first_real_island_visual_slice_01.gd

New documentation and launcher:

- res://scenes/visual_slices/FIRST_REAL_ISLAND_ASSET_CURATION.md
- res://scenes/visual_slices/FIRST_REAL_ISLAND_VISUAL_SLICE_REPORT.md
- res://启动第一真实岛屿切片.bat

New selected imported assets:

- res://assets/3d/environment/kaykit_forest_cc0/

Formal existing game files modified: 0.

## Launch

Double-click:

E:\让一艘船航行\启动第一真实岛屿切片.bat

Equivalent command:

E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64.exe --path E:\让一艘船航行 res://scenes/visual_slices/FirstRealIslandVisualSlice01.tscn -- --sailing-reference --first-real-island-slice

Controls are inherited from the canonical reference: W/S for throttle and
braking/reverse, A/D or arrows for steering, mouse drag for orbit, R for
camera reset, and Space for stop/restart behavior in the reference test.
