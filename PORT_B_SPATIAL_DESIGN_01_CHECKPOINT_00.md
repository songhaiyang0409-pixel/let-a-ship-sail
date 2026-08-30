# Destination B Spatial Rebuild 01 — CHECKPOINT 00

## Baseline frozen

- Source scene: `scenes/staging/reconstruction_03/NorthAtlanticWorldReconstruction03.tscn`
- Source script: `scenes/staging/reconstruction_03/north_atlantic_world_reconstruction_03.gd`
- Existing evidence: `scenes/staging/reconstruction_03_captures/__qa_final_contact.jpg`, `06_harbor_entry_B.png`, `07_arrival_B.png`
- New work is isolated under `scenes/staging/port_b_spatial_01/`.

## Three largest visible baseline problems

1. Destination B is read as separate low-poly hills instead of one large coastal landform with a clear outer coast, constrained entrance, and protected inner water.
2. The entrance and sheltered-water logic are not legible from the gameplay camera; the route still reads as open water ending at a backdrop.
3. The working building, proxy houses, pier, and shoreline elements read as placed markers rather than a coherent shoreline function.

## Protected baseline systems

The canonical sailing reference, Regional Ocean / B+ V3 wave and boat coupling, formal controls, camera, Sea Trial, Journey Test, Port-to-Port scenes, and `project.godot` are not to be modified by this task.

## Validation note

R03 is preserved unchanged as rollback/reference evidence. Windows `gda` live input is unavailable in this environment; the new staging harness will provide deterministic in-engine traversal and gameplay-camera captures, while human A→B/B→A driving remains a user gate.
