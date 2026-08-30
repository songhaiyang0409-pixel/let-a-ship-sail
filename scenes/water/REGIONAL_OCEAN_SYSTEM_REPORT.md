# REGIONAL OCEAN SYSTEM REPORT

## 1. Scope

This is an isolated regional-water prototype. It is not connected to Sea Trial, Journey Test, formal Port-to-Port, production water, production boat control, collision, wake, `project.godot`, islands, buildings, UI, missions, or progression.

The approved B+ V3 wave structure remains the foundation. The new system uses one shared shader, one shared subdivided water mesh, four small Godot Resource presets, and one duplicated boat visual.

## 2. B+ V3 preservation

Preserved without changing the proven structural behavior:

- the four active base Gerstner layers: wave 1, wave 5, wave 7, and wave 8;
- `wave_time`, `time_factor = 2.7`, `wave_amplitude_scale = 0.70`, and `wave_length_scale = 3.8`;
- the B+ V3 secondary direction, wavelength, speed, phase, and formula;
- shared analytic sampling for water geometry and boat wave follow;
- the B+ V3 boat response baseline: heave `0.50`, pitch `0.25`, roll `0.18`;
- the existing warm cabin sailboat visual copy.

Regional amplitude and secondary strength are applied to both the shader and the GDScript sampler. Therefore a transition changes the water surface and the boat response from the same values instead of producing a separate boat jump.

## 3. Preset architecture

`regional_ocean_preset.gd` defines a compact Godot `Resource` with only useful regional controls:

- trough, normal-water, crest, and atmospheric colors;
- restrained amplitude multiplier;
- secondary-wave strength;
- broad surface contrast;
- saturation;
- horizon response;
- subtle specular and Fresnel strength.

`regional_ocean_b_plus_v3.gdshader` is the only regional water shader. Its route position is evaluated in world space and uses smoothstep bands to interpolate the four presets. No shader is duplicated per region and no heavy water mesh is duplicated per region.

The route order is:

`Harbor Calm → North Atlantic / Faroe → Open Ocean → Shallow Bay`

The route origin is world Z `10`. Transition bands are:

| transition | route distance | width |
|---|---:|---:|
| Harbor Calm → North Atlantic / Faroe | 32–48 m | 16 m |
| North Atlantic / Faroe → Open Ocean | 70–86 m | 16 m |
| Open Ocean → Shallow Bay | 112–128 m | 16 m |

These same boundaries are used by the shader and the boat sampler.

## 4. Four final presets

| preset | intended read | amplitude | secondary | contrast | saturation |
|---|---|---:|---:|---:|---:|
| Harbor Calm | lighter, calmer, sheltered | 0.72 | 0.55 | 0.26 | 0.82 |
| North Atlantic / Faroe | grey-blue, cool, lower saturation | 0.92 | 0.78 | 0.34 | 0.76 |
| Open Ocean | deeper, desaturated, strongest travel read | 1.00 | 1.00 | 0.42 | 0.90 |
| Shallow Bay | lighter blue-green, gentle coastal water | 0.64 | 0.42 | 0.22 | 0.84 |

All four remain muted blue/blue-teal variants of the same ocean. None uses tropical turquoise, a separate wave formula, foam, caustics, refraction, or a new high-frequency texture layer.

## 5. V1 → V2 → V3 visual iteration

The capture runner produced an actual game-camera overview for all three versions of every preset. V1 and V2 are deliberate diagnostic variants derived from each final Resource; V3 is the Resource value used by the route.

### Harbor Calm

- V1 increased secondary strength, surface contrast, and saturation. Diagnosis: the sheltered water became too visually active and lost some of its quiet arrival character.
- V2 reduced the excess toward the target. Diagnosis: wave readability remained while the water stopped competing with the boat.
- V3 uses the calmer Resource values and is the final candidate.

### North Atlantic / Faroe

- V1 made the cool regional identity and broad wave read more assertive. Diagnosis: darker troughs and stronger contrast risked making the region feel heavier than the warm graphic world.
- V2 kept the grey-blue distinction but reduced the aggressive response.
- V3 uses the lower-saturation, restrained final values.

### Open Ocean

- V1 made the B+ V3 travel character most obvious. Diagnosis: the stronger surface response made broad repetition easier to notice.
- V2 reduced the excess while retaining the clearest large-scale motion.
- V3 preserves the original approved B+ V3 identity and is the strongest open-water candidate.

### Shallow Bay

- V1 made the lighter coastal color more noticeable. Diagnosis: too much surface response would contradict the intended gentler bay read.
- V2 reduced contrast and secondary motion.
- V3 is the lightest and calmest final regional response while remaining recognizably the same ocean.

The actual screenshots show the intended difference primarily through broad value/color and response changes. They do not create four unrelated materials.

## 6. Transition implementation

The shader blends colors and regional controls with three smoothstep bands in world-space route distance. The boat sampler performs the same sequential interpolation for amplitude multiplier, secondary strength, and all visual response data.

During a transition:

