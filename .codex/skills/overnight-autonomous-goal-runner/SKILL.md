---
name: overnight-autonomous-goal-runner
description: Run long, multi-phase Godot production goals from checkpoints with runtime evidence, safe fallbacks, and mandatory quality loops.
---

# Overnight autonomous goal runner

Use this skill for long autonomous production goals in this sailing project.

- A completed phase is not completion of the Goal. Preserve the full requested scope.
- Read the current project and checkpoint before editing; resume at the first incomplete item.
- Establish a small rollback/checkpoint note before risky reconstruction and update it after major phases.
- Runtime and visual work requires actual scene launches, gameplay-camera captures, logs, and inspection; code validation alone is insufficient.
- If a tool fails, try a safe equivalent local method before calling the project blocked. `apply_patch` failure alone is not a blocker; for isolated project files, a precise encoding-preserving Python/PowerShell replacement is allowed when needed.
- Prefer existing scenes, shaders, helpers, and native Godot features. Avoid duplicate systems and speculative abstractions.
- After the baseline works, perform substantial improvement cycles: run, capture, rank visible failures, fix the highest-impact issue, rerun, compare, and checkpoint.
- Do not shrink the requested scope to claim success, and do not pad the run with low-value work.
- Keep formal scenes and project configuration outside scope unless a real dependency makes a minimal change unavoidable.
- Use reversible fallbacks and isolate optional failures so independent production can continue.
- Declare blocked only after safe fallbacks are exhausted and useful work cannot continue; record evidence and the next action.
- Finish with a runnable deliverable, standard captures, a concise report, and an explicit list of remaining user-judgment items.
