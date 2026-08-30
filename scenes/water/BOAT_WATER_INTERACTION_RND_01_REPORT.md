# BOAT WATER INTERACTION RND 01

## Scope

This is an isolated production experiment for hull-caused water interaction. It
reuses the canonical reference boat, camera, B+ V3 macro-wave sampler, Boat
Wave Follow, and the useful subtle surface layer from Ocean Production Depth
Pass 01. It does not add gameplay and does not change Sea Trial, Journey Test,
Port-to-Port, or project.godot.

## Three approaches tested

### A — continuous world-space ribbon

The boat path is recorded as a widening world-space strip. It is cheap and
makes a curved route obvious, but the continuous surface still reads like one
painted effect trailing behind the boat. Rejected as the production candidate.

### B — shader-only local interaction

The water shader receives boat position, heading, and speed for a local
pressure response. It avoids persistent trail objects, but it cannot leave a
curved historical route and cannot give the hull-side disturbance a readable
world-space presence. Rejected as the production candidate.

### C — fragmented world-space patches (selected prototype)

One bounded dynamic ArrayMesh contains irregular vertex-colored patches for:

- close bow pressure, split and curved outward on both sides;
- short hull-side disturbance at the waterline;
- dense but short stern turbulence;
- older wake remnants that widen, break up, and fade.

Each wake sample stores world position, historical heading, age, strength, and
seed. Existing samples stay in their original world positions while the boat
turns. No particle system, fluid simulation, or emitter line is used.

## Selected behavior and current parameters

- Wake sampling: 0.20 m of travelled distance.
- Maximum stored samples: 96.
- Current experimental wake lifetime: 3.8 s; this is a tunable test value,
  not a final design decision.
- New wake is suppressed below 0.10 speed.
- Bow patches stay close to the waterline and use broken, irregular quads.
- Hull-side patches are low-alpha blue-gray/off-white water breakup.
- Stern disturbance is short and denser than the older wake.
- Older wake remnants widen from about 0.10 to 1.30 m and fade with squared
  lifetime alpha.
- Stopping only ages existing samples. It does not delete them instantly and
  does not create new ones.
- Restarting appends new samples; old samples are never revived.

## Actual runtime evidence

All three approaches were launched in Godot 4.7.2 at 1152x648 with the
isolated scene and exited successfully with code 0. Each produced:

- 01_stationary.png
- 02_cruise.png
- 03_long_turn.png
- 04_stop_decay.png

Capture roots:

- scenes/water/boat_water_interaction_rnd_01_captures/a_ribbon/
- scenes/water/boat_water_interaction_rnd_01_captures/b_shader_only/
- scenes/water/boat_water_interaction_rnd_01_captures/c_fragmented_patches/

The selected C approach also completed the 23-second scripted observation
covering stationary, slow, cruise, left turn, right turn, stop, wait, and
restart. The console reported:

BOAT_WATER_INTERACTION_RND_01_AUTO_DEMO_END|seconds=23.0|approach=C_FRAGMENTED_PATCHES

The dedicated stop check reported:

- cruise: speed=2.20
- stopped: speed=0.00, existing samples still present
- restart: speed=2.20
- end: wake_samples=33, new_after_restart=true

The test wrapper owns its isolated steering sign configuration; the new
boat-water command flag is not retained in the shared formal steering branch.

## Manual visual QA still required

The runtime and screenshot generation are verified, but final visual
acceptance still belongs to a human playtest. In particular, verify A–O from
the task in the actual game camera:

- the old white bow lines are visually gone;
- bow and hull-side interaction read as caused by the hull;
- C does not read as a jet exhaust or opaque white block during turns;
- the historical wake remains behind the route;
- stopping does not cause reappearance;
- low-speed wake is subtle and the boat remains stable.

The local image inspection helper was unavailable in this run, so this report
does not self-certify those visual judgments from code or image file metadata.

## Launch

Selected C approach:

E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64.exe --path E:\让一艘船航行 --resolution 1152x648 res://scenes/water/BoatWaterInteractionRND01.tscn -- --sailing-reference --boat-water-rnd-01

Automatic observation:

append --boat-water-auto-demo

Comparison modes:

- A: --boat-water-approach-a --capture-boat-water-rnd-01
- B: --boat-water-approach-b --capture-boat-water-rnd-01
- C: --capture-boat-water-rnd-01

Stop/restart diagnostic:

append --boat-water-stop-check

## Known limitations

This remains a low-cost visual prototype. It does not yet simulate foam
volume, hull displacement physics, spray, or natural offshore whitecaps. The
current 3.8-second lifetime and patch colors require human tuning against the
actual camera before any production integration.
