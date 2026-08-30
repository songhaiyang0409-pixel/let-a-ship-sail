# World Scale Guide — Isolated Port-to-Port V03

This guide applies only to the isolated overnight / port-to-port prototype and
its `AssetGallery`. It does not authorize a production boat rescale.

## Unit convention

- `1 Godot unit ≈ 1 meter`.
- `Y` is up.
- Boat forward is local `-Z`.
- Imported asset pivots should sit on the supporting ground/water contact plane,
  centered on the asset footprint unless an articulated pivot is required.
- Apply model transforms before export. Do not compensate for inconsistent
  source scale in the voyage controller.

## Two different scales — do not conflate them

### RAW MODEL SCALE

The current generated boat visual, as authored by the existing prototype,
exposes an approximately `1.75 m` hull after its current presentation scale.
Its approximate visible dimensions are:

- hull length: `1.75 m`;
- hull width: `0.74 m`;
- visible hull body height: `0.43 m`;
- mast / sail height above the visual waterline: `2.2 m`.

This is the preserved raw/presentation asset reference. It remains unchanged
in the production boat and formal sailing scenes.

### INTENDED GAME-WORLD SCALE

For the isolated V03 / AssetGallery workflow, the intended player sailboat hull
length is approximately `6 m`. The gallery creates a duplicate only and applies
this reference factor:

`6.0 / 1.75 = 3.4286x`

The duplicate is named `IntendedGameWorldBoatReference_6mHull`. It exists to
validate proportions against human-scale references; it is not a permanent
rescale of the production boat.

## Human-scale references in AssetGallery

- `1 m` cube;
- `1.8 m` human-height marker;
- `3 m` marker;
- `10 m` marker;
- a `6 m` hull-length guide below the intended-scale boat.

## Provisional incoming asset target ranges

These are scale targets for future GLB / GLTF assets, not a Port B redesign.
Validate every incoming asset in `AssetGallery` before approval.

| Asset | Provisional target range |
| --- | --- |
| Player sailboat | hull length `5.5–7 m`; width `1.8–2.4 m`; overall mast/sail height `6–8 m` |
| Small house | width `3–5 m`; depth `3–6 m`; height `2.5–4 m` |
| Two-story house | width `4–7 m`; depth `4–8 m`; height `5–8 m` |
| Pier | deck height `0.4–0.8 m` above water; width `2–3 m`; useful segment length `5–15 m` |
| Harbor entrance | clear navigable width `12–25 m` |
| Lighthouse | overall height `8–16 m` |
| Tree | typical readable height `4–10 m` |

## Validation rules

- Check hull/ground or hull/water contact before judging proportions.
- Check pivot, forward axis, scale, material response, shadow, and collision
  separately.
- Keep formal Sea Trial, Journey Test, water, controls, and production boat
  untouched while calibrating this gallery.
- Treat all placeholder geometry and generated prototype visuals as
  `PLACEHOLDER`, not final art.
