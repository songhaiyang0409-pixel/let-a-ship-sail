# FIRST REAL ISLAND — NATURAL WORLD PASS 02

## Scope

This is an isolated natural-world pass built on
FirstRealIslandVisualSlice01. It keeps the existing SailingReferenceScene
responsible for B+ V3 water, boat/wave coupling, camera, controls, and the
temporary coastal navigation authority.

The evaluation mode hides the placeholder houses, beacon, and reserved future
building markers. The point of this pass is to test whether the island still
reads as a destination from terrain, exposed rock, vegetation, water, and
harbor geography alone.

No formal Sea Trial, Journey Test, Port-to-Port scene, project settings, boat
control, camera core, water shader, collision, or wake file was changed.

## What changed

The isolated visual script now builds the island from a small number of
deliberate low-cost natural masses:

- exposed grey coastal rock mound;
- smaller green upper landform placed on the camera-facing side;
- two inner slope mounds that frame the harbor water;
- a rear rise that supplies one simple height change;
- low-poly boulders at the outer coast and harbor mouth;
- three curated vegetation groups: west sheltered grove, east sheltered
  grove, and sparse windward vegetation.

The long rectangular shore shelves and imported rock instances that read as
white blocks were removed. KayKit CC0 is retained for trees, bushes, and its
license-backed natural source; shoreline boulders in this pass are deliberately
small generated placeholder forms because the imported rock variants did not
read correctly at the gameplay camera.

Buildings and the beacon remain in the normal isolated slice as explicitly
marked placeholder/future layers. They are hidden by --natural-only and by
the natural capture command.

## Natural-world decisions

- The harbour is read through two headlands, a central protected channel, a
  rear rise, the existing restrained pier, and boulders at the mouth. No
  marker or building is required to understand the opening.
- Rock is placed at the water edge and remains visible below the green upper
  land instead of using a single green plate.
- Vegetation is grouped in sheltered pockets and kept sparse on the
  windward rise. There is no uniform random forest.
- Green/grey colors were muted and split into lower/upper graphic faces. The
  landforms use stable graphic materials so the hierarchy is not washed out by
  the test environment.

## Additional pack review

The only imported natural subset used here remains the CC0 KayKit Forest
Nature Pack. Other supplied downloads were checked during curation:

- LowpolyForestPack: potentially useful silhouettes, but the supplied files
  did not include a clear redistribution license.
- MBJ Plant Pack: personal/commercial terms were present, but redistribution
  restrictions make it unsuitable for this committed subset.
- Broken Vector/Models/Textures downloads: overlapping or duplicate packages
  with incomplete license evidence.
- Blender and Unity packages: not used because this pass does not need a
  conversion dependency.

No additional pack met the combined license, camera-readability, and
silhouette bar for this pass.

## Visual QA

The scene was launched with the actual Godot 4.7.2 Compatibility renderer at
1152x648. The natural capture run completed with no script or shader errors
and reported:

draw_calls=74, primitives=367024, buildings_hidden=true

Natural-world captures:

- first_real_island_natural_world_pass_02_captures/01_distant_approach.png
- first_real_island_natural_world_pass_02_captures/02_medium_approach.png
- first_real_island_natural_world_pass_02_captures/03_coastline.png
- first_real_island_natural_world_pass_02_captures/04_harbor_entrance.png
- first_real_island_natural_world_pass_02_captures/05_inside_harbor.png
- first_real_island_natural_world_pass_02_captures/06_buildings_hidden_natural_view.png

Concrete checks:

- distant view reads a compact land destination rather than a straight
  rectangular plate;
- medium and coastline views show grey shore masses, green upper land, and
  irregular boulders;
- the center channel and pier establish a protected harbor opening;
- the boat stays owned and positioned by the existing reference system;
- natural-only mode hides houses, beacon, and future building markers;
- no new UI, characters, missions, objects, or gameplay systems were added.

## Acceptance status

The natural blockout criteria are met for this prototype pass: the hidden
man-made layer is still intentional, the island has a readable destination
silhouette, grey rock participates in the coast, green land sits above it,
the boundary is no longer a single flat edge, vegetation is grouped, colors
are restrained, and the harbor geography can be read without buildings.

Known limitations remain intentionally visible:

- the island is still a low-cost placeholder blockout, not final art;
- the mound language is simple and needs authored island meshes later;
- the KayKit vegetation remains generic at close distance;
- the pier is still a placeholder cue;
- the hidden natural test is stronger than the default man-made presentation,
  so future building placement must respect the natural landform rather than
  cover it.

## Files

Modified isolated file:

- scenes/visual_slices/first_real_island_visual_slice_01.gd

New launcher:

- 启动第一真实岛屿自然世界Pass02.bat

New report:

- scenes/visual_slices/FIRST_REAL_ISLAND_NATURAL_WORLD_PASS_02_REPORT.md

Existing V01 files and captures were preserved. Formal project files modified:
0.

## Launch

Double-click:

启动第一真实岛屿自然世界Pass02.bat

Equivalent command:

tools/Godot/Godot_v4.7.2-stable_win64.exe --path . res://scenes/visual_slices/FirstRealIslandVisualSlice01.tscn -- --sailing-reference --natural-only

