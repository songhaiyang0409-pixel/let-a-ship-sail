# P-13 — Overnight World & Boat-Ready Integration Pass 01

## Checkpoint and scope

Work continued in the existing `PortBArrivalIntegration02` A-to-B slice. The
formal project scene, controller, camera, B+ V3 shader, wave sampler, wake
implementation, and protected test scenes were not changed. Rollback is one
localized script revert plus removal of the visual adapter.

Destination B remains **USER DRIVE GATE PENDING**. This pass does not claim
final visual approval or final harbor completion.

## Three largest player-facing changes

1. The playable route now begins outside Destination A at z=166 and runs 359 m
   to the working shore, instead of beginning at z=-105 only 88 m from arrival.
   At the protected 2.2 m/s cruise this gives about 163 seconds of travel and a
   materially distinct open-sea interval.
2. A now has a geographically framed departure mouth and outer marks; B gains
   two sparse, asymmetric outer skerries. These establish departure separation,
   give B a distant reveal, and lead the eye toward the existing offset dog-leg
   without HUD guidance.
3. The unchanged shared B+ V3 water now follows the journey order North Atlantic
   → Open Ocean → Shallow Bay → Harbor Calm across broad transitions. The final
   sheltered-water change is therefore caused by the approach and harbor, not a
   separate water implementation.

## Boat-ready integration

The current geometry is preserved but moved under
`VisualModelMount_REPLACE_CONTENTS_ONLY`. Steering, the camera, wave pose,
shader boat uniforms, and wake still reference the unchanged outer controlled
root. `PLAYER_BOAT_MODEL_SCENE` is the single empty hook for tomorrow's
`PackedScene`; the exact path, axes, scale, pivot, optional animation children,
and protected boundaries are documented in
`docs/player_boat_model_integration.md`.

## Runtime evidence

Godot 4.7.2 stable ran the scene directly. Three independent autonomous QA
passes completed. Each reported all seven center/offset/early/late/reverse
routes logically and physically clear; the tightest intended late-turn margin
remains 4.0 m. The adapter reported `motion_root_untouched=true`. Protected Sea
Trial input/navigation and Journey Test navigation all passed.

Commands:

```bash
godot --headless --path . scenes/staging/port_b_arrival_integration_02/PortBArrivalIntegration02.tscn -- --port-b-arrival-qa
godot --headless --path . --script tests/sea_trial_01_input_path_check.gd
godot --headless --path . --script tests/sea_trial_01_navigation_check.gd
godot --headless --path . --script tests/journey_test_02_navigation_check.gd
```

The headless dummy renderer could run the deterministic nine-stage camera route
but returned null viewport textures, so it produced no screenshot files. No
visual evidence is fabricated. Reproducible display launch:

```bash
godot --path . --resolution 1152x648 scenes/staging/port_b_arrival_integration_02/PortBArrivalIntegration02.tscn
```

## Exact changed files

- `scenes/staging/port_b_arrival_integration_02/port_b_arrival_integration_02.gd`
- `scenes/staging/port_b_arrival_integration_02/player_boat_visual_adapter.gd`
- `docs/player_boat_model_integration.md`
- `OVERNIGHT_WORLD_BOAT_READY_INTEGRATION_PASS_01_REPORT.md`

## Remaining blockers / user decisions

- **USER DRIVE GATE:** steering comfort, discoverability under imperfect
  approaches, collision recovery at the 4 m late-turn margin, and whether the
  163-second interval feels appropriately substantial.
- **USER VISUAL DECISION:** approve the world composition and the finalized boat
  model in a display-capable local run. Cloud headless capture was unavailable.
- The finalized player boat does not yet exist in this repository; tomorrow's
  swap should follow the documented adapter contract and rerun the commands
  above before visual/feel approval.
