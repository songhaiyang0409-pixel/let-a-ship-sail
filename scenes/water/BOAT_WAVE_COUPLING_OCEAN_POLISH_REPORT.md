# BOAT WAVE COUPLING OCEAN POLISH REPORT

## 0. Scope and completion boundary

This report covers an isolated visual R&D scene only:

`scenes/water/BoatWaveCouplingOceanPolish.tscn`

The scene instantiates a copy of the Robin Hood's Bay blockout and drives a duplicated boat visual. It does not instantiate or modify the production controller, timer, voyage state, collision, wake, formal camera behavior, Sea Trial, Journey Test, Port-to-Port gameplay, or `project.godot`.

The goal was to test whether the boat can feel spatially connected to a moving stylized ocean without implementing buoyancy or changing gameplay physics.

## 0.1 Isolated interactive trial entry points

After the visual candidate review, the same isolated scene was given two development-only keyboard launch profiles. These are visual coupling trials, not Sea Trial or Journey Test replacements:

- `启动B+V3耦合试航.bat` launches the selected **B+ V3** profile.
- `启动H3+V3耦合试航.bat` launches the selected **H3+ V3** profile.

Controls in either launcher:

- `W` / `Up`: accelerate forward; release to coast and slow down.
- `S` / `Down`: brake first; after reaching zero, continue holding to reverse slowly.
- `A` / `D` or `Left` / `Right`: smoothly steer the boat yaw.
- `Space`: toggle a smooth stop; press again after stopped to resume.
- Hold the left mouse button and drag: orbit the isolated camera around the boat; release to keep the view.
- `R`: reset the isolated camera to the default rear three-quarter view.
- `Backspace`: reset the isolated boat to its starting pose.

The interactive path changes only the duplicated boat visual and its duplicated camera in this scene. It does not call production steering, controller, timer, collision, wake, voyage-state, Sea Trial, or Journey Test code. No HUD is added.

## 1. Baseline diagnosis

The locked Variant B and Hybrid V3 R&D baselines already had readable long-wave geometry, but their boat was only a visual copy placed above the water. The water moved through vertex displacement while the boat did not sample that displacement in this R&D scene. This produced the specific failure:

> animated water plane + boat model, rather than boat sitting inside a moving sea.

The baseline differences were preserved:

| Property | Variant B baseline | Hybrid V3 baseline |
|---|---|---|
| Base waves | Four active Gerstner layers | Same four layers |
| Amplitude scale | 0.70 | 0.70 |
| Wavelength scale | 3.8 | 3.8 |
| Visual treatment | Broad triangular/faceted regions | Quiet broad directional flow and distance quieting |
| Repetition read | More geometrically visible | Less obvious at distance |
| Near-water read | Clearer broad shapes | Quieter, lower contrast |
| Noise | Low | Lowest at distance |

The baseline record is also in [BOAT_WAVE_BASELINE.md](BOAT_WAVE_BASELINE.md).

## 2. Shared wave sampling implementation

The new shader and GDScript sampler use the same active base wave parameters and the same Gerstner calculation:

- `wave_1 = (0.34, 3.60, 0.18, 0.86)`
- `wave_5 = (1.42, 0.28, 0.12, 2.18)`
- `wave_7 = (-1.05, 2.90, 0.08, 1.30)`
- `wave_8 = (-0.58, -1.22, 0.10, 1.82)`
- `wave_amplitude_scale = 0.70`
- `wave_length_scale = 3.8`
- `time_factor = 2.7`

At the boat world X/Z position the sampler:

1. Evaluates the four base waves.
2. Sums vertical displacement for local water height.
3. Sums analytic wave normals for local slope.
4. Adds the candidate's weaker secondary wave with the same direction, wavelength, speed factor, phase, amplitude normalization and time basis used by the shader.
5. Applies a damped height response to the duplicated boat root.
6. Derives pitch from slope along the boat heading and roll from lateral slope.
7. Smooths the transform so the visual remains calm and readable.

The secondary shader parameter normalization was corrected after the first run so its wavelength and amplitude are identical between vertex rendering and boat sampling. The boat heading was also separated from its tilted Basis so pitch/roll cannot feed back into the yaw sample.

This is deterministic visual following, not physical buoyancy. The boat visual has no authority over movement, collision, controller, or gameplay position.

## 3. Height, pitch and roll experiments

The candidate table in `boat_wave_coupling_ocean_polish.gd` deliberately varies heave, pitch and roll response rather than adding an unrelated bobbing sine wave.

### Observed response

- B+ V1: clearly readable heave and tilt, but the larger tilt makes the boat feel more synchronized with the broad wave pattern.
- B+ V2: lower tilt and smoother slope response; the boat sits more calmly while still moving with the sampled surface.
- B+ V3: strongest usable height response among the restrained candidates, with weaker roll; the spatial relationship is easiest to read without a seasick look.
- H3+ V1: quieter and less visually assertive than B+ V1.
- H3+ V2: stable compromise with less visible broad-band repetition.
- H3+ V3: calmest and least intrusive; the boat response is readable in near-water views but less obvious at the normal overview distance.

