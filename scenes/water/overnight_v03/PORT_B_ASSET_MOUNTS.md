# Port B Asset Mounts

`PortB_Root`

- `PortBVisualRoot`
  - `PortBVisualLayouts`
    - `PortBVisualLayout_A`
    - `PortBVisualLayout_B`
    - `PortBVisualLayout_C`
      - `LighthouseMount`
      - `HousesMount`
      - `PierMount`
      - `BreakwaterMount`
      - `RocksMount`
      - `VegetationMount`
      - `LandmarkPropsMount`
- `PortBCollisionRoot`

The active placeholder blockout is generated only inside the selected layout. `PortBCollisionRoot` is an explicit architecture marker; the actual current collision remains the cheap, independent `_is_presentation_land(position)` function so visual replacement does not change route behavior.
