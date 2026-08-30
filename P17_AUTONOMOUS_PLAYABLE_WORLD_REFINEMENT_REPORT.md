# P-17 Autonomous Playable World Refinement & Sailing Feel Pass 03

## Playable result

The isolated Terra showcase remains the launch target:

- Scene: `res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn`
- Windows launcher: `启动Terra北大西洋展示切片01.bat`
- Route: Destination A at `z=150` to Destination B at `z=-193`, 343 m.
- Estimated normal crossing: 155.9 seconds at 2.2 m/s; deterministic test traversal: 68.6 seconds.

The formal project main scene, formal Sea Trial/Journey scenes, controls, camera, B+ V3 shader, boat-wave coupling, collision architecture, and wake implementation were not changed.

## Three largest visible improvements

1. **The playable interval is now a real 2–3 minute crossing.** The earlier compressed 73 m showcase was extended to 343 m while preserving the established A and B endpoints and harbor dog-leg.
2. **Open water now has restrained compositional rhythm.** Continuous departure coast shoulders, three sparse asymmetric skerry groups, and low far-coast reveal forms establish departure separation, mid-crossing scale, and destination anticipation without route arrows or HUD.
3. **Coast-to-water contact is structural rather than stamped.** Repeated six-sphere shore strips were replaced by continuous irregular rock-edge meshes. Port B also gains a small warm diegetic beacon at its existing headland landmark.

## Ocean and transition work

The protected shared B+ V3 foundation was retained. Only regional transition distances were redistributed across the longer route: Harbor Calm / North Atlantic transition at 42–72 m, Open Ocean at 148–188 m, and Shallow Bay approach at 272–302 m. Runtime logs confirmed transition into North Atlantic/Faroe, Open Ocean, and Shallow Bay during deterministic traversal.

## Runtime and regression evidence

- Godot 4.7.2 loaded and ran the isolated scene.
- Route QA passed the center, moderate-left/right, early/late turn, lateral-safe, and reverse B→A paths; the intentionally excessive lateral route remained correctly rejected.
- Sea Trial 01 input, Sea Trial 01 navigation, Journey Test 02 navigation, and Sea Trial 02 world checks passed.
- A deterministic 11-stage route capture traversal completed and reported the expected 343 m / 155.9 s route.
- This Linux container has no display server or `xvfb-run`. Headless Godot uses the dummy renderer, so viewport readback produced null-texture errors and no trustworthy PNGs. Visual QA is therefore incomplete rather than fabricated.

## Remaining three largest weaknesses

1. Port B houses, quay, pier, and work gear remain intentionally simple proxies and need a later approved art replacement/grounding pass.
2. The new long crossing needs human drive approval for pace, steering comfort, skerry framing, and the timing of first B reveal.
3. Rendered gameplay-camera and phone-size comparison captures must be repeated on a machine with a display-capable Godot renderer.

## Blockers and decisions

- **Local blocker:** display capture is unavailable in this container; it did not block geometry, runtime traversal, route QA, or protected regression work.
- **Global blockers:** none.
- **USER DECISION REQUIRED:** none for continued safe development. Human play remains a subjective approval gate, not a production blocker.

## Reproducible launch and QA

- Windows play: run `启动Terra北大西洋展示切片01.bat`.
- Linux/editor play: `godot --path . --rendering-method gl_compatibility scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn`.
- Deterministic route QA: `godot --headless --path . --rendering-method gl_compatibility scenes/staging/terra_playable_north_atlantic_showcase_slice_01/TerraPlayableNorthAtlanticShowcaseSlice01.tscn -- --terra-showcase-qa`.

