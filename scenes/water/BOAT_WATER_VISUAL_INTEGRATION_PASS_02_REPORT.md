# BOAT WATER VISUAL INTEGRATION PASS 02

## Scope

This is an isolated visual integration pass. It preserves the B+ V3 macro
ocean, the useful subtle micro-wave layer from Ocean Production Depth Pass 01,
the canonical boat/wave coupling, and Prototype C world-space wake history.
Sea Trial, Journey Test, Port-to-Port V03, project.godot, steering, camera,
boat art, and formal wake code were not changed.

## What was preserved from Prototype C

Every wake sample still stores its world position, historical heading, age,
strength, and seed. Old samples therefore remain on the route that the boat
actually travelled during a turn. The approved behavior remains:

moving boat -> generate wake
stop -> stop generation
old wake -> remain -> fade once -> disappear
restart -> generate new wake

## Why RND 01 looked like a ribbon

The old material drew mostly opaque vertex-colored quads with visible straight
boundaries and nearly uniform coverage. Even though the points were stored in
world space, the eye read the connected coverage as a grey translucent hose.
The bow also used too little local contrast to make sideways displacement
readable from the gameplay camera.

## Visual representation changes

The new isolated material is
materials/water_test/boat_water_interaction_pass_02.gdshader.

It keeps one dynamic ArrayMesh but adds:

- seeded procedural alpha breakup;
- elongated local masks instead of round full-quad coverage;
- internal holes and eroded edges;
- small, slow temporal variation;
- per-patch UV2 seed and age;
- transparent coverage so the underlying water remains visible.

The GDScript geometry also applies small seeded rotation and scale variation.
The wake is no longer drawn as one connected strip.

## Bow displacement

The bow is independent from the historical wake. A compact center pressure
patch begins at the bow waterline, then separates into short port/starboard
pieces with increasing lateral offset. The patches are low-cost and low-alpha,
weaken with speed, and are absent at rest. They are not straight rails or
permanent hull outlines.

## Three wake zones

- Zone A, close stern: narrow, denser turbulence with a short lifetime.
- Zone B, middle wake: wider side remnants with gaps and occasional loose
  fragments.
- Zone C, far wake: sparse, weak fragments with larger gaps and lower alpha.

There is no second history system; the zones are derived from the same sample
age and strength data.

## Foam and material strategy

Foam colors are pale desaturated water/foam values rather than pure white.
Dark blue-gray patches carry part of the turbulence information, so disturbed
water is not represented entirely as foam. The material is unshaded, nearly
fully rough, uses one shader material, and has no particles, caustics,
refraction, fluid simulation, or high-frequency texture stack.

At normal test speed the bounded history is about 42 samples for the current
3.8 second lifetime. The selected path uses at most roughly 170 masked patch
quads including bow and hull-side pieces, in one dynamic mesh/material; the
actual count varies with the seeded skips and age.

## Three visual correction cycles

### Iteration 1

Observed failure: the bow disturbance was barely readable, and the remaining
patch geometry was still too easy to infer.

Correction: replaced full-alpha patch appearance with seeded procedural
breakup, and increased the compact bow pressure and side separation.

### Iteration 2

Observed failure: the bow became readable and the hose silhouette was reduced,
but the wake pieces looked too much like a repeated chain of round bubbles.

Correction: changed the mask to an elongated local shape, introduced true
internal gaps, and varied the patch orientation, size, and seed.

### Iteration 3

Observed result: the long-turn capture shows separated historical structures
with open water between them rather than a continuous strip. The final pass
adds only slow temporal breakup and a small number of loose mid-zone fragments
to reduce repeated shapes.

## Runtime and stop-decay verification

The final selected C scene was actually launched at 1152x648. Static script
validation, scene validation, and scene preflight all passed. The 23-second
automatic observation completed stationary, slow, cruise, left turn, right
turn, stop, wait, and restart.

The dedicated stop check reported:

- cruise: speed 2.20
- stopped: speed 0.00, existing samples still present
- restart: speed 2.20
- end: wake_samples=33, new_after_restart=true

This confirms the previously approved stop-decay data behavior was preserved.
It does not replace human judgment of whether the visual result feels like
water pushed by a hull.

## Screenshots

Final selected C captures:

- scenes/water/boat_water_visual_integration_pass_02_captures/c_fragmented_patches/01_bow_close.png
- scenes/water/boat_water_visual_integration_pass_02_captures/c_fragmented_patches/02_straight_cruise.png
- scenes/water/boat_water_visual_integration_pass_02_captures/c_fragmented_patches/03_long_turn.png
- scenes/water/boat_water_visual_integration_pass_02_captures/c_fragmented_patches/04_immediately_after_stop.png
- scenes/water/boat_water_visual_integration_pass_02_captures/c_fragmented_patches/05_later_decay.png

Previous RND 01 C comparison remains at:

scenes/water/boat_water_interaction_rnd_01_captures/c_fragmented_patches/02_cruise.png

All listed captures are 1152x648 and contain no HUD or editor gizmos.

## Remaining weaknesses

The boat is small in the normal gameplay composition, so the bow push remains
deliberately restrained and should be checked by the user at normal speed and
in a closer view. This is still a stylized prototype: it has no spray volume,
physical foam, or natural offshore whitecaps. The visual A–O acceptance still
requires human inspection; no automatic test can prove the absence of a
subjective hose/jet-exhaust reading.

## Launch

Selected C:

E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64.exe --path E:\让一艘船航行 --resolution 1152x648 res://scenes/water/BoatWaterInteractionRND01.tscn -- --sailing-reference --boat-water-rnd-01

Automatic observation:

append --boat-water-auto-demo

Stop/restart check:

append --boat-water-stop-check

## Files

Added:

- materials/water_test/boat_water_interaction_pass_02.gdshader
- scenes/water/BOAT_WATER_VISUAL_INTEGRATION_PASS_02_REPORT.md

Modified:

- scenes/water/boat_water_interaction_rnd_01.gd

The existing isolated scene, launcher, and previous RND 01 captures remain in
place. No formal sailing scene or project configuration was changed.