- primary Gerstner wave identity stays constant;
- amplitude changes continuously;
- secondary contribution changes continuously;
- surface contrast and atmospheric response change continuously;
- boat heave, pitch, and roll read from the same interpolated wave sample;
- there is no preset switch event or one-frame snap.

The route uses no island or destination art. Optional small boundary posts can be enabled with `--regional-ocean-markers`; they are hidden by default and are test markers only.

## 7. Drivable route

Launch with `启动区域海洋试航.bat`, or use:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64.exe" --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/water/RegionalOceanSystem.tscn" -- --regional-ocean-test
```

Controls:

- `W` / `Up`: accelerate forward;
- `S` / `Down`: brake first, then reverse after reaching zero;
- `A` / `D` or arrow keys: turn;
- left mouse drag: orbit the isolated camera;
- `R`: reset the camera;
- `Space`: smooth stop/resume;
- `Backspace`: reset the boat to the route origin.

The automated observation command is:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/water/RegionalOceanSystem.tscn" -- --observe-regional-ocean
```

The actual graphical observation completed in about 59 seconds and logged Harbor Calm, North Atlantic / Faroe, Open Ocean, and Shallow Bay in order, including all three transition bands.

## 8. Screenshot comparison

All captures are `1152 x 648`, made by the actual Godot game camera with the same duplicated boat and lighting setup.

Final preset captures:

- Open Ocean: `regional_ocean_captures/open_ocean/01_overview.png`, `02_boat.png`, `03_world.png`;
- Harbor Calm: `regional_ocean_captures/harbor_calm/01_overview.png`, `02_boat.png`, `03_world.png`;
- North Atlantic / Faroe: `regional_ocean_captures/north_atlantic_faroe/01_overview.png`, `02_boat.png`, `03_world.png`;
- Shallow Bay: `regional_ocean_captures/shallow_bay/01_overview.png`, `02_boat.png`, `03_world.png`.

Route captures:

- `regional_ocean_captures/route/00_harbor_calm.png`
- `regional_ocean_captures/route/01_harbor_to_atlantic.png`
- `regional_ocean_captures/route/02_north_atlantic.png`
- `regional_ocean_captures/route/03_open_ocean.png`
- `regional_ocean_captures/route/04_shallow_bay.png`

Iteration captures are under `regional_ocean_captures/iterations/<preset>/V1_overview.png`, `V2_overview.png`, and `V3_overview.png` for all four presets.

Observed facts from the captures:

- Open Ocean has the deepest and clearest broad wave read.
- Harbor Calm and Shallow Bay are visibly lighter and calmer.
- North Atlantic / Faroe is the least saturated/coolest variant.
- All four retain the same large-scale wave family and warm boat readability.
- No island was added, so destination/world readability is intentionally not evaluated here.
- The water still occupies most of the image and can be visually dominant without a distant land anchor; this is a known limitation of the no-island route scope.

## 9. Technical observations

Actual graphical capture run:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/water/RegionalOceanSystem.tscn" -- --capture-regional-ocean
```

Runtime facts:

- Godot `4.7.2` loaded the scene and all four resources.
- Renderer was Compatibility / OpenGL 3.3 because `project.godot` was deliberately not changed.
- Capture output reported `draw_calls=46`, `primitives=365484`.
- Reliable GPU milliseconds per frame were unavailable; no GPU timing number is invented.
- No water shader compilation error appeared in the graphical capture or route observation.
- Existing runtime warnings about `user://` log/shader-cache/certificate access are environment warnings.

## 10. Files created or modified

New isolated files:

- `materials/water_test/regional_ocean/regional_ocean_b_plus_v3.gdshader`
- `scenes/water/regional_ocean/regional_ocean_preset.gd`
- `scenes/water/regional_ocean/HarborCalm.tres`
- `scenes/water/regional_ocean/NorthAtlanticFaroe.tres`
- `scenes/water/regional_ocean/OpenOcean.tres`
- `scenes/water/regional_ocean/ShallowBay.tres`
- `scenes/water/regional_ocean/regional_ocean_system.gd`
- `scenes/water/RegionalOceanSystem.tscn`
- `scenes/water/regional_ocean/README.md`
- `启动区域海洋试航.bat`
- `scenes/water/regional_ocean_captures/`

Modified isolated file:

- `scenes/water/regional_ocean/regional_ocean_system.gd` was corrected for async source-boat initialization and capture-camera locking during verification.

Formal project files modified: **0**.

## 11. Unresolved issues

- The scene is an ocean-system test route, not a final world route; no island or destination context was added.
- The current project remains on its unchanged Compatibility renderer, so this is not a Forward+ certification.
- The visual differences are intentionally restrained and should receive human judgment for whether the four regions are distinct enough without becoming four unrelated materials.
- Manual keyboard feel and camera comfort still require human playtest; the automated observation confirms runtime route progression and transition logging, not subjective handling quality.
- A future production integration would still need a deliberate decision about how voyage progress selects or blends regional presets.

