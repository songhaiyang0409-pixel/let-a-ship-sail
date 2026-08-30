# Player boat model integration contract

The Port B playable slice now wraps the current boat geometry in
`VisualModelMount_REPLACE_CONTENTS_ONLY`. The outer
`MainCabinSailboatVisual_COPY_ONLY` node remains the protected motion root used
by steering, the gameplay camera, B+ V3 wave sampling/coupling, and the wake.

## Drop-in procedure

1. Put the finalized model scene under `res://assets/player_boat/` (recommended:
   `res://assets/player_boat/PlayerBoatFinal.tscn`). Keep source `.glb` files in
   the same folder if the scene instances an imported model.
2. Make the scene root a `Node3D`, with identity position/rotation/scale.
3. In `port_b_arrival_integration_02.gd`, set `PLAYER_BOAT_MODEL_SCENE` to that
   `.tscn` path. This is the only required swap edit.
4. Launch the Port B slice, then run the three QA commands in the integration
   report before judging the model visually or by feel.

## Coordinate and scale contract

- Godot axes: forward **-Z**, up **+Y**, starboard **+X**.
- Scale: **1 Godot unit = 1 meter**. The target production hull is about **6 m**
  long. Apply import correction inside the final visual scene, never on the
  protected motion root.
- Root/pivot: centered on the vessel centerline at the design waterline, near
  the longitudinal center of buoyancy. The root must not carry an authored
  world offset. If the mesh origin differs, correct it with a child node.
- Keep visual geometry free of gameplay collision. Collision remains owned by
  the world/controller integration and must not be generated from the render
  mesh.

## Animation-ready child names

The final scene may expose separate `Mast`, `Sail`, `Boom`, `Rudder`, and
`Cabin` child roots. Sail life and rudder animation can be added beneath those
nodes later without moving the scene root. No animation is required for the
initial swap.

## Must remain untouched

Do not rename, scale, reparent, or animate the outer controlled boat root. Do
not redirect `RegionalOceanSystem.boat_visual`, camera tracking, water shader
boat uniforms, wave-follow pose, wake history, steering constants, or world
collision to the model's mesh nodes. The adapter mount is the sole visual
replacement boundary.
