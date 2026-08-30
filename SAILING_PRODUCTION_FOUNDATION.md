# Sailing Production Foundation 01

This is the production entry point for future sailing, water, and environment
work. It is a routing document, not a project history.

## Start here

Run the canonical isolated reference scene:

    E:\\让一艘船航行\\tools\\Godot\\Godot_v4.7.2-stable_win64.exe --path E:\\让一艘船航行 --resolution 1152x648 res://scenes/reference/SailingReferenceScene.tscn -- --sailing-reference

Or double-click 启动航海基准场景.bat.

The canonical scene is an isolated, drivable development reference. It is not
the formal game entry scene or a production level.

Controls in the reference scene:

- W / Up: forward acceleration
- S / Down: brake, then reverse after reaching zero
- A / D / arrows: steering
- left-mouse drag: camera orbit
- R: reset camera
- Space: stop/resume
- Backspace: reset to the reference route start

## Approved foundation

### Water

The approved water direction is B+ V3, implemented by one shared regional
shader and one shared Gerstner sampling path:

- Shader: materials/water_test/regional_ocean/regional_ocean_b_plus_v3.gdshader
- Controller and boat sampler: scenes/water/regional_ocean/regional_ocean_system.gd
- Preset resource: scenes/water/regional_ocean/regional_ocean_preset.gd
- Presets:
  - HarborCalm.tres
  - NorthAtlanticFaroe.tres
  - OpenOcean.tres
  - ShallowBay.tres

The shared base keeps the B+ V3 wave layers and couples the boat height,
pitch, and roll to the same analytic sample. Regional presets change restrained
color and response values. Coastal, Shallow, and Harbor are smooth local
modifiers over this base, not new water shaders.

Do not create another near-duplicate approved shader or another boat wave
sampler. If a new water experiment is needed, keep it isolated and classify it
below as history until explicitly approved.

## Canonical scene contents

scenes/reference/SailingReferenceScene.tscn is a thin entry scene that
instances the existing Regional Ocean system with --sailing-reference.
That mode reuses the existing:

- B+ V3-derived regional water;
- shared boat/wave coupling;
- drivable boat visual and current test camera;
- four regional presets;
- smooth Coastal / Shallow / Harbor local modifiers;
- simple shoreline, harbor, pier, and beacon proxy geometry;
- development-only world-scale reference objects.

The scale references are world objects, not a gameplay HUD. The proxy coast,
harbor, pier, and beacon remain placeholder geometry.

## Status map

### APPROVED

- scenes/reference/SailingReferenceScene.tscn: the single canonical sailing
  comparison scene.
- scenes/water/regional_ocean/: shared B+ V3 regional water foundation.
- scenes/water/RegionalOceanSystem.tscn: reusable implementation scene behind
  the canonical entry.
- COASTAL_WATER_REGIONAL_BLENDING_REPORT.md: evidence for smooth local
  coastal/harbor modifiers.
- scenes/water/overnight_v03/AssetGallery.tscn: scale and incoming-asset
  inspection tool, not a sailing reference scene.
- scenes/world/IslandPrototype.tscn and scenes/world/HarborPrototype.tscn:
  replaceable visual/collision mounting structures.

### REFERENCE / FALLBACK

- scenes/water/BoatWaveCouplingOceanPolish.tscn: B+ V3 and H3+ V3 coupling
  comparison. Use it only when inspecting coupling variants.
- H3+ V3: quieter alternative retained for comparison; it is not the approved
  primary water direction.
- scenes/water/overnight_v03/PortToPortSlice03.tscn: isolated A-to-B-to-A
  voyage-loop prototype. It remains preserved, but its older Surface Response
  05 water is not the canonical water source.
- scenes/water/RobinHoodsBayIslandBlockout01.tscn: placeholder destination
  reference.
- scenes/water/regional_ocean_captures/: visual evidence, not runtime source.

### EXPERIMENTAL HISTORY

These scenes document prior experiments and should not be selected as the new
starting point:

- StylizedOceanRND01.tscn
- WaterStyleTest02.tscn
- WaterStylePrototype03.tscn
- WaterBeautification04.tscn
- WaterColorRescue04B.tscn
- WaterSurfaceResponse05.tscn

WaterSurfaceResponse05 is still referenced by the isolated Port-to-Port V03
slice; preserve it until that slice is deliberately migrated. Historical
captures and reports are evidence only.

### OBSOLETE CANDIDATE

- WaterTest.tscn and addons/boujie_water_shader/: third-party benchmark
  material, not an approved project water direction.
- LesusX, Boujie, and Jtfinlay benchmark variants: retained only as documented
  research history where present; never treat them as production defaults.
- The older procedural island, mountain, and arrival silhouettes listed in
  docs/placeholder_assets.md: temporary spatial tests, not final environment
  assets.

No historical scene is deleted solely to make the tree look clean.

## World scale and asset entry

Convention: 1 Godot unit is approximately 1 meter.

The intended player sailboat hull is approximately 6 m in the production
world. The raw generated prototype boat is preserved and must not be silently
rescaled in formal sailing scenes.

Read these before importing new GLB/GLTF/FBX assets:

- docs/asset_scale_guide.md
- scenes/water/overnight_v03/WORLD_SCALE_GUIDE.md
- docs/asset_pipeline_guide.md
- scenes/water/overnight_v03/ASSET_IMPORT_WORKFLOW.md

Use scenes/water/overnight_v03/AssetGallery.tscn to check scale, pivot,
forward axis, materials, shadows, collision proxy, animation baggage, and
approximate face count. Put incoming assets under the staging directories in
scenes/water/overnight_v03/asset_staging/third_party/ or the corresponding
assets/3d/ category. Approve and place a visual asset only after it passes
gallery inspection.

Keep visual assets separate from gameplay collision. Replacing an island or
harbor visual must not require rewriting sailing control, boundary, arrival,
or wave sampling code.

## Formal boundaries

Do not casually modify:

- main.gd, Main.tscn, and the formal Sea Trial/Journey Test path;
- formal boat control, collision, wake, camera, and timer behavior;
- scenes/water/overnight_v03/PortToPortSlice03.tscn when working on the
  canonical water foundation;
- project.godot.

Use the canonical reference scene for new water, boat-wave, and environment
comparison work. Use Port-to-Port V03 only for its preserved voyage-loop
behavior unless a migration is explicitly requested.

## Complexity rule

Reuse the existing regional shader, preset resources, wave sampler, and
Godot-native scene composition first. Add a new helper only when it has more
than one clear consumer or removes a real maintenance risk. Do not introduce
parallel managers, duplicate wave formulas, or a second approved water family
to solve a local presentation problem.

## Quick verification

Headless scene inventory:

    $env:GDA_PROJECT = E:\\让一艘船航行
    $env:GDA_GODOT = E:\\让一艘船航行\\tools\\Godot\\Godot_v4.7.2-stable_win64_console.exe
    gda scene list --json
    gda info --json

Canonical route observation, including regional and local water transitions
and the return to open water:

    E:\\让一艘船航行\\tools\\Godot\\Godot_v4.7.2-stable_win64_console.exe --path E:\\让一艘船航行 --resolution 1152x648 res://scenes/reference/SailingReferenceScene.tscn -- --sailing-reference --observe-coastal-water

The observation is evidence for runtime loading, route movement, shared wave
sampling, and smooth profile transitions. Manual steering and camera comfort
still require a human playtest.