The deliberately excessive calibration uses heave `1.65`, tilt `1.35`, roll `1.20`, stronger secondary waves and stronger contact. It visibly leaves the restrained style range and is labeled [REJECTED_TOO_STRONG_boat.png](boat_wave_coupling_ocean_polish_captures/rejected_too_strong/REJECTED_TOO_STRONG_boat.png). It is not a candidate.

## 4. Secondary-wave experiments

The secondary system was kept to one additional broad Gerstner layer. It was not used to replace the locked base waves.

Tested direction/scale/speed families include:

- B+ V1: direction `(0.82, 0.28)`, wavelength `5.4`, relative time `0.70`, steepness `0.030`.
- B+ V2: direction `(0.66, -0.75)`, wavelength `6.4`, relative time `0.58`, steepness `0.038`.
- B+ V3: direction `(-0.36, 0.93)`, wavelength `7.2`, relative time `0.48`, steepness `0.043`.
- H3+ V1: direction `(0.74, -0.67)`, wavelength `6.8`, relative time `0.66`, steepness `0.026`.
- H3+ V2: direction `(-0.52, 0.85)`, wavelength `7.6`, relative time `0.54`, steepness `0.032`.
- H3+ V3: direction `(0.38, 0.92)`, wavelength `8.4`, relative time `0.44`, steepness `0.035`.

The visual result was richer when the secondary direction and speed were sufficiently separated from the base layers. The low-amplitude, long-wavelength versions reduced synchronized rows; the extreme calibration instead made the sea busier and was rejected.

## 5. Crest, slope and trough shading experiments

All shading remains procedural and low-frequency:

- Base trough / water / crest colors use smooth height interpolation.
- All candidates use a restrained analytic normal light response.
- B+ V1 uses broad facet value separation.
- B+ V2 adds a broad directional ribbon to the facet read.
- B+ V3 keeps a softer diagonal ribbon and lower distance contrast.
- H3+ V1/V2/V3 progressively use quieter broad flow and stronger distance quieting.

There are no textures, high-frequency normals, foam stacks, caustics, refraction, or screen-space effects.

## 6. Contact and waterline tests

Contact treatments were intentionally local and weak, not screen-space halos:

- V1 profiles: weak local contact darkening, no visible waterline band.
- V2 profiles: stronger local contact darkening plus a very weak local waterline contribution.
- V3 profiles: slightly stronger but still restrained contact and waterline values.

The shader uses boat world position and heading to calculate a small local response. It is evaluated in the water material and does not modify the boat mesh. The differences are subtle at overview scale and more inspectable in `04_near_water.png` and `06_boat_side.png`.

## 7. Bow disturbance tests

The isolated scene adds one `BowInteraction_TEST_ONLY` mesh. It is a small graphic wedge, not a replacement for the formal wake system. Its scale is driven by the capture speed value:

- idle: `0.0`, hidden
- near-water: `0.6`, weakly visible
- turning: `0.8`
- cruising: `1.0`

The wedge is deliberately low-alpha and disappears at rest. It remains a prototype calibration aid; its final readability and whether it belongs in the project require human review.

## 8. B+ V1 → V2 → V3 progression

### B+ V1 diagnosis before V2

V1 made sampled movement readable, but the stronger pitch/roll and first secondary direction still made the boat response feel too synchronized with the broad geometric pattern. Contact was too weak to be judged confidently.

### B+ V2 correction

V2 changed the secondary direction, increased its wavelength, slowed its relative phase, reduced tilt/roll, added a restrained directional ribbon, and made contact/waterline response separately visible. This reduced the “rubber boat” risk and improved wave separation.

### B+ V3 diagnosis before final V3

V2 was calmer, but the broad directional read could still become a repeated surface pattern over longer viewing. The waterline treatment also needed to stay local and the boat needed to remain the clear visual subject.

### B+ V3 correction

V3 uses the longest B+ secondary wavelength, the slowest relative speed, the weakest roll among B+ candidates, stronger distance quieting, a softer ribbon direction, and a low-strength contact/waterline response. It retained the clearest usable broad wave read of the B+ family without using high-frequency texture.

## 9. H3+ V1 → V2 → V3 progression

### H3+ V1 diagnosis before V2

H3+ V1 preserved the quiet H3 character, but the coupling signal was close to the threshold of being lost at the normal overview distance. The secondary direction needed more separation without adding visible noise.

### H3+ V2 correction

V2 used a different diagonal secondary direction, a longer wavelength and slower relative time, while retaining a quiet broad-flow shader treatment. The boat response became more stable and the water remained less busy than B+.

### H3+ V3 diagnosis before final V3

H3+ V2 was stable but still needed a clearer distinction between near-water readability and quiet horizon behavior. Increasing detail would have violated the style target, so the final pass used scale and distance separation instead.

### H3+ V3 correction

V3 uses the longest H3+ secondary wavelength, lowest relative speed, weakest roll, soft broad flow, stronger far-distance quieting and restrained contact. Its tradeoff is that the boat/water coupling is less obvious from the overview camera.

