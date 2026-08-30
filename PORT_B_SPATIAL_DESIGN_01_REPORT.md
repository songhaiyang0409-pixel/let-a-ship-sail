# PORT_B_SPATIAL_DESIGN_01_REPORT

## Scope

This is an isolated Destination B spatial rebuild. The preserved Reconstruction 03 scene remains the rollback/reference baseline. No formal Sea Trial, Journey Test, Port-to-Port slice, `project.godot`, canonical camera/controller, B+ V3 shader, boat-wave coupling, or clean historical wake file was modified by this task.

## Staging scene and launcher

- Scene: `scenes/staging/port_b_spatial_01/NorthAtlanticPortBSpatial01.tscn`
- Script: `scenes/staging/port_b_spatial_01/north_atlantic_port_b_spatial_01.gd`
- Launcher: `启动DestinationBHarborSpatial01.bat`
- Portrait capture root: `scenes/staging/port_b_spatial_01_captures/`

The scene instances `scenes/reference/SailingReferenceScene.tscn` and reuses the existing Regional Ocean system. The new script owns only temporary world geometry, V2FUN working-derivative mounting, command-line candidate selection, and deterministic capture traversal.

## Spatial result

Default selected layout: **B — dog-leg cove**.

The selected staging geography contains a large western headland, lower eastern shoulder, a continuous rear coast, an offset inner working shore, a restrained pier/apron/path relation, one mounted working shed, two simple proxy houses, one landmark, and sparse shore/breakwater forms. The additional rear coast was added after the candidate comparison because the first pass still read as separate hills.

The sequence represented by the harness is:

`open sea → distant B reveal → approach → harbor entrance → inner water → working shoreline → arrival`

The route proxy remains about 335 m. The deterministic harness traverses it at 5 m/s over staged frame intervals for repeatable evidence; this is not a claim about final game travel time or human steering.

## Candidate comparison

- **A — offset narrow inlet:** clear split entrance, but the working shore remained more marker-like.
- **B — dog-leg cove:** strongest spatial separation between exposed approach, constrained entrance, protected water, and a working shore. Selected.
- **C — asymmetric high headland:** strongest scale silhouette, but its shoreline/work relation was less direct.

Comparison contact sheet: `scenes/staging/port_b_spatial_01_captures/layout_candidates_contact.jpg`

## Runtime evidence

All listed images are actual Godot runtime captures from the new scene and are 648x1152 (9:16):

- `scenes/staging/port_b_spatial_01_captures/final/01_distant_destination_reveal.png`
- `scenes/staging/port_b_spatial_01_captures/final/02_approach.png`
- `scenes/staging/port_b_spatial_01_captures/final/03_harbor_entrance.png`
- `scenes/staging/port_b_spatial_01_captures/final/04_inner_harbor.png`
- `scenes/staging/port_b_spatial_01_captures/final/05_working_shoreline.png`
- `scenes/staging/port_b_spatial_01_captures/final/06_arrival.png`

Candidate evidence is retained in `layout_a/`, `layout_b/`, and `layout_c/` under the same capture root.

## Confirmed / partially confirmed / not confirmed

### Confirmed by local checks

- New scene resource validates in gda.
- New script validates in gda.
- Layout A, B, C and selected final runs launched in Godot 4.7.2 and exited through the capture harness.
- Runs printed `PORT_B_SPATIAL_01_CAPTURE_COMPLETE` with no observed Godot stderr.
- Existing B+ V3 regional ocean path, boat visual, camera, and wave-follow initialization were present.
- Final evidence is portrait gameplay-camera output, not editor screenshots.
- The new scene and script are separate from Reconstruction 03.

### Partially confirmed

- The deterministic harness proves a repeatable in-engine spatial traversal and capture path, but it does not prove that a human can steer A→B or B→A through every narrow passage.
- The working shoreline is functionally readable as a staging relationship, but its apron/path geometry remains blockout-level.

### Not confirmed — user drive required

- Manual A→B and B→A steering.
- Manual entry into the dog-leg cove, collision clearance, and escape behavior.
- Whether the selected spatial sequence creates the intended “I found a protected working harbor” feeling in live play.

The Windows gda live-input limitation was not retried; it is recorded as a user gate rather than treated as runtime evidence.

## Known visual limitations

- Terrain and proxy houses remain deliberately low-cost blockout geometry.
- The working apron/path uses simple proxy surfaces and is not final harbor art.
- V2FUN shed is a working derivative and may still need final placement, material simplification, and art-direction approval.
- The current ocean remains the shared B+ V3 foundation; no local harbor-water shader experiment was added here.
- The portrait framing is a staging-only adjustment to the referenced camera instance, not a change to the formal camera script.

## Validation commands

Capture selected layout:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" "res://scenes/staging/port_b_spatial_01/NorthAtlanticPortBSpatial01.tscn" -- --capture-port-b-spatial-01 --port-b-final
```

Candidate A/C use `--port-b-layout-a` or `--port-b-layout-c` instead of `--port-b-final`.

Manual isolated scene:

```powershell
& "E:\让一艘船航行\启动DestinationBHarborSpatial01.bat"
```

## Files added or changed

Added:

- `scenes/staging/port_b_spatial_01/NorthAtlanticPortBSpatial01.tscn`
- `scenes/staging/port_b_spatial_01/north_atlantic_port_b_spatial_01.gd`
- `启动DestinationBHarborSpatial01.bat`
- `PORT_B_SPATIAL_DESIGN_01_CHECKPOINT_00.md`
- `PORT_B_SPATIAL_DESIGN_01_CHECKPOINT_01.md`
- `PORT_B_SPATIAL_DESIGN_01_CHECKPOINT_02.md`
- `PORT_B_SPATIAL_DESIGN_01_CHECKPOINT_03.md`
- `PORT_B_SPATIAL_DESIGN_01_CHECKPOINT_04.md`
- `PORT_B_SPATIAL_DESIGN_01_PROGRESS.md`
- `PORT_B_SPATIAL_DESIGN_01_REPORT.md`
- runtime capture PNGs and comparison JPGs under `scenes/staging/port_b_spatial_01_captures/`

Preserved R03 files were read as baseline evidence and were not edited. No formal project files were modified.