# Regional Ocean System (isolated)

This folder contains the reusable regional preset layer for the approved B+ V3 ocean direction.

- `regional_ocean_preset.gd` is the small Godot `Resource` data definition.
- `HarborCalm.tres`, `NorthAtlanticFaroe.tres`, `OpenOcean.tres`, and `ShallowBay.tres` are the four regional presets.
- `regional_ocean_system.gd` owns one shared water mesh, one shared shader, a duplicated boat visual, and an isolated drivable route.

The primary Gerstner wave function, secondary wave shape, and boat coupling response remain in the system. Presets expose only color, restrained regional amplitude, secondary strength, surface contrast, saturation, horizon response, and subtle material response.

The route uses world-space distance along negative Z. The three transition bands are broad and use the same smoothstep boundaries in the shader and the GDScript boat sampler.

Interactive launcher: `启动区域海洋试航.bat`.

Manual controls: `W`/`Up` forward, `S`/`Down` brake then reverse, `A`/`D` or arrow keys steer, left-mouse drag orbits the camera, `R` resets the camera, `Space` stops/resumes, and `Backspace` resets the boat.

Capture command:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/water/RegionalOceanSystem.tscn" -- --capture-regional-ocean
```

Observation command:

```powershell
& "E:\让一艘船航行\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "E:\让一艘船航行" --resolution 1152x648 "res://scenes/water/RegionalOceanSystem.tscn" -- --observe-regional-ocean
```

This is not connected to Sea Trial, Journey Test, formal Port-to-Port, `project.godot`, or production water.

