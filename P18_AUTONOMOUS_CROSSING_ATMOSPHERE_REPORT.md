# P-18 Autonomous Crossing Atmosphere & Harbor Approach Pass 04

## Player-facing improvements by impact

1. **A crossing with readable phases.** The isolated continuation preserves the 343 m / 155.9 s route, but redistributes the protected regional-ocean transitions across departure, North Atlantic, open ocean, shallow approach, and harbor water. Two sparse asymmetric skerry groups provide parallax without route arrows or open-sea clutter.
2. **Progressive destination reveal.** Three offset terrain depth layers replace paired primitive horizon lumps. Departure A falls away before the mid-weather coast appears; the low far-east layer and broad Port B backdrop then establish an increasingly enclosed approach.
3. **A coherent dog-leg arrival.** Port B was moved as one geographic unit to the end of the long crossing. Its existing wide outer entrance, left dog-leg, working quay, slipway, pier, and restrained beacon remain intact; visual terrain and simple collision proxies remain separate.
4. **Reversible contact recovery retained.** Contact correction only restores the last safe water pose and caps speed after demonstrated land contact. It does not create a hidden slow zone or modify the protected boat controller.

## Exact changed files

- `scenes/staging/crossing_atmosphere_harbor_approach_pass_04/CrossingAtmosphereHarborApproachPass04.tscn`
- `scenes/staging/crossing_atmosphere_harbor_approach_pass_04/crossing_atmosphere_harbor_approach_pass_04.gd`
- `P18_CHECKPOINT.md`
- `P18_AUTONOMOUS_CROSSING_ATMOSPHERE_REPORT.md`

No formal reference, Sea Trial, Journey Test, ocean shader, boat controller, or `project.godot` file changed.

## Runtime evidence

- `godot --headless --path . --rendering-method gl_compatibility scenes/staging/crossing_atmosphere_harbor_approach_pass_04/CrossingAtmosphereHarborApproachPass04.tscn -- --p18-qa`
  - PASS: scene ready at 343 m and 155.9 s normal travel time.
  - PASS: center, moderate-left, moderate-right, reverse, early-turn, late-turn, and lateral-safe paths clear logically and physically.
  - PASS: intentionally excessive lateral route rejected by the logical shoreline mask.
  - PASS: Visual != Collision reported by the harness.
- `godot --headless --path . --rendering-method gl_compatibility scenes/staging/crossing_atmosphere_harbor_approach_pass_04/CrossingAtmosphereHarborApproachPass04.tscn -- --capture-p18`
  - PASS: all 11 deterministic poses traversed and all four water regions activated in order.
  - LIMITATION: the headless dummy renderer exposes no viewport texture, so PNG writes failed and visual QA remains incomplete. No fabricated images are included.

## Three largest visible improvements

1. More convincing departure separation and open-water duration.
2. Calm near/mid/far geography with asymmetric parallax and staged destination reveal.
3. Port B now emerges through coastal approach water before the geography-led dog-leg and working shore.

## Three largest remaining weaknesses

1. Port B buildings remain authored proxies and need a gameplay-camera silhouette/grounding pass on a display-capable renderer.
2. The procedural terrain still has a deliberately compressed material vocabulary; shoreline contact needs final screenshot-based color tuning.
3. Human steering comfort through the entrance has not been certified; deterministic and reverse path probes cannot replace hands-on input.

## Blockers and decisions

- **Local blocker:** this container's headless dummy renderer cannot return viewport pixels. Run the capture command on a display-capable Vulkan/OpenGL session for mandatory screenshot review.
- **Global blockers:** none. The scene is runnable and deterministic QA passes.
- **USER DECISION REQUIRED:** none. Boat hidden geometry was not invented and no locked identity was changed.

## Reproducible local launch

From the repository root:

```bash
godot --path . scenes/staging/crossing_atmosphere_harbor_approach_pass_04/CrossingAtmosphereHarborApproachPass04.tscn
```

Controls remain inherited from the protected sailing reference: W/S speed, A/D or arrows steer, mouse drag observes, R resets camera, and Backspace returns to departure.
