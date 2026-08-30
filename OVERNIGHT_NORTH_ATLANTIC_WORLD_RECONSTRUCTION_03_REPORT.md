# OVERNIGHT NORTH ATLANTIC WORLD RECONSTRUCTION 03

## Result

An isolated Reconstruction 03 derivative is ready for continued world production. It preserves the validated B+ V3 Regional Ocean, boat/wave coupling, boat, camera, controls, wake, and the Reconstruction 02 rollback point. The new world remains deliberately a blockout, not final island art.

## Final scene and launcher

- Scene: `scenes/staging/reconstruction_03/NorthAtlanticWorldReconstruction03.tscn`
- World script: `scenes/staging/reconstruction_03/north_atlantic_world_reconstruction_03.gd`
- Launcher: `启动NorthAtlanticWorldReconstruction03.bat`
- Route: Destination A at approximately `START_Z=160` to Destination B at `END_Z=-175`, approximately `335 m`.
- Estimated route time from the scene's tested speed constants: normal `152.3 s`; test speed `67.0 s`.

## What changed in four evidence-backed passes

1. Added low continuous west/east harbor arms to make B read as a sheltered opening.
2. Aligned the V2FUN working shed with the central working bank, pier, and path; retained the isolated working scale `6.8`.
3. Differentiated A as cooler/exposed rocky terrain and B as greener/sheltered inhabited terrain using only large-form color changes.
4. Reused the existing shore-strip helper for a low working harbor apron and placed the shed behind the working edge.

No new gameplay system, shader, boat, camera, control, wake, or formal scene was introduced.

## World structure

### Destination A — exposed northern coast

- Continuous irregular sloped landforms rather than a single slab.
- Exposed rocky landing, windward ridge, sparse path, lighthouse proxy, rocks, and the V2FUN turf-roof cottage.
- Cooler rock/green treatment to separate it from B.

### Destination B — sheltered inhabited working coast

- Two sheltering headlands and two low harbor arms.
- Inhabited rear slope with two simple proxy houses.
- Sheltered shore, breakwater rocks, low working bank, working harbor apron, pier, path, cargo proxy, lighthouse proxy, and V2FUN fishing shed.
- Visual and collision roots remain separate in the generated world: `WorldVisualRoot_REPLACEABLE` and `WorldCollisionRoot_SIMPLE_PROXY`.

## V2FUN integration

- Cottage source used through the existing working derivative:
  `V2FUN_INBOX/working/Faroe_Turf_Roof_Cottage__V2FUN__7e3dd2ee.glb`
- Shed source used through the existing working derivative:
  `V2FUN_INBOX/working/Harbor_Fishing_Shed__V2FUN__68c336dd.glb`
- Originals were not changed. No new optimization pass was started in Reconstruction 03.

## Runtime and visual QA evidence

Final route capture files are in `scenes/staging/reconstruction_03_captures/`:

- `01_departure_A.png`
- `02_open_sea.png`
- `03_mid_voyage.png`
- `04_first_distant_read_B.png`
- `05_approach_B.png`
- `06_harbor_entry_B.png`
- `07_arrival_B.png`
- `08_reverse_view.png`

Contact evidence:

- `__qa_baseline_small.jpg`
- `__qa_cycle01.jpg`
- `__qa_cycle02_full.jpg`
- `__qa_cycle03.jpg`
- `__qa_cycle04_arrival.jpg`
- `__qa_final_contact.jpg`
- `__qa_baseline_vs_final.jpg`

Actual checks completed:

- R03 script validation: valid, no diagnostics.
- R03 scene validation: valid, no problems.
- R03 scene preflight: ready, no diagnostics.
- B+ V3 runtime launch: reached `NORTH_ATLANTIC_RECONSTRUCTION_03_READY` with `formal_project_modified=false`.
- Final runtime capture: completed all eight views at `1152x648`; no stderr was emitted.
- B+ V3 regional samples logged Harbor Calm, North Atlantic/Faroe, Open Ocean, and Shallow Bay route zones.
- A bounded non-capture runtime launch remained alive for 8 seconds and produced no stderr; it was then stopped by the test harness.
- A bounded Windows native keyboard/window probe could not bring the Godot window to the foreground; the captured before/after image was the Codex foreground window, so this is not counted as gameplay input evidence.

## Acceptance status

- A/B scene isolation: **CONFIRMED**.
- Four improvement cycles with evidence: **CONFIRMED**.
- A and B have different spatial roles: **PARTIALLY CONFIRMED**; the distinction is visible at blockout scale, but B is still simplified.
- B reads as a sheltered working harbor blockout: **PARTIALLY CONFIRMED**; the harbor relationship improved, but the geometry is not production art.
- V2FUN buildings are placed in plausible working/settled relationships: **PARTIALLY CONFIRMED**; the shed is aligned and scaled down, but final grounding needs human review.
- Route stage captures from departure through arrival: **CONFIRMED as runtime pose evidence**.
- Interactive player A→B and B→A driving: **NOT CONFIRMED** in this environment. The capture sequence uses world-space test poses, and gda live control reports `live_unsupported_platform` on Windows. This must be manually verified with the launcher.
- Collision, steering, camera, water, boat/wave coupling, and wake regression: **NOT fully confirmed interactively**; no protected code was changed, and scene/preflight/runtime checks passed.

## Known weaknesses and risks

- B still contains simple proxy terrain, houses, rocks, and pier geometry; it is not final harbor art.
- Some shore cuts and proxy pieces may still read as assembled blockout at close range.
- Final building grounding, collision feel, steering around both destinations, and B→A return require manual gameplay verification.
- The final captures are actual game-camera renders, but they are a scripted route-pose sequence rather than proof of keyboard-driven travel.

## Protected files and systems

This Goal did not modify `project.godot`, formal Sea Trial, Journey Test, formal Port-to-Port, Reconstruction 02, the B+ V3 water foundation, boat controls, formal camera logic, boat model, collision logic, or wake implementation. Changes are isolated to the Reconstruction 03 derivative, its evidence, checkpoint/progress notes, and launcher.

## Next three priorities

1. Manual playtest A→B and B→A with the launcher; confirm steering, camera, collision, grounding, and harbor entry.
2. Replace only the approved B harbor visual proxies with selected real assets after human art-direction review.
3. Re-capture the canonical route after interactive validation; keep this R03 blockout as the rollback/reference state.
