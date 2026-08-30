# Overnight North Atlantic World Reconstruction 02

## Result

This is an isolated playable-world reconstruction, not final island art. The canonical overnight scene is:

`res://scenes/staging/OvernightPlayableNorthAtlanticWorld01_Fixed.tscn`

The route remains approximately **335 m** from A to B. At the preserved regional test speeds, the reported travel times are approximately **152.3 s normal** and **67.0 s test**. The current wrapper captures repeatable route positions for visual QA; the capture mode is not a substitute for a user playtest of steering.

## Preserved foundation

- B+ V3 / one shared RegionalOceanSystem and shared boat-wave sampling.
- Existing boat, cabin, camera, controls, wake, scale relationship, and V2FUN working derivatives.
- Regional samples remain Harbor Calm → North Atlantic / Faroe → Open Ocean → Shallow Bay.
- Formal Sea Trial, Journey Test, formal Port-to-Port scenes, and `project.godot` were not changed.

## World reconstruction

- Destination A: three continuous irregular sloped landforms, exposed rocky landing, cottage path, short beacon, and restrained windward rocks.
- Destination B: two sheltered headlands, an inhabited rear slope, a low working harbor bank, irregular shore/breakwater rocks, dock/path relationship, two small proxy houses, short beacon, and the V2FUN fishing shed.
- Terrain proxies use low-cost custom grid meshes with irregular shore/front edges, broad slope, turf top, and tapered rock-cut skirts. They are marked `DESIGNED_TERRAIN_PROXY` / `OVERNIGHT_BLOCKOUT` and are not final art.
- The V2FUN cottage and fishing shed remain working high-detail derivatives at the existing staging scale `8.0`; they are not mobile-final assets.

## Quality cycles completed

1. Replaced rectangular slab blocks with continuous asymmetric sloped landforms.
2. Added front/back rock-cut shore geometry after the first real capture showed green terrain meeting water too abruptly.
3. Tapered and lowered shore walls after the second capture showed rectangular vertical cuts.
4. Added a low harbor working bank under the B warehouse approach and slightly reduced staging fog density; expanded the evidence sequence to eight views.

Each cycle was followed by a Godot run and real game-camera capture inspection. The inspected contact sheets showed improved continuous landform and harbor framing, while retaining visible blockout limitations.

## Standard captures

Directory:

`scenes/staging/overnight_playable_north_atlantic_world_01_captures/`

- `01_departure_A.png`
- `02_open_sea.png`
- `03_mid_voyage.png`
- `04_first_distant_read_B.png`
- `05_approach_B.png`
- `06_harbor_entry_B.png`
- `07_arrival_B.png`
- `08_reverse_view.png`

The pre-reconstruction visual baseline is preserved in:

`scenes/staging/overnight_playable_north_atlantic_world_01_captures/baseline_before_reconstruction/`

## Validation and risks

- `gda script validate` passed for the fixed wrapper and shared `regional_ocean_system.gd`.
- `gda scene preflight` reported `ready` with no diagnostics for the fixed scene.
- Real Godot 4.7.2 Compatibility run completed with `PLAYABLE_WORLD_CAPTURE_COMPLETE` and no shader/script error in the run output.
- The wrapper adds only a small number of low-resolution procedural proxy meshes; no new shader or high-frequency texture cost was introduced. A reliable GPU-ms benchmark was not available from this Windows headless capture path, so mobile performance still requires a device/profile pass.
- The old non-fixed overnight draft remains in the project as superseded history and is not the launch target.

## Known weak points

1. The terrain is now continuous and sloped, but it is still a neutral procedural blockout with broad graphic faces rather than believable finished geology.
2. Proxy houses and the V2FUN buildings establish scale and destination identity, but their grounding and architectural integration need an art-directed asset pass.
3. A/B route steering, collision edge cases, and the feeling of harbor arrival still require human playtest; static capture mode cannot prove those subjective/runtime behaviors.

## Launch

Double-click:

`启动OvernightNorthAtlanticWorldReconstruction02.bat`

Equivalent command:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" --rendering-method gl_compatibility --resolution 1152x648 "res://scenes/staging/OvernightPlayableNorthAtlanticWorld01_Fixed.tscn" -- --sailing-reference --overnight-playable-north-atlantic-world-01
```
