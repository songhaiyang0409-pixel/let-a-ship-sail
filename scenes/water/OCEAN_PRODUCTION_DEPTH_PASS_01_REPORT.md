# Ocean Production Depth Pass 01

Isolated visual experiment based on the approved B+ V3 regional ocean.

## Scope

- The candidate keeps the B+ V3 macro Gerstner layers and the existing
  `RegionalOceanSystem` boat height / pitch / roll sampler.
- The candidate shader adds two restrained medium-scale visual wave layers,
  one low-frequency directional surface breakup, a rare crest breakup mask,
  and a small bow-pressure response.
- The wrapper adds a world-space structured wake with a short three-second
  lifetime. It is a visual test layer and does not replace formal wake logic.
- The baseline mode renders the original B+ V3 material with the same copied
  reference boat, camera and placeholder coast.

## Files

- `scenes/water/ProductionDepthPass01.tscn`
- `scenes/water/production_depth_pass_01.gd`
- `materials/water_test/regional_ocean/regional_ocean_depth_pass_01.gdshader`
- `启动OceanProductionDepthPass01.bat`
- `启动OceanProductionDepthPass01基线.bat`

## Parameters

- Macro B+ values: unchanged (`wave_amplitude_scale=0.70`,
  `wave_length_scale=3.8`, same four active wave parameters).
- Medium visual layers: directions `(0.82,0.24)` and `(-0.20,0.98)`,
  wavelengths `7.5` and `12.0`, combined strength `0.48`.
- Micro directional response: strength `0.035`, scale `0.62`, fragment-only.
- Crest breakup is deliberately low contrast (`0.055`) and fades at distance.
- Bow response is restrained and speed-driven; it does not affect geometry.
- Wake lifetime is `3.0 s`, spacing `0.16 m`, maximum history `120` points.

## Non-goals

No formal scene, project settings, Sea Trial, Journey Test, Port-to-Port,
controls, collision, formal wake or formal camera behavior is modified.

## Captures

Candidate and baseline captures are generated under:

- `scenes/water/production_depth_pass_01_captures/candidate/`
- `scenes/water/production_depth_pass_01_captures/baseline/`

The capture script uses the reference scene's actual game camera.

## Runtime verification

- gda script validation: passed for the new wrapper and existing regional
  system, using the project's Windows Godot 4.7.2 console binary explicitly.
- gda scene validation and preflight: passed for ProductionDepthPass01.tscn.
- Candidate window run: completed without stderr errors after fixing one
  shader compile issue found by the first runtime log.
- Baseline window capture: completed with the original B+ V3 material.
- Dynamic observation: the candidate was run through the existing automated
  coastal route for eight seconds; route distance advanced from zero through
  the first regional samples without runtime errors.
- Four 1152x648 candidate captures and four matching baseline captures were
  generated from the real game camera.

The Windows environment does not support gda's live daemon/screen controls,
so manual steering comfort, wake appearance during a held turn, and temporal
perceptual quality remain human playtest checks. This pass did not alter any
formal sailing scene or project.godot.
