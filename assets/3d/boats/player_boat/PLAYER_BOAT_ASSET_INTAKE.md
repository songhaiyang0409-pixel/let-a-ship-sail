# Player Boat Asset Intake Contract

This directory is the canonical handoff point for the approved player-boat 3D binary.

## Naming roles

- 2D visual source gate: `PLAYER_BOAT_MOTHER_IMAGE` — image/reference only.
- Approved 3D source archive name: `PLAYER_BOAT_MASTER_MODEL_LOCKED_v001.glb`.
- Runtime canonical filename: `approved_player_boat.glb`.

Do not call a GLB `MOTHER_IMAGE`; that name is reserved for the locked 2D visual source.

## Runtime path

`res://assets/3d/boats/player_boat/approved_player_boat.glb`

Code and wrapper scenes should target this stable path. Incoming upload filenames may be random GUIDs and are never authoritative by filename alone.

## Authority / integrity

The currently approved v001 binary is expected to have:

- size: `54393580` bytes
- SHA-256: `4fc1d1ada5622b1b9d8ed561ecff9c204bfbbbe75f557704cc14042e92cf9816`

A future replacement must be explicitly approved and must update this contract/manifest. Newer timestamps or similar filenames do not override the approved asset automatically.

## Locked visual identity

- one mast
- exactly two triangular sails
- low / semi-sunken cabin
- blue upper hull
- dark reddish lower hull
- cream sails
- warm wood accents
- exactly one clear rudder
- small auxiliary propeller
- small working sailboat proportions

Do not substitute an older boat, gaff/quadrilateral-sail version, double-rudder candidate, tall yacht cabin, racing hull, Viking form, or unrelated model.

## Intake workflow

1. Treat the user-approved binary as source; preserve the source unchanged.
2. Verify size/hash when possible.
3. Copy the approved runtime binary to `approved_player_boat.glb` in this directory.
4. Use the existing visual-only player-boat adapter / `PLAYER_BOAT_MODEL_SCENE` boundary.
5. Do not change controls, collision, gameplay camera, waterline logic, boat-wave coupling, wake, or `project.godot` just to fit the visual model.
6. Calibrate wrapper transform/orientation/scale/waterline only.
7. Run asset readiness + authoritative A→B + protected Sea Trial/Journey regressions.
8. A binary asset is not persisted by the text relay patch. Confirm the GLB itself exists in shared Git before declaring binary persistence complete.

## Large-file handoff rule

Linear Free attachments are limited to 10 MB. Large player-boat binaries must therefore be moved into the repository through a local Codex/worktree or another shared binary-capable channel. Do not ask the user to rename the file manually; the project manager / asset-manager thread owns naming and routing.
