# PORT B ARRIVAL INTEGRATION 02 — PLAYTEST RECOVERY REPORT

## Current user-facing playtest

Use this launcher for the current playtest:

`E:\让一艘船航行\启动PortBArrivalIntegration02.bat`

Exact scene:

`scenes/staging/port_b_arrival_integration_02/PortBArrivalIntegration02.tscn`

The launcher explicitly passes the project path, the landscape resolution (`1152x648`), Compatibility rendering, and the current Integration 02 scene. It no longer relies on Godot's project default scene.

## Recovery findings

- Steering direction was wrong in this isolated wrapper because the canonical regional-ocean controller's input sign was left at its default. Integration 02 now explicitly uses `steering_input_sign = -1.0`, matching the protected verified profile: A/Left turns left and D/Right turns right from the default rear-follow view.
- The Integration 02 scene already referenced the B+ V3-derived `RegionalOceanSystem` and did not replace its Gerstner geometry, shared boat-wave sampling, or regional water uniforms. The missing historical wake was an integration omission: Integration 02 did not instantiate the clean-baseline stern wake helper. A scene-local stern-only helper now records world-space history and fades each fragment once; no hull-side stamped patches or bow effect were added.
- The isolated route was shortened for repeatable playtest review. The formal Sea Trial, Journey Test, Port-to-Port scenes, controller/camera/ocean baselines, and `project.godot` were not changed.

## Runtime evidence

Captured from the exact user-facing launcher after a real window launch and real keyboard input (`W`, then `A`):

- `scenes/staging/port_b_arrival_integration_02_playtest_captures/recovery/01_user_launch_landscape_start.png`
- `scenes/staging/port_b_arrival_integration_02_playtest_captures/recovery/02_user_launch_landscape_cruise_wake.png`
- `scenes/staging/port_b_arrival_integration_02_playtest_captures/recovery/03_user_launch_landscape_turn.png`

The captured game window is landscape (the window capture includes its title frame). The scene rendered without a test HUD or harness dependency. The start and turn captures show the current landscape world and the moving-water composition; the cruise capture is the wake review frame.

## Approximate playtest timing

With the shortened isolated route, the Port B entrance is intended to become reviewable after roughly 25–35 seconds of ordinary forward travel, depending on acceleration and steering. The working shoreline/arrival review is roughly 40–55 seconds from the reset position. These are staging-test timings, not formal voyage design.

## Controls

- `W` / `Up`: automatic forward travel input
- `S` / `Down`: brake/reverse according to the existing controller
- `A` / `Left`: steer left
- `D` / `Right`: steer right
- Mouse drag: camera orbit only
- `R`: reset camera
- `Backspace`: reset the isolated playtest position
- `Space`: preserve the existing controller's isolated stop/resume behavior

## Validation

- Integration script validation: passed for `port_b_arrival_integration_02.gd` and `port_b_arrival_playtest_wake.gd`.
- Scene validation: passed with no reported problems.
- Scene preflight: ready with no diagnostics.
- Exact launcher process verification: passed; the running command line named `PortBArrivalIntegration02.tscn` and the intended project path.
- Real-window smoke check: completed with landscape rendering and real `W`/`A` keyboard input. The remaining left/right feel, camera feel, shoreline readability, and wake believability remain a USER DRIVE GATE.

## Files changed in this recovery pass

- `启动PortBArrivalIntegration02.bat`
- `scenes/staging/port_b_arrival_integration_02/port_b_arrival_integration_02.gd`
- `scenes/staging/port_b_arrival_integration_02/port_b_arrival_playtest_wake.gd`
- `PORT_B_ARRIVAL_INTEGRATION_02_PLAYTEST_RECOVERY_REPORT.md`
- Runtime evidence under `scenes/staging/port_b_arrival_integration_02_playtest_captures/recovery/`

No formal Sea Trial, Journey Test, formal Port-to-Port, Port B Spatial 01, or `project.godot` file was changed.

## Remaining user-drive gate

The next human check should use the launcher above and confirm: A/Left and D/Right direction, the visible turn of the boat relative to the world, continuous wake on cruise/turn, and whether the shortened Port B entrance and working shoreline read clearly from the player's preferred driving angle. This pass intentionally stops here; it does not claim final harbor acceptance.
