---
name: sailing-visual-production
description: Recover the sailing project's current visual Source of Truth before visual design, reference inspection, image generation or editing, visual QA, and player-boat or environment appearance work. Use for candidate convergence and art-direction decisions; do not use for modeling turnarounds.
---

# Sailing Visual Production

Use this project skill for visual production in the sailing project. It owns source-control and review gates; an unapproved generated image is never automatically project truth.

## Source-of-truth recovery

Before visual work, inspect the current project entry/routing rules, hard-rules skill, decision log, reference index, and relevant implementation/evidence. Prefer newer explicit sources. If a named source is absent, report that fact and continue only from sources that are present. If sources genuinely conflict, stop and report the conflict.

Classify every visual input:

- `LOCKED`: explicitly approved project truth. Preserve identity-defining features unless the user requests redesign.
- `LOCAL`: current candidate, editing base, experiment, or local evidence. Useful for diagnosis, never automatically truth.
- `REJECTED`: explicitly rejected, obsolete, or historical material. Do not use as a default reference.

The current direction is `True 3D + Graphic Stylized 3D + North Atlantic`: believable real-world construction underneath simplified shapes, compressed color/material language, intentional silhouettes, calm readable detail, and restrained believable weathering. World logic remains real while visual expression is simplified. Do not drift into generic AI concept art, photorealism, toy/pirate/fantasy boats, dense decorative clutter, or a separate style for the player boat.

## Player-boat R-002 Source-of-Truth Gate

Treat the supplied/current player-boat image as `LOCAL` unless the project explicitly says it is locked. Never reconstruct it from an old text description. Freeze identity-defining features from the current image before editing, and preserve what works. A request to fix one component is not permission to redesign the vessel. Generated images are candidates until the user explicitly locks one.

For a candidate repair pass:

1. Inspect the actual image and compare it with current project evidence.
2. Diagnose `KEEP`, `FIX`, `UNCERTAIN`, and `STYLE MISMATCH`.
3. Propose the smallest high-impact edit pass.
4. Edit one gameplay-relevant 3/4 view unless the user asks for another deliverable; keep the entire boat visible and do not add labels, panels, insets, turnarounds, or technical annotations.
5. Compare the result against the source and reject it if it is merely different rather than clearly better overall.

## Internal QA

Before showing a result, identify the three largest visible problems and distinguish structural errors (hull proportion, cabin volume, sail arrangement, equipment placement, camera/readability) from local errors (one edge, small color, minor wear, or isolated detail). Check that the hull has not become fatter, the low integrated cabin has not grown generic, successful two-triangular-sail identity has not been lost, equipment has not moved without reason, and the boat has not become cleaner, newer, or more luxurious.

After two repeated failures of the same core issue, change the method or narrow the edit rather than blindly regenerating. Do not make the user perform obvious first-pass QA.

For implementation-facing visual work, keep the approved shared B+ V3 regional water foundation and existing project art rules in view. Do not modify Godot code as a side effect of a visual-reference task.

