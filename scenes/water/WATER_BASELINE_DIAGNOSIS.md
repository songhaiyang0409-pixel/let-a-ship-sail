# WATER BASELINE DIAGNOSIS

## Scope

This diagnosis covers the isolated visual blockout used by Stylized Ocean R&D
01. It does not change or redefine the formal Sea Trial water.

## Current mesh structure

The isolated Robin Hood's Bay blockout creates one `PlaneMesh` water surface:

- size: `190 x 190` world units;
- subdivision: `160 x 160` in the blockout;
- one `MeshInstance3D` named `StylizedWaterForIslandBlockout`;
- boat visual and island are separate world-space nodes.

The formal port-to-port scene has a separate water instance and is not part of
this R&D modification.

## Current material/shader structure

The blockout baseline uses:

- `materials/water_test/stylized_water_prototype_03.gdshader`;
- `render_mode unshaded`;
- no texture samples, caustics, refraction, foam system, or high-frequency
  normal layer;
- broad trough / water / crest color mixing.

The source script supplies four active long-wave layers from the existing
Gerstner starting point: `wave_1`, `wave_5`, `wave_7`, and `wave_8`.

## How visible motion is currently produced

The shader displaces each water vertex with the summed Gerstner result and
advances `wave_time` every frame. The copied boat samples the same long-wave
formula for visual Wave Follow, so its height and restrained orientation are
separate visual synchronization logic rather than physics.

There is no scrolling texture in this baseline. Motion is therefore real
geometry displacement, but the material read is still very broad and quiet.

## Repetition and perceived flatness

The current mesh has a regular grid and the wave field is deterministic. The
four wave directions and wavelengths provide geometric motion, but the baseline
material compresses most of the result into a small number of broad colors.
At the normal camera distance this can read as a large animated colored plane:

1. there is little directional surface response;
2. the horizon removes most high-frequency shape cues;
3. repeated phase relationships are not deliberately broken by secondary
   low-frequency layers;
4. the boat has Wave Follow, but the water does not provide enough local visual
   context to make that relationship obvious.

This is a diagnosis, not a justification to add dense noise. The R&D variants
will test whether a few broad, phase-offset structures and/or restrained
faceted value regions improve motion readability without becoming busy.

## Baseline capture set

The baseline screenshots are stored under:

`scenes/water/stylized_ocean_rnd_01_captures/baseline/`

They use the same camera positions as Variants A/B/C and Hybrid V1/V2/V3.
