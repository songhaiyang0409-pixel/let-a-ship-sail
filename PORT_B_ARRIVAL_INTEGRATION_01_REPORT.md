# PORT B ARRIVAL INTEGRATION 01

## Result

An isolated Layout B dog-leg arrival slice is present and verified by an in-engine deterministic portrait harness. The original Port B Spatial 01 source and protected sailing systems were not edited.

This is a staging/blockout integration result, not a claim of final harbor art and not a substitute for USER DRIVE GATE.

## Entry points

- Scene: res://scenes/staging/port_b_arrival_integration_01/PortBArrivalIntegration01.tscn
- Script: res://scenes/staging/port_b_arrival_integration_01/port_b_arrival_integration_01.gd
- Launcher: 启动PortBArrivalIntegration01.bat
- Portrait evidence: res://scenes/staging/port_b_arrival_integration_01_captures/final/
- QA log: res://scenes/staging/port_b_arrival_integration_01_captures/PORT_B_ARRIVAL_INTEGRATION_01_QA.txt

Launch command:

启动PortBArrivalIntegration01.bat

Equivalent command:

tools\Godot\Godot_v4.7.2-stable_win64.exe --path "E:\让一艘船航行" --resolution 648x1152 "res://scenes/staging/port_b_arrival_integration_01/PortBArrivalIntegration01.tscn"

## Selected Layout B journey

The selected dog-leg is preserved in the integration copy. The harness presents:

1. 01_departure.png
2. 02_open_sea.png
3. 03_distant_B.png
4. 04_approach.png
5. 05_entrance_discovery.png
6. 06_dog_leg_turn.png
7. 07_inner_water.png
8. 08_working_shore_reveal.png
9. 09_arrival.png

The entrance is framed by the west headland and east inner arm. The working shore uses the existing blockout apron, work path, pier, inner shore and V2FUN working derivative shed. The harbor is still intentionally sparse.

## Autonomous route and collision QA

All seven deterministic routes reported clear=true, logical_clear=true, and physics_clear=true:

- center: 14 m minimum entrance margin
- moderate left: 8 m
- moderate right: 23 m
- reverse B-to-A: 18 m
- slightly early turn: 14 m
- lateral offset: 15 m
- slightly late turn: 4 m

The 4 m late-turn margin is recorded as a risk, not as comfortable human steering clearance. Reverse and imperfect-approach probes passed the available logical/physics checks. The collision QA confirms separated visual and simple collision roots for headlands, quay/apron, work path/slipway and inner shoreline.

human_steering_certified=false remains intentional. Camera feel, shoreline feel, collision recovery, and final arrival feeling still require the user to drive the scene.

## Three runtime review/fix cycles

### Cycle 01 — shoreline weight

Reduced the Layout B working apron from (17, 0.28, 5) to (12, 0.16, 3.4) after inspecting the actual arrival frames. Evidence: cycle_01_apron/.

### Cycle 02 — grounding

Reduced only the B working shed instance from scale 4.5 to 3.8 and replaced the four thick pier slabs with three thinner, shorter offset segments. Evidence: cycle_02_grounding/.

### Cycle 03 — entrance readability

Moved the copied east inner arm from x 28 to x 25 with width 9, reduced the apron to position (-7, 0.39, -194) and size (8.5, 0.12, 2.6), and made the deterministic turn points more explicit. Evidence: cycle_03_entrance/ and final/.

The final portrait contact sheet is final_journey_contact_sheet.jpg. A matching-stage comparison with the available original Port B evidence is baseline_vs_final_contact_sheet.jpg. The individual final PNGs are the primary evidence.

## Protected baseline regression

The following existing checks passed after the integration work:

- SEA_TRIAL_01_INPUT_PATH_CHECK: PASS
- SEA_TRIAL_01_NAVIGATION_CHECK: PASS
- JOURNEY_TEST_02_NAVIGATION_CHECK: PASS

The final script and scene passed gda script validation, scene validation and scene preflight. A bounded non-harness Godot launch also started the isolated scene successfully.

No changes were made in this task to:

- original Port B Spatial 01 scene/script
- formal Sea Trial
- Journey Test
- formal Port-to-Port
- project.godot
- canonical boat/controller/camera/ocean/wake implementations

## Evidence limits and remaining risks

- The final nine images are individual 648x1152 portrait captures from the isolated scene.
- The harness is deterministic pose traversal, so it proves scene loading, stage composition, geometry probes and capture output; it does not prove human steering comfort.
- The staging island, houses, pier, apron, path and collision volumes remain proxy/blockout content.
- The late-turn 4 m margin may be too tight for a person.
- Arrival feeling, camera/shoreline occlusion, actual collision recovery and whether the dog-leg naturally invites the player inward remain USER DRIVE REQUIRED.