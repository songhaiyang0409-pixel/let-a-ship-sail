# COASTAL WATER REGIONAL BLENDING REPORT

## Scope

This is an isolated coastal-water route on top of the approved B+ V3 regional
ocean prototype. It does not modify Sea Trial, Journey Test, formal
Port-to-Port, production boat control, production water, or `project.godot`.
The visible coastline, harbor walls, pier strips, and beacon are explicitly
`PLACEHOLDER_COASTLINE_ONLY` proxy geometry.

## Final architecture

- One shared B+ V3 regional water shader remains the only water shader.
- Four existing `RegionalOceanPreset` resources remain the regional identity
  layer. The coastal test orders the same resources as:
  `North Atlantic / Faroe -> Open Ocean -> Shallow Bay -> Harbor Calm`.
- Three smooth route bands blend the regional layer in world space.
- A separate coastal-local layer computes broad coast and harbor masks from
  world position. It only reduces amplitude, secondary response, and surface
  contrast; it does not duplicate a shader per zone.
- The boat samples the same local-adjusted profile and the same Gerstner
  formula as the shader, so Wave Follow remains continuous through transitions.

## Route and transition strategy

The isolated route starts at world `z=70` and measures forward distance as
`-z - (-70)`. The current transition bands are:

| transition | route distance | width |
|---|---:|---:|
| North Atlantic / Faroe -> Open Ocean | 58–82 m | 24 m |
| Open Ocean -> Shallow Bay | 94–116 m | 22 m |
| Shallow Bay -> Harbor Calm | 126–148 m | 22 m |

The widths are deliberately several boat lengths rather than the previous
16 m default. The goal is to avoid a recognizable preset switch at normal
test speed while leaving enough distance to read the change.

Local conditions are independent of preset identity:

- coastal influence eases in over route distance 62–98 m;
- harbor influence eases in around the central channel from the entry near
  `z=-30` to the back near `z=-74`;
- local modifiers reduce wave energy progressively, with the strongest calm
  response in the central harbor corridor.

## Shoreline strategy

The test world uses two sloped outer headlands, two low harbor wall masses,
back land, narrow muted shoreline strips, two simple pier strips, and one
small beacon. The shader adds a very low-strength shoreline contact tint only
for the broad analytic shore mask. There is no glowing outline, continuous
white foam, caustics, refraction, or extra high-frequency layer.

The current coastline is intentionally a blockout. It proves water behavior
and navigation space, but it is not final island art.

## Failed / rejected approaches

- No separate harbor shader was introduced; that would make future
  archipelago regions expensive and would create material-switch artifacts.
- No hard distance threshold was used for local water conditions; all local
  changes use smoothstep bands.
- No high-frequency texture stack, foam ring, or white shoreline halo was
  added because those would compete with the boat and violate the graphic
  water direction.

## Performance observations

The graphical route capture runs on the existing Godot 4.7.2 project without
changing the formal renderer configuration. Runtime draw information is
reported by Godot; reliable GPU milliseconds are not available from this
environment, so no invented GPU timing is included.

## Evidence generated

Run the coastal capture command to generate:

`scenes/water/regional_ocean_captures/coastal_water/`

The useful evidence set is:

- `01_open_ocean.png`
- `02_coastal_approach.png`
- `03_shallow_shore.png`
- `04_harbor_entrance.png`
- `05_inside_harbor.png`
- `06_return_open_ocean.png`

The capture is from the actual Godot camera and contains no debug HUD.

## Exact files changed

Modified isolated files:

- `materials/water_test/regional_ocean/regional_ocean_b_plus_v3.gdshader`
- `scenes/water/regional_ocean/regional_ocean_system.gd`

New files:

- `启动连续近岸海域试航.bat`
- `COASTAL_WATER_REGIONAL_BLENDING_REPORT.md`
- `scenes/water/regional_ocean_captures/coastal_water/` (generated captures)

Formal production files modified: **0**.

## Remaining weaknesses

- The proxy harbor geometry is deliberately simple and should not be read as
  final Robin Hood's Bay or harbor art.
- The water region is still a stylized analytic surface, not physical
  shallow-water simulation.
- Manual steering feel, visual comfort, and whether the route creates a
  convincing arrival must be judged by a human using the one-click launcher.
