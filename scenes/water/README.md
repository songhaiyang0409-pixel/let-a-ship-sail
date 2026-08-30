# Water Test

`WaterTest.tscn` is an isolated validation scene for the copied Boujie Water
Shader addon. It does not replace the project's existing sea and does not load
the main sailing scene.

The scene uses the addon `Ocean` runtime script and `outset_ocean_material.tres`.
It intentionally does not copy the repository's full `example/` directory. The
shipped example prefabs reference wave preset files outside the addon folder;
the Water Test validates the self-contained addon prefab components and material
without adding that example project to this game.
