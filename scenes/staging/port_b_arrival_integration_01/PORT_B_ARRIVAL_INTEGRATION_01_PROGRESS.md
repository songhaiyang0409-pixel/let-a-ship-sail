# PORT B ARRIVAL INTEGRATION 01 — PROGRESS

## Scope
New isolated staging slice derived from the selected Layout B dog-leg harbor in
scenes/staging/port_b_spatial_01/NorthAtlanticPortBSpatial01.tscn.

Protected source files remain the authority and are not edited:
- Port B Spatial 01 source
- Reconstruction 03
- formal Sea Trial / Journey Test / Port-to-Port
- project.godot
- canonical boat, camera, ocean and wake implementations

## Checkpoint 00 — forensic review
Observed from the existing 648x1152 runtime captures:
1. The earlier capture sequence reached useful locations, but did not make the dog-leg turn itself a distinct journey beat.
2. The working shoreline and pier/apron still read as temporary blockout slabs, so the arrival relationship needs to unfold more clearly through motion.
3. The selected route's collision and imperfect-steering room were not yet demonstrated by dedicated center/left/right and reverse QA.

## Autonomous status
- New scene/script copied into this directory only.
- Layout B remains the only active layout.
- The new harness will capture nine journey beats and run geometry/physics probes.
- Human steering, collision recovery feel, near-shore camera feel and final arrival feeling remain USER DRIVE REQUIRED.
## Review cycle 01 — completed
- Evidence: ../port_b_arrival_integration_01_captures/cycle_01_apron/
- Fix: reduced the working apron visual weight.
- Runtime result: less foreground slab dominance; shed/pier remained the next issue.

## Review cycle 02 — completed
- Evidence: ../port_b_arrival_integration_01_captures/cycle_02_grounding/
- Fix: reduced B shed instance scale to 3.8 and rebuilt the pier as three thinner dog-leg segments.
- Runtime result: building and landing read with less blockout mass.

## Review cycle 03 — completed
- Evidence: ../port_b_arrival_integration_01_captures/cycle_03_entrance/
- Fix: strengthened the east inner-arm dog-leg read, reduced the apron again, and made capture turn points more explicit.
- Runtime result: clearer entrance turn; late-turn margin remains a human-drive risk.

## Final autonomous QA
- 9 deterministic A-to-B portrait stages captured in-engine.
- 7 route probes clear: center, moderate_left, moderate_right, reverse_B_to_A, slightly_late_turn, slightly_early_turn, lateral_offset.
- Minimum entrance margins: center 14 m; moderate_left 8 m; moderate_right 23 m; reverse 18 m; late 4 m; early 14 m; lateral 15 m.
- Collision report: visual/collision roots separated; human steering certification remains pending.
- Protected regression: Sea Trial 01 input path PASS; Sea Trial 01 navigation PASS; Journey Test 02 navigation PASS.