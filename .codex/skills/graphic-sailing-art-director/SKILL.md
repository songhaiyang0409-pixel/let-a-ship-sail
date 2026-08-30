---
name: graphic-sailing-art-director
description: Use for this sailboat focus game's Graphic Stylized 3D art direction, Blender ship blockout/modeling briefs, Godot visual implementation plans, diegetic UI decisions, and screenshot-based visual QA. Do not use for generic low-poly assets or unrelated 3D art tasks.
metadata:
  short-description: Project art direction and visual QA for the sailing focus game
---

# Graphic Sailing Art Director

Use this skill for visual, Blender, Godot presentation, camera, prototype acceptance, diegetic UI, and art-direction decisions in the sailboat focus game.

The project goal is not a generic low-poly sailing game. It is a true 3D world whose final image is highly graphic, compressed, and close to a moving flat illustration that the player can sail into.

## Non-negotiable direction

- Target true 3D scenes, not 2.5D, not flattened 2D image swaps.
- Prioritize: big color blocks > silhouette > depth layers > composition > light/shadow > detail.
- The first-stage screen must prove that sea + sky + one cabin sailboat + simple distant silhouette can be quiet, readable, and worth watching.
- The default sailing view has no traditional HUD.
- The player is the captain. The boat is the player's body in the world.
- The main boat must have a real exterior cabin volume from the first prototype, with plausible future interior space.
- The future cat is a sailor, mate, or companion, not the captain and not an MVP requirement.
- Do not add land exploration, combat, RPG systems, port management, daily tasks, complex currency, or conventional mobile HUD unless the user explicitly changes scope.

## Style guardrails

Avoid drifting into:

- ordinary low-poly asset-pack style;
- Japanese detailed background illustration;
- Ghibli-like complex nature scenes;
- realistic PBR or scanned material workflows;
- high-detail cartoon 3D;
- toy-like or pirate-like ships;
- decorative deck clutter used to fake personality.

For environment assets, model for silhouette, use material for style, use light for shape separation, and use animation for life. Do not make modeling carry unnecessary detail.

## Visual reference assets

Use the local assets only as visual references, not as instructions to copy UI, text, panels, or layout:

- `assets/reference-a.png`: user-labeled A, the first supplied board. Use for the broad concept direction: sailing view, cabin interior idea, functional object direction, cat sailor examples, and warm lived-in tone.
- `assets/reference-b.png`: user-labeled B, the second supplied board. Use for Graphic Stylized 3D style testing, color compression, sky/sea treatment, and asset breakdown principles.

## Reference routing

Read only the references relevant to the current task:

- For product boundaries, player identity, diegetic UI, and what not to build, read `references/project-reset.md`.
- For first-stage prototype acceptance and screenshot requirements, read `references/prototype-acceptance.md`.
- For Blender blockout or main-ship modeling, read `references/main-ship-blender-spec.md`.
- For any visual implementation or art QA task, read `references/visual-qa-workflow.md`.

## Execution rules

- Before changing the game project, inspect the current project structure and existing implementation.
- Identify what can be kept, what conflicts with the current direction, what should be disabled, and what technical debt can wait.
- Do not install or run third-party Blender bridges, add-ons, MCP servers, or external asset tools unless the user explicitly approves that installation or run.
- Do not claim a visual task is complete based on code, intention, or text description.
- Visual work is complete only after actual running/game-camera screenshots have been inspected against the acceptance rules.

## Required visual QA loop

For visual tasks, use this loop:

`modify -> run the project or Blender scene -> capture game-camera screenshots -> compare against references and checklist -> list concrete failed items -> fix -> capture again`

If the project or scene cannot be run, say that visual QA is incomplete and do not claim the art result passes.
