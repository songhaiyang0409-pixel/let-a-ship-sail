---
name: sailing-modeling-reference
description: Create separate, consistent modeling-reference images and asset breakdowns from an approved sailing concept or Source-of-Truth image. Use for 3D reconstruction, animation-ready part planning, and multiview references; do not use for redesigning the asset.
---

# Sailing Modeling Reference

Use this skill only when the user supplies an approved concept/source image and requests modeling views, 3D asset decomposition, animation-ready parts, or reconstruction references.

## Identity gate

1. Treat the user-approved image as the asset identity Source of Truth. If the player boat is not explicitly locked, apply the player-boat R-002 gate from `sailing-visual-production` and stop for approval before treating it as final.
2. Extract and freeze identity-defining features before making views.
3. Separate findings into visible confirmed geometry, reasonable 3D inference, and unknown/hidden geometry. Never silently turn unknown geometry into a new design.
4. Research real-world nautical, mechanical, or architectural structure first when function matters.
5. Separate only parts that plausibly need rotation, steering, sail deformation/control, rigging motion, propeller/shaft rotation, opening/closing, independent animation, independent material replacement, or meaningful reuse. Do not explode every static detail.

## View production

Produce each requested view as a separate image file. Never create a four-view collage, turnaround board, contact sheet, inset panel, explanatory board, or multi-angle sheet when separate views are requested. A normal set is:

- one 3/4 identity/master view;
- one strict side view;
- one strict front or rear view;
- one strict top view.

Each image contains one object and one camera/view. All views must describe the same 3D object: proportions, hull/body, cabin/body structures, materials, wear, equipment locations, and rigging/major components stay consistent. Camera changes reveal geometry; they do not redesign it. The top view must be a genuine projection of the same volume, not a flattened icon or invented silhouette.

## Cross-view rejection gate

Before delivery, audit all views against each other and reject the set if identity drifts, proportions change, locked color/material changes, components move without evidence, one view contradicts another, hidden mechanical structure is invented, or multiple requested views are combined into one file. Generated references are candidates, not automatically project truth.

