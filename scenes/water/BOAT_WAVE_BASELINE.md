# BOAT WAVE BASELINE

## Scope

This document records the locked comparison baselines for the isolated boat/water coupling experiment. It does not change the formal Sea Trial, Journey Test, Port-to-Port scenes, production boat controller, production water, camera behavior, or `project.godot`.

The source baseline is the existing `stylized_ocean_rnd_01.gdshader` used by `StylizedOceanRND01.tscn`. The duplicated boat and Robin Hood's Bay blockout are visual-only copies.

## Locked comparison: Variant B vs Hybrid V3

| Property | Variant B | Hybrid V3 |
|---|---|---|
| Base wave formula | Four active Gerstner layers | Same four active Gerstner layers |
| Base amplitude scale | 0.70 | 0.70 |
| Base wavelength scale | 3.8 | 3.8 |
| Base direction | wave_1 / wave_5 / wave_7 / wave_8 | Same |
| Added visual structure | Broad triangular/faceted value regions and a small broad facet displacement | Quiet broad directional ribbons, stronger distance quieting and small cross-current displacement |
| Repetition visibility | Facet regions are readable and can show broad repeated shapes | Lower contrast and less obvious row repetition |
| Large-scale motion | Clear, geometric, relatively calm | Broad directional flow, quieter at distance |
| Near-water readability | Stronger shape separation | Softer and less busy |
| Horizon behavior | Clean, but broad value regions remain readable | Quietest horizon behavior |
| Visual noise | Low, with geometric structure | Lowest at distance; can become too subdued |

The new coupling scene captures both baselines with matching camera positions before applying any coupling candidate. Baseline captures are not treated as final art; they are comparison controls.

## Shared sampling method

The coupling scene samples the same deterministic function used by the new isolated shader:

1. Evaluate active `wave_1`, `wave_5`, `wave_7`, and `wave_8` at the boat's world X/Z position.
2. Sum their Gerstner vertical displacement for local water height.
3. Sum their analytic wave normals for local slope.
4. For candidate profiles, add one weaker broad secondary Gerstner system with its own direction, wavelength, speed factor, and phase.
5. Apply the sampled height to the duplicated boat visual only.
6. Project the boat heading against the sampled slope and derive restrained pitch/roll; smooth the transform to prevent jitter.

This is deterministic visual following, not hydrodynamic buoyancy. It has no collision or gameplay authority.

## Experiment axes

- Heave candidates: subtle, readable, and deliberately excessive calibration.
- Pitch candidates: derived from slope along the boat heading; never a free-running sine.
- Roll candidates: derived from lateral slope and weaker than pitch.
- Secondary system: broad, lower-amplitude, and deliberately different in direction/scale/speed/phase from the base layers.
- Contact: local darkening and a very weak waterline treatment, tested separately through profile values.
- Bow: one lightweight local bow wedge whose visible scale follows capture speed and disappears at rest.

All parameters are in `boat_wave_coupling_ocean_polish.gd` and are intentionally easy to compare and revert.
