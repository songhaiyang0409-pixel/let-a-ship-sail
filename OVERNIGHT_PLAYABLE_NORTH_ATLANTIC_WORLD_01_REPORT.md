# OVERNIGHT PLAYABLE NORTH ATLANTIC WORLD 01

## Active isolated slice

- Scene: `scenes/staging/OvernightPlayableNorthAtlanticWorld01_Fixed.tscn`
- Script: `scenes/staging/overnight_playable_north_atlantic_world_01_fixed.gd`
- Launcher: `启动OvernightNorthAtlanticPlayableWorld01.bat`
- Renderer used for validation: Godot 4.7.2, Compatibility, NVIDIA GeForce RTX 4070 SUPER
- Normal gameplay command: `启动OvernightNorthAtlanticPlayableWorld01.bat`

The earlier `OvernightPlayableNorthAtlanticWorld01.tscn` draft is superseded. Use the `Fixed` scene above; it is the scene that passed validation and runtime capture.

## World and route

- World scale: 1 Godot unit approximately 1 meter.
- Route: z=160 to z=-175, approximately 335 meters.
- Expected route time: approximately 152.3 seconds at 2.2 m/s; approximately 67.0 seconds at 5.0 m/s test speed.
- Regional water samples: Harbor Calm at 0 m, North Atlantic/Faroe at 82 m, Open Ocean at 145 m, Shallow Bay at 252 m, with the final sample at approximately 334 m.
- Destination A: exposed northern coast proxy with large rock/turf masses, high landmark, rocks, landing strip, and one Faroe turf-roof cottage working asset.
- Destination B: sheltered inhabited coast proxy with headlands, back slope, two simple houses, pier, breakwater, harbor landmark, cargo staging, and one Harbor Fishing Shed working asset.
- Outer bounds: simple collision boundaries at approximately x=+-92 m and z=-240/+235 m; destination land also has simple box collision and a lightweight wrapper-side land mask.

## Assets

The V2FUN originals remain untouched. The isolated world loads the working derivatives at runtime:

- `V2FUN_INBOX/working/Faroe_Turf_Roof_Cottage__V2FUN__7e3dd2ee.glb`
- `V2FUN_INBOX/working/Harbor_Fishing_Shed__V2FUN__68c336dd.glb`

Runtime scale is 8.0, recorded as a provisional staging scale only. These working files are pass-through high-poly derivatives and are not mobile-final assets.

## Captures

All captures are 1152x648 viewport images from the game camera:

- `scenes/staging/overnight_playable_north_atlantic_world_01_captures/01_departure_A.png`
- `scenes/staging/overnight_playable_north_atlantic_world_01_captures/02_open_sea.png`
- `scenes/staging/overnight_playable_north_atlantic_world_01_captures/03_first_distant_read_B.png`
- `scenes/staging/overnight_playable_north_atlantic_world_01_captures/04_approach_B.png`
- `scenes/staging/overnight_playable_north_atlantic_world_01_captures/05_harbor_entry_B.png`
- `scenes/staging/overnight_playable_north_atlantic_world_01_captures/06_arrival_B.png`
- `scenes/staging/overnight_playable_north_atlantic_world_01_captures/07_reverse_view.png`

## Verification performed

- `gda script validate` passed for the active script.
- `gda scene validate` passed for the active scene.
- `gda scene preflight` reached `status=ready` with no diagnostics.
- Two complete runtime capture launches completed with `PLAYABLE_WORLD_CAPTURE_COMPLETE` and no shader/script errors.
- A GUI runtime launch found the actual Godot game window and accepted a W/D input test without crashing. Window-focus injection did not produce reliable movement telemetry in the redirected log, so player steering feel and route movement still require human in-game confirmation.
- Compressed visual review of the captures confirmed the destination grows from a distant silhouette to a readable nearshore blockout and that the V2FUN working shed appears at arrival.

## Known limitations

- Terrain and harbor pieces are still neutral blockout geometry; broad horizontal proxy strata are visible in close views.
- Destination A is an origin-side staging landmark rather than a finished port scene.
- V2FUN working derivatives are high-poly pass-through files and need a separate conservative optimization pass before mobile production.
- The final subjective judgment of scale, destination readability, and steering feel remains a user playtest gate.

## Formal-project boundary

This overnight slice does not modify formal Sea Trial, Journey Test, formal Port-to-Port scenes, or `project.godot`.
