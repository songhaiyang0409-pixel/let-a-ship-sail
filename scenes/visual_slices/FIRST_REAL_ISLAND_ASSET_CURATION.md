# First Real Island Visual Slice 01 - Asset Curation

## Selected source

'KayKit_Forest_Nature_Pack_1.0_FREE.zip' was selected for the first natural
environment pass because its included 'License.txt' states Creative Commons
Zero (CC0), allowing personal, educational, and commercial use. Only a small
subset was copied into the project; the original download remains in the user
Downloads folder.

Selected models:

- 'Rock_1_A/B/C_Color1.gltf', 'Rock_2_B_Color1.gltf'
- 'Tree_1_A/B_Color1.gltf', 'Tree_Bare_1_A_Color1.gltf'
- 'Bush_1_A/B_Color1.gltf'

The shared 'forest_texture.png' and the required '.bin' files were copied next
to their GLTF files so Godot can import them without a hidden external path.

## Conditional / not used in this slice

- Broken Vector 'Demo.zip', 'Models.zip', 'Models (1).zip', and related DAE
  packs: overlapping copies and no complete license text in the supplied
  files. Kept in Downloads for later review; not used here.
- 'LowpolyForestPack.zip': useful rock/tree candidates, but the supplied
  readme has no explicit license terms. Not used as an approved source.
- 'MBJ_PLANTPACK_01_FREE.zip': its README permits personal/commercial use but
  prohibits redistribution as an asset pack. It is not needed for this slice.
- Blender-only packs and Unity packages: not imported because no Blender
  conversion is needed for the selected GLTF subset.

## Project policy

Natural assets are sparse and placed for silhouette and shoreline scale, not
as a dense asset-pack forest. Terrain masses, pier, breakwaters, beacon, and
three future building sites remain explicitly marked placeholders. The
temporary RegionalOceanSystem proxy stays the collision/navigation authority
but is hidden visually by the slice wrapper.
