# Overnight V03 QA / Polish Passes

Evidence was collected from the isolated `PortToPortSlice03.tscn` scene. No formal Sea Trial or Journey Test scene was changed.

## Pass 1 — Functional A ↔ B loop

Command:

```text
Godot ... PortToPortSlice03.tscn -- --port-to-port-v03-autoplay --port-to-port-v03-roundtrip --quit-after-roundtrip
```

Observed state sequence twice:

```text
DEPARTING_A → OPEN_WATER_TO_B → APPROACHING_B → ARRIVING_B → AT_PORT_B
DEPARTING_B → OPEN_WATER_TO_A → APPROACHING_A → ARRIVING_A → AT_PORT_A
```

Result: PASS. The run completed with `round_trips=2`; the ports do not auto-depart in normal launch.

## Pass 2 — Collision / abuse matrix

Command:

```text
Godot ... PortToPortSlice03.tscn -- --port-to-port-v03-abuse-check
```

Result: PASS, `cases=20`, route coverage `A-B-A-B`. The separate collision check also passed for both ports, docks, and safe reset.

## Pass 3 — Camera / controls boundary

The V03 camera remains the copied approved rear three-quarter rig. Boat movement remains under `PlayableBoat`; camera orbit remains independent. The actual GUI capture was produced with no HUD, gizmos, or debug text. The normal manual input path remains available for human playtest: Space departs from a port, A/D steers, W/S changes speed, mouse drag looks, R resets the camera, and Backspace resets to Port A.

Result: PASS for structural isolation and clean capture; final control feel remains a human acceptance item.

## Pass 4 — Port readability

Reviewed the balanced captures from idle, departure, open water, approach, harbor entry, and both port directions. Port A reads as a low U-shaped harbor; Port B reads as a larger vertical settlement with a high landmark. The harbor mouths remain navigable in the automated route.

Result: PASS for blockout readability. P2: placeholder slabs and the high-angle world overview still look technical and are intentionally left for future art/content work.

## Pass 5 — Water / atmosphere presets

Captured identical stage packages for `calm`, `balanced`, and `lively`. All use the same Gerstner geometry and boat wave-follow. The preset changes are limited to atmosphere, lighting, and restrained surface-response values. Each package reports 63 draw calls and 157179 primitives in the GUI capture run.

Result: PASS for isolation and consistency. No shader compile errors were observed. `balanced` remains the technical default; no permanent winner is declared.

## Pass 6 — Final presentation regression

Regenerated the balanced 13-shot package after the V03 changes and checked the key images with the real game camera. Formal regression tests remained green:

- Sea Trial 01 input path: PASS
- Sea Trial 01 navigation: PASS
- Sea Trial 02 world: PASS
- Journey Test 02 navigation: PASS

Result: PASS for the current isolated package. Remaining visible flaws are blockout/final-art limitations, not a broken A ↔ B loop.

## Known limitations kept intentionally

- Port geometry is still low-cost placeholder blockout.
- The optional sheltered-harbor wave modulation and extra micro-landmark were not added because they would expand the slice without improving the core loop evidence.
- The world overview camera can reveal the finite test-water plane from a high angle.
- GPU milliseconds are unavailable from the current runtime; draw calls/primitives are reported instead.
