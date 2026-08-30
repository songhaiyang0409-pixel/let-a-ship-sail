# Visual QA workflow

Use this reference for every visual implementation, Blender, camera, lighting, sea, sky, UI, or prototype acceptance task.

## Completion rule

Do not say a visual task is complete because the code changed, the idea is plausible, or the result is described well. Completion requires actual screenshots or renders inspected against the relevant checklist.

Forbidden completion claims:

- "Cargo style is implemented."
- "The effect is already close."
- "This should look right."
- "The code should produce the intended result."

Use observable evidence instead:

- screenshot paths;
- what was inspected;
- concrete pass/fail items;
- what remains wrong.

## Required loop

Use this loop for visual work:

1. Modify.
2. Run the project or Blender scene.
3. Capture screenshots from the real game camera or intended Blender camera.
4. Compare against `assets/reference-a.png`, `assets/reference-b.png`, and the relevant checklist.
5. Explicitly list failed items.
6. Fix the concrete failures.
7. Capture again.

If the scene cannot be run or screenshots cannot be captured, report the limitation and mark visual QA incomplete.

## Minimum screenshot set

For first-stage Godot visual submissions:

- Screenshot A: normal sailing view.
- Screenshot B: boat closer to camera for main-ship readability.
- Screenshot C: distant view visible for depth/layer check.

For Blender main-ship Blockout 01:

- side view;
- 3/4 rear view;
- game-camera-distance view.

All screenshots must be:

- vertical when judging game view;
- from the actual game camera when judging gameplay composition;
- without debug UI;
- without editor gizmos;
- without temporary labels;
- without default HUD;
- stored in a clearly named project folder.

## Checklist categories

When reporting QA, cover only categories relevant to the current task:

- composition: sky/sea/boat/distant read;
- true 3D setup: camera, light, geometry, not flat image swapping;
- Graphic Stylized 3D: big color blocks, silhouette, simple light;
- anti-drift: not asset-pack low-poly, not Japanese detailed background illustration, not realistic PBR;
- boat: cabin visibility, hull/cabin/mast/sail readability, no deck clutter;
- sea: big color fields, restrained glints, wake, motion, no simulation noise;
- sky: clean blue, few graphic clouds, clear horizon;
- distant view: silhouette first, low saturation, not attention-stealing;
- UI: default no HUD, debug hidden in final screenshots;
- motion: comfortable bob/roll/pitch, sail life, wake direction.

## Mobile readability checks

Every visual result must be judged at phone scale:

- Is the boat recognizable immediately?
- Is the cabin visible?
- Does the sail remain a strong warm-white shape?
- Are sea and sky cleanly separated?
- Is the far layer readable but not distracting?
- Can 30% of detail be removed without harming the image?
- If plain-color materials replaced textures, would the asset still read?

Do not add detail to solve a silhouette or composition problem.

## Reporting format

For visual handoff, report:

- files changed;
- screenshot paths;
- what was run;
- pass items;
- failed or weak items;
- next correction step.

Keep subjective claims tied to screenshot evidence.
