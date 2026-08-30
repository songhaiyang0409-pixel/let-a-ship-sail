# OVERNIGHT AUTONOMOUS MICRO-WORLD REPORT

## Goal Status

V03 isolated micro-world build complete for the current in-scope prototype. Final art, content systems, and formal Sea Trial integration remain out of scope.

## V02 Fallback

`scenes/water/fallback/PortToPortSlice01_Fallback.tscn` and its local script remain available. The V02 working copy remains under `scenes/water/overnight_v02/`.

## V03 Current Best Build

`scenes/water/overnight_v03/PortToPortSlice03.tscn`

Normal launch starts stopped at Port A. Space departs from the current port. On arrival the boat stops and remains there until Space is pressed again. Backspace resets to the stopped Port A start position.

## A ↔ B Loop

The local state model is:

`AT_PORT_A → DEPARTING_A → OPEN_WATER_TO_B → APPROACHING_B → ARRIVING_B → AT_PORT_B`

and the symmetric return path:

`AT_PORT_B → DEPARTING_B → OPEN_WATER_TO_A → APPROACHING_A → ARRIVING_A → AT_PORT_A`

Arrival speed is continuously reduced; ports do not automatically depart in normal play. Explicit autoplay is only available through the V03 command-line test arguments.

## Port A / Port B

Port A remains the low, quiet, functional U-shaped placeholder harbor. Port B remains the larger, more vertical Robin-Hood's-Bay-inspired placeholder cove with a high landmark, clustered slope settlement, lower shore, and dock.

## Harbor Navigation / Collision

The existing lightweight world-space land guard was reused and applied symmetrically to both ports. It stops at the last safe sub-step, preserves steering, and allows a reverse or turn-away escape. No rigid-body impulse or teleport was added.

## Boat / Wave Follow / Camera / Wake

The V03 scene uses the existing isolated boat visual extraction, wave-follow root, approved camera behavior, and world-space wake implementation. These were not copied into or connected to formal Sea Trial systems.

## Presets

Identical capture packages exist under:

- `port_to_port_slice_03_captures/calm/`
- `port_to_port_slice_03_captures/balanced/`
- `port_to_port_slice_03_captures/lively/`

Presets only vary restrained atmosphere, light, and surface-response values. Balanced is the technical default; no permanent winner is declared.

## QA / Regression

See `QA_PASSES.md` for six distinct passes and evidence. The V03 abuse run covered 20 cases and A-B-A-B route repetition. Formal Sea Trial 01 input/navigation, Sea Trial 02 world, and Journey Test 02 navigation tests all remained PASS.

## Known Issues

The ports and island masses remain placeholder blockout geometry. The high-angle overview can reveal the finite test-water plane. These are presentation/final-content limitations, not resolved by adding systems in this goal.

## Launch

Double-click `启动PortToPort_V03.bat`. For command-line capture and regression examples, see `README.md`.

Formal existing project files modified: 0.
