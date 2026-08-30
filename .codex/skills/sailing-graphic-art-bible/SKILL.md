---
name: sailing-graphic-art-bible
description: Apply the approved visual language and screenshot-based QA rules for this sailing focus game when planning, modeling, rendering, or reviewing its 3D art.
metadata:
  short-description: Project sailing art rules and visual QA
---

# Sailing Graphic Art Bible

Use this project-local skill for recurring art-direction decisions in the sailing focus game. It is a compact operational bible for the currently approved rules; do not invent omitted requirements from a later mission document.

## Core visual target

- Build a true 3D world whose rendered image reads like a restrained, moving graphic illustration.
- Prioritize, in order: big color blocks > silhouette > depth layers > composition > light and shadow > detail.
- Keep visual information compressed, calm, readable, and suitable for a vertical mobile screen.
- The sea, sky, boat, and a simple distant silhouette must work before additional content is added.
- Use plain-color materials and designed planes to prove form before adding texture.
- The approved water foundation is the shared B+ V3 Gerstner structure with synchronized boat sampling and regional presets; do not create a parallel approved water family.
- Project scale is approximately 1 Godot unit = 1 meter. The intended production player sailboat hull is approximately 6 m; preserve raw prototype scale until a deliberate asset replacement.

## Anti-drift rules

Do not let the result become:

- an ordinary low-poly asset-pack scene;
- a detailed Japanese or Ghibli-like background illustration;
- realistic PBR, scanned materials, dense normal maps, or simulation-heavy water;
- a toy boat, pirate ship, fantasy warship, or cluttered deck;
- a busy productivity dashboard disguised as a sailing game.

Primitive geometry is allowed as a blockout, but visible hero forms must have intentional silhouettes and edited proportions. Do not leave unmodified cubes as the final hull, cabin, roof, island, or landmark when the task is a visual pass.

## World and player identity

- The player is the captain; the boat is the player's presence in the world.
- The main boat must have a readable physical cabin volume from the first production-facing prototype and remain plausible for future interior entry.
- Character species, crew composition, and story roles are currently undecided; do not encode them as visual production rules. Characters are not an MVP requirement.
- Current scope is sea travel and destinations. Do not add land free-walking or island exploration without explicit scope change.
- Islands and landmarks should first read as distance, silhouette, and destination; avoid decorative clutter.

## Boat rules

- Read the boat immediately as hull + cabin + mast + sail at the real game-camera distance.
- Favor a warm, compact, sturdy, lived-in cruising sailboat with a curved hull, narrowed bow, stable stern, designed cabin roof, and simple cream sail.
- Use a small material set: warm wood, dark hull accent, cabin beige, warm-white sail, dark mast, and restrained accents.
- Do not use boxes, barrels, ropes, windows, or texture detail to rescue a weak silhouette.
- Keep motion subtle: bob, pitch, roll, sail life, and a restrained wake.

## Sea, sky, and distance

- Sky: clean large color field, restrained gradient, few graphic clouds, clear horizon, no heavy volumetrics.
- Sea: large controlled blue/blue-teal fields, readable large-scale wave shapes, restrained highlight response, and a wake that communicates forward motion.
- Keep near/mid/far separation quiet. Distant water and landmarks should simplify rather than become noisy.
- Avoid neon cyan, continuous white horizon bands, dense high-frequency ripples, excessive foam, caustics, refraction, and high-gloss demo-water behavior.
- Use true world-space geometry and world-space landmarks for approach; do not fake distance with screen sprites or background scaling.
- Use regional water as local response over the shared base: Harbor Calm, North Atlantic / Faroe, Open Ocean, and Shallow Bay are preset variations, while Coastal/Shallow/Harbor are smooth local modifiers rather than separate shader implementations.

## Interaction and UI direction

- Default sailing view has no persistent HUD, progress bar, quest list, minimap, route arrow, coin/level display, or reward popup.
- Prefer diegetic UI: information belongs to a chart, logbook, weather instrument, ship state, light, sail, landmark, or other world object.
- Debug controls and diagnostics may exist in isolated development scenes, but must be disabled in final visual screenshots.

## Scope guard

Before adding a feature, check whether it improves the quiet voyage, companionship, forward movement, destination anticipation, or visible passage of time. Do not add NPC systems, collection systems, shops, combat, daily tasks, or pressure mechanics merely to make a visual scene feel busy.

## Mandatory visual QA

For any visual implementation or Blender/Godot presentation task, follow this loop:

`modify -> run the actual project or scene -> capture real game-camera screenshots -> compare with the checklist and reference A/B -> list concrete failures -> fix only those failures -> capture again`

Never declare a visual task complete from code inspection or intention alone. Report screenshot paths, what was run, concrete pass items, and concrete weak/fail items. If the real scene cannot run or screenshots cannot be inspected, mark visual QA incomplete.

Minimum game-view evidence:

- normal sailing composition;
- closer boat shot for hull/cabin/mast/sail readability;
- distant shot for sea/sky/landmark layering;
- phone-size readability check;
- no editor gizmos, temporary labels, debug UI, or conventional HUD.

## Reference assets

Use the existing project references as visual evidence, not as instructions to copy text, UI panels, or layouts:

- `E:/让一艘船航行/.codex/skills/graphic-sailing-art-director/assets/reference-a.png`
- `E:/让一艘船航行/.codex/skills/graphic-sailing-art-director/assets/reference-b.png`

Detailed project boundaries and ship specifications remain in the existing `graphic-sailing-art-director/references/` files and should be read when a task needs them.
