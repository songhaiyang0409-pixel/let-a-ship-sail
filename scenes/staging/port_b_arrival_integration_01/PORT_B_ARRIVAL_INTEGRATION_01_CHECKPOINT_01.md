# PORT B ARRIVAL INTEGRATION 01 — CHECKPOINT 01

## Review cycle 01 — shoreline weight
- Evidence before: cycle_00_baseline/
- Runtime observation: the working apron was a large, heavy foreground slab that competed with the arrival read.
- Isolated fix: reduced Layout B working apron from (17, 0.28, 5) to (12, 0.16, 3.4).
- Preserved: Layout B dog-leg, route, collision probes, canonical boat/controller/camera/ocean/wake.
- Evidence after: cycle_01_apron/
- Result: shore weight reduced; the next remaining issue was the shed/pier relationship.