## 10. Captures and visual QA

The actual graphical run generated matching captures for:

- `baseline_b`
- `baseline_h3`
- `b_plus_v1`
- `b_plus_v2`
- `b_plus_v3`
- `h3_plus_v1`
- `h3_plus_v2`
- `h3_plus_v3`
- `rejected_too_strong`

Each baseline and candidate includes:

- `01_idle.png`
- `02_cruising.png`
- `03_turning.png`
- `04_near_water.png`
- `05_horizon.png`
- `06_boat_side.png`
- `temporal/00.png` through `temporal/05.png`

All regular screenshots are `1152 x 648`.

Representative final captures:

- [B+ V3 near water](boat_wave_coupling_ocean_polish_captures/b_plus_v3/04_near_water.png)
- [B+ V3 boat side](boat_wave_coupling_ocean_polish_captures/b_plus_v3/06_boat_side.png)
- [H3+ V3 near water](boat_wave_coupling_ocean_polish_captures/h3_plus_v3/04_near_water.png)
- [H3+ V3 boat side](boat_wave_coupling_ocean_polish_captures/h3_plus_v3/06_boat_side.png)
- [B+ V2 temporal start](boat_wave_coupling_ocean_polish_captures/b_plus_v2/temporal/00.png)
- [B+ V2 temporal later](boat_wave_coupling_ocean_polish_captures/b_plus_v2/temporal/05.png)
- [Rejected calibration](boat_wave_coupling_ocean_polish_captures/rejected_too_strong/REJECTED_TOO_STRONG_boat.png)

The temporal sequences show the sampled water phase changing beneath a fixed test boat. The boat's height and orientation change with the same sampled wave function; the difference is subtle by design and is easier to see in the near-water and side captures than in the overview.

## 11. Long-duration observation

An actual 60-second graphical observation was run with B+ V3:

1. 0–10 seconds: stationary.
2. 10–22 seconds: slow straight sailing.
3. 22–34 seconds: normal straight sailing.
4. 34–46 seconds: slow turn.
5. 46–60 seconds: repeated heading changes, including parallel/across-wave style heading changes.

The runtime printed sampled height and normal values at 5-second intervals. The samples changed over time and remained bounded; no script or shader error appeared during the observation. This is a visual observation path, not a production movement system.

Long-duration limitations: the current blockout island is intentionally simple, and the command-line run cannot substitute for a human judging motion comfort, perceived weight, or visual fatigue.

## 12. Performance and compatibility

Actual run command:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/water/BoatWaveCouplingOceanPolish.tscn" -- --capture-boat-wave-coupling
```

Long observation command:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/water/BoatWaveCouplingOceanPolish.tscn" -- --observe-boat-wave-coupling
```

Observed runtime information:

- Godot 4.7.2 loaded the isolated scene successfully.
- Renderer: Compatibility / OpenGL 3.3, because the existing project configuration was not changed.
- Capture run: `draw_calls=130`, `primitives=261970`.
- Reliable GPU ms/frame was unavailable in this runtime, so no GPU timing number is invented.
- No water shader compilation error was observed in the actual graphical runs.
- The `user://logs` and shader-cache warnings are environment warnings from this runtime and are unrelated to the isolated shader logic.

## 13. Files created or modified

New isolated files:

- `materials/water_test/boat_wave_coupling_ocean_polish.gdshader`
- `scenes/water/boat_wave_coupling_ocean_polish.gd`
- `scenes/water/BoatWaveCouplingOceanPolish.tscn`
- `scenes/water/BOAT_WAVE_BASELINE.md`
- `scenes/water/BOAT_WAVE_COUPLING_OCEAN_POLISH_REPORT.md`
- `scenes/water/boat_wave_coupling_ocean_polish_captures/`
- `启动B+V3耦合试航.bat`
- `启动H3+V3耦合试航.bat`

Modified isolated files:

- `scenes/water/boat_wave_coupling_ocean_polish.gd` — added the development-only interactive trial path and removed an unused input variable.
- This report — documented the two launchers and their controls.

Formal project files modified: **0**.

## 14. Remaining visual issues

- The boat and island are still prototype blockout assets; this task did not replace production art.
- B+ retains more readable broad geometry but also carries more visible repetition risk than H3+.
- H3+ is quieter and more stable at distance, but the coupling signal can be too subtle from the overview camera.
- Contact and bow treatment are intentionally restrained and need human review for whether they read as water contact instead of decoration.
- The current graphical run used Compatibility rather than Forward+, so this is not a Forward+ performance certification.
- Human play remains necessary to judge whether the boat feels seated, weighty, calm and non-rubbery over a long session.

## 15. Technical recommendation

For the next isolated visual review, start with **B+ V3**. It provides the clearest readable relationship between broad wave shape and boat response while remaining inside the restrained prototype range.

Keep **H3+ V3** as the quieter alternative if the next human review prioritizes an unobtrusive far ocean over obvious near-water coupling.

This is a technical recommendation, not a final artistic selection. The final choice belongs to human review, and neither candidate has been connected to the formal project.
