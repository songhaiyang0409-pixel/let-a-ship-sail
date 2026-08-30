# P-19 Runtime Visual Cohesion & Port B Refinement Pass 05

## Scope and baseline note

This pass refines the existing playable Terra A-to-B slice in place. The checkout supplied to this session contains only commit `91d94a2` and does not contain the referenced `1a22429` object; no attempt was made to reconstruct or replace protected sailing systems. `RegionalOceanSystem`, B+ V3 water, boat coupling, controls, camera, wake, collision masks, `Main.tscn`, and `project.godot` remain unchanged.

## Three largest player-visible improvements

1. **A coast with an entrance, not two islands beside a dock.** The dominant western terrain now reaches the harbor mouth and folds into a separate lower inner shelter mass. This strengthens the exposed-sea / discovered-entrance / protected-basin sequence from the real route.
2. **A grounded working shoreline.** A low, dark, angled harbor bank now joins the inner terrain, quay, slipway, work apron, and waterline as one material group instead of leaving small slabs visually detached over the sea.
3. **Clearer near-shore depth.** A restrained tidal rock contact line under the western inner shoulder adds one quiet coast-contact layer without foam decals, bright ribbons, or prop clutter.

## Exact changed files

- `scenes/staging/terra_playable_north_atlantic_showcase_slice_01/terra_playable_north_atlantic_showcase_slice_01.gd`
- `P19_RUNTIME_VISUAL_COHESION_PORT_B_PASS_05_REPORT.md`

## Runtime evidence

- `godot --headless --path . scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn -- --terra-showcase-qa`
  - Scene ready; canonical B+ V3 regional ocean initialized.
  - Center, moderate-left, moderate-right, reverse B-to-A, late-turn, early-turn, and lateral-safe deterministic routes passed logical and physics clearance.
  - The intentionally excessive lateral route remained rejected.
  - Visual and collision roots remain separated.
- `godot --headless --path . scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn -- --capture-terra-showcase-slice-01 --terra-wake-b`
  - Full nine-stage traversal completed.
  - The dummy headless renderer cannot supply viewport textures, so PNG capture emitted `texture_2d_get` errors and produced no fabricated screenshots.

## Visual QA status

Runtime traversal and geometry checks are complete. Screenshot-based visual judgment is incomplete on this host because there is no display server or `xvfb-run`, while Godot's dummy renderer cannot read back viewport textures. The deterministic camera route did execute through all nine stages. Re-run the capture command below on a graphical Windows host to produce the evidence set.

## Three largest remaining weaknesses

1. The terrain is still authored procedural blockout geometry, so the headland silhouette needs graphical capture review for faceting and tangencies at the entrance.
2. The low work house, pier, and quay remain proxies; their scale grouping may still read as staging geometry at the final approach camera.
3. The regional water sequence and route length in this available slice are 73 m / about 33.2 s, not the 343 m / about 155.9 s P-18 baseline described by the issue. Resolving that requires the missing P-18 source commit rather than speculative replacement of protected systems.

## Blockers and decisions

- **Local blocker:** no display/Xvfb; actual game-camera PNG review is unavailable here.
- **Global blocker:** referenced commit `1a22429` is absent from all refs and objects in this checkout.
- **USER DECISION REQUIRED:** none for this reversible geometry pass. If exact P-18 continuity is required for the next pass, the repository must expose commit `1a22429` or its branch.

## Reproducible Windows launch

From the project directory:

```bat
tools\Godot\Godot_v4.7.2-stable_win64.exe --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn"
```

Capture the deterministic route:

```bat
tools\Godot\Godot_v4.7.2-stable_win64_console.exe --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn" -- --capture-terra-showcase-slice-01 --terra-wake-b
```
