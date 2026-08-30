# Terra Playable North Atlantic Showcase Slice 01

## Launch

Use `E:\让一艘船航行\启动Terra北大西洋展示切片01.bat`.

Scene: `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn`

This is an isolated landscape showcase. It does not replace Sea Trial, Journey Test, formal Port-to-Port, Port B Spatial 01, or `project.godot`.

## Integrated result

- Preserves the shared B+ V3 ocean, macro-wave structure, boat/wave coupling, controller, and protected follow-camera implementation.
- Preserves the Layout B open-sea -> reveal -> entrance -> dog-leg -> sheltered water -> working-shore sequence.
- Isolated route: 73 m. Approximate duration is 33.2 s at 2.2 m/s; deterministic capture traversal is about 14.6 s. Backspace resets this showcase slice to departure.
- The old broad harbor slowdown was removed from this isolated slice. Genuine contact restores the last safe position and caps the immediate impact response; there is no harbor-wide invisible slow zone.
- Added visual-only distant west coast, east island group, and far rocks. They have no collision and are subordinate context, not another destination.

## Wake decision

The old mosaic read came from repeated disconnected pale four-vertex patches. Two isolated candidates were tested:

- Candidate A: a continuous tapered world-history strip. It read as a hose/ribbon in close orbit review and remains a fallback only.
- Candidate B: two restrained divergent world-history filaments with gradual fade. It is the default because it avoids rectangular stamps, opaque ribbon behavior, and static decals.

Both candidates sample actual boat movement and use the water mesh local coordinate space for wave height. Candidate B is selected for this showcase. The close wake review uses a capture-only orbit preset; normal play remains on the protected camera path.

## Review cycles

1. Integration review found the old entrance slowdown in a broad proxy land-mask path. The isolated route now uses explicit channel limits plus genuine-contact handling. Showcase initialization also waits for inherited scene startup before sampling wake history.
2. Wake review compared Candidates A and B in the Godot renderer. A was rejected for its ribbon read; B was selected.
3. Presentation review removed floating redundant proxy buildings. A high-detail V2FUN warehouse derivative was tested only in this isolated scene and rejected from the visible slice for an incompatible photoreal collage read. The source/derivative remains preserved in `V2FUN_INBOX`; no production asset was altered.

## Runtime evidence

Final captures at 1152x648:

- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/01_departure.png`
- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/02_open_sea_wake.png`
- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/03_destination_context.png`
- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/04_B_approach.png`
- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/05_entrance.png`
- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/06_dog_leg_turn.png`
- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/07_inner_harbor.png`
- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/08_working_shore.png`
- `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_b/09_arrival_stop.png`

Contact sheet: `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/TerraShowcaseSlice01_contact_sheet.jpg`

## Automated evidence

- `gda` static validation passed for the Terra scene, Terra script, both wake candidates, and the scene resource.
- Route geometry/collision QA passed for center, moderate-left, moderate-right, early turn, late turn, safe lateral, and reverse B-to-A paths. The deliberately excessive lateral path was correctly rejected.
- Protected regressions passed: Sea Trial 01 input path, Sea Trial 01 navigation, Journey Test 02 navigation, and Sea Trial 02 world checks.
- Final capture run completed without runtime errors and emitted `TERRA_SHOWCASE_SLICE_01_READY` and `TERRA_SHOWCASE_CAPTURE_COMPLETE`.

## Checkpoints

- Baseline: `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_checkpoints/00_port_b_integration_02_baseline/`
- Integrated Candidate B: `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_checkpoints/01_integrated_candidate_b_playable/`

## Complexity review

A scoped Ponytail review removed unused high-poly V2FUN runtime-loading helpers after the visual integration was rejected. No new dependency, manager, parallel state machine, or formal-system abstraction was added.

## User drive gate

Human play is still required to judge speed feel, default-orbit presentation, entrance readability, dog-leg comfort, collision recovery, route duration, and whether the extra background geography improves the sense of regional scale.

## Files added or changed

- `scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn`
- `scenes/staging/terra_playable_north_atlantic_showcase_slice_01/terra_playable_north_atlantic_showcase_slice_01.gd`
- `scenes/staging/terra_playable_north_atlantic_showcase_slice_01/terra_showcase_wake_candidate_a.gd`
- `scenes/staging/terra_playable_north_atlantic_showcase_slice_01/terra_showcase_wake_candidate_b.gd`
- `scenes/staging/terra_playable_north_atlantic_showcase_slice_01_checkpoints/`
- `scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/`
- `启动Terra北大西洋展示切片01.bat`
- `TERRA_PLAYABLE_NORTH_ATLANTIC_SHOWCASE_SLICE_01_REPORT.md`

Formal Sea Trial, Journey Test, Port-to-Port, Port B Spatial 01, and `project.godot` were not modified.

## Execution notes

- Safe PowerShell exact-file edits were used where the Windows `apply_patch` helper was unavailable.
- gda/static and console runtime checks were used; Windows live-input tooling remains unreliable.
- Remaining quota/token: UNAVAILABLE